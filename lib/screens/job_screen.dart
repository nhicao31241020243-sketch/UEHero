import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/career_goal.dart';
import '../models/cv_check.dart';
import '../models/student_job.dart';
import '../services/points_manager.dart';
import '../widgets/match_bar.dart';
import 'cv_check_screen.dart';

class JobScreen extends StatefulWidget {
  const JobScreen({this.initialQuery = '', this.initialCareerGoal, super.key});

  final String initialQuery;
  final String? initialCareerGoal;

  @override
  State<JobScreen> createState() => _JobScreenState();
}

class _JobScreenState extends State<JobScreen> with WidgetsBindingObserver {
  static const _background = Color(0xFF100E19);
  static const _surface = Color(0xFF211D2B);
  static const _accent = Color(0xFFBFA8FF);
  static const _cyan = Color(0xFF70D8F2);
  static const _muted = Color(0xFFAAA5B8);
  static const _skillLevelsKey = 'career_map_skills';
  static const _statusesKey = 'student_job_statuses';
  static const _matchesKey = 'student_job_match_snapshot';
  static const _awardedJobsKey = 'student_job_points_awarded';

  late final TextEditingController _searchController;
  late String _activeFilter;
  int _selectedTab = 0;
  bool _loading = true;
  bool _hasCvSkillLevels = false;
  bool _awaitingApplicationReturn = false;
  final Map<String, int> _skillLevels = {};
  final Map<String, JobApplicationStatus> _statuses = {};
  String? _improvedJobMessage;
  StudentJob? _pendingApplicationJob;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController = TextEditingController(text: widget.initialQuery);
    _activeFilter = studentJobFilters.first;
    _loadSavedData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingApplicationReturn) {
      _awaitingApplicationReturn = false;
      final job = _pendingApplicationJob;
      if (job != null && mounted) {
        _askApplicationSubmitted(job);
      }
    }
  }

  Future<void> _loadSavedData() async {
    final preferences = await SharedPreferences.getInstance();
    final savedLevels = _decodeMap(preferences.getString(_skillLevelsKey));
    final savedStatuses = _decodeMap(preferences.getString(_statusesKey));
    final savedMatches = _decodeMap(preferences.getString(_matchesKey));
    final savedApplied = preferences.getStringList(_awardedJobsKey) ?? [];
    final previous = <String, int>{
      for (final entry in savedMatches.entries)
        entry.key: (entry.value as num?)?.toInt() ?? 0,
    };
    final levels = <String, int>{
      for (final entry in savedLevels.entries)
        entry.key: (entry.value as num?)?.toInt() ?? 0,
    };
    final statuses = <String, JobApplicationStatus>{
      for (final entry in savedStatuses.entries)
        entry.key: JobApplicationStatus.fromName(entry.value?.toString()),
    };
    for (final job in studentJobs) {
      final match = _calculateMatch(job, levels);
      final old = previous[job.id];
      if (old != null && match - old >= 10) {
        _improvedJobMessage =
            'Job ${job.company} giờ khớp $match%, tăng ${match - old}%';
        break;
      }
    }
    final currentMatches = <String, int>{
      for (final job in studentJobs) job.id: _calculateMatch(job, levels),
    };
    await preferences.setString(_matchesKey, jsonEncode(currentMatches));
    if (!mounted) return;
    setState(() {
      _skillLevels
        ..clear()
        ..addAll(levels);
      _statuses
        ..clear()
        ..addAll(statuses);
      _hasCvSkillLevels = preferences.containsKey(_skillLevelsKey);
      for (final jobId in savedApplied) {
        _statuses[jobId] = JobApplicationStatus.applied;
      }
      _loading = false;
    });
  }

  Map<String, dynamic> _decodeMap(String? json) {
    if (json == null || json.isEmpty) return {};
    final decoded = jsonDecode(json);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  int _calculateMatch(StudentJob job, Map<String, int> levels) {
    if (job.requirements.isEmpty) return 0;
    final ratios = job.requirements.map((requirement) {
      final current = levels[requirement.name] ?? 0;
      return (current / requirement.level).clamp(0.0, 1.0);
    });
    return (ratios.reduce((total, ratio) => total + ratio) /
            job.requirements.length *
            100)
        .round();
  }

  int _matchFor(StudentJob job) => _calculateMatch(job, _skillLevels);

  List<StudentJob> get _filteredJobs {
    final query = _normalize(_searchController.text.trim());
    return studentJobs.where((job) {
      final textMatches =
          query.isEmpty ||
          _normalize(
            '${job.title} ${job.company} ${job.location} ${job.requirements.map((item) => item.name).join(' ')}',
          ).contains(query);
      final goalMatches =
          widget.initialCareerGoal == null ||
          _normalize(
            job.title,
          ).contains(_normalize(widget.initialCareerGoal!).split(' ').first) ||
          careerGoalByTitle(widget.initialCareerGoal)?.skills.any(
                (skill) => job.requirements.any(
                  (requirement) =>
                      _normalize(requirement.name)
                          .contains(_normalize(skill.name)) ||
                      _normalize(skill.name)
                          .contains(_normalize(requirement.name)),
                ),
              ) ==
              true;
      final categoryMatches = switch (_activeFilter) {
        'Phù hợp với tôi' => _matchFor(job) >= 40,
        'Thực tập' => job.type == 'Thực tập',
        'Part-time' => job.type == 'Part-time',
        'Fresher' => job.type == 'Fresher',
        'Job Fair' => job.category == 'Job Fair',
        _ => true,
      };
      final isSavedTab = _selectedTab == 0 || _statuses.containsKey(job.id);
      return textMatches && goalMatches && categoryMatches && isSavedTab;
    }).toList()..sort((a, b) => _matchFor(b).compareTo(_matchFor(a)));
  }

  String _normalize(String value) {
    final result = value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ả', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ạ', 'a')
        .replaceAll('ă', 'a')
        .replaceAll('â', 'a')
        .replaceAll('đ', 'd')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ơ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ư', 'u')
        .replaceAll('ý', 'y');
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> _persistStatuses() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _statusesKey,
      jsonEncode({
        for (final entry in _statuses.entries) entry.key: entry.value.name,
      }),
    );
  }

  Future<void> _saveJob(StudentJob job) async {
    final dueDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Chọn hạn nộp hồ sơ (không bắt buộc)',
      cancelText: 'Bỏ qua',
      confirmText: 'Chọn hạn',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _accent,
            surface: _surface,
          ),
        ),
        child: child!,
      ),
    );
    if (!mounted) return;
    setState(() => _statuses[job.id] = JobApplicationStatus.saved);
    await _persistStatuses();
    if (dueDate == null) {
      _showMessage('Đã lưu job. TODO: nối hạn nộp vào To-Do List.');
    } else {
      _showMessage(
        'Đã lưu job · hạn ${dueDate.day}/${dueDate.month}. TODO: nối To-Do List.',
      );
    }
  }

  Future<void> _setStatus(StudentJob job, JobApplicationStatus status) async {
    setState(() => _statuses[job.id] = status);
    await _persistStatuses();
    if (status == JobApplicationStatus.interview) {
      _showMessage('Mascot gợi ý luyện hỏi đáp trước buổi phỏng vấn 🚀');
    }
  }

  Future<void> _launchApplication(StudentJob job) async {
    _pendingApplicationJob = job;
    final uri = Uri.tryParse(job.url);
    if (uri == null) {
      _pendingApplicationJob = null;
      _showMessage('Không mở được liên kết ứng tuyển của job này.');
      return;
    }
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _pendingApplicationJob = null;
        _showMessage('Không mở được liên kết ứng tuyển của job này.');
        return;
      }
      _awaitingApplicationReturn = true;
    } on PlatformException catch (error) {
      _awaitingApplicationReturn = false;
      _pendingApplicationJob = null;
      _showMessage('Không thể mở trang ứng tuyển: ${error.message}');
    }
  }

  Future<void> _askApplicationSubmitted(StudentJob job) async {
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: const Text(
          'Bạn đã nộp chưa?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Bạn đã gửi hồ sơ cho ${job.title} tại ${job.company} chưa?',
          style: const TextStyle(color: _muted),
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
    _pendingApplicationJob = null;
    if (submitted != true || !mounted) return;
    await _setStatus(job, JobApplicationStatus.applied);
    final preferences = await SharedPreferences.getInstance();
    final rewarded =
        preferences.getStringList(_awardedJobsKey)?.toSet() ?? <String>{};
    if (rewarded.add(job.id)) {
      await preferences.setStringList(_awardedJobsKey, rewarded.toList());
      PointsManager.instance.addJobApplicationPoints(10);
      _showMessage('Đã cập nhật trạng thái · +10 điểm UEHero!');
    }
    // TODO(career-map): mark the “Ứng tuyển thực tập” milestone completed.
  }

  Future<void> _showFilterPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final filter in studentJobFilters)
              ListTile(
                title: Text(
                  filter,
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: filter == _activeFilter
                    ? const Icon(Icons.check_rounded, color: _cyan)
                    : null,
                onTap: () => Navigator.pop(context, filter),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _activeFilter = selected);
    }
  }

  void _openJobDetails(StudentJob job) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => _JobDetailSheet(
        job: job,
        match: _matchFor(job),
        levels: _skillLevels,
        saved: _statuses.containsKey(job.id),
        onSave: () => _saveJob(job),
        onApply: () => _launchApplication(job),
        onOpenCvCheck: () {
          final navigator = Navigator.of(context);
          navigator.pop();
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) => CvCheckScreen(job: _asCvJob(job)),
            ),
          );
        },
        onOpenCareerMap: () => _showMessage(
          'Tính năng Lộ trình sắp ra mắt. TODO(career-map): connect job milestones.',
        ),
      ),
    );
  }

  CvCheckJob _asCvJob(StudentJob job) => CvCheckJob(
    title: job.title,
    company: job.company,
    requirements: job.requirements.map((item) => item.name).toList(),
  );

  void _openInterviewPractice(StudentJob job) {
    _showMessage('TODO: Nối chatbot RAG/trợ lý mascot cho phần luyện hỏi đáp.');
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _InterviewPracticeScreen(job: job),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        title: const Text(
          'Xem job sinh viên',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Việc của tôi',
            onPressed: () => setState(() => _selectedTab = 1),
            icon: const Icon(Icons.bookmark_outline_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : Column(
              children: [
                _buildSearchBar(),
                _buildFilterRow(),
                Expanded(
                  child: _selectedTab == 1 ? _buildMyJobs() : _buildJobList(),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 5, top: 2),
                    child: Text(
                      'Độ khớp mang tính tham khảo · dữ liệu mẫu · TODO: API tuyển dụng',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted.withValues(alpha: 0.8),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search_rounded, color: _muted, size: 21),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Tìm vị trí, kỹ năng, công ty...',
                  hintStyle: TextStyle(color: _muted, fontSize: 12),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Bộ lọc',
              onPressed: _showFilterPicker,
              icon: const Icon(Icons.tune_rounded, color: _accent, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: studentJobFilters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final filter = studentJobFilters[index];
          final selected = filter == _activeFilter;
          return ChoiceChip(
            label: Text(filter),
            selected: selected,
            onSelected: (_) => setState(() => _activeFilter = filter),
            labelStyle: TextStyle(
              color: selected ? _background : const Color(0xFFD8D3E2),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            selectedColor: _accent,
            backgroundColor: _surface,
            side: BorderSide(
              color: selected ? _accent : Colors.white.withValues(alpha: 0.1),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  Widget _buildJobList() {
    final jobs = _filteredJobs;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 16),
      children: [
        if (!_hasCvSkillLevels) ...[
          _CvReminder(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CvCheckScreen()),
              );
            },
          ),
          const SizedBox(height: 11),
        ],
        if (_improvedJobMessage != null && _selectedTab == 0) ...[
          _ImprovementBanner(message: _improvedJobMessage!),
          const SizedBox(height: 10),
        ],
        for (final job in jobs) ...[
          _JobCard(
            job: job,
            match: _matchFor(job),
            onTap: () => _openJobDetails(job),
          ),
          const SizedBox(height: 11),
        ],
        if (jobs.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 45),
            child: Text(
              _selectedTab == 1
                  ? 'Chưa có job nào trong Việc của tôi.'
                  : 'Chưa tìm thấy job phù hợp.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted),
            ),
          ),
      ],
    );
  }

  Widget _buildMyJobs() {
    final jobs = studentJobs
        .where((job) => _statuses.containsKey(job.id))
        .toList(growable: false);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      children: [
        for (final job in jobs) ...[
          _MyJobCard(
            job: job,
            status: _statuses[job.id] ?? JobApplicationStatus.saved,
            onStatusChanged: (status) => _setStatus(job, status),
            onTap: () => _openJobDetails(job),
            onPractice: () => _openInterviewPractice(job),
          ),
          const SizedBox(height: 10),
        ],
        if (jobs.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Text(
              'Lưu một job để theo dõi tiến trình tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Container(
        height: 62,
        decoration: const BoxDecoration(
          color: Color(0xFF191622),
          border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
        ),
        child: Row(
          children: [
            _JobNavButton(
              icon: Icons.search_rounded,
              label: 'Khám phá',
              selected: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
            ),
            _JobNavButton(
              icon: Icons.bookmark_outline_rounded,
              label: 'Việc của tôi',
              selected: _selectedTab == 1,
              onTap: () => setState(() => _selectedTab = 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.match, required this.onTap});

  final StudentJob job;
  final int match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _JobScreenState._surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CompanyLogo(letter: job.logoLetter, size: 46),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          job.company,
                          style: const TextStyle(
                            color: _JobScreenState._muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          job.salary,
                          style: const TextStyle(
                            color: _JobScreenState._cyan,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${job.postedHoursAgo} giờ trước',
                    style: const TextStyle(
                      color: _JobScreenState._muted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 5,
                children: [
                  _SmallTag(
                    icon: Icons.location_on_outlined,
                    text: job.location,
                  ),
                  _SmallTag(icon: Icons.laptop_mac_rounded, text: job.workMode),
                  _SmallTag(icon: Icons.schedule_rounded, text: job.type),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Độ khớp',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const Spacer(),
                  Text(
                    '$match%',
                    style: TextStyle(
                      color: match >= 70
                          ? const Color(0xFF82D977)
                          : _JobScreenState._accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              MatchBar(percent: match, height: 7),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobDetailSheet extends StatefulWidget {
  const _JobDetailSheet({
    required this.job,
    required this.match,
    required this.levels,
    required this.saved,
    required this.onSave,
    required this.onApply,
    required this.onOpenCvCheck,
    required this.onOpenCareerMap,
  });

  final StudentJob job;
  final int match;
  final Map<String, int> levels;
  final bool saved;
  final Future<void> Function() onSave;
  final Future<void> Function() onApply;
  final VoidCallback onOpenCvCheck;
  final VoidCallback onOpenCareerMap;

  @override
  State<_JobDetailSheet> createState() => _JobDetailSheetState();
}

class _JobDetailSheetState extends State<_JobDetailSheet> {
  static const _cyan = Color(0xFF70D8F2);
  static const _muted = Color(0xFFAAA5B8);

  int get _missingCount => widget.job.requirements
      .where((item) => (widget.levels[item.name] ?? 0) < item.level)
      .length;

  @override
  Widget build(BuildContext context) {
    final actions = _actionsForMatch(widget.match);
    final missingSkills = widget.job.requirements
        .where((item) => (widget.levels[item.name] ?? 0) < item.level)
        .map((item) => item.name)
        .toList(growable: false);
    final missingLabel = missingSkills.take(2).join(', ');
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.94,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _muted.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                Row(
                  children: [
                    _CompanyLogo(letter: widget.job.logoLetter, size: 56),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.job.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.job.company} · ${widget.job.location}',
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.job.salary,
                            style: const TextStyle(
                              color: _cyan,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: _muted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _SmallTag(
                      icon: Icons.laptop_mac_rounded,
                      text: widget.job.workMode,
                    ),
                    _SmallTag(
                      icon: Icons.schedule_rounded,
                      text: widget.job.type,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _DetailCard(
                  title: 'Độ khớp',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'AI Match',
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                          const Spacer(),
                          Text(
                            '${widget.match}%',
                            style: const TextStyle(
                              color: _cyan,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      MatchBar(percent: widget.match, height: 11),
                      const Text(
                        'Độ khớp mang tính tham khảo.',
                        style: TextStyle(color: _muted, fontSize: 10),
                      ),
                      if (widget.match < 40) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Còn thiếu $missingLabel${missingSkills.length > 2 ? ' và ${missingSkills.length - 2} kỹ năng khác' : ''}, khoảng ${_missingCount.clamp(1, 5)} mốc nữa',
                          style: const TextStyle(
                            color: Color(0xFFFFD166),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (widget.match < 40) ...[
                        const SizedBox(height: 2),
                        TextButton(
                          onPressed: widget.onOpenCvCheck,
                          child: const Text('So CV với job này'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                _DetailCard(
                  title: 'Phân tích độ khớp',
                  child: Column(
                    children: [
                      for (final requirement in widget.job.requirements)
                        _SkillRequirementRow(
                          requirement: requirement,
                          current: widget.levels[requirement.name] ?? 0,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                _DetailCard(
                  title: 'Yêu cầu công việc',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final requirement in widget.job.requirements)
                        _BulletText(requirement.name),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                _DetailCard(
                  title: 'Trách nhiệm',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final item in widget.job.responsibilities)
                        _BulletText(item),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _DetailActionBar(
            saved: widget.saved,
            primaryLabel: actions.primaryLabel,
            secondaryLabel: actions.secondaryLabel,
            onSave: widget.onSave,
            onPrimary: actions.primaryIsApply
                ? widget.onApply
                : actions.primaryIsCv
                ? widget.onOpenCvCheck
                : widget.onOpenCareerMap,
            onSecondary: actions.secondaryIsApply
                ? widget.onApply
                : actions.secondaryIsCv
                ? widget.onOpenCvCheck
                : widget.onOpenCareerMap,
          ),
        ],
      ),
    );
  }

  _JobActionConfig _actionsForMatch(int match) {
    if (match < 40) {
      return const _JobActionConfig(
        primaryLabel: 'Lộ trình tới job này',
        secondaryLabel: 'Ứng tuyển',
        primaryIsApply: false,
        primaryIsCv: false,
        secondaryIsApply: true,
        secondaryIsCv: false,
      );
    }
    if (match <= 70) {
      return const _JobActionConfig(
        primaryLabel: 'So CV với job này',
        secondaryLabel: 'Lộ trình',
        primaryIsApply: false,
        primaryIsCv: true,
        secondaryIsApply: false,
        secondaryIsCv: false,
      );
    }
    return const _JobActionConfig(
      primaryLabel: 'Ứng tuyển',
      secondaryLabel: 'So CV',
      primaryIsApply: true,
      primaryIsCv: false,
      secondaryIsApply: false,
      secondaryIsCv: true,
    );
  }
}

class _JobActionConfig {
  const _JobActionConfig({
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.primaryIsApply,
    required this.primaryIsCv,
    required this.secondaryIsApply,
    required this.secondaryIsCv,
  });

  final String primaryLabel;
  final String secondaryLabel;
  final bool primaryIsApply;
  final bool primaryIsCv;
  final bool secondaryIsApply;
  final bool secondaryIsCv;
}

class _DetailActionBar extends StatelessWidget {
  const _DetailActionBar({
    required this.saved,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onSave,
    required this.onPrimary,
    required this.onSecondary,
  });

  final bool saved;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onSave;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF191622),
        border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            SizedBox(
              width: 45,
              height: 45,
              child: OutlinedButton(
                onPressed: onSave,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: saved
                      ? _JobScreenState._cyan
                      : _JobScreenState._accent,
                  side: BorderSide(
                    color: saved
                        ? _JobScreenState._cyan
                        : _JobScreenState._accent.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Icon(
                  saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _SecondaryActionButton(
                label: secondaryLabel,
                onPressed: onSecondary,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 45,
                child: FilledButton(
                  onPressed: onPrimary,
                  style: FilledButton.styleFrom(
                    backgroundColor: _JobScreenState._accent,
                    foregroundColor: _JobScreenState._background,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Text(
                    primaryLabel,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _JobScreenState._accent,
          side: BorderSide(
            color: _JobScreenState._accent.withValues(alpha: 0.65),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _MyJobCard extends StatelessWidget {
  const _MyJobCard({
    required this.job,
    required this.status,
    required this.onStatusChanged,
    required this.onTap,
    required this.onPractice,
  });

  final StudentJob job;
  final JobApplicationStatus status;
  final ValueChanged<JobApplicationStatus> onStatusChanged;
  final VoidCallback onTap;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      JobApplicationStatus.saved => _JobScreenState._accent,
      JobApplicationStatus.applied => _JobScreenState._cyan,
      JobApplicationStatus.interview => const Color(0xFFFFD166),
      JobApplicationStatus.result => const Color(0xFF82D977),
    };
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _JobScreenState._surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            child: Row(
              children: [
                _CompanyLogo(letter: job.logoLetter, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${job.title}\n${job.company}',
                    style: const TextStyle(
                      color: Colors.white,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    status.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          DropdownButtonFormField<JobApplicationStatus>(
            initialValue: status,
            dropdownColor: _JobScreenState._surface,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: _JobScreenState._background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            items: [
              for (final value in JobApplicationStatus.values)
                DropdownMenuItem(value: value, child: Text(value.label)),
            ],
            onChanged: (value) {
              if (value != null) onStatusChanged(value);
            },
          ),
          if (status == JobApplicationStatus.interview) ...[
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onPractice,
                icon: const Icon(Icons.record_voice_over_rounded, size: 18),
                label: const Text('Luyện phỏng vấn'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InterviewPracticeScreen extends StatelessWidget {
  const _InterviewPracticeScreen({required this.job});

  final StudentJob job;

  static const _criteria = [
    ('Mô tả kinh nghiệm', 68),
    ('Tư duy giải quyết vấn đề', 74),
    ('Giao tiếp rõ ràng', 82),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _JobScreenState._background,
      appBar: AppBar(
        backgroundColor: _JobScreenState._background,
        foregroundColor: Colors.white,
        title: const Text('Luyện phỏng vấn'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            job.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bản luyện tập mẫu · TODO: nối chatbot RAG/trợ lý mascot.',
            style: TextStyle(color: _JobScreenState._muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          for (final criterion in _criteria) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    criterion.$1,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Text(
                  '${criterion.$2}%',
                  style: const TextStyle(
                    color: _JobScreenState._cyan,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            MatchBar(percent: criterion.$2, height: 9),
            const SizedBox(height: 12),
          ],
          _DetailCard(
            title: 'Điểm mạnh',
            child: const _BulletList(
              items: [
                'Nêu được kinh nghiệm liên quan đến vị trí.',
                'Câu trả lời có cấu trúc và dễ theo dõi.',
                'Thể hiện tinh thần chủ động.',
              ],
            ),
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Cần cải thiện',
            child: const _BulletList(
              items: [
                'Bổ sung số liệu để làm rõ kết quả.',
                'Nêu rõ vai trò cá nhân trong dự án nhóm.',
                'Chuẩn bị ví dụ theo phương pháp STAR.',
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillRequirementRow extends StatelessWidget {
  const _SkillRequirementRow({
    required this.requirement,
    required this.current,
  });

  final JobSkillRequirement requirement;
  final int current;

  @override
  Widget build(BuildContext context) {
    final enough = current >= requirement.level;
    final color = enough
        ? const Color(0xFF82D977)
        : current > 0
        ? const Color(0xFFFFD166)
        : const Color(0xFF777181);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            enough
                ? Icons.check_circle_rounded
                : current > 0
                ? Icons.warning_amber_rounded
                : Icons.radio_button_unchecked_rounded,
            color: color,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              requirement.name,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Text(
            '$current/${requirement.level}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _JobScreenState._surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final item in items) _BulletText(item)],
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(color: _JobScreenState._cyan)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFD8D3E2),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  const _CompanyLogo({required this.letter, required this.size});

  final String letter;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF423369), Color(0xFF21556C)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.43,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _JobScreenState._muted),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(color: _JobScreenState._muted, fontSize: 10),
        ),
      ],
    );
  }
}

class _CvReminder extends StatelessWidget {
  const _CvReminder({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF30284A),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: _JobScreenState._cyan),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kiểm tra CV để khớp job chính xác hơn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: _JobScreenState._accent,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImprovementBanner extends StatelessWidget {
  const _ImprovementBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF183D3D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _JobScreenState._cyan.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: _JobScreenState._cyan,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _JobNavButton extends StatelessWidget {
  const _JobNavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _JobScreenState._accent : _JobScreenState._muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 21),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
