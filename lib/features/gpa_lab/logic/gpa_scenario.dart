import '../../gpa_tracker/logic/gpa_calculator.dart';

class ScenarioCourse {
  final String id;
  final String name;
  final String shortCode;
  final int credits;

  final String? committedGradeLabel;
  final double? committedGradePoint;

  const ScenarioCourse({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.credits,
    this.committedGradeLabel,
    this.committedGradePoint,
  });

  bool get isAssigned => committedGradePoint != null;

  ScenarioCourse withGrade({
    required String gradeLabel,
    required double gradePoint,
  }) {
    return ScenarioCourse(
      id: id,
      name: name,
      shortCode: shortCode,
      credits: credits,
      committedGradeLabel: gradeLabel,
      committedGradePoint: gradePoint,
    );
  }
}

class GpaScenario {
  final double currentGpa;
  final int completedCredits;
  final double targetGpa;

  final List<ScenarioCourse> courses;

  const GpaScenario({
    required this.currentGpa,
    required this.completedCredits,
    required this.targetGpa,
    required this.courses,
  });

  int get assignedCount => courses.where((course) => course.isAssigned).length;

  int get totalCourseCount => courses.length;

  int get assignedCredits => courses
      .where((course) => course.isAssigned)
      .fold(0, (total, course) => total + course.credits);

  int get totalFutureCredits =>
      courses.fold(0, (total, course) => total + course.credits);

  bool get isComplete => assignedCount == totalCourseCount;

  double get projectedGpa {
    final assignedCourses = courses
        .where((course) => course.isAssigned)
        .toList();

    if (assignedCourses.isEmpty) {
      return currentGpa;
    }

    return GpaCalculator.projectedGpa(
      currentGpa: currentGpa,
      completedCredits: completedCredits,
      futureCourses: assignedCourses
          .map(
            (course) => FutureCourseResult(
              credits: course.credits,
              gradePoint: course.committedGradePoint!,
            ),
          )
          .toList(),
    );
  }

  double get gapToTarget => projectedGpa - targetGpa;

  ScenarioCourse? courseById(String courseId) {
    for (final course in courses) {
      if (course.id == courseId) {
        return course;
      }
    }

    return null;
  }

  GpaScenario assignGrade({
    required String courseId,
    required String gradeLabel,
    required double gradePoint,
  }) {
    return GpaScenario(
      currentGpa: currentGpa,
      completedCredits: completedCredits,
      targetGpa: targetGpa,
      courses: courses.map((course) {
        if (course.id != courseId) {
          return course;
        }

        return course.withGrade(gradeLabel: gradeLabel, gradePoint: gradePoint);
      }).toList(),
    );
  }
}
