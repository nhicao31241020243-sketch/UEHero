import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/events.dart';
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
import 'package:flutter/services.dart';

import 'grade_pocket.dart';
import 'physics_filters.dart';

enum PuckState { idle, held, flying, candidate, snapped }

typedef PuckSnapCallback = void Function(
  String courseId,
  int credits,
  String gradeLabel,
  double gradePoint,
);

class CoursePuck extends BodyComponent with DragCallbacks, ContactCallbacks {
  final String courseId;
  final String courseName;
  final int credits;
  final double radius;

  final PuckSnapCallback? onSnapped;

  final Set<GradePocket> activePockets = {};

  Vector2? _targetWorldPosition;

  PuckState puckState = PuckState.idle;

  GradePocket? committedPocket;

  double _visualLift = 0.0;

  static const double _chaseGain = 15.0;
  static const double _maxChaseSpeed = 18.0;
  static const double _maxFlingSpeed = 14.0;
  static const double _autoSnapSpeed = 1.2;

  CoursePuck({
    required this.courseId,
    required this.courseName,
    required this.credits,
    required Vector2 position,
    Vector2? initialVelocity,
    this.onSnapped,
  }) : radius = credits >= 5 ? 1.08 : 0.96,
       super(
         renderBody: false,
         bodyDef: BodyDef(
           type: BodyType.dynamic,
           position: position,
           linearVelocity: initialVelocity ?? Vector2.zero(),
           linearDamping: 0.70,
           angularDamping: 1.8,
           fixedRotation: true,
         ),
         shapeSpecs: [
           ShapeSpec(
             Circle(radius: credits >= 5 ? 1.08 : 0.96),
             ShapeDef(
               density: credits >= 5 ? 1.25 : 1.0,
               filter: freePuckFilter(),
               material: SurfaceMaterial(friction: 0.32, restitution: 0.68),
               enableContactEvents: true,
               enableSensorEvents: true,
             ),
           ),
         ],
       );

  Color get accentColor {
    return courseId == 'internship'
        ? const Color(0xFFFF9B55)
        : const Color(0xFFEF5C5F);
  }

  String get shortCode {
    return courseId == 'internship' ? 'TI' : 'AI';
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    body.userData = this;

    for (final shape in body.shapes) {
      shape.userData = this;
      shape.sensorEventsEnabled = true;
      shape.contactEventsEnabled = true;
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);

    if (!contact.isSensorEvent) return;

    if (other is GradePocket) {
      activePockets.add(other);

      if (puckState == PuckState.flying) {
        puckState = PuckState.candidate;
      }
    }
  }

  @override
  void endContact(Object other, Contact contact) {
    super.endContact(other, contact);

    if (!contact.isSensorEvent) return;

    if (other is GradePocket) {
      activePockets.remove(other);

      if (activePockets.isEmpty && puckState == PuckState.candidate) {
        puckState = PuckState.flying;
      }
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);

    HapticFeedback.lightImpact();

    puckState = PuckState.held;

    _targetWorldPosition = game.screenToWorld(event.canvasPosition);

    body.type = BodyType.kinematic;
    body.linearVelocity = Vector2.zero();
    body.angularVelocity = 0;
    body.isAwake = true;

    _setFilter(heldPuckFilter());

    priority = 100;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);

    _targetWorldPosition = game.screenToWorld(event.canvasEndPosition);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);

    _targetWorldPosition = null;

    final pocket = _closestActivePocket();

    if (pocket != null) {
      _snapTo(pocket);
      return;
    }

    if (committedPocket != null) {
      _snapTo(committedPocket!, notify: false);
      return;
    }

    puckState = PuckState.flying;

    body.type = BodyType.dynamic;
    body.isAwake = true;

    _setFilter(freePuckFilter());

    final releaseVelocity = _canvasVelocityToWorld(event.velocity);

    _clampMagnitude(releaseVelocity, _maxFlingSpeed);

    body.linearVelocity = releaseVelocity;

    priority = 0;
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);

    _targetWorldPosition = null;

    if (committedPocket != null) {
      _snapTo(committedPocket!, notify: false);
      return;
    }

    puckState = PuckState.idle;

    body.type = BodyType.dynamic;
    body.linearVelocity = Vector2.zero();
    body.angularVelocity = 0;
    body.isAwake = true;

    _setFilter(freePuckFilter());

    priority = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final held = puckState == PuckState.held;

    final targetLift = held ? 1.0 : 0.0;

    final t = math.min(1.0, dt * 14);

    _visualLift += (targetLift - _visualLift) * t;

    if (held && _targetWorldPosition != null) {
      final displacement = _targetWorldPosition! - body.position;

      final chaseVelocity = displacement * _chaseGain;

      _clampMagnitude(chaseVelocity, _maxChaseSpeed);

      body.linearVelocity = chaseVelocity;
      return;
    }

    if ((puckState == PuckState.flying || puckState == PuckState.candidate) &&
        activePockets.isNotEmpty &&
        body.linearVelocity.length <= _autoSnapSpeed) {
      final pocket = _closestActivePocket();

      if (pocket != null) {
        _snapTo(pocket);
      }
    }
  }

  GradePocket? _closestActivePocket() {
    if (activePockets.isEmpty) return null;

    GradePocket? closest;
    var closestDistanceSquared = double.infinity;

    for (final pocket in activePockets) {
      final delta = pocket.body.position - body.position;

      final distanceSquared = delta.length2;

      if (distanceSquared < closestDistanceSquared) {
        closestDistanceSquared = distanceSquared;

        closest = pocket;
      }
    }

    return closest;
  }

  void _snapTo(GradePocket pocket, {bool notify = true}) {
    puckState = PuckState.snapped;
    committedPocket = pocket;

    body.type = BodyType.static;

    body.setTransform(
      Vector2(pocket.body.position.x, pocket.body.position.y),
      Rot.fromAngle(body.angle),
    );

    body.linearVelocity = Vector2.zero();
    body.angularVelocity = 0;

    _setFilter(snappedPuckFilter());

    priority = 0;

    if (notify) {
      HapticFeedback.mediumImpact();

      onSnapped?.call(courseId, credits, pocket.label, pocket.gradePoint);
    }
  }

  void _setFilter(Filter filter) {
    for (final shape in body.shapes) {
      shape.filter = filter;
    }
  }

  Vector2 _canvasVelocityToWorld(Vector2 canvasVelocity) {
    final worldOrigin = game.screenToWorld(Vector2.zero());

    final worldTip = game.screenToWorld(canvasVelocity);

    return worldTip - worldOrigin;
  }

  void _clampMagnitude(Vector2 vector, double maxMagnitude) {
    final speed = vector.length;

    if (speed <= maxMagnitude || speed == 0) {
      return;
    }

    vector.scale(maxMagnitude / speed);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final snapped = puckState == PuckState.snapped;

    final baseScale = snapped ? 0.91 : 1.0;

    final scale = baseScale + (_visualLift * 0.12);

    canvas.save();

    canvas.scale(scale);

    // ------------------------------
    // 1. OPTICAL Z SHADOW
    // ------------------------------

    final shadowOffset = radius * (0.20 + _visualLift * 0.31);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, shadowOffset),
        width: radius * (1.76 + _visualLift * 0.18),
        height: radius * (0.64 + _visualLift * 0.08),
      ),
      Paint()
        ..color = Color.fromRGBO(
          47,
          30,
          29,
          snapped ? 0.18 : 0.28 - (_visualLift * 0.08),
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + (_visualLift * 8)),
    );

    // ------------------------------
    // 2. DEEP BODY
    // ------------------------------

    canvas.drawCircle(
      Offset(0, radius * 0.17),
      radius,
      Paint()..color = const Color(0xFF211D1E),
    );

    // ------------------------------
    // 3. MACHINED OUTER RING
    // ------------------------------

    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.38, -0.48),
          radius: 1.10,
          colors: [Color(0xFF8D8380), Color(0xFF4C4647), Color(0xFF292526)],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
    );

    // ------------------------------
    // 4. FUNCTIONAL COLOR RING
    // ------------------------------

    canvas.drawCircle(Offset.zero, radius * 0.86, Paint()..color = accentColor);

    // ------------------------------
    // 5. CERAMIC FACE
    // ------------------------------

    canvas.drawCircle(
      Offset.zero,
      radius * 0.74,
      Paint()
        ..shader =
            const RadialGradient(
              center: Alignment(-0.40, -0.48),
              radius: 1.05,
              colors: [Color(0xFF5D5556), Color(0xFF383233), Color(0xFF242021)],
            ).createShader(
              Rect.fromCircle(center: Offset.zero, radius: radius * 0.74),
            ),
    );

    // Specular highlight.
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius * 0.64),
      3.65,
      1.45,
      false,
      Paint()
        ..color = const Color(0x45FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.065,
    );

    _renderIdentity(canvas);

    // When docked, front lip covers
    // part of the token to sell depth.
    if (snapped && committedPocket != null) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(0, radius * 0.10),
          width: radius * 1.72,
          height: radius * 1.00,
        ),
        0.12,
        2.90,
        false,
        Paint()
          ..color = committedPocket!.accentColor.withValues(alpha: 0.52)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.13
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.restore();
  }

  void _renderIdentity(Canvas canvas) {
    final codePainter = TextPainter(
      text: TextSpan(
        text: shortCode,
        style: TextStyle(
          color: const Color(0xFFFDF9F7),
          fontSize: radius * 0.50,
          fontWeight: FontWeight.w900,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    codePainter.paint(
      canvas,
      Offset(-codePainter.width / 2, -codePainter.height / 2 - radius * 0.09),
    );

    final creditPainter = TextPainter(
      text: TextSpan(
        text: '$credits TC',
        style: TextStyle(
          color: accentColor,
          fontSize: radius * 0.27,
          fontWeight: FontWeight.w800,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    creditPainter.paint(
      canvas,
      Offset(-creditPainter.width / 2, radius * 0.22),
    );
  }
}
