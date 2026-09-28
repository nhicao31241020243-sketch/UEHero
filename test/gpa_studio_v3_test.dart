import 'package:flutter_test/flutter_test.dart';

import 'package:uehero/features/gpa_studio_v3/scenario.dart';
import 'package:uehero/features/gpa_studio_v3/controller.dart';

void main() {
  group('Synthetic academic scenario', () {
    test('six courses in fixed order, totaling 20 credits', () {
      final s = StudioScenario.demo();
      expect(s.courses.map((c) => c.code), [
        'AI',
        'TI',
        'MB',
        'DB',
        'QA',
        'UX',
      ]);
      expect(s.totalFutureCredits, 20);
      expect(s.completedCredits, 77);
      expect(s.currentGpa, closeTo(3.47, 1e-12));
    });
    test('Balanced projection uses weighted quality points', () {
      final s = StudioScenario.demo();
      expect(s.futureQualityUnits, 7150);
      expect(s.projectedGpa, closeTo(33869 / 9700, 1e-10));
      expect(s.projectedGpa.toStringAsFixed(2), '3.49');
      expect(s.fullScenarioMeetsTarget, isFalse);
    });
    test('empty plan is a partial estimate, not all Fs', () {
      final s = StudioScenario.demo().copy(grades: {});
      expect(s.plannedCount, 0);
      expect(s.projectedGpa, closeTo(3.47, 1e-12));
      expect(s.isComplete, isFalse);
      expect(s.fullScenarioMeetsTarget, isFalse);
      expect(s.termFloor, closeTo(26719 / 9700, 1e-10));
    });
    test('unplanned and F have different denominators', () {
      final blank = StudioScenario.demo().copy(grades: {});
      final failed = blank.setGrade('ai_project', 0);
      expect(failed.plannedCredits, 3);
      expect(failed.projectedGpa, closeTo(26719 / 8000, 1e-10));
      expect(failed.projectedGpa, lessThan(blank.projectedGpa));
      expect(
        failed.setGrade('ai_project', null).projectedGpa,
        closeTo(3.47, 1e-10),
      );
    });
    test('many courses can share the same A grade', () {
      final s = StudioScenario.demo();
      final a = s.copy(grades: {for (final c in s.courses) c.id: 400});
      expect(a.plannedCount, 6);
      expect(a.projectedGpa, closeTo(34719 / 9700, 1e-10));
      expect(a.fullScenarioMeetsTarget, isTrue);
    });
    test('changing 5 credits has more impact than changing 3 credits', () {
      final s = StudioScenario.demo();
      final tiDelta =
          s.setGrade('internship', 400).projectedGpa - s.projectedGpa;
      final aiDelta =
          s.setGrade('ai_project', 400).projectedGpa - s.projectedGpa;
      expect(tiDelta / aiDelta, closeTo(5 / 3, 1e-9));
    });
    test('required mean and all-A ceiling use the same 20-credit horizon', () {
      final s = StudioScenario.demo();
      expect(s.requiredWholeTermMean, closeTo(3.6155, 1e-10));
      expect(s.allACeiling, closeTo(3.579278350515464, 1e-10));
    });
    test('target feasibility must not use a rounded 3.58 ceiling', () {
      final s = StudioScenario.demo().copy(targetUnits: 358);
      expect(s.allACeiling.toStringAsFixed(2), '3.58');
      expect(s.targetPossibleFromBase, isFalse);
      expect(s.minimumACreditPlan, isNull);
    });
    test(
      'whole-course A plan rounds to a reachable bundle, not 4.62 credits',
      () {
        final plan = StudioScenario.demo().minimumACreditPlan!;
        expect(plan.credits, 5);
        expect(plan.courseIds, ['internship']);
      },
    );
    test('A-credit route is an explicitly different full-term plan', () {
      final s = StudioScenario.demo();
      final p = s.minimumACreditPlan!;
      final route = s.copy(
        grades: {
          for (final c in s.courses)
            c.id: p.courseIds.contains(c.id) ? 400 : 350,
        },
      );
      expect(route.fullScenarioMeetsTarget, isTrue);
      expect(s.grades['internship'], 350);
    });
    test('partial bounds hold the assigned grade fixed', () {
      final s = StudioScenario.demo()
          .copy(grades: {})
          .setGrade('ai_project', 400);
      expect(s.unplannedCredits, 17);
      expect(s.termFloor, closeTo(27919 / 9700, 1e-10));
      expect(s.termCeilingWithPlan, closeTo(34719 / 9700, 1e-10));
      expect(s.requiredUnplannedMean, closeTo(6031 / 1700, 1e-10));
    });
    test('complete plan has no unplanned average', () {
      expect(StudioScenario.demo().requiredUnplannedMean, isNull);
    });
    test('unknown course and unsupported grade fail loudly', () {
      final s = StudioScenario.demo();
      expect(() => s.setGrade('not-a-course', 350), throwsArgumentError);
      expect(() => s.setGrade('ai_project', 399), throwsArgumentError);
      expect(() => s.copy(targetUnits: 450), throwsArgumentError);
    });
    test('duplicate IDs and zero-credit courses are rejected', () {
      final c = StudioScenario.demoCourses.first;
      expect(
        () => StudioScenario(
          completedCredits: 0,
          completedQualityUnits: 0,
          targetUnits: 350,
          courses: [c, c],
        ),
        throwsArgumentError,
      );
      expect(
        () => StudioScenario(
          completedCredits: 0,
          completedQualityUnits: 0,
          targetUnits: 350,
          courses: const [
            StudioCourse(
              id: 'x',
              name: 'X',
              code: 'X',
              credits: 0,
              colorValue: 0,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
    test('maps and course lists cannot be changed by callers', () {
      final s = StudioScenario.demo();
      expect(() => s.grades['ai_project'] = 0, throwsUnsupportedError);
      expect(() => s.courses.clear(), throwsUnsupportedError);
    });
    test('zero completed credits has a defined empty projection', () {
      final s = StudioScenario(
        completedCredits: 0,
        completedQualityUnits: 0,
        targetUnits: 350,
        courses: StudioScenario.demoCourses,
      );
      expect(s.currentGpa, 0);
      expect(s.projectedGpa, 0);
      expect(s.setGrade('ai_project', 400).projectedGpa, 4);
    });
    test('export clearly marks synthetic data', () {
      expect(StudioScenario.demo().toJson()['syntheticDemo'], isTrue);
    });
  });

  group('Controller is the only editing state', () {
    late StudioController c;
    setUp(() {
      c = StudioController();
    });
    tearDown(() {
      c.dispose();
    });
    test('selection is not a grade edit', () {
      final before = c.committed;
      c.select('internship');
      expect(c.committed, same(before));
      expect(c.canUndo, isFalse);
    });
    test('drag previews affect the display, not committed data', () {
      c.previewGrade('ai_project', 400);
      expect(c.display.grades['ai_project'], 400);
      expect(c.committed.grades['ai_project'], 350);
      expect(c.hasPreview, isTrue);
      c.cancelPreview();
      expect(c.display.grades['ai_project'], 350);
      expect(c.canUndo, isFalse);
    });
    test('multiple preview ticks create one undo entry on release', () {
      c.previewGrade('ai_project', 300);
      c.previewGrade('ai_project', 370);
      c.previewGrade('ai_project', 400);
      c.commitPreview();
      expect(c.committed.grades['ai_project'], 400);
      expect(c.hasPreview, isFalse);
      c.undo();
      expect(c.committed.grades['ai_project'], 350);
      expect(c.canUndo, isFalse);
    });
    test('same grade is an idempotent edit', () {
      c.setGrade('ai_project', 350);
      expect(c.canUndo, isFalse);
      expect(c.lastImpact, isNull);
    });
    test('target drag never edits grades', () {
      final grades = c.committed.grades;
      c.previewTarget(360);
      expect(c.display.target, 3.6);
      expect(c.committed.target, 3.5);
      c.commitPreview();
      expect(c.committed.grades, grades);
      c.undo();
      expect(c.committed.target, 3.5);
    });
    test('presets have reproducible projections', () {
      c.preset('Stretch');
      expect(c.display.projectedGpa, closeTo(34169 / 9700, 1e-10));
      expect(c.display.fullScenarioMeetsTarget, isTrue);
      c.preset('All A');
      expect(c.display.projectedGpa, closeTo(34719 / 9700, 1e-10));
      c.preset('Blank');
      expect(c.display.plannedCount, 0);
      expect(c.display.projectedGpa, closeTo(3.47, 1e-12));
    });
    test('course ordering never follows assigned/unassigned status', () {
      final before = c.display.courses.map((e) => e.id).toList();
      c.setGrade('ai_project', null);
      c.setGrade('database', 400);
      expect(c.display.courses.map((e) => e.id).toList(), before);
    });
    test('undo resets all derived values together', () {
      final before = c.display.projectedGpa;
      c.setGrade('internship', 0);
      expect(c.display.projectedGpa, lessThan(before));
      c.undo();
      expect(c.display.projectedGpa, closeTo(before, 1e-12));
      expect(c.display.plannedCredits, 20);
    });
  });
}
