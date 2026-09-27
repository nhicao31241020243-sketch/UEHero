import 'dart:ui';

import 'package:flutter/material.dart' show Alignment, RadialGradient;

import 'package:flame_forge2d/flame_forge2d.dart';

import 'physics_filters.dart';

class GradePocket extends BodyComponent with ContactCallbacks {
  final String label;
  final double gradePoint;
  final Vector2 worldPosition;
  final double sensorRadius;

  GradePocket({
    required this.label,
    required this.gradePoint,
    required this.worldPosition,
    this.sensorRadius = 1.15,
  }) : super(renderBody: false);

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

    // Outer well rim.
    canvas.drawCircle(
      Offset.zero,
      sensorRadius * 1.18,
      Paint()..color = const Color(0xFF29292D),
    );

    // Recessed cavity.
    canvas.drawCircle(
      Offset.zero,
      sensorRadius,
      Paint()
        ..shader =
            const RadialGradient(
              center: Alignment(0, 0.25),
              radius: 0.85,
              colors: [Color(0xFF050506), Color(0xFF111114)],
            ).createShader(
              Rect.fromCircle(center: Offset.zero, radius: sensorRadius),
            ),
    );

    // Subtle silver lip.
    canvas.drawCircle(
      Offset.zero,
      sensorRadius,
      Paint()
        ..color = const Color(0x35FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.045,
    );
  }
}
