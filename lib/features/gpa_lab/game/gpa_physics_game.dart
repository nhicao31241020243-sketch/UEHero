import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

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
  Future<void> onLoad() async {
    await super.onLoad();

    debugMode = true;

    final rect = camera.visibleWorldRect;

    const inset = 0.35;

    final left = rect.left + inset;
    final right = rect.right - inset;
    final top = rect.top + inset;
    final bottom = rect.bottom - inset;

    await world.addAll([
      TableWall(start: Vector2(left, top), end: Vector2(right, top)),
      TableWall(start: Vector2(right, top), end: Vector2(right, bottom)),
      TableWall(start: Vector2(right, bottom), end: Vector2(left, bottom)),
      TableWall(start: Vector2(left, bottom), end: Vector2(left, top)),
    ]);

    // Four evenly spaced grade pockets.
    const grades = [('B', 3.0), ('B+', 3.5), ('A-', 3.7), ('A', 4.0)];

    final pocketY = bottom - 1.35;

    final pocketLeft = left + 1.15;
    final pocketRight = right - 1.15;

    final pocketSpan = pocketRight - pocketLeft;

    for (var i = 0; i < grades.length; i++) {
      final t = i / (grades.length - 1);

      final x = pocketLeft + (pocketSpan * t);

      final grade = grades[i];

      await world.add(
        GradePocket(
          label: grade.$1,
          gradePoint: grade.$2,
          worldPosition: Vector2(x, pocketY),
          sensorRadius: 0.78,
        ),
      );
    }

    // Course 1: real anonymized transcript data.
    await world.add(
      CoursePuck(
        courseId: 'ai_project',
        courseName: 'Dự án A.I.',
        credits: 3,
        position: Vector2(left + 2.0, top + 2.5),
        onSnapped: _handleSnap,
      ),
    );

    // Course 2: 5-credit course gives visible mass/size contrast.
    await world.add(
      CoursePuck(
        courseId: 'internship',
        courseName: 'Kiến tập - TI',
        credits: 5,
        position: Vector2(right - 2.0, top + 2.5),
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
    status.value = '$courseId → $gradeLabel ($gradePoint)';

    onGradeCommitted(courseId, credits, gradeLabel, gradePoint);
  }

  @override
  void onRemove() {
    status.dispose();
    super.onRemove();
  }
}
