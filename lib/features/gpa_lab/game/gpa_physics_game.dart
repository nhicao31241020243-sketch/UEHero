import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import 'course_puck.dart';
import 'grade_pocket.dart';
import 'table_wall.dart';

class GpaPhysicsGame extends Forge2DGame {
  final ValueNotifier<String> status = ValueNotifier<String>(
    'Drag or fling the puck into A',
  );

  GpaPhysicsGame() : super(gravity: Vector2.zero(), metersToPixels: 32);

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

    final pocket = GradePocket(
      label: 'A',
      gradePoint: 4.0,
      worldPosition: Vector2(0, bottom - 2.0),
      sensorRadius: 1.15,
    );

    await world.add(pocket);

    await world.add(
      CoursePuck(
        courseName: 'Dự án A.I.',
        credits: 3,
        position: Vector2(0, top + 3.0),
        onSnapped: (gradeLabel, gradePoint) {
          status.value = 'SNAPPED → $gradeLabel ($gradePoint)';
        },
      ),
    );
  }

  @override
  void onRemove() {
    status.dispose();
    super.onRemove();
  }
}
