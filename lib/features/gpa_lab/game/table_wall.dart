import 'package:flame_forge2d/flame_forge2d.dart';

import 'physics_filters.dart';

class TableWall extends BodyComponent {
  final Vector2 start;
  final Vector2 end;

  TableWall({required this.start, required this.end});

  @override
  Body createBody() {
    final bodyDef = BodyDef(type: BodyType.static, position: Vector2.zero());

    final shapeDef = ShapeDef(
      filter: wallFilter(),
      material: SurfaceMaterial(friction: 0.35, restitution: 0.72),
    );

    return world.createBody(bodyDef)
      ..createShape(Segment(point1: start, point2: end), shapeDef);
  }
}
