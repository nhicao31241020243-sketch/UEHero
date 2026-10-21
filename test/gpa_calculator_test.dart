import 'package:flutter_test/flutter_test.dart';
import 'package:uehero/features/gpa_tracker/logic/gpa_calculator.dart';

void main() {
  group('GpaCalculator', () {
    test('tính GPA cần đạt cho số tín chỉ còn lại', () {
      final result = GpaCalculator.requiredRemainingGpa(
        currentGpa: 3.42,
        completedCredits: 88,
        totalCredits: 120,
        targetGpa: 3.50,
      );

      expect(result, closeTo(3.72, 0.001));
    });

    test('tính GPA tối đa có thể đạt', () {
      final result = GpaCalculator.maxPossibleGpa(
        currentGpa: 3.42,
        completedCredits: 88,
        totalCredits: 120,
      );

      expect(result, closeTo(3.5747, 0.001));
    });

    test('nhận diện target 3.50 là khả thi', () {
      final result = GpaCalculator.isTargetPossible(
        currentGpa: 3.42,
        completedCredits: 88,
        totalCredits: 120,
        targetGpa: 3.50,
      );

      expect(result, isTrue);
    });

    test('nhận diện target 3.60 là không khả thi', () {
      final result = GpaCalculator.isTargetPossible(
        currentGpa: 3.42,
        completedCredits: 88,
        totalCredits: 120,
        targetGpa: 3.60,
      );

      expect(result, isFalse);
    });

    test('tính GPA dự kiến từ các môn tương lai', () {
      final result = GpaCalculator.projectedGpa(
        currentGpa: 3.42,
        completedCredits: 88,
        futureCourses: const [
          FutureCourseResult(credits: 3, gradePoint: 4.0),
          FutureCourseResult(credits: 3, gradePoint: 3.5),
          FutureCourseResult(credits: 3, gradePoint: 4.0),
        ],
      );

      expect(result, closeTo(3.45835, 0.001));
    });
  });
}
