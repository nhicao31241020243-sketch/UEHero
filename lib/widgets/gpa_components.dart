import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/gpa_conversion_config.dart';
import '../models/gpa_models.dart';
import '../theme/space_theme.dart';

const _gradeColors = <String, Color>{
  'A': Color(0xFF75F0CE),
  'B+': Color(0xFF76D8FF),
  'B': Color(0xFF8DA6FF),
  'C+': Color(0xFFB997FF),
  'C': Color(0xFFFFC878),
  'D+': Color(0xFFFF9A76),
  'D': Color(0xFFFF7F9D),
  'F': Color(0xFFB66F94),
};

class GpaSampleCard extends StatelessWidget {
  const GpaSampleCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Opacity(opacity: .68, child: IgnorePointer(child: child)),
      Positioned(
        top: 11,
        right: 15,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xEE342C62),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x887D74D9)),
          ),
          child: const Text(
            'Dữ liệu mẫu',
            style: TextStyle(
              color: Color(0xFFD7D0FF),
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    ],
  );
}

class GpaGauge extends StatelessWidget {
  const GpaGauge({
    required this.gpa,
    required this.previousGpa,
    required this.credits,
    required this.programCredits,
    required this.gradeLabel,
    super.key,
  });

  final double gpa;
  final double? previousGpa;
  final int credits;
  final int programCredits;
  final String gradeLabel;

  @override
  Widget build(BuildContext context) {
    final change = previousGpa == null ? null : gpa - previousGpa!;
    final encouragement = gpa == 0
        ? 'Ghi lại điểm đầu tiên để khởi động quỹ đạo.'
        : change == null
        ? 'Đã xác lập quỹ đạo. Tiếp tục tiến lên!'
        : change >= 0
        ? 'Quỹ đạo đang ổn định, tiếp tục tiến lên.'
        : 'Một kỳ chệch quỹ đạo thôi — ta sẽ hiệu chỉnh lại.';
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            eyebrow: 'FLIGHT PERFORMANCE',
            title: 'Mission Score',
            icon: Icons.radar_rounded,
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final diameter = math.min(178.0, constraints.maxWidth * 0.56);
              return Row(
                children: [
                  SizedBox(
                    width: diameter,
                    height: diameter,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: (gpa / 4).clamp(0, 1)),
                      duration: const Duration(milliseconds: 1100),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => CustomPaint(
                        painter: _GaugePainter(progress: value),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                gpa.toStringAsFixed(2),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                '/ 4.00 GPA',
                                style: TextStyle(
                                  color: SpaceTheme.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 7),
                              _MiniPill(
                                label: gradeLabel,
                                color: const Color(0xFF9A8BFF),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tín chỉ tích lũy',
                          style: TextStyle(
                            color: SpaceTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$credits / $programCredits',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: (credits / programCredits).clamp(0, 1),
                            backgroundColor: Colors.white.withValues(
                              alpha: .12,
                            ),
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF79D9F5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(
                              change == null
                                  ? Icons.remove_rounded
                                  : change >= 0
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              size: 18,
                              color: change == null
                                  ? SpaceTheme.textMuted
                                  : change >= 0
                                  ? const Color(0xFF74E3C3)
                                  : const Color(0xFFFF9A9E),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                change == null
                                    ? 'Chưa có kỳ trước'
                                    : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)} kỳ trước',
                                style: TextStyle(
                                  color: change == null
                                      ? SpaceTheme.textMuted
                                      : change >= 0
                                      ? const Color(0xFF74E3C3)
                                      : const Color(0xFFFFA4A9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x1C8A83FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .07)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.waving_hand_rounded,
                  color: Color(0xFFFFD17C),
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    encouragement,
                    style: const TextStyle(
                      color: SpaceTheme.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TrajectoryChart extends StatelessWidget {
  const TrajectoryChart({
    required this.labels,
    required this.semesterGpas,
    required this.cumulativeGpas,
    required this.target,
    this.projectedGpa,
    this.onSelect,
    super.key,
  });

  final List<String> labels;
  final List<double?> semesterGpas;
  final List<double?> cumulativeGpas;
  final double target;
  final double? projectedGpa;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) => _GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CardHeading(
          eyebrow: 'ACADEMIC ORBIT',
          title: 'Quỹ đạo GPA',
          icon: Icons.show_chart_rounded,
        ),
        const SizedBox(height: 6),
        const Wrap(
          spacing: 14,
          children: [
            _LegendDot(label: 'GPA kỳ', color: Color(0xFF8D77FF)),
            _LegendDot(label: 'Tích lũy', color: Color(0xFF69D8F4)),
            _LegendDot(label: 'Mục tiêu', color: Color(0xFFFFC872)),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 190,
          width: double.infinity,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: onSelect == null || labels.isEmpty
                ? null
                : (details) {
                    final box = context.findRenderObject() as RenderBox;
                    final local = box.globalToLocal(details.globalPosition);
                    final index =
                        ((local.dx / box.size.width) *
                                math.max(1, labels.length - 1))
                            .round()
                            .clamp(0, labels.length - 1);
                    onSelect!(index);
                  },
            child: CustomPaint(
              painter: _TrajectoryPainter(
                semesterGpas: semesterGpas,
                cumulativeGpas: cumulativeGpas,
                target: target,
                projectedGpa: projectedGpa,
              ),
            ),
          ),
        ),
        if (labels.isNotEmpty) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: i == 0
                        ? TextAlign.left
                        : i == labels.length - 1
                        ? TextAlign.right
                        : TextAlign.center,
                    style: const TextStyle(
                      color: SpaceTheme.textMuted,
                      fontSize: 8,
                    ),
                  ),
                ),
            ],
          ),
        ] else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Text(
                'Ghi nhận một học kỳ để xem quỹ đạo.',
                style: TextStyle(color: SpaceTheme.textMuted, fontSize: 12),
              ),
            ),
          ),
      ],
    ),
  );
}

class GradeDonut extends StatelessWidget {
  const GradeDonut({
    required this.courses,
    required this.selectedGrade,
    required this.onSelect,
    super.key,
  });

  final List<GpaCourse> courses;
  final String? selectedGrade;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (final band in gpaGradeBands)
        band.label: courses
            .where((course) => course.gradeBand.label == band.label)
            .length,
    };
    final total = counts.values.fold<int>(0, (sum, count) => sum + count);
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            eyebrow: 'GRADE DISTRIBUTION',
            title: 'Phân bổ điểm',
            icon: Icons.donut_small_rounded,
          ),
          const SizedBox(height: 14),
          if (total == 0)
            const Text(
              'Chưa có môn được tính GPA.',
              style: TextStyle(color: SpaceTheme.textMuted, fontSize: 12),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 142,
                  height: 142,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      final center = const Offset(71, 71);
                      final point = details.localPosition - center;
                      var angle = math.atan2(point.dy, point.dx) + math.pi / 2;
                      if (angle < 0) angle += math.pi * 2;
                      var start = 0.0;
                      for (final band in gpaGradeBands) {
                        final count = counts[band.label] ?? 0;
                        final sweep = math.pi * 2 * count / total;
                        if (count > 0 && angle <= start + sweep) {
                          onSelect(
                            selectedGrade == band.label ? null : band.label,
                          );
                          return;
                        }
                        start += sweep;
                      }
                    },
                    child: CustomPaint(
                      painter: _DonutPainter(
                        counts: counts,
                        selectedGrade: selectedGrade,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$total',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              'MÔN',
                              style: TextStyle(
                                color: SpaceTheme.textMuted,
                                fontSize: 9,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: [
                      for (final band in gpaGradeBands)
                        InkWell(
                          onTap: () => onSelect(
                            selectedGrade == band.label ? null : band.label,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 76,
                            child: Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: _gradeColors[band.label],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  band.label,
                                  style: TextStyle(
                                    color: selectedGrade == band.label
                                        ? Colors.white
                                        : SpaceTheme.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${((counts[band.label]! / total) * 100).round()}%',
                                  style: const TextStyle(
                                    color: SpaceTheme.textMuted,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TrajectoryPainter extends CustomPainter {
  const _TrajectoryPainter({
    required this.semesterGpas,
    required this.cumulativeGpas,
    required this.target,
    required this.projectedGpa,
  });

  final List<double?> semesterGpas;
  final List<double?> cumulativeGpas;
  final double target;
  final double? projectedGpa;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 24.0;
    const right = 8.0;
    const top = 12.0;
    const bottom = 12.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      math.max(left + 1, size.width - right),
      math.max(top + 1, size.height - bottom),
    );
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: .09)
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = chart.bottom - chart.height * i / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      final text = TextPainter(
        text: TextSpan(
          text: i.toString(),
          style: const TextStyle(color: SpaceTheme.textMuted, fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(1, y - 5));
    }
    final targetY = chart.bottom - (target.clamp(0, 4) / 4) * chart.height;
    _drawDashedLine(
      canvas,
      Offset(chart.left, targetY),
      Offset(chart.right, targetY),
      Paint()
        ..color = const Color(0xFFFFC872)
        ..strokeWidth = 1.2,
    );
    _drawSeries(
      canvas,
      chart,
      semesterGpas,
      const Color(0xFF8D77FF),
      fill: true,
    );
    _drawSeries(
      canvas,
      chart,
      cumulativeGpas,
      const Color(0xFF69D8F4),
      fill: false,
    );
    if (projectedGpa != null) {
      final values = cumulativeGpas.whereType<double>().toList();
      if (values.isNotEmpty) {
        final last = _point(
          chart,
          values.length - 1,
          values.length,
          values.last,
        );
        final projected = _point(
          chart,
          values.length,
          math.max(2, values.length + 1),
          projectedGpa!,
        );
        _drawDashedLine(
          canvas,
          last,
          projected,
          Paint()
            ..color = const Color(0xFFB9F0FF)
            ..strokeWidth = 2,
        );
        canvas.drawCircle(
          projected,
          4,
          Paint()..color = const Color(0xFFB9F0FF),
        );
      }
    }
  }

  void _drawSeries(
    Canvas canvas,
    Rect rect,
    List<double?> values,
    Color color, {
    required bool fill,
  }) {
    final valid = values
        .asMap()
        .entries
        .where((entry) => entry.value != null)
        .toList();
    if (valid.isEmpty) return;
    final points = [
      for (final entry in valid)
        _point(rect, entry.key, math.max(1, values.length - 1), entry.value!),
    ];
    if (fill && points.length > 1) {
      final area = Path()
        ..moveTo(points.first.dx, rect.bottom)
        ..lineTo(points.first.dx, points.first.dy);
      _appendSmooth(area, points);
      area
        ..lineTo(points.last.dx, rect.bottom)
        ..close();
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .25), color.withValues(alpha: 0)],
        ).createShader(rect);
      canvas.drawPath(area, fillPaint);
    }
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    _appendSmooth(line, points);
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (final point in points) {
      canvas.drawCircle(point, 5, Paint()..color = color.withValues(alpha: .2));
      canvas.drawCircle(point, 2.6, Paint()..color = color);
    }
  }

  static Offset _point(Rect rect, int index, int count, double value) => Offset(
    rect.left + rect.width * index / math.max(1, count),
    rect.bottom - (value.clamp(0, 4) / 4) * rect.height,
  );

  static void _appendSmooth(Path path, List<Offset> points) {
    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final midpoint = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, midpoint.dx, midpoint.dy);
    }
    if (points.length > 1) path.lineTo(points.last.dx, points.last.dy);
  }

  static void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    final distance = (end - start).distance;
    const dash = 5.0;
    const gap = 4.0;
    final direction = (end - start) / distance;
    for (var offset = 0.0; offset < distance; offset += dash + gap) {
      final finish = math.min(offset + dash, distance);
      canvas.drawLine(
        start + direction * offset,
        start + direction * finish,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrajectoryPainter oldDelegate) =>
      oldDelegate.semesterGpas != semesterGpas ||
      oldDelegate.cumulativeGpas != cumulativeGpas ||
      oldDelegate.target != target ||
      oldDelegate.projectedGpa != projectedGpa;
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: .1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9,
    );
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [Color(0xFF6CE4D0), Color(0xFF61BFFF), Color(0xFF9C72FF)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
    if (progress > 0) {
      final angle = -math.pi / 2 + math.pi * 2 * progress;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(
        point,
        6,
        Paint()
          ..color = const Color(0xFFB5F4FF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawCircle(point, 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.counts, required this.selectedGrade});

  final Map<String, int> counts;
  final String? selectedGrade;

  @override
  void paint(Canvas canvas, Size size) {
    final total = counts.values.fold<int>(0, (sum, value) => sum + value);
    if (total == 0) return;
    final rect = Offset.zero & size;
    var start = -math.pi / 2;
    for (final band in gpaGradeBands) {
      final count = counts[band.label] ?? 0;
      if (count == 0) continue;
      final sweep = math.pi * 2 * count / total;
      final isSelected = selectedGrade == null || selectedGrade == band.label;
      canvas.drawArc(
        rect.deflate(8),
        start,
        sweep,
        false,
        Paint()
          ..color = _gradeColors[band.label]!.withValues(
            alpha: isSelected ? 1 : .22,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 17
          ..strokeCap = StrokeCap.round,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.counts != counts ||
      oldDelegate.selectedGrade != selectedGrade;
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xB91A2044),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: SpaceTheme.glassBorder),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF040719).withValues(alpha: .18),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: child,
  );
}

class _CardHeading extends StatelessWidget {
  const _CardHeading({
    required this.eyebrow,
    required this.title,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: SpaceTheme.violet.withValues(alpha: .2),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: const Color(0xFFD8C8FF), size: 20),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: const TextStyle(
                color: SpaceTheme.textMuted,
                fontSize: 8,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .2),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: .6)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
    ),
  );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(color: SpaceTheme.textSecondary, fontSize: 9),
      ),
    ],
  );
}
