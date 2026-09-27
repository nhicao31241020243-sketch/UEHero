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

    _drawTitle(canvas);

    _drawSlot(canvas, center: Offset(leftSlotX, slotY), radius: 1.12);

    _drawSlot(canvas, center: Offset(rightSlotX, slotY), radius: 1.24);

    _drawCourseLabel(canvas, text: leftCourse, x: leftSlotX);

    _drawCourseLabel(canvas, text: rightCourse, x: rightSlotX);
  }

  void _drawTitle(Canvas canvas) {
    final painter = TextPainter(
      text: const TextSpan(
        text: 'COURSES THIS TERM',
        style: TextStyle(
          color: Color(0xFFA79C98),
          fontSize: 0.23,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.055,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, Offset(size.x / 2 - painter.width / 2, 0.04));
  }

  void _drawSlot(
    Canvas canvas, {
    required Offset center,
    required double radius,
  }) {
    // Soft depression, not a bordered card.
    canvas.drawCircle(
      Offset(center.dx, center.dy + 0.09),
      radius,
      Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawCircle(center, radius, Paint()..color = const Color(0x33201617));

    canvas.drawCircle(
      center,
      radius * 0.88,
      Paint()..color = const Color(0x44100E0F),
    );

    // Tiny upper rim catches the same warm light as the whole app.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.35,
      2.7,
      false,
      Paint()
        ..color = const Color(0x22FFE4D8)
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
          color: Color(0xFFECE5E2),
          fontSize: 0.29,
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: size.x * 0.39);

    painter.paint(canvas, Offset(x - painter.width / 2, size.y - 0.40));
  }
}
