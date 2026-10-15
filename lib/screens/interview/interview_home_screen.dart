import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/career_goal.dart';
import '../../models/character_data.dart';
import '../../models/interview_models.dart';
import '../../services/interview_service.dart';
import '../../services/mascot_selection_store.dart';
import '../career_goal_screen.dart';
import 'interview_feedback_screen.dart';
import 'interview_room_screen.dart';

class InterviewHomeScreen extends StatefulWidget {
  const InterviewHomeScreen({this.jobTitle, super.key});

  final String? jobTitle;

  @override
  State<InterviewHomeScreen> createState() => _InterviewHomeScreenState();
}

class _InterviewHomeScreenState extends State<InterviewHomeScreen> {
  static const _background = Color(0xFF100E19);
  static const _surface = Color(0xD9142E52);
  static const _accent = Color(0xFFBFA8FF);
  static const _cyan = Color(0xFF70D8F2);
  static const _modes = {
    'Thực tập': 'intern',
    'Fresher': 'fresher',
    'Hành vi': 'behavioral',
  };
  static const _difficulties = ['Dễ', 'Vừa', 'Khó'];

  String? _careerTitle;
  CharacterData _mascot = characterData.first;
  String _modeLabel = 'Thực tập';
  String _difficulty = 'Vừa';
  List<InterviewSession> _history = [];
  Map<String, double> _skillMastery = {};
  int _remaining = 2;
  bool _loading = true;
  bool _starting = false;
  bool _buying = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final mascots = await MascotSelectionStore.instance.read(
        preferences: preferences,
      );
      final history = await InterviewService.instance.loadHistory();
      final remaining = await InterviewService.instance.remainingToday();
      final rawMastery = jsonDecode(
        preferences.getString('career_map_skills') ?? '{}',
      );
      final mastery = rawMastery is Map<String, dynamic>
          ? rawMastery.map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            )
          : <String, double>{};
      if (!mounted) return;
      setState(() {
        _careerTitle = preferences.getString('career_goal');
        _mascot =
            mascots.primary ??
            CharacterSelection.selected ??
            characterData.first;
        _history = history;
        _skillMastery = mastery;
        _remaining = remaining;
        _loading = false;
        _loadError = null;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Không thể tải dữ liệu phỏng vấn: $error';
      });
    }
  }

  Future<void> _changeCareer() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/onboarding-goal'),
        builder: (_) => const CareerGoalScreen(skipIfSavedUser: false),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _start() async {
    final career = _careerTitle;
    if (_starting || careerGoalByTitle(career) == null) return;
    setState(() => _starting = true);
    try {
      final questions = await InterviewService.instance.questionsFor(
        career: career!,
        mode: _modes[_modeLabel]!,
        count: 6,
      );
      if (questions.isEmpty) {
        _message('Chưa có câu hỏi mẫu cho nghề này. Hãy thử lại sau.');
        return;
      }
      final started = await InterviewService.instance.startSession();
      if (!started) {
        _message('Bạn đã hết lượt hôm nay. Hãy đổi 50 điểm lấy thêm một lượt.');
        return;
      }
      if (!mounted) return;
      final session = InterviewSession(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        career: career,
        mode: _modes[_modeLabel]!,
        difficulty: _difficulty,
        startedAt: DateTime.now(),
        durationSeconds: 0,
        responses: const [],
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/interview-room'),
          builder: (_) => InterviewRoomScreen(
            initialSession: session,
            questions: questions,
            mascot: _mascot,
          ),
        ),
      );
      if (mounted) _load();
    } on Exception catch (error) {
      _message('Không thể bắt đầu phỏng vấn: $error');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _buyExtraSession() async {
    if (_buying) return;
    setState(() => _buying = true);
    try {
      final purchased = await InterviewService.instance.buyExtraSession();
      if (!purchased) {
        _message('Bạn cần ít nhất 50 điểm để đổi thêm một lượt.');
        return;
      }
      await _load();
    } on Exception catch (error) {
      _message('Không thể đổi lượt phỏng vấn: $error');
    } finally {
      if (mounted) setState(() => _buying = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openHistory(InterviewSession session) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InterviewFeedbackScreen(
          session: session,
          mascot: _mascot,
          allowRetry: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Phỏng vấn',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _loadError!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_background, Color(0xFF171326), _background],
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  _buildGreeting(),
                  if (widget.jobTitle != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _accent.withValues(alpha: .3),
                        ),
                      ),
                      child: Text(
                        'Vị trí đang luyện: ${widget.jobTitle}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _buildCareerCard(),
                  if (_skillMastery.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildSkillsCard(),
                  ],
                  const SizedBox(height: 16),
                  _buildChoiceSection(
                    title: 'Chế độ phỏng vấn',
                    options: _modes.keys.toList(),
                    selected: _modeLabel,
                    onSelected: (value) => setState(() => _modeLabel = value),
                  ),
                  const SizedBox(height: 12),
                  _buildChoiceSection(
                    title: 'Độ khó',
                    options: _difficulties,
                    selected: _difficulty,
                    onSelected: (value) => setState(() => _difficulty = value),
                  ),
                  const SizedBox(height: 14),
                  _buildUsageCard(),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed:
                          _starting || careerGoalByTitle(_careerTitle) == null
                          ? null
                          : _start,
                      icon: _starting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF211A30),
                              ),
                            )
                          : const Icon(Icons.play_arrow_rounded),
                      label: const Text(
                        'Bắt đầu phỏng vấn',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: const Color(0xFF211A30),
                        disabledBackgroundColor: const Color(0xFF393445),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mô phỏng bằng ngân hàng câu hỏi mẫu; nhận xét hiện được chấm cục bộ.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFAAA5B8), fontSize: 11),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Lịch sử phỏng vấn',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Text(
                        '${_history.length} buổi',
                        style: const TextStyle(color: Color(0xFFAAA5B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_history.isEmpty)
                    _card(
                      const Text(
                        'Hoàn thành buổi đầu tiên để xem nhận xét tại đây.',
                        style: TextStyle(color: Color(0xFFAAA5B8)),
                      ),
                    )
                  else
                    for (final session in _history.take(20))
                      _buildHistoryTile(session),
                ],
              ),
            ),
    );
  }

  Widget _buildGreeting() {
    return _card(
      Row(
        children: [
          SizedBox(
            width: 66,
            height: 66,
            child: ModelViewer(
              key: ValueKey('interview-home-${_mascot.modelPath}'),
              src: _mascot.modelPath,
              alt: _mascot.name,
              autoPlay: true,
              animationName: _mascot.animationName,
              autoRotate: true,
              autoRotateDelay: 0,
              cameraControls: false,
              disableZoom: true,
              backgroundColor: Colors.transparent,
              debugLogging: false,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Sẵn sàng phỏng vấn chưa, phi hành gia?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerCard() {
    final goal = careerGoalByTitle(_careerTitle);
    return _card(
      Row(
        children: [
          Icon(goal?.icon ?? Icons.flag_outlined, color: _cyan, size: 25),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nghề mục tiêu',
                  style: TextStyle(color: Color(0xFFAAA5B8), fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  goal?.title ?? 'Chưa chọn nghề',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: _changeCareer, child: const Text('Đổi nghề')),
        ],
      ),
      note: goal == null ? 'Hãy chọn nghề mục tiêu trước khi bắt đầu.' : null,
    );
  }

  Widget _buildSkillsCard() {
    final skills = _skillMastery.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kỹ năng đã ghi nhận',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 2,
            children: [
              for (final skill in skills.take(6))
                Chip(
                  label: Text(
                    '${skill.key} · ${skill.value.toStringAsFixed(1)}',
                  ),
                  backgroundColor: const Color(0xFF302547),
                  labelStyle: const TextStyle(
                    color: Color(0xFFCFC7DC),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceSection({
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final option in options)
                ChoiceChip(
                  label: Text(option),
                  selected: option == selected,
                  onSelected: (_) => onSelected(option),
                  selectedColor: _accent,
                  backgroundColor: const Color(0xFF302C3B),
                  labelStyle: TextStyle(
                    color: option == selected
                        ? const Color(0xFF211A30)
                        : Colors.white,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageCard() => _card(
    Row(
      children: [
        const Icon(Icons.local_fire_department_rounded, color: _cyan),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Còn $_remaining lượt hôm nay',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        if (_remaining == 0)
          TextButton(
            onPressed: _buying ? null : _buyExtraSession,
            child: Text(_buying ? 'Đang đổi...' : 'Đổi 50 điểm'),
          )
        else
          const Text(
            'Thêm lượt · 50 điểm',
            style: TextStyle(color: Color(0xFFAAA5B8), fontSize: 11),
          ),
      ],
    ),
  );

  Widget _buildHistoryTile(InterviewSession session) {
    final mode = _modes.entries
        .where((entry) => entry.value == session.mode)
        .firstOrNull
        ?.key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        child: ListTile(
          onTap: () => _openHistory(session),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF302547),
            child: Text('${session.overall}'),
          ),
          title: Text(
            session.career,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '${mode ?? session.mode} · ${session.startedAt.day}/${session.startedAt.month}/${session.startedAt.year}',
            style: const TextStyle(color: Color(0xFFAAA5B8), fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _card(Widget child, {String? note}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        if (note != null) ...[
          const SizedBox(height: 8),
          Text(
            note,
            style: const TextStyle(color: Color(0xFFFFD36E), fontSize: 12),
          ),
        ],
      ],
    ),
  );
}
