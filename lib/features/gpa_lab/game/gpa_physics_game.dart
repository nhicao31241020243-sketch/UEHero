import 'dart:ui';

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import 'course_puck.dart';
import 'course_tray.dart';
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
    return const Color(0x00000000);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    debugMode = false;

    final rect = camera.visibleWorldRect;

    const inset = 0.30;

    final left = rect.left + inset;
    final right = rect.right - inset;
    final top = rect.top + inset;
    final bottom = rect.bottom - inset;

    final width = right - left;
    final height = bottom - top;

    await world.addAll([
      TableWall(start: Vector2(left, top), end: Vector2(right, top)),
      TableWall(start: Vector2(right, top), end: Vector2(right, bottom)),
      TableWall(start: Vector2(right, bottom), end: Vector2(left, bottom)),
      TableWall(start: Vector2(left, bottom), end: Vector2(left, top)),
    ]);

    // ------------------------------------------------------
    // COURSES
    // Compact top zone.
    // ------------------------------------------------------

    final trayPosition = Vector2(left + 0.30, top + 0.30);

    final traySize = Vector2(width - 0.60, height * 0.31);

    final tray = CourseTray(
      position: trayPosition,
      size: traySize,
      leftCourse: 'Dự án A.I.',
      rightCourse: 'Kiến tập - TI',
    );

    await world.add(tray);

    final puckY = trayPosition.y + tray.slotY;

    final aiHome = Vector2(trayPosition.x + tray.leftSlotX, puckY);

    final internshipHome = Vector2(trayPosition.x + tray.rightSlotX, puckY);

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

    // ------------------------------------------------------
    // GRADE TARGETS
    // Move upward strongly: short, controllable runway.
    // ------------------------------------------------------

    const grades = [('B', 3.0), ('B+', 3.5), ('A-', 3.7), ('A', 4.0)];

    final pocketY = top + height * 0.72;

    final pocketLeft = left + 1.02;

    final pocketRight = right - 1.02;

    final pocketSpan = pocketRight - pocketLeft;

    for (var i = 0; i < grades.length; i++) {
      final ratio = i / (grades.length - 1);

      final x = pocketLeft + pocketSpan * ratio;

      final grade = grades[i];

      await world.add(
        GradePocket(
          label: grade.$1,
          gradePoint: grade.$2,
          worldPosition: Vector2(x, pocketY),
          sensorRadius: 0.64,
          visualRadius: 1.08,
        ),
      );
    }
  }

  void _handleSnap(
    String courseId,
    int credits,
    String gradeLabel,
    double gradePoint,
  ) {
    status.value = '$courseId → $gradeLabel ($gradePoint)';

    onGradeCommitted(courseId, credits, gradeLabel, gradePoint);
  }

  @override
  void onRemove() {
    status.dispose();
    super.onRemove();
  }
}
