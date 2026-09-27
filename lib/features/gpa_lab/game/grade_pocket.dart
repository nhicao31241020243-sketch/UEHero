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

  // Physics sensor nhỏ hơn visual well để tránh bắt nhầm pocket bên cạnh.
  final double sensorRadius;

  // Phần hốc người dùng nhìn thấy.
  final double visualRadius;

  GradePocket({
    required this.label,
    required this.gradePoint,
    required this.worldPosition,
    this.sensorRadius = 0.56,
    this.visualRadius = 0.82,
  }) : super(renderBody: false);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Well nằm dưới puck về mặt render.
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

    // 1. Bóng sâu dưới hốc.
    canvas.drawCircle(
      Offset(0, visualRadius * 0.08),
      visualRadius * 1.03,
      Paint()
        ..color = const Color(0xCC000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2),
    );

    // 2. Vành kim loại/ceramic ngoài.
    canvas.drawCircle(
      Offset.zero,
      visualRadius,
      Paint()
        ..shader =
            const RadialGradient(
              center: Alignment(-0.32, -0.38),
              radius: 1.0,
              colors: [Color(0xFF38383D), Color(0xFF202024), Color(0xFF0B0B0D)],
            ).createShader(
              Rect.fromCircle(center: Offset.zero, radius: visualRadius),
            ),
    );

    // 3. Lòng hốc tối hơn — tạo cảm giác chìm xuống.
    final cavityRadius = visualRadius * 0.76;

    canvas.drawCircle(
      Offset(0, visualRadius * 0.035),
      cavityRadius,
      Paint()
        ..shader =
            const RadialGradient(
              center: Alignment(0, 0.28),
              radius: 0.90,
              colors: [Color(0xFF020203), Color(0xFF08080A), Color(0xFF17171A)],
            ).createShader(
              Rect.fromCircle(center: Offset.zero, radius: cavityRadius),
            ),
    );

    // 4. Inner rim highlight.
    canvas.drawCircle(
      Offset.zero,
      cavityRadius,
      Paint()
        ..color = const Color(0x20FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.035,
    );

    // 5. Outer silver edge.
    canvas.drawCircle(
      Offset.zero,
      visualRadius,
      Paint()
        ..color = const Color(0x30FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.04,
    );

    _renderLabel(canvas);
  }

  void _renderLabel(Canvas canvas) {
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFFE7E7EA),
          fontSize: 0.29,
          fontWeight: FontWeight.w800,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    labelPainter.paint(
      canvas,
      Offset(-labelPainter.width / 2, -labelPainter.height / 2 - 0.08),
    );

    final valuePainter = TextPainter(
      text: TextSpan(
        text: gradePoint.toStringAsFixed(1),
        style: const TextStyle(
          color: Color(0xFF777780),
          fontSize: 0.17,
          fontWeight: FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    valuePainter.paint(canvas, Offset(-valuePainter.width / 2, 0.16));
  }
}
