import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/career_progress_config.dart';
import '../config/xp_stages.dart';
import '../models/career_goal.dart';
import '../models/event_item.dart';
import '../models/xp_entry.dart';
import '../models/xp_gain.dart';

const Map<String, int> xpDailyCaps = {
  'flashcard': 100,
  'skill_drill': 100,
  'debug': 100,
  'cv_check': 100,
  'skill_practice': 15,
  'mentor_meeting': 100,
};

class PointsManager extends ChangeNotifier {
  PointsManager._();

  static final PointsManager instance = PointsManager._();
  static const _entriesKey = 'xp_log_v1';
  static const _legacyEntriesKey = 'xp_ledger_v1';
  static const _legacyProgressKey = 'career_progress_ledger_v1';
  static const _progressMigrationKey = 'xp_progress_ledger_migrated_v1';
  static const _skillMigrationKey = 'xp_initial_profile_migrated_v1';
  static const _pendingAnimationKey = 'career_progress_pending_animation';

  static final Map<String, int> dailyCaps = Map<String, int>.from(xpDailyCaps);

  final Map<String, EventItem> _joinedEvents = {};
  final List<XpGain> _pendingGains = [];
  final StreamController<XpGain> _gainController =
      StreamController<XpGain>.broadcast();
  List<XpEntry> _entries = const [];
  bool _initialized = false;
  Future<void>? _initializing;
  Future<void> _mutationTail = Future<void>.value();

  bool get isInitialized => _initialized;
  List<XpEntry> get entries => List.unmodifiable(_entries);
  Stream<XpGain> get gains => _gainController.stream;
  int get totalPoints => totalXp;
  int get totalXp => _totalXpForEntries(_entries);
  List<EventItem> get joinedEvents => List.unmodifiable(_joinedEvents.values);

  List<XpGain> drainPending() {
    final gains = List<XpGain>.from(_pendingGains);
    _pendingGains.clear();
    return gains;
  }

  bool hasJoined(String title) => _joinedEvents.containsKey(title);

  void joinEvent(EventItem event) {
    if (_joinedEvents.containsKey(event.title)) return;
    _joinedEvents[event.title] = event;
    notifyListeners();
  }

  Future<void> initialize({SharedPreferences? preferences}) async {
    if (_initialized) return;
    final active = _initializing;
    if (active != null) {
      await active;
      return;
    }
    final initialization = _load(preferences);
    _initializing = initialization;
    try {
      await initialization;
    } finally {
      _initializing = null;
    }
  }

  Future<int> addXP({
    required XpBar thanh,
    required int luong,
    required String nguon,
    String user = 'local',
    String? skill,
    String? sourceRef,
    SharedPreferences? preferences,
    DateTime? at,
  }) async {
    await initialize(preferences: preferences);
    if (luong <= 0 || nguon.trim().isEmpty) return 0;

    return _serialize(() async {
      if (sourceRef != null &&
          _entries.any(
            (entry) =>
                entry.user == user &&
                entry.nguon == nguon &&
                entry.sourceRef == sourceRef,
          )) {
        return 0;
      }

      final timestamp = at ?? DateTime.now();
      final cap = dailyCaps[nguon];
      final sourceToday = _entries
          .where(
            (entry) =>
                entry.user == user &&
                entry.nguon == nguon &&
                _sameDay(entry.thoiGian, timestamp),
          )
          .fold(0, (total, entry) => total + entry.luong);
      final allowed = cap == null
          ? luong
          : (cap - sourceToday).clamp(0, luong).toInt();
      if (allowed <= 0) return 0;

      final before = _totalXpForEntries(_entries);
      final skillBefore = _levelForEntries(_entries, skill, user: user);
      final nextEntries = [
        ..._entries,
        XpEntry(
          id: 'xp-${timestamp.microsecondsSinceEpoch}-${_entries.length}',
          user: user,
          thanh: thanh,
          luong: allowed,
          nguon: nguon,
          thoiGian: timestamp,
          skill: skill,
          sourceRef: sourceRef,
        ),
      ];
      await _save(nextEntries, preferences: preferences);
      final skillAfter = _levelForEntries(nextEntries, skill, user: user);
      final gain = XpGain(
        amount: allowed,
        skill: skill,
        bar: thanh.legacyName,
        leveledUp: skillAfter > skillBefore,
        at: timestamp,
      );
      _pendingGains.add(gain);
      _gainController.add(gain);
      if (user == 'local' &&
          _crossedCareerNode(before, _totalXpForEntries(nextEntries))) {
        final prefs = preferences ?? await SharedPreferences.getInstance();
        await prefs.setBool(_pendingAnimationKey, true);
      }
      notifyListeners();
      return allowed;
    });
  }

  Future<bool> trySpendPoints(
    int amount, {
    SharedPreferences? preferences,
  }) async {
    await initialize(preferences: preferences);
    if (amount <= 0) return false;
    return _serialize(() async {
      if (totalXp < amount) return false;
      var remaining = amount;
      final nextEntries = List<XpEntry>.from(_entries);
      for (final bar in XpBar.values) {
        final available = nextEntries
            .where((entry) => entry.user == 'local' && entry.thanh == bar)
            .fold(0, (total, entry) => total + entry.luong);
        if (available <= 0) continue;
        final spent = available.clamp(0, remaining).toInt();
        if (spent == 0) continue;
        final now = DateTime.now();
        nextEntries.add(
          XpEntry(
            id: 'spend-${now.microsecondsSinceEpoch}-${nextEntries.length}',
            user: 'local',
            thanh: bar,
            luong: -spent,
            nguon: 'spend',
            thoiGian: now,
          ),
        );
        remaining -= spent;
        if (remaining == 0) break;
      }
      if (remaining > 0) return false;
      await _save(nextEntries, preferences: preferences);
      notifyListeners();
      return true;
    });
  }

  int totalXpForSkill(String? skill, {String user = 'local'}) => _entries
      .where((entry) => entry.user == user && entry.skill == skill)
      .fold(0, (total, entry) => total + entry.luong);

  int level(String? skill, {String user = 'local'}) =>
      (totalXpForSkill(skill, user: user) ~/ 100).clamp(0, 10);

  int totalXpByBar(XpBar bar, {String user = 'local'}) => _entries
      .where((entry) => entry.user == user && entry.thanh == bar)
      .fold(0, (total, entry) => total + entry.luong);

  XpStage get currentStage => stageForXp(totalXp);

  double get stageProgress => stageProgressForXp(totalXp);

  List<String> get unlockedFeatures =>
      featuresUnlockedForXp(totalXp, demoMode: demoMode);

  Future<void> migrateInitialSkills(
    Iterable<CareerSkill> skills, {
    Map<String, dynamic> savedMastery = const {},
    SharedPreferences? preferences,
  }) async {
    await initialize(preferences: preferences);
    final prefs = preferences ?? await SharedPreferences.getInstance();
    if (prefs.getBool(_skillMigrationKey) ?? false) return;
    final now = DateTime.now();
    for (final skill in skills) {
      final savedLevel = (savedMastery[skill.name] as num?)?.toInt();
      final skillLevel = (savedLevel ?? skill.level).clamp(0, 10);
      if (skillLevel == 0) continue;
      await addXP(
        thanh: XpBar.kienThuc,
        skill: skill.name,
        luong: skillLevel * 100,
        nguon: 'initial',
        sourceRef: skill.name,
        preferences: prefs,
        at: now,
      );
    }
    await prefs.setBool(_skillMigrationKey, true);
  }

  void resetForTesting() {
    _entries = const [];
    _pendingGains.clear();
    _joinedEvents.clear();
    _initialized = false;
    _initializing = null;
    _mutationTail = Future<void>.value();
    dailyCaps
      ..clear()
      ..addAll(xpDailyCaps);
  }

  Future<void> _load(SharedPreferences? preferences) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final raw =
        prefs.getString(_entriesKey) ?? prefs.getString(_legacyEntriesKey);
    var loadedEntries = raw == null
        ? <XpEntry>[]
        : _decodeEntries(raw, key: _entriesKey);

    final needsProgressMigration =
        !(prefs.getBool(_progressMigrationKey) ?? false);
    if (needsProgressMigration) {
      final legacyProgress = prefs.getString(_legacyProgressKey);
      if (legacyProgress != null) {
        final decoded = jsonDecode(legacyProgress);
        if (decoded is! List) {
          throw const FormatException('Career progress ledger must be a list.');
        }
        for (final item in decoded.whereType<Map>()) {
          final record = Map<String, dynamic>.from(item);
          final source = record['eventType'] as String?;
          final amount = (record['points'] as num?)?.toInt() ?? 0;
          final ref = record['refId'] as String?;
          final timestamp = DateTime.parse(record['timestamp'] as String);
          if (source == null || amount <= 0) continue;
          final migratedId =
              'migrated-$source-${ref ?? timestamp.microsecondsSinceEpoch}';
          if (loadedEntries.any(
            (entry) =>
                entry.id == migratedId ||
                (ref != null &&
                    entry.nguon == source &&
                    entry.sourceRef == ref),
          )) {
            continue;
          }
          loadedEntries.add(
            XpEntry(
              id: migratedId,
              user: 'local',
              thanh: _barForLegacySource(source),
              luong: amount,
              nguon: source,
              sourceRef: ref,
              thoiGian: timestamp,
            ),
          );
        }
      }
    }

    if (raw != null || loadedEntries.isNotEmpty) {
      await _save(loadedEntries, preferences: prefs);
    } else {
      _entries = List.unmodifiable(loadedEntries);
    }
    if (needsProgressMigration) {
      await prefs.setBool(_progressMigrationKey, true);
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _save(
    List<XpEntry> entries, {
    SharedPreferences? preferences,
  }) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      _entriesKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
    if (!saved) throw StateError('Could not persist XP ledger.');
    _entries = List.unmodifiable(entries);
  }

  List<XpEntry> _decodeEntries(String raw, {required String key}) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw FormatException('$key must be a list.');
    }
    return decoded
        .whereType<Map>()
        .map((entry) => XpEntry.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }

  XpBar _barForLegacySource(String source) => switch (source) {
    'flashcardCompleted' || 'skillDrillCompleted' => XpBar.kienThuc,
    'cvFirstCheck' ||
    'cvScoreImproved' ||
    'profileCompleted' ||
    'jobApplied' ||
    'mockInterviewCompleted' => XpBar.hoSo,
    _ => XpBar.thucChien,
  };

  bool _crossedCareerNode(int before, int after) {
    int nodeIndex(int points) {
      var index = 0;
      for (var i = 0; i < careerNodes.length; i++) {
        if (points >= careerNodes[i].threshold) index = i;
      }
      return index;
    }

    return nodeIndex(after) > nodeIndex(before);
  }

  int _totalXpForEntries(List<XpEntry> entries, {String user = 'local'}) =>
      entries
          .where((entry) => entry.user == user)
          .fold(0, (total, entry) => total + entry.luong);

  int _levelForEntries(
    List<XpEntry> entries,
    String? skill, {
    String user = 'local',
  }) =>
      (entries
                  .where((entry) => entry.user == user && entry.skill == skill)
                  .fold(0, (total, entry) => total + entry.luong) ~/
              100)
          .clamp(0, 10);

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  Future<T> _serialize<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _mutationTail = _mutationTail.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}
