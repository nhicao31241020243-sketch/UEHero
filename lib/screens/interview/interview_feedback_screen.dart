import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/character_data.dart';
import '../../models/interview_models.dart';
import '../../services/interview_service.dart';
import 'interview_room_screen.dart';

class InterviewFeedbackScreen extends StatefulWidget {
  const InterviewFeedbackScreen({
    required this.session,
    required this.mascot,
    this.allowRetry = true,
    super.key,
  });

  final InterviewSession session;
  final CharacterData mascot;
  final bool allowRetry;

  @override
  State<InterviewFeedbackScreen> createState() =>
      _InterviewFeedbackScreenState();
}

class _InterviewFeedbackScreenState extends State<InterviewFeedbackScreen> {
  static const _background = Color(0xFF100E19);
  static const _surface = Color(0xFF211D2B);
  static const _flashcardsKey = 'study_flashcards';

  int _selectedQuestion = 0;
  bool _restarting = false;

  List<Map<String, dynamic>> get _questions {
    final raw = widget.session.feedback?['questions'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  List<String> get _weakSkills {
    final raw = widget.session.feedback?['weak_skills'];
    if (raw is! List) return [];
    return raw.whereType<String>().toList();
  }

  Future<void> _retry() async {
    if (_restarting) return;
    setState(() => _restarting = true);
    try {
      final allowed = await InterviewService.instance.startSession();
      if (!allowed) {
        _message('Hết lượt hôm nay hoặc chưa đủ 50 điểm để mở thêm lượt.');
        return;
      }
      final questions = await InterviewService.instance.questionsFor(
        career: widget.session.career,
        mode: widget.session.mode,
        count: 6,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => InterviewRoomScreen(
            initialSession: InterviewSession(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              career: widget.session.career,
              mode: widget.session.mode,
              difficulty: widget.session.difficulty,
              startedAt: DateTime.now(),
              durationSeconds: 0,
              responses: const [],
            ),
            questions: questions,
            mascot: widget.mascot,
          ),
        ),
      );
    } on Exception catch (error) {
      _message('Không thể bắt đầu lại: $error');
    } finally {
      if (mounted) setState(() => _restarting = false);
    }
  }

  Future<void> _createWeakSkillFlashcards() async {
    if (_weakSkills.isEmpty) {
      _message('Chưa có kỹ năng yếu được ghi nhận trong buổi này.');
      return;
    }
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_flashcardsKey) ?? '[]';
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Flashcard data is not a list.');
      }
      final cards = decoded
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .toList();
      for (final skill in _weakSkills) {
        cards.insert(0, {
          'question':
              'Ôn tập kỹ năng $skill trong phỏng vấn ${widget.session.career}',
          'answer':
              'Chuẩn bị một câu trả lời có bối cảnh, cách bạn xử lý và kết quả cụ thể về kỹ năng $skill.',
          'subject': skill,
          'createdAt': DateTime.now().toIso8601String(),
          'source': 'interview',
        });
      }
      await preferences.setString(_flashcardsKey, jsonEncode(cards));
      _message(
        'Đã thêm ${_weakSkills.length} thẻ vào study_flashcards. TODO: mở màn Flashcard.',
      );
    } on FormatException catch (error) {
      _message('Không thể đọc kho flashcard: $error');
    } on Exception catch (error) {
      _message('Không thể lưu flashcard: $error');
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    final current = questions.isEmpty
        ? const <String, dynamic>{}
        : questions[_selectedQuestion.clamp(0, questions.length - 1)];
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        title: const Text(
          'Nhận xét phỏng vấn',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_background, Color(0xFF171326), _background],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          children: [
            _buildScoreCard(),
            const SizedBox(height: 14),
            if (questions.isNotEmpty) ...[
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: questions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => ChoiceChip(
                    label: Text('${index + 1}'),
                    selected: index == _selectedQuestion,
                    onSelected: (_) => setState(() => _selectedQuestion = index),
                    selectedColor: const Color(0xFFBFA8FF),
                    backgroundColor: _surface,
                    labelStyle: TextStyle(
                      color: index == _selectedQuestion
                          ? const Color(0xFF211A30)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _section(
                title: 'Câu hỏi',
                child: Text(
                  current['question']?.toString() ?? 'Chưa có câu hỏi.',
                  style: const TextStyle(color: Colors.white, height: 1.4),
                ),
              ),
              _section(
                title: 'Câu trả lời của bạn',
                child: Text(
                  (current['answer'] as String?)?.isNotEmpty == true
                      ? current['answer'] as String
                      : 'Bạn đã bỏ qua câu hỏi này.',
                  style: const TextStyle(
                    color: Color(0xFFCFC7DC),
                    height: 1.45,
                  ),
                ),
              ),
              _section(
                title: 'Đánh giá câu trả lời',
                child: Column(
                  children: [
                    _ratingRow(
                      'Độ chính xác nội dung',
                      current['accuracy_score'] as num? ??
                          current['score'] as num? ??
                          0,
                      current['accuracy']?.toString() ?? '',
                    ),
                    _ratingRow(
                      'Cách diễn đạt / độ rõ ràng',
                      current['clarity_score'] as num? ??
                          current['score'] as num? ??
                          0,
                      current['clarity']?.toString() ?? '',
                    ),
                    _ratingRow(
                      'Ví dụ cụ thể',
                      current['example_score'] as num? ??
                          (current['example']?.toString().startsWith('Có') ==
                                  true
                              ? 75
                              : 35),
                      current['example']?.toString() ?? '',
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Gợi ý cải thiện: ${current['suggestion'] ?? 'Nêu thêm ví dụ cụ thể.'}',
                        style: const TextStyle(
                          color: Color(0xFFFFD36E),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            _section(
              title: 'Kỹ năng cần củng cố',
              child: _weakSkills.isEmpty
                  ? const Text(
                      'Chưa phát hiện kỹ năng cần củng cố từ câu trả lời này.',
                      style: TextStyle(color: Color(0xFFCFC7DC)),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final skill in _weakSkills)
                          Chip(
                            label: Text(skill),
                            avatar: const Icon(
                              Icons.auto_stories_rounded,
                              size: 16,
                            ),
                            backgroundColor: const Color(0xFF302547),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                      ],
                    ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 5, bottom: 12),
              child: Text(
                'Đánh giá tham khảo, không phải kết quả chính thức.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFAAA5B8), fontSize: 12),
              ),
            ),
            if (widget.allowRetry)
              _actionButton(
                label: 'Phỏng vấn lại',
                icon: Icons.replay_rounded,
                onPressed: _restarting ? null : _retry,
                primary: true,
              ),
            const SizedBox(height: 8),
            _actionButton(
              label: 'Ôn thẻ kỹ năng yếu',
              icon: Icons.style_rounded,
              onPressed: _createWeakSkillFlashcards,
            ),
            const SizedBox(height: 8),
            _actionButton(
              label: 'Thêm việc luyện lại vào Kế hoạch tuần',
              icon: Icons.event_note_rounded,
              onPressed: () => _message(
                'TODO(calendar): nối API tạo việc luyện kỹ năng vào Kế hoạch tuần.',
              ),
            ),
            const SizedBox(height: 8),
            _actionButton(
              label: 'Về trang Phỏng vấn',
              icon: Icons.home_outlined,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    final score = widget.session.overall;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFBFA8FF).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 118,
            height: 118,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    backgroundColor: const Color(0xFF393445),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF70D8F2)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      '/ 100',
                      style: TextStyle(color: Color(0xFFAAA5B8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.session.career,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${widget.session.durationSeconds ~/ 60} phút · ${widget.session.difficulty}',
            style: const TextStyle(color: Color(0xFFAAA5B8), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _ratingRow(String label, num score, String comment) {
    final percent = score.toDouble().clamp(0.0, 100.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${percent.round()}%',
                style: const TextStyle(
                  color: Color(0xFF70D8F2),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 7,
              backgroundColor: const Color(0xFF393445),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF70D8F2)),
            ),
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              comment,
              style: const TextStyle(
                color: Color(0xFFAAA5B8),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) => Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(19),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        child,
      ],
    ),
  );

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool primary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: primary
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.replay_rounded),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBFA8FF),
                foregroundColor: const Color(0xFF211A30),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
    );
  }
}
