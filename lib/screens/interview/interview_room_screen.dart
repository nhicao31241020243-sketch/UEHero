import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/character_data.dart';
import '../../models/interview_models.dart';
import '../../services/interview_service.dart';
import '../../widgets/interview/answer_pill.dart';
import '../../widgets/interview/interview_control_bar.dart';
import '../../widgets/interview/interview_stage.dart';
import '../../widgets/interview/voice_orb.dart';
import 'interview_feedback_screen.dart';

class InterviewRoomScreen extends StatefulWidget {
  const InterviewRoomScreen({
    required this.initialSession,
    required this.questions,
    required this.mascot,
    super.key,
  });

  final InterviewSession initialSession;
  final List<InterviewQuestion> questions;
  final CharacterData mascot;

  @override
  State<InterviewRoomScreen> createState() => _InterviewRoomScreenState();
}

class _InterviewRoomScreenState extends State<InterviewRoomScreen>
    with WidgetsBindingObserver {
  static const _accent = Color(0xFFBFA8FF);
  final _answerController = TextEditingController();
  final _responses = <Map<String, dynamic>>[];
  Timer? _elapsedTimer;
  Timer? _typingTimer;
  late final DateTime _startedAt;
  int _questionIndex = 0;
  int _visibleCharacters = 0;
  int _elapsedSeconds = 0;
  int _hintsUsed = 0;
  bool _questionReady = false;
  bool _followUp = false;
  bool _busy = false;
  bool _finished = false;
  bool _foreground = true;
  bool _allowPop = false;

  InterviewQuestion get _question => widget.questions[_questionIndex];

  String get _questionText {
    if (!_followUp) return _question.text;
    return 'Puoi chia sẻ thêm một chi tiết hoặc ví dụ cụ thể cho câu trả lời vừa rồi?';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startedAt = widget.initialSession.startedAt;
    _startTimer();
    _typeQuestion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _startTimer();
      _typeQuestion();
    } else {
      _elapsedTimer?.cancel();
      _typingTimer?.cancel();
    }
  }

  void _startTimer() {
    if (!_foreground || _finished || (_elapsedTimer?.isActive ?? false)) return;
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(_startedAt).inSeconds;
      setState(() => _elapsedSeconds = elapsed);
      if (elapsed >= 15 * 60) _finish();
    });
  }

  void _typeQuestion() {
    _typingTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _visibleCharacters = 0;
      _questionReady = false;
    });
    _typingTimer = Timer.periodic(const Duration(milliseconds: 24), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final length = _questionText.characters.length;
      if (_visibleCharacters >= length) {
        timer.cancel();
        setState(() => _questionReady = true);
      } else {
        setState(() => _visibleCharacters += 1);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _elapsedTimer?.cancel();
    _typingTimer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  String get _elapsedLabel {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _confirmExit() async {
    final exit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF211D2B),
        title: const Text(
          'Thoát buổi phỏng vấn?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tiến độ sẽ không được lưu.',
          style: TextStyle(color: Color(0xFFCFC7DC)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ở lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
    if (exit == true && mounted) {
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  Future<void> _submitAnswer() async {
    final answer = _answerController.text.trim();
    if (_busy || !_questionReady || answer.isEmpty) return;
    setState(() => _busy = true);
    _responses.add({
      'index': _questionIndex,
      'question': _questionText,
      'answer': answer,
      'skill': _question.skill,
      'skipped': false,
      'followUp': _followUp,
    });
    _answerController.clear();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    // TODO(interview-ai): choose a focused follow-up using the recent answer once the chat API is available.
    if (!_followUp && answer.split(RegExp(r'\s+')).length < 20) {
      setState(() {
        _busy = false;
        _followUp = true;
      });
      _typeQuestion();
      return;
    }
    await _moveNext();
  }

  Future<void> _skipQuestion() async {
    if (_busy || !_questionReady) return;
    final skip = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF211D2B),
        title: const Text(
          'Bỏ qua câu này?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Câu bị bỏ qua sẽ nhận 0 điểm.',
          style: TextStyle(color: Color(0xFFCFC7DC)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Quay lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Bỏ qua'),
          ),
        ],
      ),
    );
    if (skip != true || !mounted) return;
    _responses.add({
      'index': _questionIndex,
      'question': _questionText,
      'answer': '',
      'skill': _question.skill,
      'skipped': true,
      'followUp': _followUp,
    });
    await _moveNext();
  }

  Future<void> _moveNext() async {
    if (_followUp) {
      _questionIndex += 1;
      _followUp = false;
    } else {
      _questionIndex += 1;
    }
    if (_questionIndex >= widget.questions.length) {
      await _finish();
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
    });
    _typeQuestion();
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    _elapsedTimer?.cancel();
    _typingTimer?.cancel();
    if (mounted) {
      setState(() => _busy = true);
    }
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final feedback = InterviewService.instance.createFeedback(_responses);
    final session = InterviewSession(
      id: widget.initialSession.id,
      career: widget.initialSession.career,
      mode: widget.initialSession.mode,
      difficulty: widget.initialSession.difficulty,
      startedAt: widget.initialSession.startedAt,
      durationSeconds: DateTime.now()
          .difference(widget.initialSession.startedAt)
          .inSeconds,
      responses: List<Map<String, dynamic>>.from(_responses),
      feedback: feedback,
    );
    await InterviewService.instance.saveCompleted(session);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            InterviewFeedbackScreen(session: session, mascot: widget.mascot),
      ),
    );
  }

  Future<void> _confirmEarlyFinish() async {
    final finish = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF211D2B),
        title: const Text(
          'Kết thúc phỏng vấn?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Các câu đã trả lời sẽ được chấm điểm.',
          style: TextStyle(color: Color(0xFFCFC7DC)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Tiếp tục'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Kết thúc'),
          ),
        ],
      ),
    );
    if (finish == true) await _finish();
  }

  Future<void> _showHint() async {
    if (_busy || _hintsUsed >= 2) return;
    setState(() => _hintsUsed += 1);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF211D2B),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gợi ý trả lời',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.initialSession.mode == 'behavioral'
                    ? 'Dùng STAR: Tình huống → Nhiệm vụ → Hành động → Kết quả.\n\n${_question.hint}'
                    : _question.hint,
                style: const TextStyle(color: Color(0xFFCFC7DC), height: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Còn ${2 - _hintsUsed} lượt gợi ý',
                style: const TextStyle(color: Color(0xFFAAA5B8)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAnswerEditor() async {
    if (_busy || !_questionReady) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF211D2B),
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          8,
          18,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Câu trả lời của bạn',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _answerController,
              autofocus: true,
              minLines: 4,
              maxLines: 7,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nhập câu trả lời...',
                hintStyle: const TextStyle(color: Color(0xFFAAA5B8)),
                filled: true,
                fillColor: const Color(0xFF17141F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                Navigator.of(sheetContext).pop();
                await _submitAnswer();
              },
              child: const Text('Gửi câu trả lời'),
            ),
          ],
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final modeName = switch (widget.initialSession.mode) {
      'intern' => 'Thực tập',
      'fresher' => 'Fresher',
      _ => 'Hành vi',
    };
    return PopScope<void>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_allowPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF100E19),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 12, 2),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Thoát buổi',
                      onPressed: _confirmExit,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Phỏng vấn',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF211D2B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _elapsedLabel,
                        style: const TextStyle(
                          color: Color(0xFF70D8F2),
                          fontFeatures: [ui.FontFeature.tabularFigures()],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                child: Row(
                  children: List.generate(widget.questions.length, (index) {
                    final done = index < _questionIndex;
                    final current = index == _questionIndex;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 22,
                        decoration: BoxDecoration(
                          color: done
                              ? const Color(0xFF70D8F2)
                              : current
                              ? _accent
                              : const Color(0xFF393445),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          done ? Icons.check_rounded : null,
                          color: const Color(0xFF171326),
                          size: 14,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${widget.initialSession.career} · $modeName · ${_questionIndex + 1}/${widget.questions.length}',
                  style: const TextStyle(
                    color: Color(0xFFAAA5B8),
                    fontSize: 11,
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: InterviewStage(
                    mascot: widget.mascot,
                    question: _questionText,
                    visibleCharacters: _visibleCharacters,
                    speaking: !_questionReady,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              VoiceOrb(
                state: _busy
                    ? VoiceOrbState.thinking
                    : _questionReady
                    ? VoiceOrbState.idle
                    : VoiceOrbState.thinking,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnswerPill(
                  text: _answerController.text,
                  onEdit: _showAnswerEditor,
                  onSend: _submitAnswer,
                  enabled: _questionReady && !_busy,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: InterviewControlBar(
                  onHint: _showHint,
                  onKeyboard: _showAnswerEditor,
                  onSkip: _skipQuestion,
                  onEnd: _confirmEarlyFinish,
                  enabled: _questionReady && !_busy,
                  hintsRemaining: 2 - _hintsUsed,
                ),
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Đang tổng hợp nhận xét...',
                    style: TextStyle(color: Color(0xFFCFC7DC), fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
