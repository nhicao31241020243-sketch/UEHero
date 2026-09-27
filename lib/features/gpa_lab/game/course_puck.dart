import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart' show Sprite;
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/services.dart';

import 'gpa_lab_art.dart';
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

  late final Sprite _tokenSprite;

  bool _artLoaded = false;

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
  }) : radius = credits >= 5 ? 2.05 : 1.82,
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
             Circle(radius: credits >= 5 ? 2.05 : 1.82),
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

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final image = await game.images.load(GpaLabArt.tokenForCourse(courseId));

    _tokenSprite = Sprite(image);
    _artLoaded = true;

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

    if (!contact.isSensorEvent) {
      return;
    }

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

    if (!contact.isSensorEvent) {
      return;
    }

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

    // Preserve the old committed grade
    // if the user drops outside a new dock.
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
    if (activePockets.isEmpty) {
      return null;
    }

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

    if (!_artLoaded) {
      return;
    }

    final snapped = puckState == PuckState.snapped;

    // Docked token visually sinks.
    final baseScale = snapped ? 0.90 : 1.0;

    // Touch = optical Z lift.
    final scale = baseScale + (_visualLift * 0.10);

    canvas.save();
    canvas.scale(scale);

    // Dynamic shadow remains realtime,
    // while the actual object is Blender-rendered.
    final shadowY = radius * (0.22 + _visualLift * 0.25);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, shadowY),
        width: radius * (1.76 + _visualLift * 0.18),
        height: radius * (0.54 + _visualLift * 0.10),
      ),
      Paint()
        ..color = Color.fromRGBO(
          62,
          40,
          38,
          snapped ? 0.11 : 0.22 - (_visualLift * 0.06),
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + (_visualLift * 7)),
    );

    // Blender PNG has transparent margins.
    // TI is already ~12% larger in Blender,
    // so compensate slightly to avoid double-scaling.
    final artExtent = radius * (courseId == 'internship' ? 2.55 : 2.84);

    _tokenSprite.render(
      canvas,
      position: Vector2(-artExtent / 2, -artExtent / 2),
      size: Vector2.all(artExtent),
    );

    // Foreground lip sells the illusion
    // that a snapped token sits inside the dock.
    if (snapped && committedPocket != null) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(0, radius * 0.22),
          width: radius * 1.67,
          height: radius * 0.78,
        ),
        0.12,
        2.90,
        false,
        Paint()
          ..color = committedPocket!.accentColor.withValues(alpha: 0.42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.07
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.restore();
  }
}
