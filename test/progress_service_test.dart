import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/models/xp_entry.dart';
import 'package:uehero/services/points_manager.dart';
import 'package:uehero/services/progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PointsManager.instance.resetForTesting();
  });

  test(
    'legacy progress facade reflects XP awards and duplicate references',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final progress = ProgressService.instance;
      await progress.initialize(preferences: preferences);

      final first = await PointsManager.instance.addXP(
        thanh: XpBar.kienThuc,
        luong: 20,
        nguon: 'flashcard_completed',
        sourceRef: 'deck-1',
        preferences: preferences,
      );
      final duplicate = await PointsManager.instance.addXP(
        thanh: XpBar.kienThuc,
        luong: 20,
        nguon: 'flashcard_completed',
        sourceRef: 'deck-1',
        preferences: preferences,
      );

      expect(first, 20);
      expect(duplicate, 0);
      expect(progress.totalPoints, 20);
    },
  );

  test('daily cap is per configured source', () async {
    final preferences = await SharedPreferences.getInstance();
    final service = PointsManager.instance;
    PointsManager.dailyCaps['debug'] = 100;

    final date = DateTime(2026, 10, 13, 9);
    for (var index = 0; index < 5; index++) {
      await service.addXP(
        thanh: XpBar.thucChien,
        luong: 30,
        nguon: 'debug',
        sourceRef: 'debug-$index',
        at: date,
        preferences: preferences,
      );
    }

    expect(service.totalXp, 100);
  });

  test('calculates rank and node progression', () {
    final service = ProgressService.instance;
    expect(service.rankFor(0), 'Cadet');
    expect(service.rankFor(120), 'Navigator');
    expect(service.currentNodeFor(121).id, 'skill-forge');
    expect(service.nextNodeFor(121)?.id, 'portfolio-station');
    expect(service.pointsToNextNode(121), 99);
  });

  test('XP log reloads from persistent storage', () async {
    final preferences = await SharedPreferences.getInstance();
    final service = PointsManager.instance;
    await service.addXP(
      thanh: XpBar.hoSo,
      luong: 5,
      nguon: 'gpa_updated',
      sourceRef: 'gpa-1',
      preferences: preferences,
    );

    service.resetForTesting();
    await service.initialize(preferences: preferences);

    expect(service.totalXp, 5);
    expect(service.entries.single.sourceRef, 'gpa-1');
  });
}
