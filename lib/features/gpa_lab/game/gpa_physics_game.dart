import 'dart:ui';

import 'package:flame_forge2d/flame_forge2d.dart';

import 'course_puck.dart';
import 'course_tray.dart';
import 'grade_pocket.dart';
import 'runway_surface.dart';
import 'table_wall.dart';

typedef GradeCommittedCallback = void Function(
  String courseId,
  int credits,
  String gradeLabel,
  double gradePoint,
);

class GpaPhysicsGame extends Forge2DGame {
  final GradeCommittedCallback onGradeCommitted;

  GpaPhysicsGame({required this.onGradeCommitted})
    : super(gravity: Vector2.zero(), metersToPixels: 32);

  @override
  Color backgroundColor() {
    return const Color(0x00000000);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Our Blender sprites live at assets/gpa_lab/3d/
    // instead of Flame's default assets/images/.
    images.prefix = '';

    debugMode = false;

    final rect = camera.visibleWorldRect;

    const inset = 0.22;

    final left = rect.left + inset;
    final right = rect.right - inset;
    final top = rect.top + inset;
    final bottom = rect.bottom - inset;

    final width = right - left;
    final height = bottom - top;

    // Invisible physics bounds.
    await world.addAll([
      TableWall(start: Vector2(left, top), end: Vector2(right, top)),
      TableWall(start: Vector2(right, top), end: Vector2(right, bottom)),
      TableWall(start: Vector2(right, bottom), end: Vector2(left, bottom)),
      TableWall(start: Vector2(left, bottom), end: Vector2(left, top)),
    ]);

    // ------------------------------------------------------
    // V2 STAGE HEADER
    // Reserve ~8% before platform.
    // ------------------------------------------------------

    final platformPosition = Vector2(left + 0.38, top + height * 0.10);

    final platformSize = Vector2(width - 0.76, height * 0.35);

    final tray = CourseTray(
      position: platformPosition,
      size: platformSize,
      leftCourse: 'Dự án A.I.',
      rightCourse: 'Kiến tập - TI',
    );

    await world.add(tray);

    // Course tokens.
    final aiHome = Vector2(
      platformPosition.x + tray.leftSlotX,
      platformPosition.y + tray.slotY,
    );

    final internshipHome = Vector2(
      platformPosition.x + tray.rightSlotX,
      platformPosition.y + tray.slotY,
    );

    await world.add(
      CoursePuck(
        courseId: 'ai_project',
        courseName: 'Dự án A.I.',
        shortCode: 'AI',
        credits: 3,
        position: aiHome,
        onSnapped: _handleSnap,
      ),
    );

    await world.add(
      CoursePuck(
        courseId: 'internship',
        courseName: 'Kiến tập - TI',
        shortCode: 'TI',
        credits: 5,
        position: internshipHome,
        onSnapped: _handleSnap,
      ),
    );

    // ------------------------------------------------------
    // RUNWAY
    // ------------------------------------------------------

    final runwayPosition = Vector2(left + 0.38, top + height * 0.49);

    final runwaySize = Vector2(width - 0.76, height * 0.20);

    await world.add(RunwaySurface(position: runwayPosition, size: runwaySize));

    // ------------------------------------------------------
    // GRADE DOCKS
    // ------------------------------------------------------

    const grades = [('B', 3.0), ('B+', 3.5), ('A-', 3.7), ('A', 4.0)];

    final pocketY = top + height * 0.85;

    final pocketLeft = left + 1.04;
    final pocketRight = right - 1.04;
    final pocketSpan = pocketRight - pocketLeft;

    for (var i = 0; i < grades.length; i++) {
      final ratio = i / (grades.length - 1);
      final grade = grades[i];

      await world.add(
        GradePocket(
          label: grade.$1,
          gradePoint: grade.$2,
          worldPosition: Vector2(pocketLeft + pocketSpan * ratio, pocketY),
          sensorRadius: 0.68,
          visualRadius: 1.16,
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
    onGradeCommitted(courseId, credits, gradeLabel, gradePoint);
  }
}
