import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/job_demo_data.dart';
import '../models/character_data.dart';
import '../models/student_job.dart';
import '../services/job_match_service.dart';
import '../services/job_repository.dart';
import '../services/mascot_selection_store.dart';
import '../services/points_manager.dart';
import '../widgets/job_card.dart';
import '../widgets/job_filter_sheet.dart';
import '../widgets/job_search_header.dart';
import 'all_jobs_screen.dart';
import 'job_detail_screen.dart';

class JobScreen extends StatefulWidget {
  const JobScreen({this.initialQuery = '', this.initialCareerGoal, super.key});

  final String initialQuery;
  final String? initialCareerGoal;

  @override
  State<JobScreen> createState() => _JobScreenState();
}

class _JobScreenState extends State<JobScreen> with WidgetsBindingObserver {
  static const _background = Color(0xFF100E19);
  static const _surface = Color(0xD9142E52);
  static const _accent = Color(0xFFBFA8FF);
  static const _muted = Color(0xFFAAA5B8);
  static const _locations = [
    'TP. Hồ Chí Minh',
    'Hà Nội',
    'Đà Nẵng',
    'Toàn quốc',
    'Remote',
  ];

  final _repository = JobRepository.instance;
  final _matchService = JobMatchService();
  late final TextEditingController _searchController;
  late JobFilterState _filter;
  List<StudentJob> _jobs = const [];
  Set<String> _savedIds = {};
  CharacterData _mascot = characterData.first;
  String? _goalTitle;
  bool _loading = true;
  bool _refreshing = false;
  StudentJob? _pendingApplication;
  bool _awaitingApplication = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController = TextEditingController(text: widget.initialQuery);
    _filter = JobFilterState(query: widget.initialQuery);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingApplication) {
      _awaitingApplication = false;
      _askIfApplied();
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) setState(() => _refreshing = true);
    await PointsManager.instance.initialize();
    await _repository.initialize();
    final jobs = refresh
        ? await _repository.refresh()
        : await _repository.getJobs();
    final preferences = await SharedPreferences.getInstance();
    final mascot = (await MascotSelectionStore.instance.read(
      preferences: preferences,
    )).primary;
    if (!mounted) return;
    final goalTitle =
        widget.initialCareerGoal ?? preferences.getString('career_goal');
    setState(() {
      _jobs = jobs;
      _savedIds = _repository.savedJobIds;
      _mascot = mascot ?? CharacterSelection.selected ?? characterData.first;
      _goalTitle = goalTitle;
      _loading = false;
      _refreshing = false;
    });
  }

  List<StudentJob> get _suggestions {
    final fieldId = fieldIdForGoal(_goalTitle);
    if (fieldId == null) return const [];
    return filterAndSortJobs(
      _jobs,
      JobFilterState(
        fieldId: fieldId,
        location: _filter.location,
        sort: 'match',
      ),
      matchPercent: _matchService.matchPercent,
    ).take(6).toList();
  }

  List<StudentJob> get _newestJobs {
    final filtered = filterAndSortJobs(
      _jobs,
      _filter.copyWith(sort: 'newest'),
      matchPercent: _matchService.matchPercent,
    );
    return filtered;
  }

  Future<void> _changeLocation() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final location in _locations)
              ListTile(
                title: Text(
                  location,
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: location == _filter.location
                    ? const Icon(Icons.check_rounded, color: _accent)
                    : null,
                onTap: () => Navigator.pop(context, location),
              ),
          ],
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() => _filter = _filter.copyWith(location: selected));
  }

  Future<void> _showFilters() async {
    final selected = await JobFilterSheet.show(context, initialState: _filter);
    if (!mounted || selected == null) return;
    setState(() {
      _filter = selected;
      _searchController.text = selected.query;
    });
  }

  void _toggleType(JobType? type, {bool remote = false}) {
    final modes = {..._filter.workModes};
    final types = {..._filter.jobTypes};
    if (remote) {
      if (!modes.add(JobWorkMode.remote)) modes.remove(JobWorkMode.remote);
    } else if (type != null) {
      if (!types.add(type)) types.remove(type);
    }
    setState(() {
      _filter = _filter.copyWith(jobTypes: types, workModes: modes);
    });
  }

  Future<void> _toggleSaved(StudentJob job) async {
    try {
      final saved = await _repository.toggleSaved(job.id);
      if (!mounted) return;
      setState(() {
        if (saved) {
          _savedIds.add(job.id);
        } else {
          _savedIds.remove(job.id);
        }
      });
      _message(saved ? 'Đã lưu job' : 'Đã bỏ lưu job');
    } on Exception catch (error) {
      if (mounted) _message('Không thể lưu job: $error');
    }
  }

  Future<void> _apply(StudentJob job) async {
    if (job.applyUrl == null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _surface,
          title: const Text('Tin mẫu', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Tin mẫu, chưa có link ứng tuyển.',
            style: TextStyle(color: _muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
      return;
    }
    final uri = Uri.tryParse(job.applyUrl!);
    if (uri == null) {
      _message('Liên kết ứng tuyển không hợp lệ.');
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (opened) {
        _pendingApplication = job;
        _awaitingApplication = true;
      } else {
        _message('Chưa mở được liên kết ứng tuyển.');
      }
    } on Exception catch (error) {
      if (mounted) _message('Không thể mở liên kết: $error');
    }
  }

  Future<void> _askIfApplied() async {
    final job = _pendingApplication;
    if (job == null || !mounted) return;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: const Text(
          'Bạn đã nộp chưa?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Chưa'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đã nộp'),
          ),
        ],
      ),
    );
    _pendingApplication = null;
    if (!mounted || submitted != true) return;
    await _repository.setApplied(job.id);
    if (!mounted) return;
    _message('Đã lưu vào Đã ứng tuyển.');
  }

  void _openDetails(StudentJob job) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => JobDetailScreen(job: job)));

  void _openAll() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AllJobsScreen(
        initialState: _filter.copyWith(
          fieldId: fieldIdForGoal(_goalTitle),
          clearField: fieldIdForGoal(_goalTitle) == null,
        ),
        goalTitle: _goalTitle,
      ),
    ),
  );

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions;
    final newest = _newestJobs;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Khám phá việc làm',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : RefreshIndicator(
                onRefresh: () => _load(refresh: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 9),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _changeLocation,
                              borderRadius: BorderRadius.circular(99),
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 44,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                ),
                                decoration: BoxDecoration(
                                  color: _surface,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .08),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: _accent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _filter.location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: _muted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          MascotAvatar(emoji: _mascot.emoji),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 9),
                      child: JobSearchHeader(
                        controller: _searchController,
                        mascotEmoji: _mascot.emoji,
                        showAvatar: false,
                        onChanged: (query) => setState(
                          () => _filter = _filter.copyWith(query: query),
                        ),
                        onFilter: _showFilters,
                      ),
                    ),
                    SizedBox(
                      height: 43,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _quickChip(
                            'Tất cả',
                            selected:
                                _filter.jobTypes.isEmpty &&
                                _filter.workModes.isEmpty,
                            onTap: () => setState(
                              () => _filter = _filter.copyWith(
                                jobTypes: const {},
                                workModes: const {},
                              ),
                            ),
                          ),
                          _quickChip(
                            'Toàn thời gian',
                            selected: _filter.jobTypes.contains(
                              JobType.fulltime,
                            ),
                            onTap: () => _toggleType(JobType.fulltime),
                          ),
                          _quickChip(
                            'Thực tập',
                            selected: _filter.jobTypes.contains(
                              JobType.internship,
                            ),
                            onTap: () => _toggleType(JobType.internship),
                          ),
                          _quickChip(
                            'Part-time',
                            selected: _filter.jobTypes.contains(
                              JobType.parttime,
                            ),
                            onTap: () => _toggleType(JobType.parttime),
                          ),
                          _quickChip(
                            'Remote',
                            selected: _filter.workModes.contains(
                              JobWorkMode.remote,
                            ),
                            onTap: () => _toggleType(null, remote: true),
                          ),
                        ],
                      ),
                    ),
                    if (suggestions.isNotEmpty) ...[
                      _sectionHeader('Gợi ý cho bạn', onAll: _openAll),
                      SizedBox(
                        height: 319,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: suggestions.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 11),
                          itemBuilder: (context, index) {
                            final job = suggestions[index];
                            return SizedBox(
                              width: (MediaQuery.sizeOf(context).width - 46)
                                  .clamp(260, 360),
                              child: _SuggestedJobCard(
                                job: job,
                                matchService: _matchService,
                                saved: _savedIds.contains(job.id),
                                onTap: () => _openDetails(job),
                                onToggleSave: () => _toggleSaved(job),
                                onApply: () => _apply(job),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    _sectionHeader('Mới đăng', onAll: _openAll),
                    if (newest.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(30),
                        child: Text(
                          'Chưa có việc phù hợp, thử bỏ bớt bộ lọc',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _muted),
                        ),
                      )
                    else
                      for (final job in newest)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 11),
                          child: JobCard(
                            job: job,
                            matchService: _matchService,
                            saved: _savedIds.contains(job.id),
                            onTap: () => _openDetails(job),
                            onToggleSave: () => _toggleSaved(job),
                            onApply: () => _apply(job),
                          ),
                        ),
                    if (_jobs.any((job) => job.isDemo))
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text(
                          'Dữ liệu mẫu · độ khớp chỉ mang tính tham khảo',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _muted, fontSize: 10),
                        ),
                      ),
                    if (_refreshing)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _quickChip(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: selected ? _background : const Color(0xFFD8D3E2),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: _accent,
      backgroundColor: _surface,
      side: BorderSide(color: selected ? _accent : Colors.white12),
      visualDensity: VisualDensity.compact,
    ),
  );

  Widget _sectionHeader(String title, {required VoidCallback onAll}) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 18, 16, 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton(
          onPressed: onAll,
          child: const Text(
            'Xem tất cả',
            style: TextStyle(color: _accent, fontSize: 11),
          ),
        ),
      ],
    ),
  );
}

class _SuggestedJobCard extends StatelessWidget {
  const _SuggestedJobCard({
    required this.job,
    required this.matchService,
    required this.saved,
    required this.onTap,
    required this.onToggleSave,
    required this.onApply,
  });

  final StudentJob job;
  final JobMatchService matchService;
  final bool saved;
  final VoidCallback onTap;
  final Future<void> Function() onToggleSave;
  final Future<void> Function() onApply;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3A2E57), Color(0xFF211D2B), Color(0xFF30253F)],
      ),
      border: Border.all(color: const Color(0xFFBFA8FF).withValues(alpha: .22)),
    ),
    child: JobCard(
      job: job,
      matchService: matchService,
      saved: saved,
      onTap: onTap,
      onToggleSave: onToggleSave,
      onApply: onApply,
      featured: true,
    ),
  );
}
