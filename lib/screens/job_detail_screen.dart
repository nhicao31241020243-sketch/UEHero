import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/cv_check.dart';
import '../models/student_job.dart';
import '../services/job_match_service.dart';
import '../services/job_repository.dart';
import '../services/points_manager.dart';
import 'cv_check_screen.dart';
import 'interview/interview_home_screen.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({required this.job, super.key});

  final StudentJob job;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen>
    with WidgetsBindingObserver {
  static const _background = Color(0xFF100E19);
  static const _surface = Color(0xD9142E52);
  static const _muted = Color(0xFFAAA5B8);
  static const _accent = Color(0xFFBFA8FF);

  final _repository = JobRepository.instance;
  final _matchService = JobMatchService();
  bool _loading = true;
  bool _saved = false;
  bool _awaitingApplication = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingApplication) {
      _awaitingApplication = false;
      _askIfApplied();
    }
  }

  Future<void> _load() async {
    await PointsManager.instance.initialize();
    final status = await _repository.statusFor(widget.job.id);
    if (!mounted) return;
    setState(() {
      _saved = status == JobApplicationStatus.saved;
      _loading = false;
    });
  }

  Future<void> _toggleSaved() async {
    try {
      final saved = await _repository.toggleSaved(widget.job.id);
      if (!mounted) return;
      setState(() => _saved = saved);
      _message(saved ? 'Đã lưu job · XP thưởng mỗi job một lần' : 'Đã bỏ lưu job');
    } on Exception catch (error) {
      if (mounted) _message('Không thể lưu job: $error');
    }
  }

  Future<void> _apply() async {
    final url = widget.job.applyUrl;
    if (url == null) {
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
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _message('Liên kết ứng tuyển không hợp lệ.');
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (opened) {
        _awaitingApplication = true;
      } else {
        _message('Chưa mở được liên kết ứng tuyển.');
      }
    } on Exception catch (error) {
      if (mounted) _message('Không thể mở liên kết: $error');
    }
  }

  Future<void> _askIfApplied() async {
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Bạn đã nộp chưa?', style: TextStyle(color: Colors.white)),
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
    if (!mounted || submitted != true) return;
    await _repository.setApplied(widget.job.id);
    if (mounted) _message('Đã lưu vào Đã ứng tuyển.');
  }

  void _openCvCheck() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CvCheckScreen(
          job: CvCheckJob(
            title: widget.job.title,
            company: widget.job.company,
            requirements: widget.job.requiredSkills
                .map((skill) => skill.label)
                .toList(),
          ),
        ),
      ),
    );
  }

  void _openInterview() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InterviewHomeScreen(jobTitle: widget.job.title),
      ),
    );
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final job = widget.job;
    final percent = _matchService.matchPercent(job);
    final missing = _matchService.missingSkills(job);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Chi tiết công việc'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            _DetailPanel(
              child: Row(
                children: [
                  _CompanyAvatar(job: job),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.company, style: const TextStyle(color: _muted, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          job.title,
                          style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 5),
                        Text(job.salaryLabel, style: const TextStyle(color: Color(0xFF70D8F2), fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 11),
            _DetailPanel(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoPill(job.location),
                  _InfoPill(job.workMode.label),
                  _InfoPill(job.jobType.label),
                  _InfoPill(_postedAgo(job.postedAt)),
                ],
              ),
            ),
            const SizedBox(height: 11),
            _DetailPanel(
              title: 'Độ khớp với kỹ năng',
              child: percent == null
                  ? const Text('Chưa đủ dữ liệu để tính độ khớp', style: TextStyle(color: _muted))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _matchService.matchLabel(percent)!,
                                style: TextStyle(color: _matchColor(percent), fontWeight: FontWeight.w800),
                              ),
                            ),
                            Text('${percent.round()}%', style: TextStyle(color: _matchColor(percent), fontWeight: FontWeight.w900, fontSize: 20)),
                          ],
                        ),
                        const SizedBox(height: 9),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: percent / 100,
                            minHeight: 7,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation(_matchColor(percent)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          missing.isEmpty ? 'Đáp ứng đủ kỹ năng trong dữ liệu mẫu.' : 'Nên bổ sung: ${missing.join(', ')}',
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 11),
            _DetailPanel(
              title: 'Mô tả công việc',
              child: Text(job.description, style: const TextStyle(color: Color(0xFFD8D3E2), height: 1.55)),
            ),
            const SizedBox(height: 11),
            _DetailPanel(
              title: 'Kỹ năng yêu cầu',
              child: Column(
                children: [
                  for (final required in job.requiredSkills)
                    _SkillRow(
                      requirement: required,
                      currentLevel: _matchService.skillLevel(required),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _apply,
              icon: const Icon(Icons.north_east_rounded),
              label: const Text('Ứng tuyển'),
              style: _primaryButton(),
            ),
            const SizedBox(height: 9),
            OutlinedButton.icon(
              onPressed: _openCvCheck,
              icon: const Icon(Icons.description_outlined),
              label: const Text('Sửa CV cho job này'),
              style: _secondaryButton(),
            ),
            const SizedBox(height: 9),
            OutlinedButton.icon(
              onPressed: _openInterview,
              icon: const Icon(Icons.record_voice_over_outlined),
              label: const Text('Luyện phỏng vấn job này'),
              style: _secondaryButton(),
            ),
            const SizedBox(height: 9),
            OutlinedButton.icon(
              onPressed: _toggleSaved,
              icon: Icon(_saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
              label: Text(_saved ? 'Đã lưu job' : 'Lưu job'),
              style: _secondaryButton(),
            ),
            if (job.isDemo) ...[
              const SizedBox(height: 16),
              const Text(
                'Dữ liệu mẫu · độ khớp chỉ mang tính tham khảo',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ButtonStyle _primaryButton() => FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(50),
    backgroundColor: _accent,
    foregroundColor: _background,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  ButtonStyle _secondaryButton() => OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(48),
    foregroundColor: Colors.white,
    side: BorderSide(color: Colors.white.withValues(alpha: .13)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  static Color _matchColor(double percent) {
    if (percent >= 70) return const Color(0xFF73D6A0);
    if (percent >= 40) return const Color(0xFFFFCF68);
    return const Color(0xFFFF9B63);
  }

  static String _postedAgo(DateTime postedAt) {
    final age = DateTime.now().difference(postedAt);
    if (age.inHours < 1) return 'Vừa đăng';
    if (age.inHours < 24) return '${age.inHours} giờ trước';
    return '${age.inDays} ngày trước';
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF211D2B),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 11),
        ],
        child,
      ],
    ),
  );
}

class _CompanyAvatar extends StatelessWidget {
  const _CompanyAvatar({required this.job});

  final StudentJob job;

  @override
  Widget build(BuildContext context) => Container(
    width: 54,
    height: 54,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: HSLColor.fromAHSL(1, (job.id.hashCode.abs() % 360).toDouble(), .42, .31).toColor(),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(job.logoLetter, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
  );
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .07), borderRadius: BorderRadius.circular(99)),
    child: Text(label, style: const TextStyle(color: Color(0xFFD8D3E2), fontSize: 11)),
  );
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.requirement, required this.currentLevel});

  final JobSkillRequirement requirement;
  final int currentLevel;

  @override
  Widget build(BuildContext context) {
    final achieved = currentLevel >= requirement.requiredLevel;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(achieved ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: achieved ? const Color(0xFF73D6A0) : const Color(0xFFAAA5B8), size: 19),
          const SizedBox(width: 9),
          Expanded(child: Text(requirement.label, style: const TextStyle(color: Colors.white, fontSize: 12))),
          Text(
            '$currentLevel/${requirement.requiredLevel}',
            style: TextStyle(color: achieved ? const Color(0xFF73D6A0) : const Color(0xFFFFCF68), fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
