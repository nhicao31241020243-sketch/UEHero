import 'package:flutter/material.dart';

import '../models/task_model.dart';

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
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  late DateTime _selectedDate;
  late DateTime _visibleMonth;
  late List<TaskModel> _tasks;

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _selectedDate = today;
    _visibleMonth = DateTime(today.year, today.month);
    _tasks = _makeSampleTasks(today);
  }

  List<TaskModel> _makeSampleTasks(DateTime today) => [
    TaskModel(
      title: 'Họp với Mentee UX',
      time: '06:30 AM - 07:00 AM',
      date: today,
      type: TaskType.mentee,
    ),
    TaskModel(
      title: 'Làm việc nhóm dự án học kỳ',
      time: '09:00 AM - 10:30 AM',
      date: today,
      type: TaskType.work,
    ),
    TaskModel(
      title: 'Thi kết thúc học phần',
      time: '01:30 PM - 03:00 PM',
      date: today.add(const Duration(days: 2)),
      type: TaskType.exam,
    ),
    TaskModel(
      title: 'Mentoring: Định hướng Data',
      time: '03:00 PM - 03:45 PM',
      date: today.add(const Duration(days: 4)),
      type: TaskType.mentee,
    ),
    TaskModel(
      title: 'Chuẩn bị nội dung thuyết trình',
      time: '08:00 AM - 09:00 AM',
      date: today.add(const Duration(days: 6)),
      type: TaskType.work,
    ),
  ];

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  List<TaskModel> get _selectedTasks {
    final tasks =
        _tasks.where((task) => _isSameDay(task.date, _selectedDate)).toList()
          ..sort(
            (first, second) =>
                _timeSortKey(first.time).compareTo(_timeSortKey(second.time)),
          );
    return tasks;
  }

  int _timeSortKey(String time) {
    final start = time.split(' - ').first.split(' ');
    final hourAndMinute = start.first.split(':');
    final hour = int.parse(hourAndMinute[0]) % 12;
    final minute = int.parse(hourAndMinute[1]);
    final isAfternoon = start.length > 1 && start[1] == 'PM';
    return (hour + (isAfternoon ? 12 : 0)) * 60 + minute;
  }

  DateTime get _today => _dateOnly(DateTime.now());

  DateTime get _calendarStart {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month);
    return first.subtract(Duration(days: first.weekday - 1));
  }

  int get _calendarDayCount {
    final last = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
    final lastIndex = last.difference(_calendarStart).inDays;
    return ((lastIndex ~/ 7) + 1) * 7;
  }

  List<TaskModel> _tasksForDay(DateTime date) =>
      _tasks.where((task) => _isSameDay(task.date, date)).toList();

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _toggleCompleted(TaskModel task) {
    final index = _tasks.indexOf(task);
    if (index < 0) return;
    setState(() {
      _tasks[index] = task.copyWith(isCompleted: !task.isCompleted);
    });
  }

  void _deleteTask(TaskModel task) {
    setState(() => _tasks.remove(task));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xóa công việc'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showAddTaskSheet() async {
    final titleController = TextEditingController();
    var selectedType = TaskType.work;
    var selectedTime = TimeOfDay.now();

    final result = await showModalBottomSheet<TaskModel>(
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
                  'Thêm công việc',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration('Tên công việc hoặc sự kiện'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TaskType>(
                  initialValue: selectedType,
                  dropdownColor: _surface,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration('Loại sự kiện'),
                  items: TaskType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_typeLabel(type)),
                        ),
                      )
                      .toList(),
                  onChanged: (type) {
                    if (type != null) {
                      setSheetState(() => selectedType = type);
                    }
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: sheetContext,
                      initialTime: selectedTime,
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: _mars,
                            surface: _surface,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedTime = picked);
                    }
                  },
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text('Bắt đầu lúc ${selectedTime.format(context)}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE4DDEB),
                    side: const BorderSide(color: Colors.white24),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng nhập tên công việc.'),
                          ),
                        );
                        return;
                      }
                      Navigator.of(sheetContext).pop(
                        TaskModel(
                          title: title,
                          time: _formatTime(selectedTime),
                          date: _selectedDate,
                          type: selectedType,
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
    titleController.dispose();
    if (result != null && mounted) {
      setState(() => _tasks.add(result));
    }
  }

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

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  static String _typeLabel(TaskType type) => switch (type) {
    TaskType.mentee => 'Lịch hẹn Mentee',
    TaskType.exam => 'Lịch thi',
    TaskType.work => 'Công việc',
  };

  static Color _typeColor(TaskType type) => switch (type) {
    TaskType.mentee => const Color(0xFFBFA8FF),
    TaskType.exam => const Color(0xFFFFC36E),
    TaskType.work => _mars,
  };

  @override
  Widget build(BuildContext context) {
    final dayCount = _calendarDayCount;
    final calendarStart = _calendarStart;
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
            _buildCalendarCard(dayCount, calendarStart),
            _buildTasksHeader(selectedTasks.length),
            Expanded(
              child: selectedTasks.isEmpty
                  ? _buildEmptyTasks()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      itemCount: selectedTasks.length,
                      itemBuilder: (context, index) {
                        final task = selectedTasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TaskCard(
                            task: task,
                            color: _typeColor(task.type),
                            typeLabel: _typeLabel(task.type),
                            onToggle: () => _toggleCompleted(task),
                            onDelete: () => _deleteTask(task),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 12),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quay lại',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lịch & To-Do',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Sắp xếp hành trình của bạn',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.calendar_month_rounded, color: _mars),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(int dayCount, DateTime calendarStart) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
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
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: _weekdays
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: day == 'CN' ? const Color(0xFFFF9A83) : _muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          for (var week = 0; week < dayCount ~/ 7; week++)
            Row(
              children: List.generate(7, (weekday) {
                final date = calendarStart.add(
                  Duration(days: week * 7 + weekday),
                );
                return Expanded(child: _buildDayCell(date));
              }),
            ),
          const SizedBox(height: 5),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _monthButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) => IconButton(
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints.tightFor(width: 34, height: 34),
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 22, color: Colors.white70),
  );

  Widget _buildDayCell(DateTime date) {
    final inMonth = date.month == _visibleMonth.month;
    final selected = _isSameDay(date, _selectedDate);
    final today = _isSameDay(date, _today);
    final dayTasks = _tasksForDay(date);
    final colors = <Color>[];
    for (final task in dayTasks) {
      final color = _typeColor(task.type);
      if (!colors.contains(color)) colors.add(color);
    }

    return SizedBox(
      height: 41,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            _selectedDate = date;
            _visibleMonth = DateTime(date.year, date.month);
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 29,
              height: 27,
              decoration: BoxDecoration(
                color: selected
                    ? _mars
                    : today
                    ? _mars.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
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
                  fontSize: 11,
                  fontWeight: selected || today
                      ? FontWeight.w800
                      : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: colors.take(3).map((color) {
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
    const entries = [
      (TaskType.mentee, 'Mentee'),
      (TaskType.exam, 'Thi'),
      (TaskType.work, 'Công việc'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _typeColor(entry.$1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    entry.$2,
                    style: const TextStyle(color: _muted, fontSize: 9),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTasksHeader(int count) {
    final isToday = _isSameDay(_selectedDate, _today);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 3, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${isToday ? 'TODAY' : 'SELECTED DATE'} · '
              '${_selectedDate.day} ${_monthNames[_selectedDate.month - 1]}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                letterSpacing: 0.45,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: _mars.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count ${count == 1 ? 'sự kiện' : 'sự kiện'}',
              style: const TextStyle(
                color: Color(0xFFFFA18C),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTasks() {
    return Center(
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
              'Ngày này chưa có lịch',
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
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.color,
    required this.typeLabel,
    required this.onToggle,
    required this.onDelete,
  });

  final TaskModel task;
  final Color color;
  final String typeLabel;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final foreground = task.isCompleted ? Colors.white38 : Colors.white;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: _CalendarScreenState._surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 45,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 11),
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              task.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              color: task.isCompleted ? const Color(0xFF77D6AE) : color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.95),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  typeLabel,
                  style: const TextStyle(
                    color: _CalendarScreenState._muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Xóa công việc',
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFAAA5B8),
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}
