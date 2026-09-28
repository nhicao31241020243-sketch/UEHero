import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class GpaHeroRing extends StatelessWidget {
  final double currentGpa;
  final double targetGpa;
  final double maxGpa;
  final bool enableGlow;

  const GpaHeroRing({
    super.key,
    required this.currentGpa,
    required this.targetGpa,
    this.maxGpa = 4.0,
    this.enableGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 250;

    final targetRatio = (targetGpa / maxGpa).clamp(0.0, 1.0);
    final targetAngle = -math.pi / 2 + (2 * math.pi * targetRatio);

    const radius = size / 2 - 22;
    const labelRadius = radius + 30;
    const center = size / 2;

    final targetLabelX = center + labelRadius * math.cos(targetAngle);

    final targetLabelY = center + labelRadius * math.sin(targetAngle);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              size: const Size.square(size),
              painter: _GpaRingPainter(
                currentGpa: currentGpa,
                targetGpa: targetGpa,
                maxGpa: maxGpa,
                enableGlow: enableGlow,
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentGpa.toStringAsFixed(2),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 46,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '/ ${maxGpa.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'GPA hiện tại',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: targetLabelX - 36,
            top: targetLabelY - 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                '🎯 ${targetGpa.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GpaRingPainter extends CustomPainter {
  final double currentGpa;
  final double targetGpa;
  final double maxGpa;
  final bool enableGlow;

  const _GpaRingPainter({
    required this.currentGpa,
    required this.targetGpa,
    required this.maxGpa,
    required this.enableGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = size.width / 2 - 22;

    final rect = Rect.fromCircle(center: center, radius: radius);

    const startAngle = -math.pi / 2;

    final currentRatio = (currentGpa / maxGpa).clamp(0.0, 1.0);

    final currentSweep = 2 * math.pi * currentRatio;

    final targetRatio = (targetGpa / maxGpa).clamp(0.0, 1.0);

    final targetAngle = startAngle + 2 * math.pi * targetRatio;

    final trackPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, 2 * math.pi, false, trackPaint);

    if (enableGlow) {
      final glowPaint = Paint()
        ..color = AppColors.brand.withValues(alpha: 0.13)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, currentSweep, false, glowPaint);
    }

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: const [AppColors.brand, AppColors.brandSoft],
      ).createShader(rect);

    canvas.drawArc(rect, startAngle, currentSweep, false, progressPaint);

    final marker = Offset(
      center.dx + radius * math.cos(targetAngle),
      center.dy + radius * math.sin(targetAngle),
    );

    canvas.drawCircle(
      marker,
      9,
      Paint()..color = AppColors.brand.withValues(alpha: 0.22),
    );

    canvas.drawCircle(marker, 4.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _GpaRingPainter oldDelegate) {
    return oldDelegate.currentGpa != currentGpa ||
        oldDelegate.targetGpa != targetGpa ||
        oldDelegate.maxGpa != maxGpa ||
        oldDelegate.enableGlow != enableGlow;
  }
}
