import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/config/xp_stages.dart';
import 'package:uehero/models/app_task.dart';
import 'package:uehero/models/xp_entry.dart';
import 'package:uehero/services/points_manager.dart';
import 'package:uehero/services/task_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PointsManager points;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    points = PointsManager.instance..resetForTesting();
    TaskRepository.instance.resetForTesting();
  });

  test('addXP writes the ledger and returns only newly applied XP', () async {
    final preferences = await SharedPreferences.getInstance();

    final added = await points.addXP(
      thanh: XpBar.kienThuc,
      luong: 120,
      nguon: 'course_completion',
      sourceRef: 'course-1',
      preferences: preferences,
    );
    final duplicate = await points.addXP(
      thanh: XpBar.kienThuc,
      luong: 120,
      nguon: 'course_completion',
      sourceRef: 'course-1',
      preferences: preferences,
    );

    expect(added, 120);
    expect(duplicate, 0);
    expect(points.totalXp, 120);
    expect(points.totalXpByBar(XpBar.kienThuc), 120);
    expect(points.entries.single.toJson(), containsPair('thanh', 'kienThuc'));
    expect(preferences.getString('xp_log_v1'), isNotNull);
  });

  test(
    'daily caps are source-specific and uncapped sources remain unlimited',
    () async {
      final preferences = await SharedPreferences.getInstance();
      PointsManager.dailyCaps['test_limited'] = 50;

      final first = await points.addXP(
        thanh: XpBar.kienThuc,
        luong: 40,
        nguon: 'test_limited',
        sourceRef: 'card-1',
        preferences: preferences,
      );
      final capped = await points.addXP(
        thanh: XpBar.kienThuc,
        luong: 40,
        nguon: 'test_limited',
        sourceRef: 'card-2',
        preferences: preferences,
      );
      final uncapped = await points.addXP(
        thanh: XpBar.hoSo,
        luong: 250,
        nguon: 'manual_award',
        preferences: preferences,
      );

      expect(first, 40);
      expect(capped, 10);
      expect(uncapped, 250);
    },
  );

  test(
    'stage and progress use the ledger total; demo unlocks every feature',
    () async {
      await points.addXP(
        thanh: XpBar.kienThuc,
        luong: 150,
        nguon: 'stage_test',
      );

      expect(points.currentStage.id, 2);
      expect(points.stageProgress, closeTo(0.25, 0.001));
      expect(points.unlockedFeatures, containsAll(['CV', 'Flashcard', 'Tay']));
      expect(
        featuresUnlockedForXp(0, demoMode: true),
        containsAll(['Mentor', 'Khóa học', 'Cơ hội nghề nghiệp']),
      );
    },
  );

  test('completing an XP task awards once; manual tasks award none', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = TaskRepository.instance;
    await repository.add(
      const AppTask(
        id: 'cv-1',
        nguon: 'CV',
        noiDung: 'Hoàn thành CV',
        trangThai: TaskStatus.pending,
        thanh: XpBar.hoSo,
        luongXp: 30,
      ),
      preferences: preferences,
    );
    await repository.add(
      const AppTask(
        id: 'manual-1',
        nguon: 'Tay',
        noiDung: 'Việc tự tạo',
        trangThai: TaskStatus.pending,
      ),
      preferences: preferences,
    );

    await repository.complete('cv-1', preferences: preferences);
    await repository.complete('cv-1', preferences: preferences);
    await repository.complete('manual-1', preferences: preferences);

    expect(points.totalXpByBar(XpBar.hoSo), 30);
    expect(
      (await repository.list(preferences: preferences))
          .every((task) => task.trangThai == TaskStatus.completed),
      isTrue,
    );
  });

  test('migrates the old progress ledger into the unified XP log', () async {
    SharedPreferences.setMockInitialValues({
      'career_progress_ledger_v1': '[{"eventType":"jobApplied","points":10,"timestamp":"2026-10-14T00:00:00.000","refId":"job-1"}]',
    });
    final preferences = await SharedPreferences.getInstance();
    points.resetForTesting();

    await points.initialize(preferences: preferences);

    expect(points.totalXp, 10);
    expect(points.entries.single.nguon, 'jobApplied');
    expect(points.entries.single.thanh, XpBar.hoSo);
  });
}
