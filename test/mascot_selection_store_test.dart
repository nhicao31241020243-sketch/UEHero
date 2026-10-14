import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/models/character_data.dart';
import 'package:uehero/services/mascot_selection_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('mascot roles contain the expected distinct model families', () {
    final primary = MascotSelectionStore.charactersFor(MascotRole.primary);
    final companions = MascotSelectionStore.charactersFor(
      MascotRole.aiCompanion,
    );

    expect(primary, hasLength(12));
    expect(
      primary.every((character) => character.modelPath.contains('Space_')),
      isTrue,
    );
    expect(companions, hasLength(24));
    expect(
      companions.every((character) => character.modelPath.contains('animal-')),
      isTrue,
    );
    expect(
      primary
          .map((character) => character.id)
          .toSet()
          .intersection(companions.map((character) => character.id).toSet()),
      isEmpty,
    );
  });

  test('legacy space mascot migrates to primary only', () async {
    SharedPreferences.setMockInitialValues({
      'selected_mascot': 'space-astronaut-rae',
    });
    final selection = await MascotSelectionStore.instance.read();
    final preferences = await SharedPreferences.getInstance();

    expect(selection.primary?.id, 'space-astronaut-rae');
    expect(selection.aiCompanion, isNull);
    expect(
      preferences.getString('primary_mascot_id_v1'),
      'space-astronaut-rae',
    );
    expect(preferences.getString('ai_companion_mascot_id_v1'), isNull);
  });

  test('legacy cube pet migrates to companion only', () async {
    SharedPreferences.setMockInitialValues({'selected_mascot': 'pet-cube-1'});
    final selection = await MascotSelectionStore.instance.read();
    final preferences = await SharedPreferences.getInstance();

    expect(selection.primary, isNull);
    expect(selection.aiCompanion?.id, 'pet-cube-1');
    expect(preferences.getString('primary_mascot_id_v1'), isNull);
    expect(preferences.getString('ai_companion_mascot_id_v1'), 'pet-cube-1');
  });

  test('fresh user stays unassigned until both roles are selected', () async {
    final selection = await MascotSelectionStore.instance.read();

    expect(selection.primary, isNull);
    expect(selection.aiCompanion, isNull);
    expect(selection.isComplete, isFalse);
    expect(characterData, hasLength(36));
  });
}
