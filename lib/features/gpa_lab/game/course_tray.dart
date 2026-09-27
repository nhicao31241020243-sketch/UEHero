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

  double get leftSlotX => size.x * 0.29;
  double get rightSlotX => size.x * 0.71;
  double get slotY => size.y * 0.47;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(0.72));

    // Wide soft platform shadow.
    canvas.drawRRect(
      rrect.shift(const Offset(0, 0.16)),
      Paint()
        ..color = const Color(0x24000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Warm raised platform.
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFF3EAE5));

    // Soft inner depth.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.10, 0.10, size.x - 0.20, size.y - 0.20),
        const Radius.circular(0.65),
      ),
      Paint()
        ..color = const Color(0x12A17B70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.055,
    );

    // Top edge highlight.
    canvas.drawArc(
      Rect.fromLTWH(0.32, 0.18, size.x - 0.64, 0.90),
      3.30,
      2.65,
      false,
      Paint()
        ..color = const Color(0x8AFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.045,
    );

    _drawSlot(canvas, center: Offset(leftSlotX, slotY), radius: 1.48);

    _drawSlot(canvas, center: Offset(rightSlotX, slotY), radius: 1.65);

    _drawCourseLabel(canvas, text: leftCourse, x: leftSlotX);

    _drawCourseLabel(canvas, text: rightCourse, x: rightSlotX);
  }

  void _drawSlot(
    Canvas canvas, {
    required Offset center,
    required double radius,
  }) {
    // Soft landing shadow.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 0.20),
        width: radius * 1.90,
        height: radius * 0.64,
      ),
      Paint()
        ..color = const Color(0x22000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );

    // Shallow origin depression.
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 1.90,
        height: radius * 0.62,
      ),
      Paint()..color = const Color(0x23A78E86),
    );

    // Specular rim.
    canvas.drawArc(
      Rect.fromCenter(
        center: center,
        width: radius * 1.84,
        height: radius * 0.58,
      ),
      3.35,
      2.45,
      false,
      Paint()
        ..color = const Color(0xA0FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.038,
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
          color: Color(0xFF4A3E3C),
          fontSize: 0.34,
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: size.x * 0.39);

    painter.paint(canvas, Offset(x - painter.width / 2, size.y - 0.58));
  }
}
