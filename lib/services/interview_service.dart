import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/interview_models.dart';
import '../models/career_progress.dart';
import 'points_manager.dart';
import 'progress_service.dart';

class InterviewService {
  InterviewService._();

  static final instance = InterviewService._();

  static const historyKey = 'interview_history';
  static const interviewDoneKey = 'career_map_interview_done';
  static const _dayKey = 'interview_usage_day';
  static const _usageKey = 'interview_usage_count';
  static const _extraKey = 'interview_extra_sessions';
  static const _questionAsset = 'assets/interview_questions.json';

  Map<String, dynamic>? _questionBank;

  Future<List<InterviewSession>> loadHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final decoded = jsonDecode(preferences.getString(historyKey) ?? '[]');
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map(
          (entry) =>
              InterviewSession.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList();
  }

  Future<int> remainingToday() async {
    final preferences = await SharedPreferences.getInstance();
    final today = _todayKey(DateTime.now());
    final used = preferences.getString(_dayKey) == today
        ? preferences.getInt(_usageKey) ?? 0
        : 0;
    final extras = preferences.getString(_dayKey) == today
        ? preferences.getInt(_extraKey) ?? 0
        : 0;
    return max(0, 2 + extras - used);
  }

  Future<bool> buyExtraSession() async {
    final preferences = await SharedPreferences.getInstance();
    final today = _todayKey(DateTime.now());
    final sameDay = preferences.getString(_dayKey) == today;
    final extras = sameDay ? preferences.getInt(_extraKey) ?? 0 : 0;
    if (!PointsManager.instance.trySpendPoints(50)) return false;
    await preferences.setString(_dayKey, today);
    await preferences.setInt(_extraKey, extras + 1);
    if (!sameDay) await preferences.setInt(_usageKey, 0);
    return true;
  }

  Future<bool> startSession() async {
    final preferences = await SharedPreferences.getInstance();
    final today = _todayKey(DateTime.now());
    final sameDay = preferences.getString(_dayKey) == today;
    var used = sameDay ? preferences.getInt(_usageKey) ?? 0 : 0;
    final extras = sameDay ? preferences.getInt(_extraKey) ?? 0 : 0;
    if (used >= 2 + extras) return false;
    await preferences.setString(_dayKey, today);
    if (!sameDay) await preferences.setInt(_extraKey, 0);
    await preferences.setInt(_usageKey, ++used);
    return true;
  }

  Future<List<InterviewQuestion>> questionsFor({
    required String career,
    required String mode,
    required int count,
  }) async {
    // TODO(interview-ai): use the existing chatbot service for selection and one follow-up once its API service exists.
    _questionBank ??= jsonDecode(
      await rootBundle.loadString(_questionAsset),
    ) as Map<String, dynamic>;
    final careerQuestions =
        _questionBank![career] as Map<String, dynamic>? ??
        _questionBank!['default'] as Map<String, dynamic>;
    final bank = (careerQuestions[mode] as List)
        .whereType<Map>()
        .map(
          (entry) =>
              InterviewQuestion.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList();
    bank.shuffle(Random(DateTime.now().microsecondsSinceEpoch));
    return bank.take(count).toList();
  }

  Map<String, dynamic> createFeedback(List<Map<String, dynamic>> responses) {
    var total = 0;
    final scored = <Map<String, dynamic>>[];
    final weakSkills = <String>{};
    for (var index = 0; index < responses.length; index++) {
      final response = responses[index];
      final answer = (response['answer'] as String? ?? '').trim();
      final skipped = response['skipped'] == true;
      final words = answer
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .length;
      final skill = response['skill'] as String? ?? '';
      final answerLower = answer.toLowerCase();
      final expectedTerms = _termsForSkill(skill);
      final matchedTerms = expectedTerms.where(answerLower.contains).length;
      final hasExample = RegExp(
        r'\b(ví dụ|chẳng hạn|kết quả|tăng|giảm|%|dự án)\b',
        caseSensitive: false,
      ).hasMatch(answer);
      final clarityScore = words >= 25
          ? 85
          : words >= 12
          ? 65
          : 35;
      final exampleScore = hasExample ? 80 : 35;
      final accuracyScore = expectedTerms.isEmpty
          ? (words >= 12 ? 65 : 30)
          : ((matchedTerms / expectedTerms.length) * 100).round();
      final score = skipped
          ? 0
          : min(
              100,
              (accuracyScore * 0.55 + clarityScore * 0.25 + exampleScore * 0.20)
                  .round(),
            );
      total += score;
      if (score < 55 && skill.isNotEmpty) weakSkills.add(skill);
      scored.add({
        ...response,
        'score': score,
        'accuracy_score': skipped ? 0 : accuracyScore,
        'clarity_score': skipped ? 0 : clarityScore,
        'example_score': skipped ? 0 : exampleScore,
        'accuracy': skipped
            ? 'Câu hỏi được bỏ qua, chưa có nội dung để đánh giá.'
            : matchedTerms > 0
            ? 'Có đề cập $matchedTerms ý chuyên môn liên quan; hãy kiểm tra độ chính xác.'
            : 'Cần bổ sung quy trình, khái niệm và căn cứ chuyên môn.',
        'clarity': words >= 25
            ? 'Trình bày có đủ ý; thử sắp xếp theo từng bước.'
            : 'Nên trả lời theo cấu trúc ngắn gọn, có mở đầu và kết luận.',
        'example': hasExample
            ? 'Có nhắc tới ví dụ hoặc kết quả cụ thể.'
            : 'Thêm ví dụ thực tế và kết quả đo lường được.',
        'suggestion':
            'Nêu bối cảnh, việc bạn trực tiếp làm và kết quả; gắn với ${skill.isEmpty ? 'nghề mục tiêu' : skill}.',
      });
    }
    return {
      'overall': responses.isEmpty ? 0 : (total / responses.length).round(),
      'questions': scored,
      'weak_skills': weakSkills.toList(),
    };
  }

  List<String> _termsForSkill(String skill) {
    final normalized = skill.toLowerCase();
    if (normalized.contains('sql')) {
      return ['select', 'join', 'where', 'group by'];
    }
    if (normalized.contains('power bi')) {
      return ['dashboard', 'kpi', 'filter', 'measure'];
    }
    if (normalized.contains('excel')) {
      return ['công thức', 'pivot', 'đối chiếu', 'dữ liệu'];
    }
    if (normalized.contains('thống kê')) {
      return ['trung bình', 'trung vị', 'phương sai', 'ngoại lệ'];
    }
    if (normalized.contains('giao tiếp')) {
      return ['lắng nghe', 'xác nhận', 'trao đổi', 'phản hồi'];
    }
    if (normalized.contains('yêu cầu')) {
      return ['phạm vi', 'tiêu chí', 'xác nhận', 'stakeholder'];
    }
    if (normalized.contains('marketing')) {
      return ['mục tiêu', 'audience', 'kpi', 'chuyển đổi'];
    }
    if (normalized.contains('người dùng')) {
      return ['phỏng vấn', 'nhu cầu', 'giả thuyết', 'kiểm chứng'];
    }
    if (normalized.contains('phân tích') || normalized.contains('dữ liệu')) {
      return ['dữ liệu', 'nguyên nhân', 'tác động', 'ưu tiên'];
    }
    if (normalized.contains('git')) {
      return ['branch', 'commit', 'review', 'merge'];
    }
    return const [];
  }

  Future<void> saveCompleted(InterviewSession session) async {
    final preferences = await SharedPreferences.getInstance();
    final current = await loadHistory();
    final completed = InterviewSession(
      id: session.id,
      career: session.career,
      mode: session.mode,
      difficulty: session.difficulty,
      startedAt: session.startedAt,
      durationSeconds: session.durationSeconds,
      responses: session.responses,
      feedback: session.feedback,
    );
    current.removeWhere((entry) => entry.id == session.id);
    current.insert(0, completed);
    await preferences.setString(
      historyKey,
      jsonEncode(current.take(20).map((entry) => entry.toJson()).toList()),
    );
    // TODO(career-map): connect this key to the milestone-completion store.
    await preferences.setBool(interviewDoneKey, true);
    PointsManager.instance.addCvPoints(30);
    if (completed.overall >= 70) PointsManager.instance.addCvPoints(10);
    await ProgressService.instance.initialize();
    await ProgressService.instance.awardPoints(
      ProgressEventType.mockInterviewCompleted,
      refId: 'mock-interview-${completed.id}',
      metadata: {'overall': completed.overall},
    );
  }

  String _todayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
