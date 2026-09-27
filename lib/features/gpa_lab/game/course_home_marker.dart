import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

class CourseHomeMarker extends PositionComponent {
  final double radius;

  CourseHomeMarker({required Vector2 position, required this.radius})
    : super(position: position, priority: -20);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = const Color(0x28FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.035;

    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);

    const segments = 18;

    for (var i = 0; i < segments; i++) {
      final start = (2 * math.pi / segments) * i;
      final sweep = (2 * math.pi / segments) * 0.52;

      canvas.drawArc(rect, start, sweep, false, paint);
    }

    canvas.drawCircle(
      Offset.zero,
      radius * 0.12,
      Paint()..color = const Color(0x18FFFFFF),
    );
  }
}
