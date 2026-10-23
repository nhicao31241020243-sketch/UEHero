import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/models/character_data.dart';
import 'package:uehero/screens/career_board_screen.dart';
import 'package:uehero/services/career_board_service.dart';
import 'package:uehero/services/companion_settings_store.dart';
import 'package:uehero/services/career_map_visibility.dart';
import 'package:uehero/services/mascot_selection_store.dart';
import 'package:uehero/services/points_manager.dart';
import 'package:uehero/widgets/career_map_widgets.dart';
import 'package:uehero/widgets/companion_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'active Career Map renders bottom progress, 3D node mascot and hides companion',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      await CareerBoardService.instance.resetForTests();
      PointsManager.instance.resetForTesting();
      final primary = MascotSelectionStore.charactersFor(MascotRole.primary)
          .first;
      final companion = characterData.firstWhere(
        (character) => character.modelPath.endsWith('animal-bee.glb'),
      );
      await MascotSelectionStore.instance.save(
        MascotSelection(primary: primary, aiCompanion: companion),
        preferences: preferences,
      );
      await CompanionSettingsStore.instance.setOverlayEnabled(true);
      CareerMapVisibility.isActive.value = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            fit: StackFit.expand,
            children: [
              CareerBoardScreen(
                embedded: true,
                isActive: true,
                mascotModelBuilder: (character) => ColoredBox(
                  key: ValueKey('test-model-${character.id}'),
                  color: Colors.transparent,
                ),
              ),
              const CompanionOverlay(),
            ],
          ),
        ),
      );
      for (var frame = 0; frame < 20; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(
        find.byKey(const ValueKey('career-progress-card')),
        findsOneWidget,
      );
      expect(find.byType(MascotLocationPin), findsOneWidget);
      expect(find.byKey(const ValueKey('career-map-mascot')), findsOneWidget);
      expect(
        find.byKey(ValueKey('companion-floating-model-${companion.id}')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);

      final cardRect = tester.getRect(
        find.byKey(const ValueKey('career-progress-card')),
      );
      final mapRect = tester.getRect(
        find.byKey(const ValueKey('career-board-map-viewport')),
      );
      expect(cardRect.top, greaterThanOrEqualTo(mapRect.bottom - 1));
      expect(CareerMapVisibility.isActive.value, isTrue);

      final mascotRect = tester.getRect(
        find.byKey(const ValueKey('career-map-mascot')),
      );
      final currentNodeRect = tester.getRect(
        find.byKey(const ValueKey('career-board-node-z0t0')),
      );
      expect(mascotRect.center.dx, closeTo(currentNodeRect.center.dx, 1));
      expect(mascotRect.bottom, closeTo(currentNodeRect.top, 1));
    },
  );
}
