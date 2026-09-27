import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GpaJourneyChart extends StatefulWidget {
  final double currentGpa;
  final double projectedGpa;
  final double targetGpa;

  final int plannedCount;
  final int totalCount;

  const GpaJourneyChart({
    super.key,
    required this.currentGpa,
    required this.projectedGpa,
    required this.targetGpa,
    required this.plannedCount,
    required this.totalCount,
  });

  @override
  State<GpaJourneyChart> createState() => _GpaJourneyChartState();
}

class _GpaJourneyChartState extends State<GpaJourneyChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late double _fromProjected;
  late double _toProjected;
  late double _displayedProjected;

  int _selectedPoint = 1;

  @override
  void initState() {
    super.initState();

    _displayedProjected = widget.projectedGpa;

    _fromProjected = widget.projectedGpa;

    _toProjected = widget.projectedGpa;

    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 520),
        )..addListener(() {
          final curved = Curves.easeOutCubic.transform(_controller.value);

          setState(() {
            _displayedProjected =
                _fromProjected + (_toProjected - _fromProjected) * curved;
          });
        });
  }

  @override
  void didUpdateWidget(covariant GpaJourneyChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if ((oldWidget.projectedGpa - widget.projectedGpa).abs() < 0.00001) {
      return;
    }

    _fromProjected = _displayedProjected;

    _toProjected = widget.projectedGpa;

    _controller
      ..stop()
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(TapUpDetails details) {
    final width = context.size?.width ?? 1;

    final ratio = details.localPosition.dx / width;

    final next = ratio < 0.34
        ? 0
        : ratio < 0.72
        ? 1
        : 2;

    if (next == _selectedPoint) {
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _selectedPoint = next;
    });
  }

  String get _selectedLabel {
    switch (_selectedPoint) {
      case 0:
        return 'Current ${widget.currentGpa.toStringAsFixed(2)}';

      case 2:
        return 'Target ${widget.targetGpa.toStringAsFixed(2)}';

      case 1:
      default:
        return 'Projected ${_displayedProjected.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reached = _displayedProjected >= widget.targetGpa;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFC),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'GPA JOURNEY',
                style: TextStyle(
                  color: Color(0xFF524643),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.plannedCount} / ${widget.totalCount} courses planned',
                style: TextStyle(
                  color: reached
                      ? const Color(0xFF428B68)
                      : const Color(0xFF8D7E79),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: _handleTap,
            child: SizedBox(
              height: 112,
              width: double.infinity,
              child: CustomPaint(
                painter: _GpaJourneyPainter(
                  currentGpa: widget.currentGpa,
                  projectedGpa: _displayedProjected,
                  targetGpa: widget.targetGpa,
                  selectedPoint: _selectedPoint,
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Container(
                key: ValueKey(_selectedLabel),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5ECE7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _selectedLabel,
                  style: const TextStyle(
                    color: Color(0xFF655754),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GpaJourneyPainter extends CustomPainter {
  final double currentGpa;
  final double projectedGpa;
  final double targetGpa;

  final int selectedPoint;

  const _GpaJourneyPainter({
    required this.currentGpa,
    required this.projectedGpa,
    required this.targetGpa,
    required this.selectedPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final minValue = math
        .max(
          0.0,
          math.min(currentGpa, math.min(projectedGpa, targetGpa)) - 0.16,
        )
        .toDouble();

    final maxValue = math
        .min(
          4.0,
          math.max(currentGpa, math.max(projectedGpa, targetGpa)) + 0.16,
        )
        .toDouble();

    final range = math.max(0.10, maxValue - minValue).toDouble();

    const top = 14.0;
    final bottom = size.height - 18;

    double yFor(double value) {
      final normalized = (value - minValue) / range;

      return bottom - normalized * (bottom - top);
    }

    final current = Offset(32, yFor(currentGpa));

    final projected = Offset(size.width * 0.56, yFor(projectedGpa));

    final target = Offset(size.width - 42, yFor(targetGpa));

    // ======================================================
    // PERSPECTIVE SURFACE
    // ======================================================

    final ground = Path()
      ..moveTo(8, bottom + 10)
      ..lineTo(size.width - 8, bottom + 10)
      ..lineTo(size.width - 42, top + 4)
      ..lineTo(42, top + 4)
      ..close();

    canvas.drawPath(
      ground,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0x36D8C4BC), Color(0x05FFFFFF)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Perspective grid.
    for (var i = 1; i <= 3; i++) {
      final t = i / 4;

      final y = top + (bottom - top) * t;

      final inset = 36 - 26 * t;

      canvas.drawLine(
        Offset(inset, y),
        Offset(size.width - inset, y),
        Paint()
          ..color = const Color(0x22A98E85)
          ..strokeWidth = 1,
      );
    }

    // ======================================================
    // TRAJECTORY
    // ======================================================

    final trajectory = Path()
      ..moveTo(current.dx, current.dy)
      ..cubicTo(
        current.dx + 55,
        current.dy,
        projected.dx - 48,
        projected.dy + 5,
        projected.dx,
        projected.dy,
      );

    // Physical shadow beneath line.
    canvas.save();
    canvas.translate(0, 4);

    canvas.drawPath(
      trajectory,
      Paint()
        ..color = const Color(0x23000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();

    final reached = projectedGpa >= targetGpa;

    canvas.drawPath(
      trajectory,
      Paint()
        ..shader = LinearGradient(
          colors: reached
              ? const [Color(0xFFBCA49B), Color(0xFF428B68)]
              : const [Color(0xFFBCA49B), Color(0xFFD92332)],
        ).createShader(Rect.fromPoints(current, projected))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );

    // Projected -> target relationship.
    final targetConnection = Paint()
      ..color = reached ? const Color(0x99428B68) : const Color(0x55D92332)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    _drawDashedLine(canvas, projected, target, targetConnection);

    // ======================================================
    // TARGET GATE
    // ======================================================

    canvas.drawLine(
      Offset(target.dx, target.dy + 7),
      Offset(target.dx, bottom + 5),
      Paint()
        ..color = reached ? const Color(0x55428B68) : const Color(0x35D92332)
        ..strokeWidth = 1.4,
    );

    final gateRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(target.dx, target.dy - 13),
        width: 68,
        height: 24,
      ),
      const Radius.circular(12),
    );

    canvas.drawRRect(
      gateRect.shift(const Offset(0, 3)),
      Paint()..color = const Color(0x16000000),
    );

    canvas.drawRRect(
      gateRect,
      Paint()
        ..color = reached ? const Color(0xFFE3F1E9) : const Color(0xFFFBE4E1),
    );

    _paintText(
      canvas,
      'TARGET ${targetGpa.toStringAsFixed(2)}',
      Offset(target.dx, target.dy - 13),
      fontSize: 8.5,
      fontWeight: FontWeight.w900,
      color: reached ? const Color(0xFF367A5A) : const Color(0xFFB94C52),
    );

    // ======================================================
    // CURRENT NODE
    // ======================================================

    _paintNode(
      canvas,
      current,
      radius: 7.5,
      color: const Color(0xFF756865),
      selected: selectedPoint == 0,
    );

    _paintText(
      canvas,
      'NOW',
      Offset(current.dx, current.dy + 16),
      fontSize: 7.5,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF8C7F7A),
    );

    // ======================================================
    // PROJECTED NODE
    // ======================================================

    _paintNode(
      canvas,
      projected,
      radius: 9,
      color: reached ? const Color(0xFF428B68) : const Color(0xFFD92332),
      selected: selectedPoint == 1,
    );

    _paintText(
      canvas,
      projectedGpa.toStringAsFixed(2),
      Offset(projected.dx, projected.dy - 17),
      fontSize: 10,
      fontWeight: FontWeight.w900,
      color: reached ? const Color(0xFF367A5A) : const Color(0xFFC82331),
    );

    if (selectedPoint == 2) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          gateRect.outerRect.inflate(3),
          const Radius.circular(15),
        ),
        Paint()
          ..color = const Color(0x35D92332)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _paintNode(
    Canvas canvas,
    Offset center, {
    required double radius,
    required Color color,
    required bool selected,
  }) {
    if (selected) {
      canvas.drawCircle(
        center,
        radius + 6,
        Paint()..color = color.withValues(alpha: 0.13),
      );
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 4),
        width: radius * 2.2,
        height: radius * 0.85,
      ),
      Paint()
        ..color = const Color(0x27000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.40),
          colors: [Colors.white.withValues(alpha: 0.85), color],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dash = 5.0;
    const gap = 4.0;

    final dx = end.dx - start.dx;

    final dy = end.dy - start.dy;

    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance <= 0) {
      return;
    }

    final unitX = dx / distance;

    final unitY = dy / distance;

    var travelled = 0.0;

    while (travelled < distance) {
      final segmentEnd = math.min(travelled + dash, distance);

      canvas.drawLine(
        Offset(start.dx + unitX * travelled, start.dy + unitY * travelled),
        Offset(start.dx + unitX * segmentEnd, start.dy + unitY * segmentEnd),
        paint,
      );

      travelled += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _GpaJourneyPainter oldDelegate) {
    return oldDelegate.currentGpa != currentGpa ||
        oldDelegate.projectedGpa != projectedGpa ||
        oldDelegate.targetGpa != targetGpa ||
        oldDelegate.selectedPoint != selectedPoint;
  }
}
