import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/services/cv_score_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tracks best and previous best in the existing score history', () async {
    SharedPreferences.setMockInitialValues({});
    final store = CvScoreStore();

    final first = await store.record(
      score: 45,
      goalId: 'Frontend Developer',
      target: 'Frontend Developer',
    );
    expect(first.isFirstCheck, isTrue);
    expect(await store.bestScore(), 45);

    await store.record(
      score: 62,
      goalId: 'Frontend Developer',
      target: 'Frontend Developer',
    );
    expect(await store.bestScore(), 62);
    expect(await store.lastScore(), 62);
    expect(await store.previousBest(), 45);
  });

  test('caps first-check XP and awards only positive score increases', () {
    expect(cvCheckXp(score: 100, previousBest: 0, isFirstCheck: true), 20);
    expect(cvCheckXp(score: 62, previousBest: 45, isFirstCheck: false), 34);
    expect(cvCheckXp(score: 40, previousBest: 45, isFirstCheck: false), 0);
  });
}
