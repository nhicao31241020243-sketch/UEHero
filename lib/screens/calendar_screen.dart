import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/weekly_plan_config.dart';
import '../models/app_task.dart';
import '../models/character_data.dart';
import '../models/xp_entry.dart';
import '../services/points_manager.dart';
import '../services/task_repository.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const _background = Color(0xFF100E19);
  static const _surface = Color(0xFF211D2B);
  static const _muted = Color(0xFFAAA5B8);
  static const _mars = Color(0xFFFF704E);
  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  static const _monthNames = [
    'tháng 1',
    'tháng 2',
    'tháng 3',
    'tháng 4',
    'tháng 5',
    'tháng 6',
    'tháng 7',
    'tháng 8',
    'tháng 9',
    'tháng 10',
    'tháng 11',
    'tháng 12',
  ];
  static const _weekdayNames = [
    'Thứ hai',
    'Thứ ba',
    'Thứ tư',
    'Thứ năm',
    'Thứ sáu',
    'Thứ bảy',
    'Chủ nhật',
  ];
  static const _greetingShownKey = 'weekly_plan_greeting_shown_day';
  static const _studyBuddyGeneratedKey = 'weekly_plan_study_buddy_generated';
  static const _studyHistoryKey = 'study_question_history';

  final _repository = TaskRepository.instance;
  final _points = PointsManager.instance;
  final _scrollController = ScrollController();
  List<AppTask> _tasks = const [];
  DateTime? _selectedDate;
  late DateTime _visibleMonth;
  bool _calendarExpanded = false;
  bool _loading = true;
  bool _showGreeting = false;
  CharacterData _mascot = characterData.first;
  int _streak = 0;

  DateTime get _today => _dateOnly(DateTime.now());
  DateTime get _weekStart => _startOfWeek(_today);
  DateTime get _weekEnd => _weekStart.add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(_today.year, _today.month);
    _initialize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final preferences = await SharedPreferences.getInstance();
    await _points.initialize(preferences: preferences);
    await _repository.initialize(preferences: preferences);
    await _repository.seedDemoIfEmpty(preferences: preferences);
    await _syncStudyBuddyTasks(preferences);

    final shownDay = preferences.getString(_greetingShownKey);
    final todayKey = _dayKey(_today);
    final mascot = characterById(preferences.getString('selected_mascot'));
    _tasks = await _repository.list(preferences: preferences);
    _mascot = mascot ?? CharacterSelection.selected ?? characterData.first;
    _showGreeting = shownDay != todayKey;
    if (_showGreeting) await preferences.setString(_greetingShownKey, todayKey);
    _streak = _currentStreak(_tasks);
    if (mounted) setState(() => _loading = false);
    await _maybeAwardStreak();
  }

  Future<void> _syncStudyBuddyTasks(SharedPreferences preferences) async {
    final raw = preferences.getString(_studyHistoryKey);
    if (raw == null) return;
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Study Buddy history must be a list.');
    }
    final cutoff = _today.subtract(const Duration(days: 6));
    final counts = <String, int>{};
    for (final rawEntry in decoded.whereType<Map>()) {
      final entry = Map<String, dynamic>.from(rawEntry);
      final subject = (entry['subject'] as String?)?.trim();
      final rawDate = entry['date'] as String?;
      if (subject == null || subject.isEmpty || rawDate == null) continue;
      final date = DateTime.tryParse(rawDate);
      if (date == null || _dateOnly(date).isBefore(cutoff)) continue;
      counts.update(subject, (count) => count + 1, ifAbsent: () => 1);
    }
    final weekKey = _dayKey(_weekStart);
    final generated = (preferences.getStringList(_studyBuddyGeneratedKey) ?? [])
        .toSet();
    for (final entry in counts.entries.where((entry) => entry.value >= 3)) {
      final marker = '$weekKey:${entry.key.toLowerCase()}';
      if (generated.contains(marker)) continue;
      final taskId = 'study-buddy-${_slug(weekKey)}-${_slug(entry.key)}';
      final tasks = await _repository.list(preferences: preferences);
      final alreadyOpen = tasks.any(
        (task) =>
            task.nguon == 'Study Buddy' &&
            task.noiDung == 'Ôn thêm: ${entry.key}' &&
            task.trangThai == TaskStatus.pending,
      );
      if (!_repository.hasTaskId(taskId) && !alreadyOpen) {
        await _repository.add(
          AppTask(
            id: taskId,
            nguon: 'Study Buddy',
            noiDung: 'Ôn thêm: ${entry.key}',
            han: _today.add(const Duration(days: 1)),
            trangThai: TaskStatus.pending,
            thanh: XpBar.kienThuc,
            luongXp: 10,
          ),
          preferences: preferences,
        );
      }
      generated.add(marker);
    }
    await preferences.setStringList(
      _studyBuddyGeneratedKey,
      generated.toList(),
    );
  }

  Future<void> _refreshTasks() async {
    _tasks = await _repository.list();
    _streak = _currentStreak(_tasks);
    if (mounted) setState(() {});
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _startOfWeek(DateTime date) =>
      _dateOnly(date).subtract(Duration(days: date.weekday - 1));

  bool _sameDay(DateTime? first, DateTime second) =>
      first != null &&
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _slug(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

  String _weekKey(DateTime monday) => _dayKey(monday);

  List<AppTask> get _selectedTasks {
    final selected = _selectedDate;
    if (selected == null) return const [];
    final tasks = _tasks.where((task) => _sameDay(task.han, selected)).toList()
      ..sort(_compareTasks);
    return tasks;
  }

  int _compareTasks(AppTask first, AppTask second) {
    final firstDue = first.han ?? DateTime(9999);
    final secondDue = second.han ?? DateTime(9999);
    return firstDue.compareTo(secondDue);
  }

  List<AppTask> _tasksForDay(DateTime date) => _tasks
      .where((task) => task.han != null && _sameDay(task.han, date))
      .toList();

  List<AppTask> get _pendingTasks =>
      _tasks.where((task) => task.trangThai == TaskStatus.pending).toList();

  List<AppTask> get _overdueTasks => _sortTasks(
    _pendingTasks.where(
      (task) => task.han != null && _dateOnly(task.han!).isBefore(_today),
    ),
  );

  List<AppTask> get _todayTasks =>
      _sortTasks(_pendingTasks.where((task) => _sameDay(task.han, _today)));

  List<AppTask> get _thisWeekTasks => _sortTasks(
    _pendingTasks.where((task) {
      final due = task.han;
      return due != null &&
          !_dateOnly(due).isBefore(_today) &&
          _dateOnly(due).isAfter(_today) &&
          _dateOnly(due).isBefore(_weekEnd);
    }),
  );

  List<AppTask> get _laterTasks => _sortTasks(
    _pendingTasks.where((task) {
      final due = task.han;
      return due == null || !_dateOnly(due).isBefore(_weekEnd);
    }),
  );

  List<AppTask> get _completedTasks => _sortTasks(
    _tasks.where((task) => task.trangThai == TaskStatus.completed),
  );

  List<AppTask> _sortTasks(Iterable<AppTask> tasks) =>
      tasks.toList()..sort(_compareTasks);

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = _dateOnly(date);
      _visibleMonth = DateTime(date.year, date.month);
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  Future<void> _completeTask(AppTask task) async {
    if (task.trangThai == TaskStatus.completed) return;
    try {
      final awarded = await _repository.complete(task.id);
      await _refreshTasks();
      final xpLabel = task.hasXp
          ? '+$awarded ${_barLabel(task.thanh!)}'
          : 'Đã hoàn thành';
      _showSnackBar(xpLabel);
      await _maybeAwardStreak();
    } catch (error) {
      _showSnackBar('Không thể hoàn thành công việc: $error');
    }
  }

  Future<bool> _confirmDelete(AppTask task) async {
    if (task.nguon == 'Tay') return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: _surface,
            title: const Text(
              'Xóa công việc?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Công việc từ ${task.nguon} sẽ bị xóa khỏi Weekly Plan.',
              style: const TextStyle(color: _muted),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Giữ lại'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa', style: TextStyle(color: _mars)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteTask(AppTask task) async {
    try {
      final deleted = await _repository.delete(task.id);
      if (deleted == null) return;
      await _refreshTasks();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Đã xóa'),
            action: SnackBarAction(
              label: 'Hoàn tác',
              textColor: const Color(0xFFFFA18C),
              onPressed: () => unawaited(_restoreTask(deleted)),
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: _surface,
          ),
        );
    } catch (error) {
      _showSnackBar('Không thể xóa công việc: $error');
      await _refreshTasks();
    }
  }

  Future<void> _restoreTask(AppTask task) async {
    try {
      await _repository.restore(task);
      await _refreshTasks();
    } catch (error) {
      _showSnackBar('Không thể hoàn tác: $error');
    }
  }

  Future<void> _showAddTaskSheet() async {
    var taskTitle = '';
    var selectedDate = _selectedDate ?? _today;
    TimeOfDay? selectedTime;
    final task = await showModalBottomSheet<AppTask>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            decoration: const BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Thêm việc cá nhân',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  autofocus: true,
                  onChanged: (value) => taskTitle = value,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration('Tên công việc'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: sheetContext,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      builder: (context, child) => _themedPicker(child),
                    );
                    if (!sheetContext.mounted) return;
                    if (picked != null) {
                      setSheetState(() => selectedDate = _dateOnly(picked));
                    }
                  },
                  icon: const Icon(Icons.calendar_today_rounded),
                  label: Text('Ngày: ${_formatShortDate(selectedDate)}'),
                  style: _outlinedButtonStyle(),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: sheetContext,
                      initialTime: selectedTime ?? TimeOfDay.now(),
                      builder: (context, child) => _themedPicker(child),
                    );
                    if (!sheetContext.mounted) return;
                    if (picked != null) {
                      setSheetState(() => selectedTime = picked);
                    }
                  },
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(
                    selectedTime == null
                        ? 'Thêm giờ (không bắt buộc)'
                        : 'Giờ: ${_formatTime(selectedTime!)}',
                  ),
                  style: _outlinedButtonStyle(),
                ),
                if (selectedTime != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setSheetState(() => selectedTime = null),
                      child: const Text('Bỏ giờ'),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      final title = taskTitle.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng nhập tên công việc.'),
                          ),
                        );
                        return;
                      }
                      final due = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime?.hour ?? 0,
                        selectedTime?.minute ?? 0,
                      );
                      Navigator.of(sheetContext).pop(
                        AppTask(
                          id: 'manual-${DateTime.now().microsecondsSinceEpoch}',
                          nguon: 'Tay',
                          noiDung: title,
                          han: due,
                          trangThai: TaskStatus.pending,
                          coGio: selectedTime != null,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _mars,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'LƯU CÔNG VIỆC',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || task == null) return;
    try {
      await _repository.add(task);
      await _refreshTasks();
    } catch (error) {
      _showSnackBar('Không thể lưu công việc: $error');
    }
  }

  Widget _themedPicker(Widget? child) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: const ColorScheme.dark(primary: _mars, surface: _surface),
    ),
    child: child ?? const SizedBox.shrink(),
  );

  ButtonStyle _outlinedButtonStyle() => OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFFE4DDEB),
    side: const BorderSide(color: Colors.white24),
    minimumSize: const Size.fromHeight(46),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _muted, fontSize: 13),
    filled: true,
    fillColor: const Color(0xFF17141F),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide.none,
    ),
  );

  Future<void> _hideGreeting() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_greetingShownKey, _dayKey(_today));
    if (mounted) setState(() => _showGreeting = false);
  }

  Future<void> _maybeAwardStreak() async {
    final current = _currentStreak(_tasks);
    if (current < 7) return;
    final monday = _startOfWeek(_today);
    final added = await _points.addXP(
      thanh: XpBar.thucChien,
      luong: weeklyStreakXpReward,
      nguon: 'streak',
      sourceRef: 'weekly-streak-${_weekKey(monday)}',
    );
    if (added > 0 && mounted) {
      _showSnackBar('Chúc mừng chuỗi 7 ngày! +$added Thực chiến');
    }
  }

  int _currentStreak(List<AppTask> tasks) {
    final completedDays = tasks
        .where(
          (task) =>
              task.trangThai == TaskStatus.completed && task.nguon != 'Tay',
        )
        .where((task) => task.han != null)
        .map((task) => _dayKey(_dateOnly(task.han!)))
        .toSet();
    var cursor = _today;
    if (!completedDays.contains(_dayKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var count = 0;
    while (completedDays.contains(_dayKey(cursor))) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  int _weekTaskCount(bool completed) => _tasks.where((task) {
    final due = task.han;
    return due != null &&
        !_dateOnly(due).isBefore(_weekStart) &&
        _dateOnly(due).isBefore(_weekEnd) &&
        (task.trangThai == TaskStatus.completed) == completed;
  }).length;

  int _xpThisWeek(XpBar bar) => _points.entries
      .where(
        (entry) =>
            entry.thanh == bar &&
            entry.luong > 0 &&
            !_dateOnly(entry.thoiGian).isBefore(_weekStart) &&
            _dateOnly(entry.thoiGian).isBefore(_weekEnd),
      )
      .fold(0, (total, entry) => total + entry.luong);

  String _greeting() {
    if (_overdueTasks.isNotEmpty) {
      return 'Có ${_overdueTasks.length} việc quá hạn, mình xử lý từng việc nhé.';
    }
    final totals = {
      XpBar.kienThuc: _points.totalXpByBar(XpBar.kienThuc),
      XpBar.hoSo: _points.totalXpByBar(XpBar.hoSo),
      XpBar.thucChien: _points.totalXpByBar(XpBar.thucChien),
    };
    final lowest = totals.entries.reduce(
      (first, second) => first.value <= second.value ? first : second,
    );
    final labels = {
      XpBar.kienThuc: 'Kiến thức',
      XpBar.hoSo: 'Hồ sơ',
      XpBar.thucChien: 'Thực chiến',
    };
    if (_todayTasks.isEmpty && _pendingTasks.isEmpty) {
      return 'Hôm nay không còn việc, giỏi lắm!';
    }
    return 'Thanh ${labels[lowest.key]} đang thấp nhất nè.';
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _surface,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  String _barLabel(XpBar bar) => switch (bar) {
    XpBar.kienThuc => 'Kiến thức',
    XpBar.hoSo => 'Hồ sơ',
    XpBar.thucChien => 'Thực chiến',
  };

  Color _sourceColor(String source) => switch (source) {
    'Mentor' => const Color(0xFFBFA8FF),
    'Cuộc thi' => const Color(0xFFFFC36E),
    'CV' => const Color(0xFFB7E59B),
    'Flashcard' => const Color(0xFF8DD8D1),
    'Khóa học' => const Color(0xFF9DBBFF),
    'Study Buddy' => const Color(0xFF70D8F2),
    'Career Map' => const Color(0xFFFF9EBD),
    'Tay' => _mars,
    'demo' => const Color(0xFF77D6AE),
    _ => _muted,
  };

  String _formatShortDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}';

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  String _taskTime(AppTask task) {
    final due = task.han;
    if (due == null) return 'Chưa lên lịch';
    if (!task.coGio) return 'Hạn: ${_formatShortDate(due)}';
    return '${due.hour.toString().padLeft(2, '0')}:'
        '${due.minute.toString().padLeft(2, '0')}';
  }

  String _selectedDayLabel(DateTime date) {
    if (_sameDay(date, _today)) {
      return 'HÔM NAY · ${date.day} ${_monthNames[date.month - 1]}';
    }
    return '${_weekdayNames[date.weekday - 1].toUpperCase()} · '
        '${date.day} ${_monthNames[date.month - 1]}';
  }

  int _daysInVisibleMonth() =>
      DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;

  DateTime get _displayWeekStart => _startOfWeek(_selectedDate ?? _today);

  Future<void> _resetDemo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: const Text(
          'Đặt lại dữ liệu mẫu?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Chỉ xóa các công việc mẫu của Weekly Plan.',
          style: TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đặt lại', style: TextStyle(color: _mars)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.resetDemo();
    await _refreshTasks();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(child: CircularProgressIndicator(color: _mars)),
      );
    }
    final hasSelectedDate = _selectedDate != null;
    final selectedTasks = _selectedTasks;

    return Scaffold(
      backgroundColor: _background,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskSheet,
        tooltip: 'Thêm công việc',
        backgroundColor: _mars,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildWeekProgress(),
            _buildCalendarCard(),
            if (hasSelectedDate)
              _buildSelectedTasksHeader(selectedTasks.length),
            Expanded(
              child: hasSelectedDate
                  ? selectedTasks.isEmpty
                        ? _buildEmptyTasks()
                        : _buildTaskList(selectedTasks)
                  : _buildGroupedTaskList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final remainingToday = _todayTasks.length;
    final subtitle = remainingToday == 0
        ? 'Hôm nay không còn việc, giỏi lắm!'
        : 'Hôm nay còn $remainingToday việc';
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quay lại',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Weekly Plan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (_streak > 0) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFFFA45F),
                        size: 18,
                      ),
                      Text(
                        '$_streak',
                        style: const TextStyle(
                          color: Color(0xFFFFA45F),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Tùy chọn',
            color: _surface,
            onSelected: (value) {
              if (value == 'reset_demo') unawaited(_resetDemo());
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'reset_demo',
                child: Text(
                  'Xóa dữ liệu mẫu',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert_rounded, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekProgress() {
    final completed = _weekTaskCount(true);
    final total = completed + _weekTaskCount(false);
    final xp = XpBar.values.map((bar) => _xpThisWeek(bar)).toList();
    final maxXp = xp.fold<int>(
      0,
      (maximum, value) => value > maximum ? value : maximum,
    );
    final barColors = [const Color(0xFF8DD8D1), const Color(0xFFB7E59B), _mars];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(13, 9, 13, 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tuần này: $completed/$total việc',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: List.generate(XpBar.values.length, (index) {
              final bar = XpBar.values[index];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == XpBar.values.length - 1 ? 0 : 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _barLabel(bar),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${xp[index]}',
                            style: TextStyle(
                              color: barColors[index],
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          value: maxXp == 0 ? 0 : xp[index] / maxXp,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation(barColors[index]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    final rangeStart = _calendarExpanded
        ? DateTime(_visibleMonth.year, _visibleMonth.month, 1).subtract(
            Duration(
              days:
                  DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday -
                  1,
            ),
          )
        : _displayWeekStart;
    final dayCount = _calendarExpanded
        ? ((_daysInVisibleMonth() +
                          DateTime(
                            _visibleMonth.year,
                            _visibleMonth.month,
                            1,
                          ).weekday -
                          2) ~/
                      7 +
                  1) *
              7
        : 7;
    return GestureDetector(
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 120 && !_calendarExpanded) {
          setState(() => _calendarExpanded = true);
        } else if (velocity < -120 && _calendarExpanded) {
          setState(() => _calendarExpanded = false);
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 7),
        padding: const EdgeInsets.fromLTRB(13, 9, 13, 7),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tháng ${_visibleMonth.month}, ${_visibleMonth.year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!_sameDay(_selectedDate, _today) ||
                    _visibleMonth.month != _today.month)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                        _visibleMonth = DateTime(_today.year, _today.month);
                      });
                    },
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: const Color(0xFFFFA18C),
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                    ),
                    child: const Text(
                      'Hôm nay',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                _monthButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Tháng trước',
                  onPressed: () => _changeMonth(-1),
                ),
                _monthButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'Tháng sau',
                  onPressed: () => _changeMonth(1),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 31,
                    height: 31,
                  ),
                  tooltip: _calendarExpanded ? 'Thu gọn lịch' : 'Mở cả tháng',
                  onPressed: () =>
                      setState(() => _calendarExpanded = !_calendarExpanded),
                  icon: Icon(
                    _calendarExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: _weekdays
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: day == 'CN'
                                ? const Color(0xFFFF9A83)
                                : _muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 2),
            for (var week = 0; week < dayCount ~/ 7; week++)
              Row(
                children: List.generate(7, (weekday) {
                  final date = rangeStart.add(
                    Duration(days: week * 7 + weekday),
                  );
                  return Expanded(child: _buildDayCell(date));
                }),
              ),
            const SizedBox(height: 3),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _monthButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) => IconButton(
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints.tightFor(width: 30, height: 30),
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 20, color: Colors.white70),
  );

  Widget _buildDayCell(DateTime date) {
    final inMonth = date.month == _visibleMonth.month;
    final selected = _sameDay(_selectedDate, date);
    final today = _sameDay(date, _today);
    final colors = <Color>[];
    for (final task in _tasksForDay(date)) {
      final color = _sourceColor(task.nguon);
      if (!colors.contains(color)) colors.add(color);
    }
    return SizedBox(
      height: 37,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectDate(date),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 27,
              height: 25,
              decoration: BoxDecoration(
                color: selected
                    ? _mars
                    : today
                    ? _mars.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                border: today && !selected
                    ? Border.all(color: _mars.withValues(alpha: 0.7))
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: !inMonth
                      ? const Color(0xFF625D6D)
                      : selected
                      ? Colors.white
                      : today
                      ? const Color(0xFFFF9A83)
                      : const Color(0xFFE4DDEB),
                  fontSize: 10,
                  fontWeight: selected || today
                      ? FontWeight.w800
                      : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 1),
            SizedBox(
              height: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: colors.take(4).map((color) {
                  return Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    const sources = [
      'Mentor',
      'Cuộc thi',
      'CV',
      'Flashcard',
      'Khóa học',
      'Study Buddy',
      'Career Map',
      'Tay',
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 9,
      runSpacing: 3,
      children: sources
          .map(
            (source) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _sourceColor(source),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  source,
                  style: const TextStyle(color: _muted, fontSize: 8),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildSelectedTasksHeader(int count) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 1, 20, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            _selectedDayLabel(_selectedDate!),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              letterSpacing: 0.25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          '$count việc',
          style: const TextStyle(
            color: Color(0xFFFFA18C),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _buildGroupedTaskList() {
    final children = <Widget>[];
    if (_showGreeting) {
      children.add(_buildGreetingCard());
    }
    _addTaskGroup(children, 'Quá hạn', _overdueTasks, overdue: true);
    _addTaskGroup(children, 'Hôm nay', _todayTasks);
    _addTaskGroup(children, 'Tuần này', _thisWeekTasks);
    _addTaskGroup(children, 'Sau đó', _laterTasks);
    if (_completedTasks.isNotEmpty) {
      children.add(
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 6),
            childrenPadding: EdgeInsets.zero,
            initiallyExpanded: false,
            iconColor: _muted,
            collapsedIconColor: _muted,
            title: Text(
              'Đã xong (${_completedTasks.length})',
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            children: _completedTasks
                .map((task) => _buildTaskCard(task))
                .toList(),
          ),
        ),
      );
    }
    if (children.isEmpty || _tasks.isEmpty) {
      children.add(_buildEmptyTasks());
    }
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      children: children,
    );
  }

  void _addTaskGroup(
    List<Widget> children,
    String title,
    List<AppTask> tasks, {
    bool overdue = false,
  }) {
    if (tasks.isEmpty) return;
    children.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
        child: Row(
          children: [
            if (overdue)
              const Padding(
                padding: EdgeInsets.only(right: 5),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFFF9A83),
                  size: 14,
                ),
              ),
            Text(
              '$title (${tasks.length})',
              style: TextStyle(
                color: overdue ? const Color(0xFFFF9A83) : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
    children.addAll(tasks.map(_buildTaskCard));
  }

  Widget _buildGreetingCard() {
    final priorities = _repository.todayPriorities(date: _today);
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.fromLTRB(11, 10, 7, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF292131),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFFF9EBD).withValues(alpha: .4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/planets/mars.png',
                    fit: BoxFit.cover,
                  ),
                  Center(
                    child: Text(
                      _mascot.emoji,
                      style: const TextStyle(fontSize: 29),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào bạn, ${_mascot.name} đây!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _greeting(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
                if (priorities.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  for (final task in priorities)
                    InkWell(
                      onTap: () => unawaited(_completeTask(task)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.circle_outlined,
                              color: Color(0xFFFFA18C),
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                task.noiDung,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 27, height: 27),
            tooltip: 'Ẩn lời chào hôm nay',
            onPressed: () => unawaited(_hideGreeting()),
            icon: const Icon(Icons.close_rounded, color: _muted, size: 17),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<AppTask> tasks) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
    children: tasks.map(_buildTaskCard).toList(),
  );

  Widget _buildTaskCard(AppTask task) {
    final color =
        task.trangThai == TaskStatus.pending &&
            task.han != null &&
            _dateOnly(task.han!).isBefore(_today)
        ? const Color(0xFFFF9A83)
        : _sourceColor(task.nguon);
    return Padding(
      key: ValueKey(task.id),
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey('dismiss-${task.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmDelete(task),
        onDismissed: (_) => unawaited(_deleteTask(task)),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF7D333B),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        child: _TaskCard(
          task: task,
          color: color,
          sourceColor: _sourceColor(task.nguon),
          timeLabel: _taskTime(task),
          xpLabel: task.hasXp
              ? '+${task.luongXp} ${_barLabel(task.thanh!)}'
              : null,
          onToggle: () => unawaited(_completeTask(task)),
        ),
      ),
    );
  }

  Widget _buildEmptyTasks() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available_rounded,
            color: Colors.white.withValues(alpha: 0.25),
            size: 42,
          ),
          const SizedBox(height: 10),
          const Text(
            'Ngày này chưa có việc',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Nhấn nút + để thêm công việc mới.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.color,
    required this.sourceColor,
    required this.timeLabel,
    required this.xpLabel,
    required this.onToggle,
  });

  final AppTask task;
  final Color color;
  final Color sourceColor;
  final String timeLabel;
  final String? xpLabel;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final completed = task.trangThai == TaskStatus.completed;
    final foreground = completed ? Colors.white38 : Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(11, 10, 9, 10),
      decoration: BoxDecoration(
        color: _CalendarScreenState._surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 54,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 9),
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              completed ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: completed ? const Color(0xFF77D6AE) : color,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.95),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.noiDung,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    _TaskChip(label: task.nguon, color: sourceColor),
                    if (xpLabel != null)
                      _TaskChip(
                        label: xpLabel!,
                        color: const Color(0xFFB7E59B),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskChip extends StatelessWidget {
  const _TaskChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w700),
    ),
  );
}
