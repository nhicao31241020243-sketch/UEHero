import 'dart:ui';

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart'
    show
        Alignment,
        FontWeight,
        RadialGradient,
        TextAlign,
        TextPainter,
        TextSpan,
        TextStyle;

import 'physics_filters.dart';

class GradePocket extends BodyComponent with ContactCallbacks {
  final String label;
  final double gradePoint;
  final Vector2 worldPosition;

  final double sensorRadius;
  final double visualRadius;

  GradePocket({
    required this.label,
    required this.gradePoint,
    required this.worldPosition,
    this.sensorRadius = 0.64,
    this.visualRadius = 1.08,
  }) : super(renderBody: false);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    priority = -10;
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.static,
      position: worldPosition,
      userData: this,
    );

    final shapeDef = ShapeDef(
      isSensor: true,
      enableSensorEvents: true,
      filter: sensorFilter(),
      userData: this,
    );

    return world.createBody(bodyDef)
      ..createShape(Circle(radius: sensorRadius), shapeDef);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    _renderLabel(canvas);

    // Deep lower shadow.
    canvas.drawCircle(
      Offset(0, visualRadius * 0.11),
      visualRadius * 1.04,
      Paint()
        ..color = const Color(0xB8000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5),
    );

    // Outer physical lip.
    canvas.drawCircle(
      Offset.zero,
      visualRadius,
      Paint()
        ..shader =
            const RadialGradient(
              center: Alignment(-0.34, -0.42),
              radius: 1.0,
              colors: [Color(0xFF5A5050), Color(0xFF312B2C), Color(0xFF171516)],
            ).createShader(
              Rect.fromCircle(center: Offset.zero, radius: visualRadius),
            ),
    );

    final cavityRadius = visualRadius * 0.76;

    // Dark cavity.
    canvas.drawCircle(
      Offset(0, visualRadius * 0.045),
      cavityRadius,
      Paint()
        ..shader =
            const RadialGradient(
              center: Alignment(0, 0.32),
              radius: 0.92,
              colors: [Color(0xFF050405), Color(0xFF0A0809), Color(0xFF211C1D)],
            ).createShader(
              Rect.fromCircle(center: Offset.zero, radius: cavityRadius),
            ),
    );

    // Inner lower darkness = recessed depth.
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: cavityRadius * 0.93),
      0.15,
      2.85,
      false,
      Paint()
        ..color = const Color(0xA8000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.11,
    );

    // Warm upper highlight.
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: visualRadius * 0.95),
      3.35,
      2.55,
      false,
      Paint()
        ..color = const Color(0x38FFE1D5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.045,
    );
  }

  void _renderLabel(Canvas canvas) {
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFFF7EFEB),
          fontSize: 0.36,
          fontWeight: FontWeight.w900,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    labelPainter.paint(
      canvas,
      Offset(-labelPainter.width / 2, -visualRadius - 0.60),
    );

    final valuePainter = TextPainter(
      text: TextSpan(
        text: gradePoint.toStringAsFixed(1),
        style: const TextStyle(
          color: Color(0xFFAFA3A0),
          fontSize: 0.20,
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    valuePainter.paint(
      canvas,
      Offset(-valuePainter.width / 2, -visualRadius - 0.23),
    );
  }
}
