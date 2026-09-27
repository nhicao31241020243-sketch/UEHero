import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show FontWeight, TextAlign, TextPainter, TextSpan, TextStyle;

class CourseTray extends PositionComponent {
  final String leftCourse;
  final String rightCourse;

  CourseTray({
    required Vector2 position,
    required Vector2 size,
    required this.leftCourse,
    required this.rightCourse,
  }) : super(position: position, size: size, priority: -30);

  double get leftSlotX => size.x * 0.28;
  double get rightSlotX => size.x * 0.72;
  double get slotY => size.y * 0.44;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final trayRect = Rect.fromLTWH(0, 0, size.x, size.y);

    final trayRRect = RRect.fromRectAndRadius(
      trayRect,
      const Radius.circular(0.42),
    );

    // Soft table shadow.
    canvas.drawRRect(
      trayRRect.shift(const Offset(0, 0.10)),
      Paint()
        ..color = const Color(0x77000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Unified material tray.
    canvas.drawRRect(trayRRect, Paint()..color = const Color(0xFF232326));

    // Fine top edge.
    canvas.drawRRect(
      trayRRect,
      Paint()
        ..color = const Color(0x22FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.035,
    );

    _drawTitle(canvas);

    _drawSlot(canvas, center: Offset(leftSlotX, slotY));

    _drawSlot(canvas, center: Offset(rightSlotX, slotY));

    _drawCourseLabel(canvas, text: leftCourse, x: leftSlotX);

    _drawCourseLabel(canvas, text: rightCourse, x: rightSlotX);
  }

  void _drawTitle(Canvas canvas) {
    final painter = TextPainter(
      text: const TextSpan(
        text: 'COURSES THIS TERM',
        style: TextStyle(
          color: Color(0xFF8D8D94),
          fontSize: 0.21,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.04,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, Offset(size.x / 2 - painter.width / 2, 0.22));
  }

  void _drawSlot(Canvas canvas, {required Offset center}) {
    // Subtle depression instead of dashed outline.
    canvas.drawCircle(
      Offset(center.dx, center.dy + 0.05),
      0.99,
      Paint()
        ..color = const Color(0x99000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    canvas.drawCircle(center, 0.95, Paint()..color = const Color(0xFF18181B));

    canvas.drawCircle(
      center,
      0.95,
      Paint()
        ..color = const Color(0x24FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.035,
    );
  }

  void _drawCourseLabel(
    Canvas canvas, {
    required String text,
    required double x,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFFE5E5E8),
          fontSize: 0.28,
          fontWeight: FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: size.x * 0.38);

    painter.paint(canvas, Offset(x - painter.width / 2, size.y - 0.58));
  }
}
