import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controller.dart';
import 'scenario.dart';
import 'theme.dart';

class StudioDial extends StatelessWidget {
  final StudioScenario scenario;
  final bool preview;

  const StudioDial({super.key, required this.scenario, required this.preview});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      label: scenario.isComplete
          ? 'Projected cumulative GPA'
          : 'Partial cumulative GPA',
      value: '${scenario.projectedGpa.toStringAsFixed(3)} out of 4',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: preview || reduceMotion ? 0 : 280),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(
              begin: scenario.currentGpa,
              end: scenario.projectedGpa,
            ),
            builder: (context, value, child) => SizedBox.square(
              dimension: 146,
              child: CustomPaint(
                painter: _DialPainter(value, scenario.target),

                // The dial is a visualization.
                // Keep accessibility semantics at full scale,
                // but scale the visible center copy down when
                // large system text would otherwise overflow.
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            value.toStringAsFixed(2),
                            style: StudioTheme.text(
                              32,
                              weight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'out of 4.00',
                            maxLines: 1,
                            style: StudioTheme.text(
                              10,
                              color: StudioTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Current ${scenario.currentGpa.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: StudioTheme.text(11, color: StudioTheme.muted),
          ),

          const SizedBox(height: 4),

          Text(
            '• Target ${scenario.target.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: StudioTheme.text(10, color: StudioTheme.wine),
          ),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double value;
  final double target;
  const _DialPainter(this.value, this.target);
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 - 2);
    final radius = size.shortestSide / 2 - 7;
    canvas.drawCircle(
      c + const Offset(0, 5),
      radius,
      Paint()
        ..color = const Color(0x25472F25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      c + const Offset(0, 3),
      radius,
      Paint()..color = const Color(0xFFCABBAF),
    );
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFEDE6DF)],
        ).createShader(Rect.fromCircle(center: c, radius: radius)),
    );
    final track = Rect.fromCircle(center: c, radius: radius - 12);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawArc(
      track,
      -math.pi / 2,
      math.pi * 2,
      false,
      stroke
        ..color = StudioTheme.line
        ..shader = null,
    );
    final sweep = (value / 4).clamp(0.0, 1.0) * 2 * math.pi;
    if (sweep > 0) {
      canvas.drawArc(
        track,
        -math.pi / 2,
        sweep,
        false,
        stroke
          ..shader = const SweepGradient(
            startAngle: -math.pi / 2,
            endAngle: math.pi * 1.5,
            colors: [StudioTheme.apricot, StudioTheme.coral, StudioTheme.wine],
            stops: [0, 0.65, 1],
          ).createShader(track),
      );
      canvas.drawArc(
        track.inflate(3),
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0x75FFF4DF),
      );
    }
    canvas.drawCircle(c, radius - 23, Paint()..color = StudioTheme.surface);
    final angle = -math.pi / 2 + (target / 4) * math.pi * 2;
    final marker = c + Offset(math.cos(angle), math.sin(angle)) * (radius - 12);
    canvas.drawCircle(marker, 4.5, Paint()..color = StudioTheme.surface);
    canvas.drawCircle(marker, 3, Paint()..color = StudioTheme.wine);
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.value != value || old.target != target;
}

/// Columns are live grade controls, not an illustration of fake time history.
/// Grade = front-face height on a fixed 0–4 axis. Width/depth encode no quantity.
class StudioGradeChart extends StatefulWidget {
  final StudioController controller;
  final bool expanded;
  const StudioGradeChart({
    super.key,
    required this.controller,
    this.expanded = false,
  });
  @override
  State<StudioGradeChart> createState() => _StudioGradeChartState();
}

class _StudioGradeChartState extends State<StudioGradeChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  final Map<String, double> _shown = {};
  Map<String, double> _from = {};
  Map<String, double> _to = {};
  String? _dragId;
  double _startY = 0;
  double _startGrade = 0;
  Offset _lastPosition = Offset.zero;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    for (final c in widget.controller.display.courses) {
      _shown[c.id] = (widget.controller.display.grades[c.id] ?? 0) / 100;
    }
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(_tick);
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(covariant StudioGradeChart old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
      _changed();
    }
  }

  void _tick() {
    final t = Curves.easeOutCubic.transform(_animation.value);
    for (final id in _to.keys) {
      final start = _from[id] ?? 0;
      _shown[id] = start + (_to[id]! - start) * t;
    }
    if (mounted) setState(() {});
  }

  void _changed() {
    if (!mounted) return;
    final s = widget.controller.display;
    final next = {for (final c in s.courses) c.id: (s.grades[c.id] ?? 0) / 100};
    if (widget.controller.hasPreview ||
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false)) {
      _animation.stop();
      _shown.addAll(next);
      setState(() {});
      return;
    }
    if (next.entries.every(
      (e) => ((_shown[e.key] ?? 0) - e.value).abs() < 0.0001,
    )) {
      setState(() {});
      return;
    }
    _from = Map.of(_shown);
    _to = next;
    _animation.forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _animation.dispose();
    super.dispose();
  }

  String? _courseAt(double x) {
    final s = widget.controller.display;
    final geo = _ChartGeometry(_size, s.courses.length);
    if (x < geo.left || x > geo.right) return null;
    final i = ((x - geo.left) / geo.lane)
        .floor()
        .clamp(0, s.courses.length - 1)
        .toInt();
    return s.courses[i].id;
  }

  void _start(DragStartDetails d) {
    final id = _courseAt(d.localPosition.dx);
    if (id == null) return;
    _animation.stop();
    _dragId = id;
    _startY = d.localPosition.dy;
    _lastPosition = d.localPosition;
    widget.controller.select(id);
    final s = widget.controller.display;
    final geo = _ChartGeometry(_size, s.courses.length);
    _startGrade = s.grades.containsKey(id)
        ? s.grades[id]! / 100
        : ((geo.bottom - d.localPosition.dy) / geo.plotHeight * 4)
              .clamp(0.0, 4.0)
              .toDouble();
    widget.controller.previewGrade(id, StudioGrade.nearest(_startGrade).units);
  }

  void _update(DragUpdateDetails d) {
    final id = _dragId;
    if (id == null) return;
    _lastPosition = d.localPosition;
    final geo = _ChartGeometry(_size, widget.controller.display.courses.length);
    final raw =
        (_startGrade - (d.localPosition.dy - _startY) / geo.plotHeight * 4)
            .clamp(0.0, 4.0)
            .toDouble();
    final next = StudioGrade.nearest(raw).units;
    if (widget.controller.display.grades[id] != next) {
      widget.controller.previewGrade(id, next);
      HapticFeedback.selectionClick();
    }
  }

  void _end(DragEndDetails d) {
    if (_dragId == null) return;
    final inside = Rect.fromLTWH(
      -20,
      -24,
      _size.width + 40,
      _size.height + 48,
    ).contains(_lastPosition);
    if (inside) {
      widget.controller.commitPreview();
    } else {
      widget.controller.cancelPreview();
    }
    _dragId = null;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.display;
    return Semantics(
      label:
          'Course-grade chart. Drag columns vertically. '
          'The course buttons and grade editor provide an alternative.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          _size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            key: ValueKey(
              widget.expanded ? 'expanded-grade-chart' : 'grade-chart',
            ),
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              final id = _courseAt(d.localPosition.dx);
              if (id != null) widget.controller.select(id);
            },
            onVerticalDragStart: _start,
            onVerticalDragUpdate: _update,
            onVerticalDragEnd: _end,
            onVerticalDragCancel: () {
              _dragId = null;
              widget.controller.cancelPreview();
            },
            child: RepaintBoundary(
              child: CustomPaint(
                size: _size,
                painter: _GradePainter(
                  s,
                  Map.of(_shown),
                  widget.controller.selectedId,
                  widget.expanded,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChartGeometry {
  final Size size;
  final int count;
  const _ChartGeometry(this.size, this.count);
  double get left => 19;
  double get right => size.width - 5;
  double get top => 28;
  double get bottom => size.height - 24;
  double get plotHeight => math.max(30.0, bottom - top);
  double get lane => math.max(1.0, (right - left) / count);
  double y(double value) => bottom - value.clamp(0.0, 4.0) / 4 * plotHeight;
}

class _GradePainter extends CustomPainter {
  final StudioScenario scenario;
  final Map<String, double> shown;
  final String selected;
  final bool expanded;
  const _GradePainter(this.scenario, this.shown, this.selected, this.expanded);

  void _text(
    Canvas canvas,
    String text,
    Offset center, {
    double font = 9,
    Color color = StudioTheme.muted,
    bool bold = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: StudioTheme.text(
          font,
          color: color,
          weight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
    painter.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final g = _ChartGeometry(size, scenario.courses.length);
    final font = expanded ? 12.0 : 9.0;
    for (var i = 0; i <= 4; i++) {
      final y = g.y(i.toDouble());
      canvas.drawLine(
        Offset(g.left, y),
        Offset(g.right, y),
        Paint()
          ..color = StudioTheme.line
          ..strokeWidth = i == 0 ? 1.2 : 0.8,
      );
      _text(canvas, '$i', Offset(7, y), font: font);
    }
    for (var i = 0; i < scenario.courses.length; i++) {
      final c = scenario.courses[i];
      final grade = scenario.grades[c.id];
      final color = Color(c.colorValue);
      final depth = math.min(6.0, g.lane * 0.20);
      final barWidth = g.lane * 0.60;
      final x = g.left + i * g.lane + (g.lane - barWidth - depth) / 2;
      final y = g.y(shown[c.id] ?? 0);
      final h = math.max(0.0, g.bottom - y);
      if (c.id == selected) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              g.left + i * g.lane,
              g.top - 7,
              g.lane - 1,
              g.plotHeight + 27,
            ),
            const Radius.circular(6),
          ),
          Paint()..color = color.withValues(alpha: 0.075),
        );
      }
      if (grade == null) {
        final dashed = Paint()
          ..color = color.withValues(alpha: 0.50)
          ..strokeWidth = 1.1;
        for (var step = 0; step < 3; step++) {
          final yy = g.bottom - 4.0 - step * 6;
          canvas.drawLine(Offset(x, yy), Offset(x, yy - 3), dashed);
          canvas.drawLine(
            Offset(x + barWidth, yy),
            Offset(x + barWidth, yy - 3),
            dashed,
          );
        }
        _text(
          canvas,
          '—',
          Offset(x + barWidth / 2, g.bottom - 28),
          font: font,
          bold: true,
        );
      } else {
        canvas.drawOval(
          Rect.fromLTWH(x - 2, g.bottom - 1, barWidth + depth + 4, 6),
          Paint()
            ..color = const Color(0x18503129)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
        // Only the front-face height encodes the grade; perspective is ornamental.
        final side = Path()
          ..moveTo(x + barWidth, g.bottom)
          ..lineTo(x + barWidth + depth, g.bottom - depth)
          ..lineTo(x + barWidth + depth, y - depth)
          ..lineTo(x + barWidth, y)
          ..close();
        canvas.drawPath(
          side,
          Paint()..color = Color.lerp(color, Colors.black, .28)!,
        );
        if (h > 0.01) {
          canvas.drawRect(
            Rect.fromLTWH(x, y, barWidth, h),
            Paint()
              ..shader = LinearGradient(
                colors: [Color.lerp(color, Colors.white, .15)!, color],
              ).createShader(Rect.fromLTWH(x, y, barWidth, h)),
          );
        }
        final top = Path()
          ..moveTo(x, y)
          ..lineTo(x + depth, y - depth)
          ..lineTo(x + barWidth + depth, y - depth)
          ..lineTo(x + barWidth, y)
          ..close();
        canvas.drawPath(
          top,
          Paint()..color = Color.lerp(color, Colors.white, .46)!,
        );
        canvas.drawLine(
          Offset(x, y),
          Offset(x + barWidth, y),
          Paint()
            ..color = Colors.white.withValues(alpha: .70)
            ..strokeWidth = 1,
        );
        _text(
          canvas,
          (grade / 100).toStringAsFixed(1),
          Offset(x + barWidth / 2 + depth / 2, math.max(9.0, y - depth - 10)),
          font: font,
          color: StudioTheme.ink,
          bold: true,
        );
      }
      _text(
        canvas,
        c.code,
        Offset(x + barWidth / 2 + depth / 2, g.bottom + 13),
        font: font,
        color: c.id == selected ? color : StudioTheme.muted,
        bold: true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GradePainter old) =>
      old.scenario != scenario ||
      old.shown != shown ||
      old.selected != selected ||
      old.expanded != expanded;
}

class StudioCourseButton extends StatelessWidget {
  final StudioCourse course;
  final int? units;
  final bool selected;
  final VoidCallback onTap;
  const StudioCourseButton({
    super.key,
    required this.course,
    required this.units,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final color = Color(course.colorValue);
    final grade = units == null ? '—' : StudioGrade.fromUnits(units!).label;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${course.name}, ${course.credits} credits, '
          '${units == null ? 'unplanned' : 'grade $grade'}',
      child: Tooltip(
        message: course.name,
        child: InkWell(
          key: ValueKey('course-${course.id}'),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            width: 56,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 56,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      transform: Matrix4.translationValues(
                        0,
                        selected ? -2 : 0,
                        0,
                      ),
                      child: SizedBox.square(
                        dimension: 44,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: 4,
                              left: 0,
                              right: 0,
                              height: 44,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color.lerp(
                                    color,
                                    StudioTheme.ink,
                                    .70,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x28422B26),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color.lerp(color, Colors.white, .28)!,
                                      color,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: DecoratedBox(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Colors.white, Color(0xFFF1EBE4)],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      course.code,
                                      style: StudioTheme.text(
                                        13,
                                        weight: FontWeight.w800,
                                        color: Color.lerp(
                                          color,
                                          StudioTheme.ink,
                                          .18,
                                        )!,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${course.credits} cr',
                  style: StudioTheme.text(10, color: StudioTheme.muted),
                ),
                const SizedBox(height: 3),
                Text(
                  grade,
                  style: StudioTheme.text(11, weight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
