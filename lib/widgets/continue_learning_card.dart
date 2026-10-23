import 'package:flutter/material.dart';

class ContinueLearningCard extends StatelessWidget {
  const ContinueLearningCard({
    required this.dueCount,
    required this.streak,
    required this.xpToday,
    required this.xpGoal,
    required this.goalName,
    required this.goalProgress,
    required this.onContinue,
    required this.onJourney,
    super.key,
  });

  final int dueCount;
  final int streak;
  final int xpToday;
  final int xpGoal;
  final String goalName;
  final double goalProgress;
  final VoidCallback onContinue;
  final VoidCallback onJourney;

  static const _text = Color(0xFFFBF8FF);
  static const _muted = Color(0xFFAAA5B8);
  static const _teal = Color(0xFF72E0C4);
  static const _lime = Color(0xFFC4EC78);
  static const _ink = Color(0xFF100E19);

  @override
  Widget build(BuildContext context) {
    final progress = goalProgress.clamp(0.0, 1.0).toDouble();
    final percent = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A2F7A), Color(0xFF1B4A52)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Continue learning',
                      style: TextStyle(
                        color: _teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hôm nay cần ôn $dueCount thẻ',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _lime.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: _lime,
                      size: 18,
                    ),
                    Text(
                      '$streak ngày',
                      style: const TextStyle(
                        color: _lime,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    valueColor: const AlwaysStoppedAnimation(_lime),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: _lime,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Hành trình $goalName · XP hôm nay $xpToday/$xpGoal',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onContinue,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Ôn ngay'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: _ink,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onJourney,
                icon: const Icon(Icons.route_rounded, size: 16),
                label: const Text('Hành trình'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _text,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
