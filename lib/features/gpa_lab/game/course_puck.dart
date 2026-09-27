import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart' show Sprite;
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart'
    show FontWeight, TextAlign, TextPainter, TextSpan, TextStyle;
import 'package:flutter/services.dart';

import 'gpa_lab_art.dart';
import 'grade_pocket.dart';
import 'physics_filters.dart';

enum PuckState { home, held, flying, candidate, stamping, returning }

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

  /// Fixed shelf slot.
  ///
  /// Grades never change this position.
  final Vector2 homePosition;

  final double radius;

  final PuckSnapCallback? onSnapped;

  final Set<GradePocket> activePockets = {};

  Vector2? _targetWorldPosition;

  PuckState puckState = PuckState.home;

  // ==========================================================
  // COURSE STATE
  //
  // The course owns this state.
  // The dock does NOT.
  // ==========================================================

  String? committedGradeLabel;
  double? committedGradePoint;

  // ==========================================================
  // STAMP / RETURN ANIMATION STATE
  // ==========================================================

  GradePocket? _stampPocket;

  double _stampElapsed = 0.0;

  Vector2? _returnStart;
  double _returnElapsed = 0.0;

  double _flightElapsed = 0.0;

  // ==========================================================
  // ART
  // ==========================================================

  late final Sprite _tokenSprite;
  bool _artLoaded = false;

  double _visualLift = 0.0;

  // ==========================================================
  // PHYSICS TUNING
  // ==========================================================

  static const double _chaseGain = 15.0;
  static const double _maxChaseSpeed = 18.0;
  static const double _maxFlingSpeed = 14.0;

  static const double _autoSnapSpeed = 1.2;

  /// If a fling does not reach a grading station,
  /// automatically send the course home.
  static const double _maxFlightTime = 0.90;

  /// Token stays on the grading station long enough
  /// for the user to see:
  ///
  /// drop -> GPA update -> successful grade -> return.
  static const double _stampDuration = 0.50;

  static const double _returnDuration = 0.48;

  CoursePuck({
    required this.courseId,
    required this.courseName,
    required this.credits,
    required Vector2 position,
    this.onSnapped,
  }) : homePosition = position.clone(),
       radius = credits >= 5 ? 2.05 : 1.82,
       super(
         renderBody: false,
         bodyDef: BodyDef(
           type: BodyType.dynamic,
           position: position,
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

  bool get isAssigned => committedGradeLabel != null;

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

    // Courses live in fixed shelf slots when idle.
    body.type = BodyType.static;
    body.linearVelocity = Vector2.zero();
    body.angularVelocity = 0.0;

    _setFilter(snappedPuckFilter());
  }

  // ==========================================================
  // SENSOR EVENTS
  // ==========================================================

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

  // ==========================================================
  // DRAG
  // ==========================================================

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);

    // Ignore touch while the automatic
    // stamp / boomerang animation is running.
    if (puckState == PuckState.stamping || puckState == PuckState.returning) {
      return;
    }

    activePockets.clear();

    HapticFeedback.lightImpact();

    puckState = PuckState.held;

    _targetWorldPosition = game.screenToWorld(event.canvasPosition);

    body.type = BodyType.kinematic;

    body.linearVelocity = Vector2.zero();
    body.angularVelocity = 0.0;

    body.isAwake = true;

    _setFilter(heldPuckFilter());

    priority = 100;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);

    if (puckState != PuckState.held) {
      return;
    }

    _targetWorldPosition = game.screenToWorld(event.canvasEndPosition);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);

    if (puckState != PuckState.held) {
      return;
    }

    _targetWorldPosition = null;

    // Direct drop on a grading station.
    final pocket = _closestActivePocket();

    if (pocket != null) {
      _beginStamp(pocket);
      return;
    }

    // Keep the satisfying fling interaction.
    //
    // If it reaches a grading station and slows down,
    // it stamps.
    //
    // Otherwise it boomerangs home automatically.
    _beginFlight(event.velocity);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);

    _targetWorldPosition = null;

    if (puckState == PuckState.held) {
      _beginReturn();
    }
  }

  // ==========================================================
  // UPDATE
  // ==========================================================

  @override
  void update(double dt) {
    super.update(dt);

    final held = puckState == PuckState.held;

    final targetLift = held ? 1.0 : 0.0;

    final liftT = math.min(1.0, dt * 14.0);

    _visualLift += (targetLift - _visualLift) * liftT;

    if (held && _targetWorldPosition != null) {
      final displacement = _targetWorldPosition! - body.position;

      final chaseVelocity = displacement * _chaseGain;

      _clampMagnitude(chaseVelocity, _maxChaseSpeed);

      body.linearVelocity = chaseVelocity;

      return;
    }

    if (puckState == PuckState.stamping) {
      _updateStamp(dt);
      return;
    }

    if (puckState == PuckState.returning) {
      _updateReturn(dt);
      return;
    }

    if (puckState == PuckState.flying || puckState == PuckState.candidate) {
      _flightElapsed += dt;

      // A fling may still settle into a dock.
      if (activePockets.isNotEmpty &&
          body.linearVelocity.length <= _autoSnapSpeed) {
        final pocket = _closestActivePocket();

        if (pocket != null) {
          _beginStamp(pocket);
          return;
        }
      }

      // Miss-drop / failed fling:
      // grade state is NOT touched.
      if (_flightElapsed >= _maxFlightTime ||
          body.linearVelocity.length <= 0.18) {
        _beginReturn();
      }
    }
  }

  // ==========================================================
  // FLIGHT
  // ==========================================================

  void _beginFlight(Vector2 canvasVelocity) {
    puckState = PuckState.flying;

    _flightElapsed = 0.0;

    body.type = BodyType.dynamic;
    body.isAwake = true;

    _setFilter(freePuckFilter());

    final releaseVelocity = _canvasVelocityToWorld(canvasVelocity);

    _clampMagnitude(releaseVelocity, _maxFlingSpeed);

    body.linearVelocity = releaseVelocity;

    priority = 0;
  }

  // ==========================================================
  // STAMP
  // ==========================================================

  void _beginStamp(GradePocket pocket) {
    puckState = PuckState.stamping;

    _stampPocket = pocket;

    _stampElapsed = 0.0;

    body.type = BodyType.kinematic;

    body.setTransform(pocket.body.position.clone(), Rot.fromAngle(0));

    body.linearVelocity = Vector2.zero();
    body.angularVelocity = 0.0;

    activePockets.clear();

    _setFilter(heldPuckFilter());

    priority = 100;

    // ========================================================
    // THE IMPORTANT ARCHITECTURE DECISION:
    //
    // DATA COMMITS NOW.
    //
    // It does NOT wait for the return animation.
    // ========================================================

    committedGradeLabel = pocket.label;
    committedGradePoint = pocket.gradePoint;

    HapticFeedback.mediumImpact();

    onSnapped?.call(courseId, credits, pocket.label, pocket.gradePoint);
  }

  void _updateStamp(double dt) {
    _stampElapsed += dt;

    final pocket = _stampPocket;

    if (pocket != null) {
      body.setTransform(pocket.body.position.clone(), Rot.fromAngle(0));
    }

    if (_stampElapsed >= _stampDuration) {
      _beginReturn();
    }
  }

  // ==========================================================
  // BOOMERANG RETURN
  // ==========================================================

  void _beginReturn() {
    _targetWorldPosition = null;

    activePockets.clear();

    _returnElapsed = 0.0;

    _returnStart = body.position.clone();

    puckState = PuckState.returning;

    body.type = BodyType.kinematic;

    body.linearVelocity = Vector2.zero();
    body.angularVelocity = 0.0;

    _setFilter(heldPuckFilter());

    priority = 100;
  }

  void _updateReturn(double dt) {
    final start = _returnStart;

    if (start == null) {
      _finishReturn();
      return;
    }

    _returnElapsed += dt;

    var t = _returnElapsed / _returnDuration;

    if (t >= 1.0) {
      _finishReturn();
      return;
    }

    t = t.clamp(0.0, 1.0);

    // Cubic ease-out:
    // quick first movement, soft landing.
    final eased = 1.0 - math.pow(1.0 - t, 3).toDouble();

    final x = start.x + (homePosition.x - start.x) * eased;

    final baseY = start.y + (homePosition.y - start.y) * eased;

    // Parabolic boomerang arc.
    //
    // Negative Y = visually upwards
    // with the current Forge2D camera.
    const arcHeight = 0.90;

    final arc = -4.0 * arcHeight * t * (1.0 - t);

    body.setTransform(Vector2(x, baseY + arc), Rot.fromAngle(0));
  }

  void _finishReturn() {
    body.setTransform(homePosition.clone(), Rot.fromAngle(0));

    body.linearVelocity = Vector2.zero();
    body.angularVelocity = 0.0;

    // Fixed shelf slot.
    body.type = BodyType.static;

    _setFilter(snappedPuckFilter());

    puckState = PuckState.home;

    _stampPocket = null;
    _returnStart = null;

    activePockets.clear();

    priority = 0;
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

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

  // ==========================================================
  // RENDER
  // ==========================================================

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!_artLoaded) {
      return;
    }

    final stamping = puckState == PuckState.stamping;

    // Token sinks slightly while being "stamped".
    final baseScale = stamping ? 0.92 : 1.0;

    // Optical lift while held.
    final scale = baseScale + (_visualLift * 0.10);

    canvas.save();

    canvas.scale(scale);

    // Dynamic optical-Z shadow.
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
          stamping ? 0.10 : 0.22 - (_visualLift * 0.06),
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + (_visualLift * 7)),
    );

    // Blender asset.
    final artExtent = radius * (courseId == 'internship' ? 2.55 : 2.84);

    _tokenSprite.render(
      canvas,
      position: Vector2(-artExtent / 2, -artExtent / 2),
      size: Vector2.all(artExtent),
    );

    // Persistent course grade.
    //
    // The token returns to its fixed shelf slot,
    // but the grade badge stays.
    if (committedGradeLabel != null && puckState == PuckState.home) {
      _renderGradeBadge(canvas);
    }

    canvas.restore();
  }

  void _renderGradeBadge(Canvas canvas) {
    final label = committedGradeLabel!;

    final Color color;

    switch (label) {
      case 'B':
        color = const Color(0xFF63C6CD);
        break;

      case 'B+':
        color = const Color(0xFF63C98D);
        break;

      case 'A-':
        color = const Color(0xFFF3A24A);
        break;

      case 'A':
      default:
        color = const Color(0xFFEF6863);
        break;
    }

    // About 4–5 o'clock on the puck.
    final center = Offset(radius * 0.70, radius * 0.62);

    final badgeRadius = radius * 0.30;

    // Badge shadow.
    canvas.drawCircle(
      Offset(center.dx, center.dy + 0.07),
      badgeRadius * 1.08,
      Paint()
        ..color = const Color(0x38000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
    );

    canvas.drawCircle(center, badgeRadius, Paint()..color = color);

    canvas.drawCircle(
      center,
      badgeRadius,
      Paint()
        ..color = const Color(0xA0FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.040,
    );

    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: radius * 0.23,
          fontWeight: FontWeight.w900,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }
}
