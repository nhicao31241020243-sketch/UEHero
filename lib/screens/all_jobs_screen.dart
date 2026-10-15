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
import 'job_detail_screen.dart';

class AllJobsScreen extends StatefulWidget {
  const AllJobsScreen({required this.initialState, this.goalTitle, super.key});

  final JobFilterState initialState;
  final String? goalTitle;

  @override
  State<AllJobsScreen> createState() => _AllJobsScreenState();
}

class _AllJobsScreenState extends State<AllJobsScreen>
    with WidgetsBindingObserver {
  static const _background = Color(0xFF100E19);
  static const _surface = Color(0xD9142E52);
  static const _accent = Color(0xFFBFA8FF);
  static const _muted = Color(0xFFAAA5B8);

  final _repository = JobRepository.instance;
  final _matchService = JobMatchService();
  late final TextEditingController _searchController;
  late JobFilterState _filter;
  List<StudentJob> _jobs = const [];
  Set<String> _savedIds = {};
  Set<String> _appliedIds = {};
  CharacterData _mascot = characterData.first;
  bool _loading = true;
  bool _refreshing = false;
  String? _selectedList;
  StudentJob? _pendingApplication;
  bool _awaitingApplication = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _filter = widget.initialState;
    _searchController = TextEditingController(text: _filter.query);
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
    if (refresh) {
      setState(() => _refreshing = true);
    }
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
    setState(() {
      _jobs = jobs;
      _savedIds = _repository.savedJobIds;
      _appliedIds = _repository.appliedJobIds;
      _mascot = mascot ?? CharacterSelection.selected ?? characterData.first;
      _loading = false;
      _refreshing = false;
    });
  }

  List<StudentJob> get _visibleJobs => filterAndSortJobs(
    _jobs,
    _filter,
    matchPercent: _matchService.matchPercent,
    includeJob: (job) {
      if (_selectedList == 'saved') return _savedIds.contains(job.id);
      if (_selectedList == 'applied') return _appliedIds.contains(job.id);
      return true;
    },
  );

  Future<void> _showFilters() async {
    final selected = await JobFilterSheet.show(context, initialState: _filter);
    if (!mounted || selected == null) return;
    setState(() {
      _filter = selected;
      _searchController.text = selected.query;
    });
  }

  void _selectField(String? fieldId) => setState(
    () => _filter = _filter.copyWith(
      fieldId: fieldId,
      clearField: fieldId == null,
    ),
  );

  void _clearFilters() => setState(() {
    _searchController.clear();
    _filter = _filter.copyWith(
      query: '',
      jobTypes: const {},
      workModes: const {},
      clearField: true,
      location: 'Toàn quốc',
    );
  });

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
    setState(() => _appliedIds = _repository.appliedJobIds);
    _message('Đã lưu vào Đã ứng tuyển.');
  }

  void _openDetails(StudentJob job) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => JobDetailScreen(job: job)));

  Future<void> _setSavedList(String? list) async {
    setState(() => _selectedList = _selectedList == list ? null : list);
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final jobs = _visibleJobs;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Tất cả việc',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(refresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 14),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 5, 16, 9),
                child: JobSearchHeader(
                  controller: _searchController,
                  mascotEmoji: _mascot.emoji,
                  onChanged: (query) =>
                      setState(() => _filter = _filter.copyWith(query: query)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 7),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _showFilters,
                      icon: const Icon(Icons.tune_rounded, size: 17),
                      label: Text(
                        _filter.activeFilterCount == 0
                            ? 'Bộ lọc'
                            : 'Bộ lọc (${_filter.activeFilterCount})',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        minimumSize: const Size(44, 44),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: .13),
                        ),
                      ),
                    ),
                    const Spacer(),
                    DropdownButton<String>(
                      value: _filter.sort,
                      dropdownColor: _surface,
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      items: const [
                        DropdownMenuItem(
                          value: 'newest',
                          child: Text('Mới nhất'),
                        ),
                        DropdownMenuItem(
                          value: 'match',
                          child: Text('Độ khớp'),
                        ),
                        DropdownMenuItem(
                          value: 'salary',
                          child: Text('Lương cao'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(
                            () => _filter = _filter.copyWith(sort: value),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _fieldChip(null, 'Tất cả ngành'),
                    for (final field in jobFields)
                      _fieldChip(field.id, field.label),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 9, 18, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${jobs.length} việc phù hợp',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed:
                          _filter.activeFilterCount == 0 &&
                              _filter.query.isEmpty
                          ? null
                          : _clearFilters,
                      child: Text(
                        _filter.activeFilterCount == 0 && _filter.query.isEmpty
                            ? 'Xem tất cả'
                            : 'Xóa lọc',
                        style: const TextStyle(color: _accent, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              if (_loading)
                const _JobSkeletonList()
              else if (jobs.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        color: _muted,
                        size: 48,
                      ),
                      const SizedBox(height: 13),
                      const Text(
                        'Chưa có việc phù hợp, thử bỏ bớt bộ lọc',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted),
                      ),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Xóa lọc'),
                      ),
                    ],
                  ),
                )
              else ...[
                for (final job in jobs)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 5, 16, 6),
                    child: JobCard(
                      job: job,
                      matchService: _matchService,
                      saved: _savedIds.contains(job.id),
                      onTap: () => _openDetails(job),
                      onToggleSave: () => _toggleSaved(job),
                      onApply: () => _apply(job),
                    ),
                  ),
              ],
              if (_refreshing)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_jobs.any((job) => job.isDemo))
                const Padding(
                  padding: EdgeInsets.only(bottom: 5, top: 3),
                  child: Text(
                    'Dữ liệu mẫu · độ khớp chỉ mang tính tham khảo',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 8),
          child: SizedBox(
            height: 54,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                children: [
                  _statusPill(
                    context,
                    'saved',
                    'Đã lưu',
                    Icons.bookmark_rounded,
                  ),
                  _statusPill(
                    context,
                    'applied',
                    'Đã ứng tuyển',
                    Icons.check_circle_outline_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldChip(String? fieldId, String label) {
    final selected = _filter.fieldId == fieldId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => _selectField(fieldId),
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
  }

  Widget _statusPill(
    BuildContext context,
    String key,
    String label,
    IconData icon,
  ) {
    final selected = _selectedList == key;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () => _setSavedList(key),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF4EEFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: const Color(0xFF302744)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF302744),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobSkeletonList extends StatelessWidget {
  const _JobSkeletonList();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        for (var index = 0; index < 3; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          Container(
            height: 210,
            decoration: BoxDecoration(
              color: const Color(0xFF211D2B),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ],
      ],
    ),
  );
}
