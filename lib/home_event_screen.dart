import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diacritic/diacritic.dart';

import 'event_detail_screen.dart';
import 'models/event_item.dart';
import 'models/tech_event.dart';
import 'services/career_board_service.dart';
import 'services/event_notification_service.dart';
import 'services/event_repository.dart';
import 'services/event_user_repository.dart';
import 'services/firebase_bootstrap.dart';
import 'services/points_manager.dart';
import 'widgets/event_catalog_widgets.dart';
import 'widgets/event_streaming_widgets.dart';
import 'models/xp_entry.dart';

class HomeEventScreen extends StatefulWidget {
  const HomeEventScreen({
    this.repository,
    this.userRepository,
    this.initialTab = 0,
    this.initialFilters = const EventSearchFilters(),
    super.key,
  });

  final EventRepository? repository;
  final EventUserRepository? userRepository;
  final int initialTab;
  final EventSearchFilters initialFilters;

  @override
  State<HomeEventScreen> createState() => _HomeEventScreenState();
}

class _HomeEventScreenState extends State<HomeEventScreen> {
  static const _muted = Color(0xFFB7B2C7);

  EventRepository? _repository;
  EventUserRepository? _userRepository;
  Stream<List<EventItem>>? _eventsStream;
  StreamSubscription<List<EventItem>>? _eventsSubscription;
  StreamSubscription<Set<String>>? _savedSubscription;
  StreamSubscription<Map<String, bool>>? _planSubscription;
  List<EventItem> _events = const [];
  Set<String> _savedIds = {};
  Map<String, bool> _planReminders = {};
  Map<String, dynamic> _skillMastery = {};
  String? _careerGoal;
  String? _error;
  bool _loading = true;
  bool _syncingReminderSchedules = false;
  int _selectedTab = 0;
  String _homeCategory = 'Tất cả';
  String _homeQuery = '';
  late final TextEditingController _homeSearchController;
  EventSearchFilters _filters = const EventSearchFilters();

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab.clamp(0, 3);
    _filters = widget.initialFilters;
    _homeSearchController = TextEditingController();
    unawaited(CareerBoardService.instance.initialize());
    _loadCareerProfile();
    _connect();
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _savedSubscription?.cancel();
    _planSubscription?.cancel();
    _homeSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadCareerProfile() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('career_map_skills');
    Map<String, dynamic> mastery = {};
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) mastery = decoded;
      } on FormatException {
        _showMessage(
          'Dữ liệu kỹ năng đã lưu không hợp lệ; dùng hồ sơ hiện có.',
        );
      }
    }
    if (!mounted) return;
    setState(() {
      _careerGoal = preferences.getString('career_goal');
      _skillMastery = mastery;
    });
  }

  Future<void> _connect() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_repository == null) {
        await FirebaseBootstrap.initialize();
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw StateError('Firebase Auth chưa tạo được phiên người dùng.');
        }
        _repository = FirestoreEventRepository(FirebaseFirestore.instance);
        _userRepository = FirestoreEventUserRepository(
          firestore: FirebaseFirestore.instance,
          uid: user.uid,
        );
      } else {
        _userRepository ??= widget.userRepository;
      }
      final users = _userRepository;
      if (users == null) {
        throw StateError('Thiếu kho dữ liệu sự kiện của người dùng.');
      }
      await _eventsSubscription?.cancel();
      await _savedSubscription?.cancel();
      await _planSubscription?.cancel();
      _eventsStream = _repository!.watchEvents().asBroadcastStream();
      _eventsSubscription = _eventsStream!.listen((events) {
        if (!mounted) return;
        setState(() {
          _events = events;
          _loading = false;
          _error = null;
        });
        _syncReminderSchedules();
      }, onError: _onStreamError);
      _savedSubscription = users.watchSavedEventIds().listen((ids) {
        if (!mounted) return;
        setState(() => _savedIds = ids);
      }, onError: _onStreamError);
      _planSubscription = users.watchPlan().listen((plan) {
        if (!mounted) return;
        setState(() => _planReminders = plan);
        _syncReminderSchedules();
      }, onError: _onStreamError);
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message ?? error.code;
          _loading = false;
        });
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message ?? 'Không thể khởi tạo Firebase.';
          _loading = false;
        });
      }
    } on StateError catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    }
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    if (!mounted) return;
    setState(() {
      _error = error.toString();
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    try {
      await _repository?.refresh();
    } on FirebaseException catch (error) {
      _showMessage('Không thể làm mới dữ liệu: ${error.message ?? error.code}');
    }
  }

  int _matchPercent(EventItem event) {
    final goal = _careerGoal?.toLowerCase().trim();
    final related =
        goal != null &&
        goal.isNotEmpty &&
        event.relatedCareers.any((career) {
          final value = career.toLowerCase();
          return value == goal || value.contains(goal) || goal.contains(value);
        });
    final skillScore = event.skills.isEmpty
        ? 0.0
        : event.skills
                  .map(
                    (skill) => (_skillMastery[skill] as num?)?.toDouble() ?? 0,
                  )
                  .fold<double>(0, math.max) /
              10;
    return (((related ? 0.65 : 0) + skillScore.clamp(0, 0.35)) * 100)
        .round()
        .clamp(0, 100);
  }

  Future<void> _syncReminderSchedules() async {
    if (_syncingReminderSchedules ||
        _events.isEmpty ||
        _planReminders.isEmpty) {
      return;
    }
    _syncingReminderSchedules = true;
    try {
      for (final entry in _planReminders.entries) {
        if (!entry.value) continue;
        EventItem? event;
        for (final item in _events) {
          if (item.id == entry.key) {
            event = item;
            break;
          }
        }
        final deadline = event?.registrationDeadline;
        if (event == null || deadline == null) continue;
        await EventNotificationService.instance.scheduleRegistrationReminders(
          eventId: event.id,
          title: event.title,
          deadline: deadline,
          requestPermission: false,
        );
      }
    } on PlatformException catch (error) {
      _showMessage(error.message ?? 'Không thể khôi phục thông báo.');
    } finally {
      _syncingReminderSchedules = false;
    }
  }

  Future<bool> _toggleSaved(EventItem event) async {
    try {
      await _userRepository!.setSaved(event.id, !_savedIds.contains(event.id));
      return true;
    } on FirebaseException catch (error) {
      _showMessage(
        'Không thể cập nhật mục đã lưu: ${error.message ?? error.code}',
      );
      return false;
    }
  }

  Future<PlanAddResult> _createPlanEntry(EventItem event) async {
    final result = await _userRepository!.addToPlan(event.id);
    if (result.added) {
      unawaited(CareerBoardService.instance.reportEventPlanned(event.id));
      PointsManager.instance.joinEvent(event);
      if (result.shouldAwardXp) {
        await PointsManager.instance.addXP(
          thanh: XpBar.thucChien,
          luong: event.trainingPoints,
          nguon: 'event_plan',
          sourceRef: 'event-plan-${event.id}',
        );
      }
    }
    return result;
  }

  Future<bool> _addToPlan(EventItem event) async {
    try {
      final result = await _createPlanEntry(event);
      if (!result.added) {
        _showMessage('Sự kiện đã có trong Kế hoạch của tôi.');
        return false;
      }
      _showMessage('Đã thêm vào Kế hoạch của tôi.');
      return true;
    } on FirebaseException catch (error) {
      _showMessage(
        'Không thể thêm vào kế hoạch: ${error.message ?? error.code}',
      );
      return false;
    }
  }

  Future<void> _removeFromPlan(EventItem event, {bool showUndo = true}) async {
    try {
      await _userRepository!.removeFromPlan(event.id);
      await EventNotificationService.instance.cancelRegistrationReminders(
        event.id,
      );
      if (showUndo && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã bỏ sự kiện khỏi kế hoạch'),
            action: SnackBarAction(
              label: 'Hoàn tác',
              onPressed: () => _addToPlan(event),
            ),
          ),
        );
      }
    } on FirebaseException catch (error) {
      _showMessage(
        'Không thể bỏ khỏi kế hoạch: ${error.message ?? error.code}',
      );
    } on PlatformException catch (error) {
      _showMessage(error.message ?? 'Không thể huỷ thông báo sự kiện.');
    }
  }

  Future<bool> _toggleReminder(EventItem event, bool enabled) async {
    final deadline = event.registrationDeadline;
    if (enabled && deadline == null) {
      _showMessage('Chưa có hạn đăng ký để đặt nhắc nhở.');
      return false;
    }
    var createdPlanEntry = false;
    try {
      if (enabled) {
        if (!_planReminders.containsKey(event.id)) {
          final result = await _createPlanEntry(event);
          createdPlanEntry = result.added;
        }
        final scheduled = await EventNotificationService.instance
            .scheduleRegistrationReminders(
              eventId: event.id,
              title: event.title,
              deadline: deadline!,
              requestPermission: true,
            );
        if (scheduled < 0) {
          if (createdPlanEntry) {
            await _userRepository!.removeFromPlan(event.id);
          }
          _showMessage('Bạn chưa cấp quyền thông báo.');
          return false;
        }
        if (scheduled == 0) {
          if (createdPlanEntry) {
            await _userRepository!.removeFromPlan(event.id);
          }
          _showMessage('Hạn đăng ký đã đến; không còn lịch nhắc phù hợp.');
          return false;
        }
      } else {
        await EventNotificationService.instance.cancelRegistrationReminders(
          event.id,
        );
      }
      await _userRepository!.setReminder(event.id, enabled);
      _showMessage(enabled ? 'Đã đặt nhắc trước hạn đăng ký.' : 'Đã tắt nhắc.');
      return true;
    } on FirebaseException catch (error) {
      if (enabled) {
        await EventNotificationService.instance.cancelRegistrationReminders(
          event.id,
        );
        if (createdPlanEntry) {
          await _userRepository!.removeFromPlan(event.id);
        }
      }
      _showMessage(
        'Không thể lưu trạng thái nhắc: ${error.message ?? error.code}',
      );
      return false;
    } on PlatformException catch (error) {
      if (createdPlanEntry) {
        await _userRepository!.removeFromPlan(event.id);
      }
      _showMessage(
        error.message ?? 'Không thể đặt thông báo trên thiết bị này.',
      );
      return false;
    }
  }

  void _openEvent(EventItem event) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EventDetailScreen(
          event: event,
          matchPercent: _matchPercent(event),
          saved: _savedIds.contains(event.id),
          planned: _planReminders.containsKey(event.id),
          reminderEnabled: _planReminders[event.id] ?? false,
          onToggleSaved: () => _toggleSaved(event),
          onAddToPlan: () => _addToPlan(event),
          onToggleReminder: (enabled) => _toggleReminder(event, enabled),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? _loadingState()
            : _error != null
            ? _errorState()
            : RefreshIndicator(
                onRefresh: _refresh,
                color: const Color(0xFFBFA8FF),
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    _homeTab(),
                    _exploreTab(),
                    _planTab(),
                    _savedTab(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _loadingState() => const EventHomeSkeleton();

  Widget _errorState() {
    final isSetupIssue =
        FirebaseBootstrap.lastError != null ||
        (Firebase.apps.isEmpty && widget.repository == null);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.cloud_off_rounded, size: 48, color: _muted),
        const SizedBox(height: 16),
        Text(
          isSetupIssue
              ? 'Firebase chưa được cấu hình'
              : 'Không thể tải dữ liệu sự kiện',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          isSetupIssue
              ? 'Chạy flutterfire configure để tạo cấu hình cho dự án Firebase, sau đó bật Anonymous Authentication và Cloud Firestore.'
              : _error ?? 'Lỗi không xác định.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, height: 1.4),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _connect,
          icon: const Icon(Icons.refresh),
          label: const Text('Thử lại'),
        ),
      ],
    );
  }

  Widget _homeTab() => StreamBuilder<List<EventItem>>(
    stream: _eventsStream,
    initialData: _events,
    builder: (context, snapshot) => _buildEventHome(snapshot.data ?? _events),
  );

  Widget _buildEventHome(List<EventItem> events) {
    final normalizedQuery = _normalizeEventSearch(_homeQuery);
    final filtered = events
        .where((event) {
          final group = techEventGroup(event.title, event.type);
          final categoryMatches =
              _homeCategory == 'Tất cả' || group.label == _homeCategory;
          final searchable = _normalizeEventSearch(
            '${event.title} ${event.organizer} ${event.type}',
          );
          return categoryMatches &&
              (normalizedQuery.isEmpty || searchable.contains(normalizedQuery));
        })
        .toList(growable: false);
    final isFiltering = normalizedQuery.isNotEmpty || _homeCategory != 'Tất cả';
    final featured = events.take(5).toList(growable: false);

    return ListView(
      key: const PageStorageKey<String>('events-home'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 112),
      children: [
        _homeSearchBar(),
        if (!isFiltering && featured.isNotEmpty) ...[
          const SizedBox(height: 14),
          EventStreamHeroCarousel(events: featured, onOpen: _openEvent),
        ],
        const SizedBox(height: 12),
        EventStreamCategoryChips(
          selected: _homeCategory,
          onSelected: (category) => setState(() => _homeCategory = category),
        ),
        if (isFiltering) ...[
          const SizedBox(height: 18),
          Text(
            '${filtered.length} kết quả',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Không tìm thấy sự kiện phù hợp.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 210,
              ),
              itemBuilder: (context, index) => EventStreamCard(
                event: filtered[index],
                onTap: () => _openEvent(filtered[index]),
                width: double.infinity,
                height: 210,
              ),
            ),
        ] else if (events.isEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Chưa có sự kiện nào',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted),
          ),
        ] else ...[
          const SizedBox(height: 8),
          EventStreamSectionRow(
            title: '🔥 Sắp diễn ra',
            events: _upcomingEvents(events),
            onOpen: _openEvent,
          ),
          for (final group in TechEventGroup.values)
            EventStreamSectionRow(
              title: group.label,
              events: events
                  .where(
                    (event) => techEventGroup(event.title, event.type) == group,
                  )
                  .toList(growable: false),
              onOpen: _openEvent,
            ),
        ],
      ],
    );
  }

  Widget _homeSearchBar() => TextField(
    controller: _homeSearchController,
    onChanged: (value) => setState(() => _homeQuery = value),
    textInputAction: TextInputAction.search,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      hintText: 'Tìm sự kiện, đơn vị tổ chức…',
      hintStyle: const TextStyle(color: _muted, fontSize: 13),
      prefixIcon: const Icon(Icons.search_rounded, color: _muted),
      suffixIcon: _homeQuery.isEmpty
          ? null
          : IconButton(
              tooltip: 'Xóa tìm kiếm',
              onPressed: () {
                _homeSearchController.clear();
                setState(() => _homeQuery = '');
              },
              icon: const Icon(Icons.close_rounded, color: _muted),
            ),
      filled: true,
      fillColor: const Color(0xB8222030),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
    ),
  );

  List<EventItem> _upcomingEvents(List<EventItem> events) {
    final now = DateTime.now();
    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final matching = events
        .where((event) {
          final timeline = event.timeline;
          if (timeline == null) return false;
          final months = _monthsInTimeline(timeline);
          return months.contains(now.month) || months.contains(nextMonth);
        })
        .toList(growable: false);
    return matching.isEmpty
        ? events.take(10).toList(growable: false)
        : matching;
  }

  Set<int> _monthsInTimeline(String timeline) {
    final normalized = _normalizeEventSearch(timeline);
    final months = <int>{};
    final range = RegExp(r'thang\s*(\d{1,2})\s*[-–]\s*(?:thang\s*)?(\d{1,2})');
    for (final match in range.allMatches(normalized)) {
      final start = int.tryParse(match.group(1) ?? '');
      final end = int.tryParse(match.group(2) ?? '');
      if (start == null || end == null || start < 1 || end > 12) continue;
      var month = start;
      while (true) {
        months.add(month);
        if (month == end) break;
        month = month == 12 ? 1 : month + 1;
      }
    }
    for (final match in RegExp(r'thang\s*(\d{1,2})').allMatches(normalized)) {
      final month = int.tryParse(match.group(1) ?? '');
      if (month != null && month >= 1 && month <= 12) months.add(month);
    }
    return months;
  }

  String _normalizeEventSearch(String value) =>
      removeDiacritics(value).toLowerCase().trim();

  Widget _exploreTab() => _ExploreEventsPage(
    events: _events,
    filters: _filters,
    matchPercent: _matchPercent,
    savedIds: _savedIds,
    onFiltersChanged: (filters) => setState(() => _filters = filters),
    onOpen: _openEvent,
    onToggleSaved: _toggleSaved,
  );

  Widget _planTab() {
    final planned = _events
        .where((event) => _planReminders.containsKey(event.id))
        .toList();
    final upcoming =
        planned
            .where(
              (event) => event.statusAt(DateTime.now()) != EventStatus.ended,
            )
            .toList()
          ..sort(
            (a, b) => (a.registrationDeadline ?? a.eventStart ?? DateTime(9999))
                .compareTo(
                  b.registrationDeadline ?? b.eventStart ?? DateTime(9999),
                ),
          );
    final past = planned
        .where((event) => event.statusAt(DateTime.now()) == EventStatus.ended)
        .toList();
    return _PlanEventsPage(
      upcoming: upcoming,
      past: past,
      reminders: _planReminders,
      matchPercent: _matchPercent,
      savedIds: _savedIds,
      onOpen: _openEvent,
      onRemove: _removeFromPlan,
      onToggleSaved: _toggleSaved,
      onExplore: () => setState(() => _selectedTab = 1),
    );
  }

  Widget _savedTab() {
    final saved =
        _events.where((event) => _savedIds.contains(event.id)).toList()
          ..sort((a, b) => a.title.compareTo(b.title));
    return ListView(
      key: const PageStorageKey<String>('events-saved'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        const Text(
          'Đã lưu',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Các cơ hội bạn muốn xem lại',
          style: TextStyle(color: _muted),
        ),
        const SizedBox(height: 18),
        if (saved.isEmpty)
          EventEmptyState(
            title: 'Chưa có sự kiện đã lưu',
            message: 'Chạm biểu tượng trái tim để lưu cơ hội bạn quan tâm.',
            actionLabel: 'Khám phá sự kiện',
            onAction: () => setState(() => _selectedTab = 1),
          )
        else
          for (final event in saved)
            EventListTile(
              event: event,
              saved: true,
              matchPercent: _matchPercent(event),
              onTap: () => _openEvent(event),
              onSave: () => _toggleSaved(event),
            ),
      ],
    );
  }
}

class _ExploreEventsPage extends StatefulWidget {
  const _ExploreEventsPage({
    required this.events,
    required this.filters,
    required this.matchPercent,
    required this.savedIds,
    required this.onFiltersChanged,
    required this.onOpen,
    required this.onToggleSaved,
  });

  final List<EventItem> events;
  final EventSearchFilters filters;
  final int Function(EventItem) matchPercent;
  final Set<String> savedIds;
  final ValueChanged<EventSearchFilters> onFiltersChanged;
  final ValueChanged<EventItem> onOpen;
  final ValueChanged<EventItem> onToggleSaved;

  @override
  State<_ExploreEventsPage> createState() => _ExploreEventsPageState();
}

class _ExploreEventsPageState extends State<_ExploreEventsPage> {
  late final TextEditingController _searchController;
  Timer? _debounce;
  String _selectedCategory = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.filters.query);
    _selectedCategory = widget.filters.type ?? 'Tất cả';
  }

  @override
  void didUpdateWidget(covariant _ExploreEventsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters.type != widget.filters.type &&
        (widget.filters.type != null || _selectedCategory != 'Kỹ năng')) {
      _selectedCategory = widget.filters.type ?? 'Tất cả';
    }
    if (oldWidget.filters.query != widget.filters.query &&
        widget.filters.query != _searchController.text) {
      _searchController.text = widget.filters.query;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      widget.onFiltersChanged(_copyFilters(query: value));
    });
  }

  EventSearchFilters _copyFilters({
    String? query,
    String? type,
    String? career,
    String? skill,
    EventStatus? status,
    DateTime? from,
    DateTime? to,
    String? format,
    EventSort? sort,
    bool clearType = false,
    bool clearCareer = false,
    bool clearSkill = false,
    bool clearStatus = false,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearFormat = false,
  }) => EventSearchFilters(
    query: query ?? widget.filters.query,
    type: clearType ? null : type ?? widget.filters.type,
    career: clearCareer ? null : career ?? widget.filters.career,
    skill: clearSkill ? null : skill ?? widget.filters.skill,
    status: clearStatus ? null : status ?? widget.filters.status,
    from: clearFrom ? null : from ?? widget.filters.from,
    to: clearTo ? null : to ?? widget.filters.to,
    format: clearFormat ? null : format ?? widget.filters.format,
    sort: sort ?? widget.filters.sort,
  );

  Future<void> _advancedFilters() async {
    final filters = await showModalBottomSheet<EventSearchFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181725),
      builder: (_) =>
          _AdvancedEventFilters(events: widget.events, initial: widget.filters),
    );
    if (filters != null) widget.onFiltersChanged(filters);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = EventCatalog.filterAndSort(
      widget.events,
      now: DateTime.now(),
      filters: widget.filters,
      matchPercent: widget.matchPercent,
    );
    final result = _selectedCategory == 'Kỹ năng'
        ? filtered.where((event) => event.skills.isNotEmpty).toList()
        : filtered;
    return ListView(
      key: const PageStorageKey<String>('events-explore'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        const Text(
          'Khám phá',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _searchController,
          onChanged: _search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Tìm sự kiện, đơn vị, kỹ năng…',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              tooltip: 'Lọc nâng cao',
              onPressed: _advancedFilters,
              icon: const Icon(Icons.tune_rounded),
            ),
            filled: true,
            fillColor: const Color(0xB8222030),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        EventCategoryChips(
          selected: _selectedCategory,
          onSelected: (category) {
            setState(() => _selectedCategory = category);
            if (category == 'Tất cả' || category == 'Kỹ năng') {
              widget.onFiltersChanged(_copyFilters(clearType: true));
            } else {
              widget.onFiltersChanged(_copyFilters(type: category));
            }
          },
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _statusFilter('Mọi trạng thái', null),
              _statusFilter('Đang mở', EventStatus.registrationOpen),
              _statusFilter('Sắp mở', EventStatus.openingSoon),
              _statusFilter('Sắp diễn ra', EventStatus.closedUpcoming),
              _statusFilter('Đã kết thúc', EventStatus.ended),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              '${result.length} sự kiện',
              style: const TextStyle(color: Color(0xFFD7D2E4)),
            ),
            const Spacer(),
            PopupMenuButton<EventSort>(
              initialValue: widget.filters.sort,
              onSelected: (sort) =>
                  widget.onFiltersChanged(_copyFilters(sort: sort)),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: EventSort.deadline,
                  child: Text('Hạn đăng ký gần nhất'),
                ),
                PopupMenuItem(
                  value: EventSort.match,
                  child: Text('Phù hợp nhất'),
                ),
                PopupMenuItem(value: EventSort.newest, child: Text('Mới nhất')),
              ],
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.sort_rounded, size: 18),
                    SizedBox(width: 5),
                    Text('Sắp xếp'),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (result.isEmpty)
          const EventEmptyState(
            title: 'Không tìm thấy sự kiện',
            message: 'Thử từ khóa khác hoặc bỏ bớt bộ lọc đang chọn.',
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: result.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 248,
            ),
            itemBuilder: (context, index) {
              final event = result[index];
              return EventCard(
                event: event,
                saved: widget.savedIds.contains(event.id),
                matchPercent: widget.matchPercent(event),
                onTap: () => widget.onOpen(event),
                onSave: () => widget.onToggleSaved(event),
                width: double.infinity,
                height: 248,
              );
            },
          ),
      ],
    );
  }

  Widget _statusFilter(String label, EventStatus? status) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: widget.filters.status == status,
      onSelected: (_) {
        widget.onFiltersChanged(
          status == null
              ? _copyFilters(clearStatus: true)
              : _copyFilters(status: status),
        );
      },
      selectedColor: const Color(0xFF574683),
      backgroundColor: const Color(0xAA242236),
      labelStyle: TextStyle(
        color: widget.filters.status == status
            ? Colors.white
            : const Color(0xFFB7B2C7),
        fontSize: 12,
      ),
    ),
  );
}

class _AdvancedEventFilters extends StatefulWidget {
  const _AdvancedEventFilters({required this.events, required this.initial});

  final List<EventItem> events;
  final EventSearchFilters initial;

  @override
  State<_AdvancedEventFilters> createState() => _AdvancedEventFiltersState();
}

class _AdvancedEventFiltersState extends State<_AdvancedEventFilters> {
  late String? _type = widget.initial.type;
  late String? _career = widget.initial.career;
  late String? _skill = widget.initial.skill;
  late String? _format = widget.initial.format;
  late EventStatus? _status = widget.initial.status;
  late DateTime? _from = widget.initial.from;
  late DateTime? _to = widget.initial.to;

  List<String> get _types =>
      widget.events.map((event) => event.type).toSet().toList()..sort();
  List<String> get _careers =>
      widget.events.expand((event) => event.relatedCareers).toSet().toList()
        ..sort();
  List<String> get _skills =>
      widget.events.expand((event) => event.skills).toSet().toList()..sort();
  List<String> get _formats =>
      widget.events
          .map((event) => event.format)
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Lọc sự kiện',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            _dropdown<String>('Loại sự kiện', _type, _types, (value) {
              setState(() => _type = value);
            }),
            _dropdown<String>('Nghề nghiệp', _career, _careers, (value) {
              setState(() => _career = value);
            }),
            _dropdown<String>('Kỹ năng', _skill, _skills, (value) {
              setState(() => _skill = value);
            }),
            _dropdown<EventStatus>(
              'Trạng thái',
              _status,
              EventStatus.values,
              (value) => setState(() => _status = value),
              labelOf: _statusLabel,
            ),
            _dropdown<String>('Hình thức', _format, _formats, (value) {
              setState(() => _format = value);
            }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickRange,
              icon: const Icon(Icons.date_range_outlined),
              label: Text(
                _from == null && _to == null
                    ? 'Khoảng thời gian'
                    : '${eventDateLabel(_from)} – ${eventDateLabel(_to)}',
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _type = null;
                      _career = null;
                      _skill = null;
                      _format = null;
                      _status = null;
                      _from = null;
                      _to = null;
                    }),
                    child: const Text('Xoá lọc'),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      EventSearchFilters(
                        query: widget.initial.query,
                        type: _type,
                        career: _career,
                        skill: _skill,
                        format: _format,
                        status: _status,
                        from: _from,
                        to: _to,
                        sort: widget.initial.sort,
                      ),
                    ),
                    child: const Text('Áp dụng'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _dropdown<T>(
    String label,
    T? value,
    List<T> options,
    ValueChanged<T?> onChanged, {
    String Function(T)? labelOf,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xAA242236),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      items: [
        DropdownMenuItem<T>(
          value: null,
          child: Text('Tất cả $label'.toLowerCase()),
        ),
        for (final option in options)
          DropdownMenuItem<T>(
            value: option,
            child: Text(labelOf?.call(option) ?? option.toString()),
          ),
      ],
      onChanged: onChanged,
    ),
  );

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDateRange: _from == null || _to == null
          ? null
          : DateTimeRange(start: _from!, end: _to!),
    );
    if (range != null) {
      setState(() {
        _from = range.start;
        _to = range.end;
      });
    }
  }

  String _statusLabel(EventStatus status) {
    switch (status) {
      case EventStatus.registrationOpen:
        return 'Đang mở đăng ký';
      case EventStatus.openingSoon:
        return 'Sắp mở';
      case EventStatus.closedUpcoming:
        return 'Sắp diễn ra';
      case EventStatus.ended:
        return 'Đã kết thúc';
      case EventStatus.newSeasonUnknown:
        return 'Chưa có mùa mới';
      case EventStatus.dateUnknown:
        return 'Chưa công bố ngày';
    }
  }
}

class _PlanEventsPage extends StatefulWidget {
  const _PlanEventsPage({
    required this.upcoming,
    required this.past,
    required this.reminders,
    required this.matchPercent,
    required this.savedIds,
    required this.onOpen,
    required this.onRemove,
    required this.onToggleSaved,
    required this.onExplore,
  });

  final List<EventItem> upcoming;
  final List<EventItem> past;
  final Map<String, bool> reminders;
  final int Function(EventItem) matchPercent;
  final Set<String> savedIds;
  final ValueChanged<EventItem> onOpen;
  final Future<void> Function(EventItem) onRemove;
  final ValueChanged<EventItem> onToggleSaved;
  final VoidCallback onExplore;

  @override
  State<_PlanEventsPage> createState() => _PlanEventsPageState();
}

class _PlanEventsPageState extends State<_PlanEventsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kế hoạch của tôi',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Sắp tới'),
                Tab(text: 'Đã qua'),
              ],
              indicatorColor: const Color(0xFFBFA8FF),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFFAAA5B8),
            ),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tabs,
          children: [
            _planList(widget.upcoming, past: false),
            _planList(widget.past, past: true),
          ],
        ),
      ),
    ],
  );

  Widget _planList(List<EventItem> events, {required bool past}) {
    if (events.isEmpty) {
      return ListView(
        children: [
          EventEmptyState(
            title: past ? 'Chưa có sự kiện đã qua' : 'Kế hoạch đang trống',
            message: past ? 'Các sự kiện đã kết thúc sẽ được lưu lại ở đây.' : 'Thêm sự kiện vào kế hoạch để theo dõi hạn đăng ký và nhắc nhở.',
            actionLabel: past ? null : 'Khám phá sự kiện',
            onAction: past ? null : widget.onExplore,
          ),
        ],
      );
    }
    return ListView(
      key: PageStorageKey<String>(
        past ? 'events-plan-past' : 'events-plan-next',
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        for (final event in events)
          Dismissible(
            key: ValueKey<String>('plan-${event.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 12),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF8C334A),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            onDismissed: (_) => widget.onRemove(event),
            child: Column(
              children: [
                EventListTile(
                  event: event,
                  saved: widget.savedIds.contains(event.id),
                  matchPercent: widget.matchPercent(event),
                  onTap: () => widget.onOpen(event),
                  onSave: () => widget.onToggleSaved(event),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Row(
                    children: [
                      Icon(
                        widget.reminders[event.id] == true
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_none_outlined,
                        size: 16,
                        color: widget.reminders[event.id] == true
                            ? const Color(0xFFFFD166)
                            : _HomeEventScreenState._muted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.reminders[event.id] == true
                              ? 'Đang nhắc trước hạn đăng ký'
                              : 'Chưa bật nhắc nhở',
                          style: const TextStyle(
                            color: _HomeEventScreenState._muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        event.daysUntilDeadline(DateTime.now()) == null
                            ? eventDateLabel(event.eventStart)
                            : 'Còn ${event.daysUntilDeadline(DateTime.now())} ngày',
                        style: const TextStyle(
                          color: Color(0xFFFFD166),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
