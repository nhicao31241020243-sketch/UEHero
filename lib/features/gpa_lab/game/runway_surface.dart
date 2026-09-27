import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show FontWeight, TextAlign, TextPainter, TextSpan, TextStyle;

class RunwaySurface extends PositionComponent {
  RunwaySurface({required Vector2 position, required Vector2 size})
    : super(position: position, size: size, priority: -25);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(0.64));

    // Recessed interaction zone.
    canvas.drawRRect(rrect, Paint()..color = const Color(0xA8E1D2CB));

    // Inner shadow approximation.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.10, 0.10, size.x - 0.20, size.y - 0.20),
        const Radius.circular(0.57),
      ),
      Paint()
        ..color = const Color(0x1F7A5B53)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.075,
    );

    // Quiet runway guides.
    for (var i = 1; i <= 3; i++) {
      final y = size.y * i / 4;

      canvas.drawLine(
        Offset(0.62, y),
        Offset(size.x - 0.62, y),
        Paint()
          ..color = const Color(0x3AFFFFFF)
          ..strokeWidth = 0.028,
      );
    }

    final painter = TextPainter(
      text: const TextSpan(
        text: 'drag  •  fling  •  snap',
        style: TextStyle(
          color: Color(0xFF96847E),
          fontSize: 0.31,
          fontWeight: FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(size.x / 2 - painter.width / 2, size.y / 2 - painter.height / 2),
    );
  }
}
