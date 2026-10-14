import 'package:flutter/material.dart';

import '../data/job_demo_data.dart';
import '../models/student_job.dart';
import '../services/job_match_service.dart';

class JobCard extends StatelessWidget {
  const JobCard({
    required this.job,
    required this.matchService,
    required this.saved,
    required this.onTap,
    required this.onToggleSave,
    required this.onApply,
    this.featured = false,
    super.key,
  });

  final StudentJob job;
  final JobMatchService matchService;
  final bool saved;
  final VoidCallback onTap;
  final Future<void> Function() onToggleSave;
  final Future<void> Function() onApply;
  final bool featured;

  static const _surface = Color(0xFF211D2B);
  static const _muted = Color(0xFFAAA5B8);

  @override
  Widget build(BuildContext context) {
    final percent = matchService.matchPercent(job);
    final missing = matchService.missingSkills(job);
    final color = _matchColor(percent);
    return Material(
      color: featured ? Colors.transparent : _surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: featured
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: .08),
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x18000000), blurRadius: 18, offset: Offset(0, 7)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CompanyAvatar(job: job, size: 42),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.company,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          job.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: saved ? 'Bỏ lưu job' : 'Lưu job',
                    onPressed: () => onToggleSave(),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    icon: Icon(
                      saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: saved ? const Color(0xFFFFC36E) : _muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                job.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      job.salaryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF70D8F2),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        _Tag(label: job.workMode.label),
                        _MoreAttributes(job: job),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (percent == null)
                const Text(
                  'Chưa đủ dữ liệu để tính độ khớp',
                  style: TextStyle(color: _muted, fontSize: 11),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: percent / 100,
                          minHeight: 5,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      '${matchService.matchLabel(percent)} · ${percent.round()}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (missing.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Thiếu: ${missing.join(', ')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 10),
                  ),
                ],
              ],
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _postedAgo(job.postedAt),
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => onApply(),
                    icon: const Icon(Icons.north_east_rounded, size: 15),
                    label: const Text('Ứng tuyển'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF6C5599),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _matchColor(double? percent) {
    if (percent == null) return _muted;
    if (percent >= 70) return const Color(0xFF73D6A0);
    if (percent >= 40) return const Color(0xFFFFCF68);
    return const Color(0xFFFF9B63);
  }

  static String _postedAgo(DateTime postedAt) {
    final elapsed = DateTime.now().difference(postedAt);
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes.clamp(1, 59)} phút trước';
    if (elapsed.inHours < 24) return '${elapsed.inHours} giờ trước';
    return '${elapsed.inDays} ngày trước';
  }
}

class _MoreAttributes extends StatelessWidget {
  const _MoreAttributes({required this.job});

  final StudentJob job;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(99),
    onTap: () => showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF211D2B),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thông tin công việc', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 14),
              Text(job.jobType.label, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Text(jobFieldLabel(job.fieldId), style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    ),
    child: const _Tag(label: '+2'),
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white.withValues(alpha: .09)),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Color(0xFFD8D3E2), fontSize: 9, fontWeight: FontWeight.w700),
    ),
  );
}

class _CompanyAvatar extends StatelessWidget {
  const _CompanyAvatar({required this.job, required this.size});

  final StudentJob job;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hue = job.id.hashCode.abs() % 360;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: HSLColor.fromAHSL(1, hue.toDouble(), .42, .31).toColor(),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        job.logoLetter,
        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
      ),
    );
  }
}
