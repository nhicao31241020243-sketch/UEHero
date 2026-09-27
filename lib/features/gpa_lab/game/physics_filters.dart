import 'package:flame_forge2d/flame_forge2d.dart';

class PhysicsCategories {
  PhysicsCategories._();

  static const int puck = 0x0001;
  static const int wall = 0x0002;
  static const int sensor = 0x0004;
  static const int snapped = 0x0008;
}

Filter freePuckFilter() {
  return Filter()
    ..categoryBits = PhysicsCategories.puck
    ..maskBits =
        PhysicsCategories.wall |
        PhysicsCategories.puck |
        PhysicsCategories.sensor |
        PhysicsCategories.snapped;
}

Filter heldPuckFilter() {
  return Filter()
    ..categoryBits = PhysicsCategories.puck
    ..maskBits = PhysicsCategories.sensor;
}

Filter snappedPuckFilter() {
  return Filter()
    ..categoryBits = PhysicsCategories.snapped
    ..maskBits = PhysicsCategories.puck;
}

Filter wallFilter() {
  return Filter()
    ..categoryBits = PhysicsCategories.wall
    ..maskBits = PhysicsCategories.puck;
}

Filter sensorFilter() {
  return Filter()
    ..categoryBits = PhysicsCategories.sensor
    ..maskBits = PhysicsCategories.puck;
}
