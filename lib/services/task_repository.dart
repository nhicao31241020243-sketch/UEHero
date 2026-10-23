import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_task.dart';
import '../models/notebook_activity.dart';
import '../models/xp_entry.dart';
import 'activity_log_service.dart';
import 'points_manager.dart';

class TaskRepository {
  TaskRepository._();

  static final instance = TaskRepository._();
  static const _tasksKey = 'shared_tasks_v1';
  static const _legacyCalendarMigrationKey = 'weekly_plan_legacy_seed_migrated';

  final _completedController = StreamController<String>.broadcast();

  /// Phát id của nhiệm vụ vừa chuyển sang trạng thái hoàn thành.
  Stream<String> get onTaskCompleted => _completedController.stream;

  List<AppTask> _tasks = const [];
  final Set<String> _deletedTaskIds = {};
  bool _initialized = false;
  bool _storageWasMissing = false;
  Future<void>? _initializing;

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

  Future<AppTask> add(AppTask task, {SharedPreferences? preferences}) async {
    await initialize(preferences: preferences);
    if (hasTaskId(task.id)) {
      throw ArgumentError.value(task.id, 'task.id', 'Task ID already exists.');
    }
    final nextTasks = [..._tasks, task];
    await _save(nextTasks, preferences: preferences);
    return task;
  }

  Future<List<AppTask>> list({SharedPreferences? preferences}) async {
    await initialize(preferences: preferences);
    return List.unmodifiable(_tasks);
  }

  List<AppTask> todayPriorities({DateTime? date, int limit = 3}) {
    final today = _dateOnly(date ?? DateTime.now());
    final candidates = _tasks.where((task) {
      if (task.trangThai != TaskStatus.pending || task.han == null) {
        return false;
      }
      final due = _dateOnly(task.han!);
      return !due.isAfter(today);
    }).toList()..sort(_compareTasks);
    return List.unmodifiable(candidates.take(limit));
  }

  bool hasTaskId(String id) =>
      _tasks.any((task) => task.id == id) || _deletedTaskIds.contains(id);

  Future<int> complete(String taskId, {SharedPreferences? preferences}) async {
    await initialize(preferences: preferences);
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) {
      throw ArgumentError.value(taskId, 'taskId', 'Task not found.');
    }
    final task = _tasks[index];
    if (task.trangThai == TaskStatus.completed) return 0;

    final added = task.hasXp
        ? await PointsManager.instance.addXP(
            thanh: task.thanh!,
            luong: task.luongXp!,
            nguon: task.nguon,
            sourceRef: 'task:$taskId',
            preferences: preferences,
          )
        : 0;
    final completed = task.copyWith(trangThai: TaskStatus.completed);
    final nextTasks = List<AppTask>.from(_tasks)..[index] = completed;
    await _save(nextTasks, preferences: preferences);
    if (!_completedController.isClosed) {
      _completedController.add(taskId);
    }
    unawaited(
      ActivityLogService.instance.record(
        feature: NotebookFeature.weeklyPlan,
        type: 'task-completed',
      ),
    );
    return added;
  }

  Future<AppTask?> delete(
    String taskId, {
    SharedPreferences? preferences,
  }) async {
    await initialize(preferences: preferences);
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) return null;
    final deleted = _tasks[index];
    final nextTasks = List<AppTask>.from(_tasks)..removeAt(index);
    _deletedTaskIds.add(taskId);
    await _save(nextTasks, preferences: preferences);
    return deleted;
  }

  Future<void> restore(AppTask task, {SharedPreferences? preferences}) async {
    await initialize(preferences: preferences);
    if (_tasks.any((existing) => existing.id == task.id)) return;
    _deletedTaskIds.remove(task.id);
    await _save([..._tasks, task], preferences: preferences);
  }

  Future<List<AppTask>> migrateLegacyCalendarTasks({
    SharedPreferences? preferences,
  }) async {
    await initialize(preferences: preferences);
    final prefs = preferences ?? await SharedPreferences.getInstance();
    if (prefs.getBool(_legacyCalendarMigrationKey) ?? false) {
      return const [];
    }

    final today = _dateOnly(DateTime.now());
    final legacyTasks = [
      AppTask(
        id: 'legacy-mentee-ux',
        nguon: 'Mentor',
        noiDung: 'Họp với Mentee UX',
        han: today.add(const Duration(hours: 6, minutes: 30)),
        trangThai: TaskStatus.pending,
        thanh: XpBar.thucChien,
        luongXp: 10,
        coGio: true,
      ),
      AppTask(
        id: 'legacy-semester-group',
        nguon: 'Tay',
        noiDung: 'Làm việc nhóm dự án học kỳ',
        han: today.add(const Duration(hours: 9)),
        trangThai: TaskStatus.pending,
        coGio: true,
      ),
      AppTask(
        id: 'legacy-course-exam',
        nguon: 'Khóa học',
        noiDung: 'Thi kết thúc học phần',
        han: today.add(const Duration(days: 2, hours: 13, minutes: 30)),
        trangThai: TaskStatus.pending,
        thanh: XpBar.kienThuc,
        luongXp: 15,
        coGio: true,
      ),
      AppTask(
        id: 'legacy-data-mentoring',
        nguon: 'Mentor',
        noiDung: 'Mentoring: Định hướng Data',
        han: today.add(const Duration(days: 4, hours: 15)),
        trangThai: TaskStatus.pending,
        thanh: XpBar.thucChien,
        luongXp: 10,
        coGio: true,
      ),
      AppTask(
        id: 'legacy-project-presentation',
        nguon: 'Tay',
        noiDung: 'Chuẩn bị nội dung thuyết trình',
        han: today.add(const Duration(days: 6, hours: 8)),
        trangThai: TaskStatus.pending,
        coGio: true,
      ),
    ];
    final added = <AppTask>[];
    for (final task in legacyTasks) {
      if (hasTaskId(task.id)) continue;
      _tasks = [..._tasks, task];
      added.add(task);
    }
    if (added.isNotEmpty) await _save(_tasks, preferences: prefs);
    await prefs.setBool(_legacyCalendarMigrationKey, true);
    return List.unmodifiable(added);
  }

  Future<bool> seedDemoIfEmpty({SharedPreferences? preferences}) async {
    await initialize(preferences: preferences);
    if (_tasks.isNotEmpty ||
        _deletedTaskIds.isNotEmpty ||
        !_storageWasMissing) {
      return false;
    }
    await PointsManager.instance.initialize(preferences: preferences);
    if (PointsManager.instance.entries.any(
      (entry) => entry.nguon != 'initial',
    )) {
      return false;
    }

    final today = _dateOnly(DateTime.now());
    final samples = <AppTask>[
      AppTask(
        id: 'demo-legacy-mentee-ux',
        nguon: 'Mentor',
        noiDung: 'Họp với Mentee UX',
        han: today.add(const Duration(hours: 6, minutes: 30)),
        trangThai: TaskStatus.pending,
        thanh: XpBar.thucChien,
        luongXp: 10,
        coGio: true,
        isDemo: true,
      ),
      AppTask(
        id: 'demo-legacy-group-project',
        nguon: 'Tay',
        noiDung: 'Làm việc nhóm dự án học kỳ',
        han: today.add(const Duration(hours: 9)),
        trangThai: TaskStatus.pending,
        coGio: true,
        isDemo: true,
      ),
      for (var day = -6; day <= 0; day++)
        AppTask(
          id: 'demo-streak-$day',
          nguon: 'demo',
          noiDung: day == 0
              ? 'Hoàn thành mục tiêu hôm nay'
              : 'Mục tiêu ngày ${day.abs()}',
          han: today.add(Duration(days: day, hours: 9)),
          trangThai: TaskStatus.completed,
          coGio: true,
          isDemo: true,
        ),
      AppTask(
        id: 'demo-overdue-cv',
        nguon: 'CV',
        noiDung: 'Cập nhật phần kinh nghiệm trong CV',
        han: today.subtract(const Duration(days: 2)),
        trangThai: TaskStatus.pending,
        thanh: XpBar.hoSo,
        luongXp: 10,
        isDemo: true,
      ),
      AppTask(
        id: 'demo-competition',
        nguon: 'Cuộc thi',
        noiDung: 'Nộp ý tưởng cho cuộc thi học thuật',
        han: today.add(const Duration(days: 1)),
        trangThai: TaskStatus.pending,
        thanh: XpBar.thucChien,
        luongXp: 15,
        isDemo: true,
      ),
      AppTask(
        id: 'demo-flashcard',
        nguon: 'Flashcard',
        noiDung: 'Ôn bộ flashcard SQL',
        han: today.add(const Duration(days: 2)),
        trangThai: TaskStatus.pending,
        thanh: XpBar.kienThuc,
        luongXp: 10,
        isDemo: true,
      ),
      AppTask(
        id: 'demo-mentor',
        nguon: 'Mentor',
        noiDung: 'Chuẩn bị câu hỏi cho buổi mentoring',
        han: today.add(const Duration(days: 3)),
        trangThai: TaskStatus.pending,
        thanh: XpBar.thucChien,
        luongXp: 10,
        isDemo: true,
      ),
      AppTask(
        id: 'demo-course',
        nguon: 'Khóa học',
        noiDung: 'Hoàn thành bài học tiếp theo',
        han: today.add(const Duration(days: 5)),
        trangThai: TaskStatus.pending,
        thanh: XpBar.kienThuc,
        luongXp: 10,
        isDemo: true,
      ),
    ];
    _tasks = samples;
    await _save(_tasks, preferences: preferences);
    _storageWasMissing = false;
    return true;
  }

  Future<void> resetDemo({SharedPreferences? preferences}) async {
    await initialize(preferences: preferences);
    _tasks = _tasks.where((task) => !task.isDemo).toList();
    _deletedTaskIds.removeWhere((id) => id.startsWith('demo-'));
    await _save(_tasks, preferences: preferences);
  }

  void resetForTesting() {
    _tasks = const [];
    _deletedTaskIds.clear();
    _initialized = false;
    _storageWasMissing = false;
    _initializing = null;
  }

  Future<void> _load(SharedPreferences? preferences) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(_tasksKey);
    _storageWasMissing = raw == null;
    if (raw == null) {
      _tasks = const [];
      _deletedTaskIds.clear();
    } else {
      final decoded = jsonDecode(raw);
      final rawTasks = decoded is List
          ? decoded
          : decoded is Map
          ? decoded['tasks']
          : null;
      if (rawTasks is! List) {
        throw const FormatException('Task storage must contain a task list.');
      }
      _tasks = List.unmodifiable(
        rawTasks.whereType<Map>().map(
          (item) => AppTask.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
      _deletedTaskIds
        ..clear()
        ..addAll(
          decoded is Map && decoded['deletedTaskIds'] is List
              ? (decoded['deletedTaskIds'] as List).whereType<String>()
              : const <String>[],
        );
    }
    _initialized = true;
  }

  Future<void> _save(
    List<AppTask> tasks, {
    SharedPreferences? preferences,
  }) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      _tasksKey,
      jsonEncode({
        'tasks': tasks.map((task) => task.toJson()).toList(),
        'deletedTaskIds': _deletedTaskIds.toList(),
      }),
    );
    if (!saved) throw StateError('Could not persist tasks.');
    _tasks = List.unmodifiable(tasks);
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  int _compareTasks(AppTask first, AppTask second) {
    final firstDue = first.han ?? DateTime(9999);
    final secondDue = second.han ?? DateTime(9999);
    return firstDue.compareTo(secondDue);
  }
}
