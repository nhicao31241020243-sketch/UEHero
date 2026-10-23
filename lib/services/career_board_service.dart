import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/career_board_config.dart';
import '../config/career_roadmap_config.dart';
import '../models/app_task.dart';
import '../models/xp_entry.dart';
import 'cv_score_store.dart';
import 'flashcard_service.dart';
import 'mentor_booking_service.dart';
import 'points_manager.dart';
import 'task_repository.dart';

const _boardDoneKey = 'career_board_done_v1';
const _boardSignalsKey = 'career_board_signals_v1';
const _boardMigrationKey = 'career_board_migrated_v1';
const _boardSourceName = 'Career Map';
const _boardWeeklyPrefix = 'board:';
const _legacyRoadmapDonePrefix = 'roadmap_done_';
const _careerGoalKey = 'career_goal';

/// Vị trí mascot theo số ô đã xong, giới hạn trong [0, total - 1].
int boardMascotIndex(int doneCount, int total) {
  if (total <= 0) return 0;
  return doneCount.clamp(0, total - 1);
}

/// Tỉ lệ nhiệm vụ bắt buộc đã xong, từ 0 đến 1.
double boardReadiness(CareerBoard board, Set<String> done) {
  final required = board.tiles.where((tile) => tile.required).toList();
  if (required.isEmpty) return 0;
  final completed = required.where((tile) => done.contains(tile.id)).length;
  return completed / required.length;
}

/// Cổng cuối vùng sáng khi đã xong hết nhiệm vụ bắt buộc của vùng.
bool boardZoneUnlocked(BoardZone zone, Set<String> done) =>
    zone.requiredTiles.every((tile) => done.contains(tile.id));

/// Các ô đã đủ điều kiện nhưng chưa được đánh dấu xong.
Set<String> tilesReachedBy(
  CareerBoard board,
  BoardProgress progress,
  Set<String> done,
) => {
  for (final tile in board.tiles)
    if (!done.contains(tile.id) && progress.meets(tile)) tile.id,
};

/// Chuyển tiến độ cũ (chỉ số chặng đã xong) sang id ô. Không cộng XP lại.
Set<String> migrateLegacyDone(CareerBoard board, Iterable<int> legacyZones) {
  final indices = legacyZones.toSet();
  return {
    for (final zone in board.zones)
      if (indices.contains(zone.index))
        for (final tile in zone.tiles) tile.id,
  };
}

const _hintStopwords = {'basics', 'advanced', 'fundamentals', 'with', 'and', 'the', 'for'};

/// Vùng đang học: vùng đầu tiên chưa xong hết nhiệm vụ bắt buộc, hoặc vùng cuối khi đã xong hết.
BoardZone? boardCurrentZone(CareerBoard board, Set<String> done) {
  if (board.zones.isEmpty) return null;
  return board.zones.firstWhere(
    (zone) => !boardZoneUnlocked(zone, done),
    orElse: () => board.zones.last,
  );
}

Set<String> _keywordsOf(String text) => {
  for (final word in text.toLowerCase().split(
    RegExp(r'[^\p{L}\p{N}]+', unicode: true),
  ))
    if (word.length >= 3 && !_hintStopwords.contains(word)) word,
};

/// Sự kiện khớp vùng khi nhãn sự kiện và tên chặng có chung từ khóa.
bool boardZoneMatchesTags(BoardZone zone, Iterable<String> tags) {
  final keywords = _keywordsOf(zone.skillHint);
  if (keywords.isEmpty) return false;
  return tags.any((tag) => _keywordsOf(tag).any(keywords.contains));
}

String boardWeeklyTaskId(String role, BoardTile tile) =>
    '$_boardWeeklyPrefix$role:${tile.id}';

({String role, String tileId})? _parseWeeklyTaskId(String id) {
  if (!id.startsWith(_boardWeeklyPrefix)) return null;
  final split = id.lastIndexOf(':');
  if (split <= _boardWeeklyPrefix.length) return null;
  return (
    role: id.substring(_boardWeeklyPrefix.length, split),
    tileId: id.substring(split + 1),
  );
}

class BoardTileReward {
  const BoardTileReward({
    required this.role,
    required this.tile,
    required this.stardust,
  });

  final String role;
  final BoardTile tile;
  final int stardust;
}

class BoardProgress {
  const BoardProgress({
    this.flashcardsMastered = 0,
    this.libraryOpened = 0,
    this.cvBestScore = 0,
    this.interviews = 0,
    this.mentorCompleted = 0,
    this.eventsPlanned = 0,
    this.studyBuddyPhotos = 0,
    this.jobMatchViewed = false,
  });

  final int flashcardsMastered;
  final int libraryOpened;
  final int cvBestScore;
  final int interviews;
  final int mentorCompleted;
  final int eventsPlanned;
  final int studyBuddyPhotos;
  final bool jobMatchViewed;

  int valueFor(BoardTaskKind kind) => switch (kind) {
    BoardTaskKind.flashcards => flashcardsMastered,
    BoardTaskKind.library => libraryOpened,
    BoardTaskKind.cvScore => cvBestScore,
    BoardTaskKind.interview => interviews,
    BoardTaskKind.mentor => mentorCompleted,
    BoardTaskKind.event => eventsPlanned,
    BoardTaskKind.jobReadiness => jobMatchViewed ? 1 : 0,
    BoardTaskKind.studyBuddy => studyBuddyPhotos,
  };

  bool meets(BoardTile tile) => valueFor(tile.kind) >= tile.target;
}

class BoardSignals {
  BoardSignals({
    Set<String>? libraryIds,
    Set<String>? eventIds,
    this.studyBuddyPhotos = 0,
    this.interviews = 0,
    this.jobMatchViewed = false,
  }) : libraryIds = libraryIds ?? <String>{},
       eventIds = eventIds ?? <String>{};

  final Set<String> libraryIds;
  final Set<String> eventIds;
  int studyBuddyPhotos;
  int interviews;
  bool jobMatchViewed;

  factory BoardSignals.fromJson(Map<String, dynamic> json) => BoardSignals(
    libraryIds: _stringSet(json['libraryIds']),
    eventIds: _stringSet(json['eventIds']),
    studyBuddyPhotos: (json['studyBuddyPhotos'] as num?)?.toInt() ?? 0,
    interviews: (json['interviews'] as num?)?.toInt() ?? 0,
    jobMatchViewed: json['jobMatchViewed'] == true,
  );

  Map<String, Object?> toJson() => {
    'libraryIds': libraryIds.toList(),
    'eventIds': eventIds.toList(),
    'studyBuddyPhotos': studyBuddyPhotos,
    'interviews': interviews,
    'jobMatchViewed': jobMatchViewed,
  };

  static Set<String> _stringSet(Object? value) =>
      value is List ? value.whereType<String>().toSet() : <String>{};
}

/// Lưu tiến độ bàn cờ Career Map. Các màn tính năng chỉ gọi report*,
/// không gọi chéo nhau. Stardust được cộng qua PointsManager với
/// sourceRef `board:<role>:<tileId>` nên mỗi ô chỉ cộng một lần.
class CareerBoardService extends ChangeNotifier {
  CareerBoardService._();

  static final instance = CareerBoardService._();

  SharedPreferences? _prefs;
  Future<void>? _initializing;
  StreamSubscription<String>? _weeklySubscription;
  final Map<String, Set<String>> _done = {};
  BoardSignals _signals = BoardSignals();
  final _tileCompletedController =
      StreamController<BoardTileReward>.broadcast();

  Stream<BoardTileReward> get onTileCompleted =>
      _tileCompletedController.stream;

  Future<void> initialize({SharedPreferences? preferences}) {
    return _initializing ??= _load(preferences);
  }

  Future<void> _load(SharedPreferences? preferences) async {
    final prefs = _prefs = preferences ?? await SharedPreferences.getInstance();
    _done
      ..clear()
      ..addAll(_readDone(prefs));
    _signals = _readSignals(prefs);
    await _migrateLegacy(prefs);
    _weeklySubscription ??= TaskRepository.instance.onTaskCompleted.listen(
      (taskId) => unawaited(_onWeeklyCompleted(taskId)),
    );
    notifyListeners();
  }

  @visibleForTesting
  Future<void> resetForTests() async {
    await _weeklySubscription?.cancel();
    _weeklySubscription = null;
    _initializing = null;
    _prefs = null;
    _done.clear();
    _signals = BoardSignals();
  }

  String currentRole() => resolveRoadmapRole(_prefs?.getString(_careerGoalKey));

  Future<String> roleFromPreferences() async {
    await initialize();
    return currentRole();
  }

  Set<String> doneTileIds(String role) =>
      Set.unmodifiable(_doneFor(resolveRoadmapRole(role)));

  double readinessFor(String role) {
    final resolved = resolveRoadmapRole(role);
    return boardReadiness(careerBoardFor(resolved), _doneFor(resolved));
  }

  /// Sự kiện có hợp với vùng đang học của [role] không. Trả về false khi chưa nạp dữ liệu.
  bool fitsCurrentZone(String role, Iterable<String> tags) {
    if (_prefs == null) return false;
    final resolved = resolveRoadmapRole(role);
    final zone = boardCurrentZone(careerBoardFor(resolved), _doneFor(resolved));
    return zone != null && boardZoneMatchesTags(zone, tags);
  }

  Future<BoardProgress> progress() async {
    await initialize();
    return _measure(_prefs!);
  }

  bool isWeeklyLinked(String role, BoardTile tile) =>
      TaskRepository.instance.hasTaskId(
        boardWeeklyTaskId(resolveRoadmapRole(role), tile),
      );

  /// Đọc tiến độ thật từ các service và tự đánh dấu những ô đã đủ điều kiện.
  Future<void> sync() async {
    await initialize();
    final prefs = _prefs!;
    final role = currentRole();
    final board = careerBoardFor(role);
    await _pullWeeklyCompletion(role);
    final progress = await _measure(prefs);
    final reached = tilesReachedBy(board, progress, _doneFor(role));
    for (final tile in board.tiles) {
      if (reached.contains(tile.id)) {
        await completeTile(role, tile);
      }
    }
    notifyListeners();
  }

  /// Đánh dấu một ô xong và cộng Stardust một lần. Trả về Stardust vừa cộng.
  Future<int> completeTile(String role, BoardTile tile) async {
    await initialize();
    final resolved = resolveRoadmapRole(role);
    final done = _doneFor(resolved);
    if (!done.add(tile.id)) return 0;
    await _saveDone();
    notifyListeners();
    final added = await PointsManager.instance.addXP(
      thanh: XpBar.kienThuc,
      luong: tile.stardust,
      nguon: _boardSourceName,
      skill: resolved,
      sourceRef: 'board:$resolved:${tile.id}',
      preferences: _prefs,
    );
    _tileCompletedController.add(
      BoardTileReward(role: resolved, tile: tile, stardust: added),
    );
    await _completeWeekly(resolved, tile);
    return added;
  }

  /// Thêm ô vào Weekly Plan. Trả về false nếu ô đã xong hoặc đã có trong kế hoạch.
  Future<bool> addToWeekly(String role, BoardTile tile) async {
    await initialize();
    final resolved = resolveRoadmapRole(role);
    if (_doneFor(resolved).contains(tile.id)) return false;
    await TaskRepository.instance.list(preferences: _prefs);
    final id = boardWeeklyTaskId(resolved, tile);
    if (TaskRepository.instance.hasTaskId(id)) return false;
    await TaskRepository.instance.add(
      AppTask(
        id: id,
        nguon: _boardSourceName,
        noiDung: tile.title,
        trangThai: TaskStatus.pending,
      ),
      preferences: _prefs,
    );
    return true;
  }

  /// Chế độ demo: hoàn thành ô chưa xong đầu tiên qua đúng luồng thật.
  Future<({BoardTile tile, int stardust})?> completeNextDemo(String role) async {
    await initialize();
    final resolved = resolveRoadmapRole(role);
    final done = _doneFor(resolved);
    final pending = careerBoardFor(resolved).tiles.where(
      (tile) => !done.contains(tile.id),
    );
    if (pending.isEmpty) return null;
    final next = pending.first;
    final stardust = await completeTile(resolved, next);
    return (tile: next, stardust: stardust);
  }

  /// Chế độ demo: xóa tiến độ bàn cờ và tín hiệu. Stardust đã cộng được giữ nguyên.
  Future<void> resetDemo(String role) async {
    await initialize();
    _doneFor(resolveRoadmapRole(role)).clear();
    _signals = BoardSignals();
    await _saveDone();
    await _saveSignals();
    notifyListeners();
  }

  Future<void> reportLibraryOpened(String resourceId) async {
    await initialize();
    _signals.libraryIds.add(resourceId);
    await _saveSignals();
    await sync();
  }

  Future<void> reportEventPlanned(String eventId) async {
    await initialize();
    _signals.eventIds.add(eventId);
    await _saveSignals();
    await sync();
  }

  Future<void> reportInterviewCompleted() async {
    await initialize();
    _signals.interviews += 1;
    await _saveSignals();
    await sync();
  }

  Future<void> reportStudyBuddyPhoto() async {
    await initialize();
    _signals.studyBuddyPhotos += 1;
    await _saveSignals();
    await sync();
  }

  Future<void> reportJobMatchViewed() async {
    await initialize();
    _signals.jobMatchViewed = true;
    await _saveSignals();
    await sync();
  }

  Set<String> _doneFor(String role) => _done.putIfAbsent(role, () => <String>{});

  Future<BoardProgress> _measure(SharedPreferences prefs) async {
    await FlashcardService.instance.initialize();
    await MentorBookingService.instance.initialize(preferences: prefs);
    final cvBest = await CvScoreStore().bestScore(preferences: prefs);
    var mastered = 0;
    for (final deck in FlashcardService.instance.decks) {
      mastered += deck.cards.where((card) => card.box >= 3).length;
    }
    return BoardProgress(
      flashcardsMastered: mastered,
      libraryOpened: _signals.libraryIds.length,
      cvBestScore: cvBest,
      interviews: _signals.interviews,
      mentorCompleted: MentorBookingService.instance.completedCount,
      eventsPlanned: _signals.eventIds.length,
      studyBuddyPhotos: _signals.studyBuddyPhotos,
      jobMatchViewed: _signals.jobMatchViewed,
    );
  }

  Future<void> _pullWeeklyCompletion(String role) async {
    final tasks = await TaskRepository.instance.list(preferences: _prefs);
    final board = careerBoardFor(role);
    for (final task in tasks) {
      if (task.trangThai != TaskStatus.completed) continue;
      final parsed = _parseWeeklyTaskId(task.id);
      if (parsed == null || parsed.role != role) continue;
      final matches = board.tiles.where((tile) => tile.id == parsed.tileId);
      if (matches.isEmpty) continue;
      await completeTile(role, matches.first);
    }
  }

  Future<void> _onWeeklyCompleted(String taskId) async {
    final parsed = _parseWeeklyTaskId(taskId);
    if (parsed == null) return;
    final board = careerBoardFor(parsed.role);
    final matches = board.tiles.where((tile) => tile.id == parsed.tileId);
    if (matches.isEmpty) return;
    await completeTile(parsed.role, matches.first);
  }

  Future<void> _completeWeekly(String role, BoardTile tile) async {
    final id = boardWeeklyTaskId(role, tile);
    final tasks = await TaskRepository.instance.list(preferences: _prefs);
    final pending = tasks.any(
      (task) => task.id == id && task.trangThai == TaskStatus.pending,
    );
    if (!pending) return;
    await TaskRepository.instance.complete(id, preferences: _prefs);
  }

  Future<void> _migrateLegacy(SharedPreferences prefs) async {
    if (prefs.getBool(_boardMigrationKey) ?? false) return;
    for (final key in prefs.getKeys().where(
      (key) => key.startsWith(_legacyRoadmapDonePrefix),
    )) {
      final raw = prefs.get(key);
      if (raw is! List) continue;
      final role = resolveRoadmapRole(key.substring(_legacyRoadmapDonePrefix.length));
      final zones = raw
          .whereType<String>()
          .map(int.tryParse)
          .whereType<int>();
      _doneFor(role).addAll(migrateLegacyDone(careerBoardFor(role), zones));
    }
    await _saveDone();
    await prefs.setBool(_boardMigrationKey, true);
  }

  Map<String, Set<String>> _readDone(SharedPreferences prefs) {
    final raw = prefs.getString(_boardDoneKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          if (entry.value is List)
            entry.key.toString(): (entry.value as List)
                .whereType<String>()
                .toSet(),
      };
    } on FormatException {
      return {};
    }
  }

  BoardSignals _readSignals(SharedPreferences prefs) {
    final raw = prefs.getString(_boardSignalsKey);
    if (raw == null) return BoardSignals();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return BoardSignals();
      return BoardSignals.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      return BoardSignals();
    }
  }

  Future<void> _saveDone() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(
      _boardDoneKey,
      jsonEncode({
        for (final entry in _done.entries) entry.key: entry.value.toList(),
      }),
    );
  }

  Future<void> _saveSignals() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_boardSignalsKey, jsonEncode(_signals.toJson()));
  }

  @override
  void dispose() {
    _weeklySubscription?.cancel();
    super.dispose();
  }
}
