import 'dart:math' as math;

class GpaCalculator {
  GpaCalculator._();

  static double remainingCredits({
    required int completedCredits,
    required int totalCredits,
  }) {
    return math.max(0, totalCredits - completedCredits).toDouble();
  }

  static double requiredRemainingGpa({
    required double currentGpa,
    required int completedCredits,
    required int totalCredits,
    required double targetGpa,
  }) {
    final remaining = totalCredits - completedCredits;

    if (remaining <= 0) {
      return currentGpa;
    }

    final currentPoints = currentGpa * completedCredits;
    final targetPoints = targetGpa * totalCredits;

    return (targetPoints - currentPoints) / remaining;
  }

  static double maxPossibleGpa({
    required double currentGpa,
    required int completedCredits,
    required int totalCredits,
    double maxGrade = 4.0,
  }) {
    final remaining = totalCredits - completedCredits;

    if (remaining <= 0) {
      return currentGpa;
    }

    final currentPoints = currentGpa * completedCredits;
    final maximumFuturePoints = remaining * maxGrade;

    return (currentPoints + maximumFuturePoints) / totalCredits;
  }

  static bool isTargetPossible({
    required double currentGpa,
    required int completedCredits,
    required int totalCredits,
    required double targetGpa,
    double maxGrade = 4.0,
  }) {
    return targetGpa <=
        maxPossibleGpa(
          currentGpa: currentGpa,
          completedCredits: completedCredits,
          totalCredits: totalCredits,
          maxGrade: maxGrade,
        );
  }

  static double projectedGpa({
    required double currentGpa,
    required int completedCredits,
    required List<FutureCourseResult> futureCourses,
  }) {
    final currentPoints = currentGpa * completedCredits;

    final futureCredits = futureCourses.fold<int>(
      0,
      (sum, course) => sum + course.credits,
    );

    final futurePoints = futureCourses.fold<double>(
      0,
      (sum, course) => sum + course.gradePoint * course.credits,
    );

    final totalCredits = completedCredits + futureCredits;

    if (totalCredits == 0) {
      return 0;
    }

    return (currentPoints + futurePoints) / totalCredits;
  }

  static double requiredTopGradeCredits({
    required double currentGpa,
    required int completedCredits,
    required int totalCredits,
    required double targetGpa,
    required double baselineRemainingGpa,
    double topGrade = 4.0,
  }) {
    final remaining = totalCredits - completedCredits;

    if (remaining <= 0 || topGrade <= baselineRemainingGpa) {
      return 0;
    }

    final currentPoints = currentGpa * completedCredits;
    final requiredFuturePoints = (targetGpa * totalCredits) - currentPoints;

    final baselinePoints = baselineRemainingGpa * remaining;

    final creditsAtTopGrade =
        (requiredFuturePoints - baselinePoints) /
        (topGrade - baselineRemainingGpa);

    return creditsAtTopGrade.clamp(0, remaining.toDouble());
  }
}

class FutureCourseResult {
  final int credits;
  final double gradePoint;

  const FutureCourseResult({required this.credits, required this.gradePoint});
}
