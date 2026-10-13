import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/career_progress_config.dart';
import '../models/career_progress.dart';

class ProgressService extends ChangeNotifier {
  ProgressService._();

  static final instance = ProgressService._();

  static const _ledgerKey = 'career_progress_ledger_v1';
  static const _pendingAnimationKey = 'career_progress_pending_animation';
  static const _dailyCap = 100;

  List<ProgressLedgerEntry> _ledger = const [];
  bool _initialized = false;

  bool get isInitialized => _initialized;
  int get totalPoints =>
      _ledger.fold(0, (total, entry) => total + entry.points);
  List<ProgressLedgerEntry> get ledger => List.unmodifiable(_ledger);
  int get dailyCap => _dailyCap;

  Future<void> initialize({SharedPreferences? preferences}) async {
    if (_initialized) return;
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(_ledgerKey);
    if (raw != null) {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Career progress ledger must be a list.');
      }
      _ledger = decoded
          .whereType<Map>()
          .map(
            (entry) =>
                ProgressLedgerEntry.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList();
    }
    _initialized = true;
    notifyListeners();
  }

  Future<int> awardPoints(
    ProgressEventType eventType, {
    String? refId,
    Map<String, Object?> metadata = const {},
    DateTime? at,
    SharedPreferences? preferences,
  }) async {
    _requireInitialized();
    final points = progressPoints[eventType] ?? 0;
    if (points <= 0) return 0;
    if (refId != null &&
        _ledger.any(
          (entry) => entry.eventType == eventType && entry.refId == refId,
        )) {
      return 0;
    }
    final timestamp = at ?? DateTime.now();
    final oldNode = currentNodeFor(totalPoints);
    final dailyTotal = _ledger
        .where((entry) => _sameDay(entry.timestamp, timestamp))
        .fold(0, (total, entry) => total + entry.points);
    final remaining = _dailyCap - dailyTotal;
    if (remaining <= 0) return 0;
    final awarded = points.clamp(0, remaining);
    if (awarded <= 0) return 0;
    _ledger = [
      ..._ledger,
      ProgressLedgerEntry(
        eventType: eventType,
        points: awarded,
        timestamp: timestamp,
        refId: refId,
        metadata: metadata,
      ),
    ];
    final prefs = preferences ?? await SharedPreferences.getInstance();
    await prefs.setString(
      _ledgerKey,
      jsonEncode(_ledger.map((entry) => entry.toJson()).toList()),
    );
    if (currentNodeFor(totalPoints).id != oldNode.id) {
      await prefs.setBool(_pendingAnimationKey, true);
    }
    notifyListeners();
    return awarded;
  }

  Future<bool> consumePendingAnimation() async {
    _requireInitialized();
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(_pendingAnimationKey) ?? false;
    if (pending) await prefs.setBool(_pendingAnimationKey, false);
    return pending;
  }

  String rankFor(int points) {
    var rank = careerRanks.first.name;
    for (final candidate in careerRanks) {
      if (points >= candidate.minimumPoints) rank = candidate.name;
    }
    return rank;
  }

  CareerNodeConfig currentNodeFor(int points) {
    var current = careerNodes.first;
    for (final node in careerNodes) {
      if (points >= node.threshold) current = node;
    }
    return current;
  }

  CareerNodeConfig? nextNodeFor(int points) {
    for (final node in careerNodes) {
      if (node.threshold > points) return node;
    }
    return null;
  }

  int pointsToNextNode(int points) =>
      (nextNodeFor(points)?.threshold ?? points) - points;

  void resetForTesting() {
    _ledger = const [];
    _initialized = false;
  }

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  void _requireInitialized() {
    if (!_initialized) {
      throw StateError('Call initialize() before using ProgressService.');
    }
  }
}
