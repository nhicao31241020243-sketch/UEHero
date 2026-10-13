import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/models/career_progress.dart';
import 'package:uehero/services/progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('awards persist and duplicate references are ignored', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final service = ProgressService.instance;
    service.resetForTesting();
    await service.initialize(preferences: preferences);

    final first = await service.awardPoints(
      ProgressEventType.flashcardCompleted,
      refId: 'deck-1',
      preferences: preferences,
    );
    final duplicate = await service.awardPoints(
      ProgressEventType.flashcardCompleted,
      refId: 'deck-1',
      preferences: preferences,
    );

    expect(first, 20);
    expect(duplicate, 0);
    expect(service.totalPoints, 20);
  });

  test('daily cap clips awards', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final service = ProgressService.instance;
    service.resetForTesting();
    await service.initialize(preferences: preferences);

    final date = DateTime(2026, 10, 13, 9);
    for (var index = 0; index < 5; index++) {
      await service.awardPoints(
        ProgressEventType.mockInterviewCompleted,
        refId: 'interview-$index',
        at: date,
        preferences: preferences,
      );
    }

    expect(service.totalPoints, 100);
  });

  test('calculates rank and node progression', () async {
    final service = ProgressService.instance;
    expect(service.rankFor(0), 'Cadet');
    expect(service.rankFor(120), 'Navigator');
    expect(service.currentNodeFor(121).id, 'skill-forge');
    expect(service.nextNodeFor(121)?.id, 'portfolio-station');
    expect(service.pointsToNextNode(121), 99);
  });
}
