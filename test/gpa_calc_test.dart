import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/config/gpa_conversion_config.dart';
import 'package:uehero/models/gpa_models.dart';
import 'package:uehero/services/gpa_repository.dart';

GpaCourse _course({
  required String id,
  required String name,
  required int credits,
  required double score,
  required DateTime at,
  bool exclude = false,
  bool retake = false,
}) => GpaCourse(
  id: id,
  name: name,
  credits: credits,
  mode: GpaEntryMode.score10,
  gradeValue: score,
  createdAt: at,
  excludeFromGpa: exclude,
  isRetake: retake,
);

void main() {
  test('uses the documented assumed 10-point conversion thresholds', () {
    expect(gradeBandForScore10(8.5), GpaGradeBand.a);
    expect(gradeBandForScore10(8.0), GpaGradeBand.bPlus);
    expect(gradeBandForScore10(7.0), GpaGradeBand.b);
    expect(gradeBandForScore10(6.5), GpaGradeBand.cPlus);
    expect(gradeBandForScore10(5.5), GpaGradeBand.c);
    expect(gradeBandForScore10(5.0), GpaGradeBand.dPlus);
    expect(gradeBandForScore10(4.0), GpaGradeBand.d);
    expect(gradeBandForScore10(3.9), GpaGradeBand.f);
  });

  test('calculates weighted GPA and excludes non-GPA courses', () {
    final snapshot = GpaSnapshot.fromSemesters([
      GpaSemester(
        id: 'semester-1',
        name: 'Học kỳ 1',
        createdAt: DateTime(2025, 1),
        courses: [
          _course(
            id: 'course-a',
            name: 'Statistics',
            credits: 3,
            score: 8.5,
            at: DateTime(2025, 2),
          ),
          _course(
            id: 'course-b',
            name: 'Physical Education',
            credits: 2,
            score: 10,
            at: DateTime(2025, 2, 2),
            exclude: true,
          ),
          _course(
            id: 'course-c',
            name: 'History',
            credits: 2,
            score: 3.5,
            at: DateTime(2025, 2, 3),
          ),
        ],
      ),
    ]);

    expect(snapshot.currentGpa, closeTo((4 * 3 + 0 * 2) / 5, 0.001));
    expect(snapshot.gpaCredits, 5);
    expect(snapshot.earnedCredits, 3);
    expect(snapshot.countedCourses, hasLength(2));
  });

  test(
    'retake replaces the current grade without rewriting earlier trajectory',
    () {
      final snapshot = GpaSnapshot.fromSemesters([
        GpaSemester(
          id: 'semester-1',
          name: 'Học kỳ 1',
          createdAt: DateTime(2025, 1),
          courses: [
            _course(
              id: 'course-old',
              name: 'Statistics',
              credits: 3,
              score: 5.5,
              at: DateTime(2025, 2),
            ),
          ],
        ),
        GpaSemester(
          id: 'semester-2',
          name: 'Học kỳ 2',
          createdAt: DateTime(2025, 8),
          courses: [
            _course(
              id: 'course-retake',
              name: 'Statistics',
              credits: 3,
              score: 8.5,
              at: DateTime(2025, 9),
              retake: true,
            ),
            _course(
              id: 'course-new',
              name: 'Research',
              credits: 3,
              score: 7,
              at: DateTime(2025, 9, 2),
            ),
          ],
        ),
      ]);

      expect(snapshot.semesterGpas[0], closeTo(2, 0.001));
      expect(snapshot.cumulativeGpas[0], closeTo(2, 0.001));
      expect(snapshot.semesterGpas[1], closeTo((4 * 3 + 3 * 3) / 6, 0.001));
      expect(snapshot.currentGpa, closeTo(3.5, 0.001));
      expect(snapshot.countedCourses, hasLength(2));
      expect(snapshot.earnedCredits, 6);
    },
  );

  test('computes remaining-credit target and handles no credits remaining', () {
    expect(
      requiredGpaAverage(
        currentGpa: 3,
        earnedCredits: 60,
        gpaCredits: 60,
        programCredits: 120,
        targetGpa: 3.2,
      ),
      closeTo(3.4, 0.001),
    );
    expect(
      requiredGpaAverage(
        currentGpa: 3,
        earnedCredits: 120,
        gpaCredits: 120,
        programCredits: 120,
        targetGpa: 3.2,
      ),
      isNull,
    );
  });

  test('repository persists semesters, goals and CV consent locally', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = GpaRepository.instance..resetForTesting();
    await repository.load();
    await repository.createSemester('Mission One', createdAt: DateTime(2025));
    final semester = repository.semesters.single;
    await repository.saveCourse(
      semester.id,
      _course(
        id: 'c-1',
        name: 'Analytics',
        credits: 3,
        score: 8.5,
        at: DateTime(2025, 2),
      ),
    );
    await repository.setGoal(3.6, programCredits: 130);
    await repository.setCvConsent(true);

    final loaded = GpaRepository.instance..resetForTesting();
    await loaded.load();

    expect(loaded.semesters.single.courses.single.name, 'Analytics');
    expect(loaded.goalGpa, 3.6);
    expect(loaded.programCredits, 130);
    expect(loaded.gpaForCv, closeTo(4, 0.001));
  });
}
