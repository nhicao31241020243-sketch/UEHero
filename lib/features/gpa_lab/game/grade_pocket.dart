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
    this.sensorRadius = 0.60,
    this.visualRadius = 0.90,
  }) : super(renderBody: false);

  Color get accentColor {
    switch (label) {
      case 'B':
        return const Color(0xFF65C9D1);
      case 'B+':
        return const Color(0xFF62C88C);
      case 'A-':
        return const Color(0xFFFFA443);
      case 'A':
        return const Color(0xFFEF6461);
      default:
        return const Color(0xFFE55B5F);
    }
  }

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

    final outer = Rect.fromCenter(
      center: Offset.zero,
      width: visualRadius * 2.05,
      height: visualRadius * 1.12,
    );

    final ring = Rect.fromCenter(
      center: const Offset(0, -0.01),
      width: visualRadius * 1.70,
      height: visualRadius * 0.91,
    );

    final cavity = Rect.fromCenter(
      center: const Offset(0, -0.02),
      width: visualRadius * 1.38,
      height: visualRadius * 0.70,
    );

    // Floating hardware shadow.
    canvas.drawOval(
      outer.shift(const Offset(0, 0.16)),
      Paint()
        ..color = const Color(0x38000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Champagne / machined metal outer dock.
    canvas.drawOval(
      outer,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.65),
          radius: 1.18,
          colors: [Color(0xFFF1E9E4), Color(0xFFB9A9A2), Color(0xFF7D706D)],
        ).createShader(outer),
    );

    // Colored functional ring.
    canvas.drawOval(ring, Paint()..color = accentColor.withValues(alpha: 0.74));

    // Deep cavity.
    canvas.drawOval(
      cavity,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, 0.50),
          radius: 1.0,
          colors: [Color(0xFF151415), Color(0xFF252426), Color(0xFF484144)],
        ).createShader(cavity),
    );

    // Inner shadow.
    canvas.drawArc(
      cavity,
      0.12,
      2.90,
      false,
      Paint()
        ..color = const Color(0x8A000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.10,
    );

    // Little status LED.
    canvas.drawCircle(
      Offset(0, -visualRadius * 0.36),
      0.105,
      Paint()
        ..color = accentColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8),
    );

    canvas.drawCircle(
      Offset(0, -visualRadius * 0.36),
      0.045,
      Paint()..color = const Color(0xFFFDFDFD),
    );
  }

  void _renderLabel(Canvas canvas) {
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFF3D3331),
          fontSize: 0.40,
          fontWeight: FontWeight.w900,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    labelPainter.paint(
      canvas,
      Offset(-labelPainter.width / 2, -visualRadius - 0.75),
    );

    final scorePainter = TextPainter(
      text: TextSpan(
        text: gradePoint.toStringAsFixed(1),
        style: const TextStyle(
          color: Color(0xFF786A67),
          fontSize: 0.22,
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    scorePainter.paint(
      canvas,
      Offset(-scorePainter.width / 2, -visualRadius - 0.33),
    );
  }
}
