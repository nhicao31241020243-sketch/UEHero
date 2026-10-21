import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'event_detail_screen.dart';
import 'models/event_item.dart';
import 'screens/career_goal_screen.dart';
import 'services/event_notification_service.dart';
import 'services/event_repository.dart';
import 'services/event_user_repository.dart';
import 'services/firebase_bootstrap.dart';
import 'services/points_manager.dart';
import 'widgets/event_catalog_widgets.dart';
import 'widgets/event_poster.dart';
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
  static const _categories = <(String, IconData)>[
    ('Cuộc thi', Icons.emoji_events_outlined),
    ('Hackathon', Icons.terminal_rounded),
    ('Hội chợ việc làm', Icons.work_outline_rounded),
    ('Workshop', Icons.handyman_outlined),
    ('Case Competition', Icons.business_center_outlined),
    ('Datathon', Icons.query_stats_rounded),
  ];

  EventRepository? _repository;
  EventUserRepository? _userRepository;
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
  EventSearchFilters _filters = const EventSearchFilters();
  late final PageController _heroController;
  int _heroIndex = 0;
  String? _group;
  static const _groups = <String>[
    'Data Analyst',
    'Business Analyst',
    'Front End',
    'AI/Hackathon',
    'Lập trình thi đấu',
  ];
  Timer? _heroTimer;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab.clamp(0, 3);
    _filters = widget.initialFilters;
    _heroController = PageController(viewportFraction: 0.92);
    _loadCareerProfile();
    _connect();
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _savedSubscription?.cancel();
    _planSubscription?.cancel();
    _heroTimer?.cancel();
    _heroController.dispose();
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
      _eventsSubscription = _repository!.watchEvents().listen((events) {
        if (!mounted) return;
        setState(() {
          _events = events;
          _loading = false;
          _error = null;
        });
        _startHeroTimer();
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

  List<EventItem> _sorted({
    String? type,
    EventStatus? status,
    String? career,
    required EventSort sort,
  }) => EventCatalog.filterAndSort(
    _scope,
    now: DateTime.now(),
    filters: EventSearchFilters(
      type: type,
      status: status,
      career: career,
      sort: sort,
    ),
    matchPercent: _matchPercent,
  );

  List<EventItem> get _scope => _group == null
      ? _events
      : _events
            .where((event) => event.relatedCareers.contains(_group))
            .toList(growable: false);

  List<EventItem> get _heroEvents {
    final now = DateTime.now();
    final open =
        _scope
            .where(
              (event) => event.statusAt(now) == EventStatus.registrationOpen,
            )
            .toList()
          ..sort((a, b) {
            final deadline = (a.registrationDeadline ?? DateTime(9999))
                .compareTo(b.registrationDeadline ?? DateTime(9999));
            if (deadline != 0) return deadline;
            return _matchPercent(b).compareTo(_matchPercent(a));
          });
    final upcoming = _scope
        .where((event) => event.statusAt(now) == EventStatus.closedUpcoming)
        .toList();
    final source = open.isNotEmpty ? open : upcoming;
    return source.take(6).toList(growable: false);
  }

  void _startHeroTimer() {
    if (_heroEvents.length < 2 || _heroTimer != null) return;
    _heroTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_heroController.hasClients || _heroEvents.isEmpty) {
        return;
      }
      final next = (_heroIndex + 1) % _heroEvents.length;
      _heroController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
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

  Future<void> _openSource(EventItem event) async {
    final uri = Uri.tryParse(event.sourceUrl ?? '');
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showMessage('Không mở được liên kết nguồn.');
    }
  }

  void _goToExplore([EventSearchFilters filters = const EventSearchFilters()]) {
    setState(() {
      _filters = filters;
      _selectedTab = 1;
    });
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: _selectTab,
        backgroundColor: const Color(0xF20D1020),
        indicatorColor: const Color(0xFF59468A),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Khám phá',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            label: 'Kế hoạch',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Đã lưu',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_history_outlined),
            label: 'Hồ sơ nghề',
          ),
        ],
      ),
    );
  }

  void _selectTab(int index) {
    if (index == 4) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const CareerGoalScreen(skipIfSavedUser: false),
        ),
      );
      return;
    }
    setState(() => _selectedTab = index);
  }

  Widget _loadingState() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
    children: [
      const Text(
        'Khám phá cơ hội nghề nghiệp',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 18),
      Container(
        height: 270,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF2C2941), Color(0xFF151B2A)],
          ),
        ),
      ),
      const SizedBox(height: 24),
      const Text('Đang tải sự kiện…', style: TextStyle(color: _muted)),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: List.generate(
            3,
            (_) => Container(
              width: 142,
              height: 210,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF29263A), Color(0xFF171925)],
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),
      const Center(child: CircularProgressIndicator()),
    ],
  );

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

  Widget _homeTab() {
    final featured = _heroEvents;
    final now = DateTime.now();
    final closing = _sorted(
      status: EventStatus.registrationOpen,
      sort: EventSort.deadline,
    ).take(10).toList();
    final matched = _sorted(sort: EventSort.match)
        .where(
          (event) =>
              _matchPercent(event) > 0 &&
              event.statusAt(now) != EventStatus.ended,
        )
        .take(10)
        .toList();
    final opened = _sorted(
      status: EventStatus.closedUpcoming,
      sort: EventSort.deadline,
    ).take(10).toList();
    final planned =
        _events.where((event) => _planReminders.containsKey(event.id)).toList()
          ..sort(
            (a, b) => (a.registrationDeadline ?? DateTime(9999)).compareTo(
              b.registrationDeadline ?? DateTime(9999),
            ),
          );
    final previous = _scope.where((event) {
      final status = event.statusAt(now);
      return status == EventStatus.ended ||
          (status == EventStatus.newSeasonUnknown &&
              event.previousSeason != null);
    }).toList();

    return ListView(
      key: const PageStorageKey<String>('events-home'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chào ${FirebaseAuth.instance.currentUser?.displayName ?? 'bạn'} 👋',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tìm cơ hội để tiến gần hơn tới nghề nghiệp mơ ước',
                    maxLines: 2,
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Nhắc nhở',
              onPressed: () => setState(() => _selectedTab = 2),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _searchBar(
          hint: 'Tìm cuộc thi, workshop, kỹ năng…',
          onTap: () => _goToExplore(),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _groups.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final label = index == 0 ? 'Tất cả' : _groups[index - 1];
              final value = index == 0 ? null : label;
              return ChoiceChip(
                label: Text(label),
                selected: _group == value,
                onSelected: (_) {
                  if (_heroController.hasClients) _heroController.jumpToPage(0);
                  setState(() {
                    _group = value;
                    _heroIndex = 0;
                  });
                },
                selectedColor: const Color(0xFF7B5CC7),
                backgroundColor: const Color(0xB5232031),
                labelStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 4),
            itemBuilder: (context, index) {
              final category = _categories[index];
              return EventCategoryIcon(
                label: category.$1,
                icon: category.$2,
                selected: false,
                onTap: () =>
                    _goToExplore(EventSearchFilters(type: category.$1)),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        if (featured.isNotEmpty) ...[
          SizedBox(
            height: 346,
            child: PageView.builder(
              controller: _heroController,
              itemCount: featured.length,
              onPageChanged: (index) => setState(() => _heroIndex = index),
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _heroCard(featured[index]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              featured.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: index == _heroIndex ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == _heroIndex
                      ? const Color(0xFFBFA8FF)
                      : Colors.white38,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        _posterSection(
          'Đang mở đăng ký',
          closing,
          filters: const EventSearchFilters(
            status: EventStatus.registrationOpen,
            sort: EventSort.deadline,
          ),
        ),
        _posterSection(
          'Sắp diễn ra',
          opened,
          filters: const EventSearchFilters(
            status: EventStatus.closedUpcoming,
            sort: EventSort.deadline,
          ),
        ),
        _posterSection(
          'Phù hợp với bạn',
          matched,
          filters: const EventSearchFilters(sort: EventSort.match),
        ),
        if (planned.isNotEmpty)
          _posterSection(
            'Đang theo dõi',
            planned,
            filters: const EventSearchFilters(),
          ),
        _posterSection(
          'Đã kết thúc và mùa tới',
          previous,
          filters: const EventSearchFilters(status: EventStatus.ended),
        ),
        if (_careerGoal != null) ...[
          const SizedBox(height: 18),
          const EventSectionTitle(title: 'Khám phá theo nghề'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final career in _careerTags)
                ActionChip(
                  label: Text(career),
                  avatar: const Icon(Icons.work_outline, size: 16),
                  onPressed: () =>
                      _goToExplore(EventSearchFilters(career: career)),
                  backgroundColor: const Color(0xAA242236),
                ),
            ],
          ),
        ],
        if (_events.isEmpty)
          const EventEmptyState(
            title: 'Chưa có sự kiện nào',
            message: 'Sự kiện mới sẽ xuất hiện tại đây khi được cập nhật từ nguồn chính thức.',
          ),
      ],
    );
  }

  List<String> get _careerTags {
    final tags = _events
        .expand((event) => event.relatedCareers)
        .toSet()
        .toList();
    tags.sort();
    return tags.take(12).toList();
  }

  Widget _heroCard(EventItem event) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: Stack(
      fit: StackFit.expand,
      children: [
        EventPoster(
          imageUrl: event.posterUrl,
          borderRadius: BorderRadius.zero,
          placeholderIcon: eventTypeIcon(event.type),
          fallbackColors: eventTypeColors(event.type),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x14080B16), Color(0xF0080B17)],
              stops: [0.2, 1],
            ),
          ),
        ),
        Positioned(
          left: 16,
          top: 16,
          child: _heroBadge(eventStatusLabel(event, DateTime.now())),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: IconButton(
            tooltip: _savedIds.contains(event.id) ? 'Bỏ lưu' : 'Lưu sự kiện',
            onPressed: () => _toggleSaved(event),
            icon: Icon(
              _savedIds.contains(event.id)
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _savedIds.contains(event.id)
                  ? const Color(0xFFFF8AA0)
                  : Colors.white,
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 23,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                event.organizer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                event.registrationDeadline == null
                    ? eventDateLabel(event.eventStart)
                    : 'Hạn đăng ký ${eventDateLabel(event.registrationDeadline)} · ${eventStatusLabel(event, DateTime.now())}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFFFD166),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _openEvent(event),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFBFA8FF),
                        foregroundColor: const Color(0xFF171323),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      child: const Text('Xem chi tiết'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (event.sourceUrl != null)
                    OutlinedButton(
                      onPressed: () => _openSource(event),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 11,
                        ),
                      ),
                      child: const Icon(Icons.open_in_new_rounded, size: 19),
                    ),
                  if (event.sourceUrl != null) const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _toggleSaved(event),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 11,
                      ),
                    ),
                    child: Icon(
                      _savedIds.contains(event.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 19,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _heroBadge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xB2121321),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white24),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
    ),
  );

  Widget _posterSection(
    String title,
    List<EventItem> events, {
    required EventSearchFilters filters,
  }) {
    if (events.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EventSectionTitle(
            title: title,
            onSeeAll: () => _goToExplore(filters),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 226,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final event = events[index];
                return EventPosterCard(
                  event: event,
                  onTap: () => _openEvent(event),
                  onSave: () => _toggleSaved(event),
                  saved: _savedIds.contains(event.id),
                  matchPercent: _matchPercent(event),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar({required String hint, required VoidCallback onTap}) =>
      InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xB8222030),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: _muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(hint, style: const TextStyle(color: _muted)),
              ),
            ],
          ),
        ),
      );

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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.filters.query);
  }

  @override
  void didUpdateWidget(covariant _ExploreEventsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    final result = EventCatalog.filterAndSort(
      widget.events,
      now: DateTime.now(),
      filters: widget.filters,
      matchPercent: widget.matchPercent,
    );
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
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _quickFilter('Tất cả', widget.filters.type == null),
              _quickFilter('Cuộc thi', widget.filters.type == 'Cuộc thi'),
              _quickFilter('Hackathon', widget.filters.type == 'Hackathon'),
              _quickFilter('Workshop', widget.filters.type == 'Workshop'),
              _quickFilter(
                'Hội chợ việc làm',
                widget.filters.type == 'Hội chợ việc làm',
              ),
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
          for (final event in result)
            EventListTile(
              event: event,
              saved: widget.savedIds.contains(event.id),
              matchPercent: widget.matchPercent(event),
              onTap: () => widget.onOpen(event),
              onSave: () => widget.onToggleSaved(event),
            ),
      ],
    );
  }

  Widget _quickFilter(String label, bool selected) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        if (label == 'Tất cả') {
          widget.onFiltersChanged(_copyFilters(clearType: true));
        } else {
          widget.onFiltersChanged(_copyFilters(type: label));
        }
      },
      selectedColor: const Color(0xFF574683),
      backgroundColor: const Color(0xAA242236),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFFB7B2C7),
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
