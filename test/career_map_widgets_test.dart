import 'package:flutter_test/flutter_test.dart';
import 'package:uehero/models/character_data.dart';
import 'package:uehero/widgets/career_map_widgets.dart';

void main() {
  test('map mascot position uses the rendered node center and diameter', () {
    expect(
      careerMapMascotPosition(const Offset(120, 200), nodeSize: 96),
      const Offset(86, 76),
    );
    expect(
      careerMapMascotPosition(const Offset(120, 200), nodeSize: 76),
      const Offset(86, 86),
    );
  });

  test('progress pin tracks the percentage and stays inside narrow tracks', () {
    expect(careerMapPinOffset(200, 0), 0);
    expect(careerMapPinOffset(200, .1), 0);
    expect(careerMapPinOffset(200, .25), 26);
    expect(careerMapPinOffset(200, .5), 76);
    expect(careerMapPinOffset(200, 1), 152);
    expect(careerMapPinOffset(200, 2), 152);
    expect(careerMapPinOffset(32, .5), 0);
  });

  test('default map mascot is a full 3D primary character asset', () {
    final primaryMascots = characterData
        .where(
          (character) => character.modelPath.startsWith('assets/3d/Space_'),
        )
        .toList();

    expect(primaryMascots, isNotEmpty);
    expect(primaryMascots.first.modelPath, endsWith('.glb'));
    expect(
      primaryMascots.first.previewAsset,
      contains(primaryMascots.first.id),
    );
  });
}
