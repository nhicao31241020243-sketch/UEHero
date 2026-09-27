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
  double get slotY => size.y * 0.48;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(0.58));

    // Large soft shadow = physical shelf.
    canvas.drawRRect(
      rrect.shift(const Offset(0, 0.12)),
      Paint()
        ..color = const Color(0x28000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Warm shelf body.
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFF1E7E1));

    // Very subtle glass-like top border.
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0x7AFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.035,
    );

    _drawTitle(canvas);

    _drawSlot(canvas, center: Offset(leftSlotX, slotY), radius: 1.10);

    _drawSlot(canvas, center: Offset(rightSlotX, slotY), radius: 1.23);

    _drawCourseLabel(canvas, text: leftCourse, x: leftSlotX);

    _drawCourseLabel(canvas, text: rightCourse, x: rightSlotX);
  }

  void _drawTitle(Canvas canvas) {
    final painter = TextPainter(
      text: const TextSpan(
        text: 'YOUR COURSES',
        style: TextStyle(
          color: Color(0xFF514441),
          fontSize: 0.25,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.07,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, Offset(0.42, 0.26));
  }

  void _drawSlot(
    Canvas canvas, {
    required Offset center,
    required double radius,
  }) {
    // Shadow inside origin slot.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 0.09),
        width: radius * 2.05,
        height: radius * 0.88,
      ),
      Paint()
        ..color = const Color(0x25000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Shallow physical depression.
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 2, height: radius * 0.84),
      Paint()..color = const Color(0x35A9948C),
    );

    // Upper reflected light.
    canvas.drawArc(
      Rect.fromCenter(
        center: center,
        width: radius * 1.92,
        height: radius * 0.80,
      ),
      3.30,
      2.55,
      false,
      Paint()
        ..color = const Color(0xA0FFFFFF)
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
          color: Color(0xFF4B403E),
          fontSize: 0.29,
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: size.x * 0.38);

    painter.paint(canvas, Offset(x - painter.width / 2, size.y - 0.48));
  }
}
