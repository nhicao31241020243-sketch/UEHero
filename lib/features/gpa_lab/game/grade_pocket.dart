import 'dart:ui';

import 'package:flame/components.dart' show Sprite;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart'
    show FontWeight, TextAlign, TextPainter, TextSpan, TextStyle;

import 'gpa_lab_art.dart';
import 'physics_filters.dart';

class GradePocket extends BodyComponent with ContactCallbacks {
  final String label;
  final double gradePoint;

  final Vector2 worldPosition;

  final double sensorRadius;
  final double visualRadius;

  late final Sprite _dockSprite;

  bool _artLoaded = false;

  GradePocket({
    required this.label,
    required this.gradePoint,
    required this.worldPosition,
    this.sensorRadius = 0.68,
    this.visualRadius = 1.16,
  }) : super(renderBody: false);

  Color get accentColor {
    switch (label) {
      case 'B':
        return const Color(0xFF63C6CD);

      case 'B+':
        return const Color(0xFF63C98D);

      case 'A-':
        return const Color(0xFFF3A24A);

      case 'A':
        return const Color(0xFFEF6863);

      default:
        return const Color(0xFFEF6863);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final image = await game.images.load(GpaLabArt.dockForGrade(label));

    _dockSprite = Sprite(image);
    _artLoaded = true;

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

    if (!_artLoaded) {
      return;
    }

    // Rendered PNG includes transparent studio framing,
    // so the image canvas is larger than the visible dock.
    final artExtent = visualRadius * 3.08;

    _dockSprite.render(
      canvas,
      position: Vector2(-artExtent / 2, -artExtent / 2),
      size: Vector2.all(artExtent),
    );
  }

  void _renderLabel(Canvas canvas) {
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFF3D3331),
          fontSize: 0.48,
          fontWeight: FontWeight.w900,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    labelPainter.paint(
      canvas,
      Offset(-labelPainter.width / 2, -visualRadius - 0.85),
    );

    final scorePainter = TextPainter(
      text: TextSpan(
        text: gradePoint.toStringAsFixed(1),
        style: const TextStyle(
          color: Color(0xFF786A67),
          fontSize: 0.25,
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    scorePainter.paint(
      canvas,
      Offset(-scorePainter.width / 2, -visualRadius - 0.38),
    );
  }
}
