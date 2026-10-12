import 'package:flutter_test/flutter_test.dart';
import 'package:uehero/services/interview_service.dart';
import 'package:uehero/models/interview_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/services/points_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InterviewService', () {
    test('question bank keeps 21 prompts per career across modes', () async {
      for (final mode in ['intern', 'fresher', 'behavioral']) {
        final questions = await InterviewService.instance.questionsFor(
          career: 'Business Analyst',
          mode: mode,
          count: 30,
        );
        expect(questions, hasLength(7));
        expect(questions.every((question) => question.hint.isNotEmpty), isTrue);
      }
    });

    test('daily limit can be expanded with 50 points', () async {
      SharedPreferences.setMockInitialValues({});
      final service = InterviewService.instance;
      expect(await service.remainingToday(), 2);
      expect(await service.startSession(), isTrue);
      expect(await service.startSession(), isTrue);
      expect(await service.startSession(), isFalse);

      PointsManager.instance.addCvPoints(50);
      expect(await service.buyExtraSession(), isTrue);
      expect(await service.remainingToday(), 1);
      expect(await service.startSession(), isTrue);
      expect(await service.remainingToday(), 0);
    });

    test('fallback feedback scores substantive and skipped answers', () {
      final feedback = InterviewService.instance.createFeedback([
        {
          'index': 0,
          'question': 'Bạn dùng SQL thế nào?',
          'answer':
              'Dùng SELECT và JOIN để lấy dữ liệu, sau đó GROUP BY để tổng hợp. '
              'Ví dụ, đối chiếu kết quả với báo cáo nguồn.',
          'skill': 'SQL',
          'skipped': false,
        },
        {
          'index': 1,
          'question': 'Câu hỏi tiếp theo',
          'answer': '',
          'skill': 'Excel',
          'skipped': true,
        },
      ]);

      expect(feedback['overall'], greaterThan(0));
      final questions = feedback['questions'] as List;
      expect(questions[0]['score'], greaterThan(0));
      expect(questions[1]['score'], 0);
      expect(feedback['weak_skills'], contains('Excel'));
    });
  });

  test('interview session serializes and restores feedback/history fields', () {
    final session = InterviewSession(
      id: 'test-1',
      career: 'Business Analyst',
      mode: 'intern',
      difficulty: 'Vừa',
      startedAt: DateTime(2026, 10, 12),
      durationSeconds: 95,
      responses: const [
        {'question': 'Câu hỏi', 'answer': 'Câu trả lời'},
      ],
      feedback: const {'overall': 72},
    );

    final restored = InterviewSession.fromJson(session.toJson());

    expect(restored.id, session.id);
    expect(restored.overall, 72);
    expect(restored.durationSeconds, 95);
    expect(restored.responses.single['answer'], 'Câu trả lời');
  });
}
