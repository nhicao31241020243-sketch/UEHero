import 'dart:ui';

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import 'course_home_marker.dart';
import 'course_puck.dart';
import 'grade_pocket.dart';
import 'table_wall.dart';

typedef GradeCommittedCallback = void Function(
  String courseId,
  int credits,
  String gradeLabel,
  double gradePoint,
);

class GpaPhysicsGame extends Forge2DGame {
  final GradeCommittedCallback onGradeCommitted;

  final ValueNotifier<String> status = ValueNotifier<String>(
    'Assign grades to the courses',
  );

  GpaPhysicsGame({required this.onGradeCommitted})
    : super(gravity: Vector2.zero(), metersToPixels: 32);

  @override
  Color backgroundColor() {
    return const Color(0xFF111113);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Visual production mode.
    debugMode = false;

    final rect = camera.visibleWorldRect;

    const inset = 0.35;

    final left = rect.left + inset;
    final right = rect.right - inset;
    final top = rect.top + inset;
    final bottom = rect.bottom - inset;

    // Invisible physical table boundaries.
    await world.addAll([
      TableWall(start: Vector2(left, top), end: Vector2(right, top)),
      TableWall(start: Vector2(right, top), end: Vector2(right, bottom)),
      TableWall(start: Vector2(right, bottom), end: Vector2(left, bottom)),
      TableWall(start: Vector2(left, bottom), end: Vector2(left, top)),
    ]);

    // -------------------------
    // GRADE WELLS
    // -------------------------

    const grades = [('B', 3.0), ('B+', 3.5), ('A-', 3.7), ('A', 4.0)];

    // Keep wells near the bottom while leaving a physics runway.
    final pocketY = bottom - 1.15;

    final pocketLeft = left + 1.0;
    final pocketRight = right - 1.0;

    final pocketSpan = pocketRight - pocketLeft;

    for (var i = 0; i < grades.length; i++) {
      final ratio = i / (grades.length - 1);

      final x = pocketLeft + (pocketSpan * ratio);

      final grade = grades[i];

      await world.add(
        GradePocket(
          label: grade.$1,
          gradePoint: grade.$2,
          worldPosition: Vector2(x, pocketY),

          // Physics area intentionally smaller
          // than the visual socket.
          sensorRadius: 0.56,
          visualRadius: 0.82,
        ),
      );
    }

    // -------------------------
    // COURSE HOME POSITIONS
    // -------------------------

    final aiHome = Vector2(left + 1.75, top + 1.85);

    final internshipHome = Vector2(right - 1.75, top + 1.85);

    // Dashed origin sockets remain visible
    // after a puck is picked up.
    await world.addAll([
      CourseHomeMarker(position: aiHome, radius: 0.70),
      CourseHomeMarker(position: internshipHome, radius: 0.78),
    ]);

    // -------------------------
    // REAL ANONYMIZED COURSES
    // -------------------------

    await world.add(
      CoursePuck(
        courseId: 'ai_project',
        courseName: 'Dự án A.I.',
        credits: 3,
        position: aiHome,
        onSnapped: _handleSnap,
      ),
    );

    await world.add(
      CoursePuck(
        courseId: 'internship',
        courseName: 'Kiến tập - TI',
        credits: 5,
        position: internshipHome,
        onSnapped: _handleSnap,
      ),
    );
  }

  void _handleSnap(
    String courseId,
    int credits,
    String gradeLabel,
    double gradePoint,
  ) {
    onGradeCommitted(courseId, credits, gradeLabel, gradePoint);
  }
}
