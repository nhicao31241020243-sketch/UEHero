import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/career_goal.dart';
import '../models/character_data.dart';
import '../models/cv_check.dart';
import '../services/cv_analyzer.dart';
import '../services/points_manager.dart';
import '../widgets/match_bar.dart';
import 'job_screen.dart';

class CvCheckScreen extends StatefulWidget {
  const CvCheckScreen({this.job, super.key});

  final CvCheckJob? job;

  @override
  State<CvCheckScreen> createState() => _CvCheckScreenState();
}

class _CvCheckScreenState extends State<CvCheckScreen> {
  static const _background = Color(0xFF100E19);
  static const _surface = Color(0xFF211D2B);
  static const _accent = Color(0xFFBFA8FF);
  static const _cyan = Color(0xFF70D8F2);
  static const _muted = Color(0xFFAAA5B8);
  static const _cvTextKey = 'cv_check_text';
  static const _bestScoreKey = 'cv_check_best_score';
  static const _historyKey = 'cv_check_history';
  static const _careerSkillsKey = 'career_map_skills';

  final _cvController = TextEditingController();
  final _analyzer = const CvAnalyzer();
  CareerGoal _career = careerGoals.first;
  CharacterData _mascot = characterData.first;
  CvCheckJob? _job;
  CvAnalysis? _analysis;
  bool _loading = true;
  bool _checking = false;
  bool _showScoreMode = false;
  int _bestScore = 0;
  int _statusIndex = 0;
  List<Map<String, Object>> _history = [];
  int _fixedIssueCount = 0;
  int? _selectedIssueLine;
  Timer? _statusTimer;

  static const _checkingMessages = [
    'Đang tìm kỹ năng...',
    'Đang đếm số liệu thành tích...',
    'Đang kiểm tra cấu trúc CV...',
    'Đang đối chiếu mục tiêu nghề nghiệp...',
  ];

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _loadSavedData();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _cvController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final preferences = await SharedPreferences.getInstance();
    final goal =
        careerGoalByTitle(preferences.getString('career_goal')) ??
        careerGoals.first;
    final mascot =
        characterById(preferences.getString('selected_mascot')) ??
        CharacterSelection.selected ??
        characterData.first;
    final encodedHistory = preferences.getString(_historyKey);
    final history = encodedHistory == null
        ? <Map<String, Object>>[]
        : (jsonDecode(encodedHistory) as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map((entry) => Map<String, Object>.from(entry))
              .toList();
    if (!mounted) return;
    setState(() {
      _career = goal;
      _mascot = mascot;
      if (widget.job == null) {
        _job = null;
      }
      _cvController.text = preferences.getString(_cvTextKey) ?? '';
      _bestScore = preferences.getInt(_bestScoreKey) ?? 0;
      _history = history;
      _loading = false;
    });
  }

  Future<void> _chooseJob() async {
    final selected = await showModalBottomSheet<CvCheckJob>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _JobPickerSheet(selectedJob: _job),
    );
    if (selected != null && mounted) {
      setState(() => _job = selected);
    }
  }

  Future<void> _runCheck() async {
    final text = _cvController.text.trim();
    if (text.isEmpty) {
      _showMessage('Hãy dán nội dung CV trước khi kiểm tra.');
      return;
    }
    if (_checking) return;

    setState(() {
      _checking = true;
      _statusIndex = 0;
    });
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(milliseconds: 850), (_) {
      if (mounted) {
        setState(
          () => _statusIndex = (_statusIndex + 1) % _checkingMessages.length,
        );
      }
    });
    await Future<void>.delayed(const Duration(milliseconds: 3500));
    _statusTimer?.cancel();
    if (!mounted) return;

    final previousIssues = _analysis?.issues ?? const <CvIssue>[];
    final result = _analyzer.analyze(text: text, career: _career, job: _job);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_cvTextKey, text);

    final previousBest = _bestScore;
    final points = previousBest == 0
        ? (result.score / 5).ceil()
        : result.score > previousBest
        ? ((result.score - previousBest) / 3).ceil()
        : 0;
    if (result.score > previousBest) {
      await preferences.setInt(_bestScoreKey, result.score);
      _bestScore = result.score;
    }
    final historyEntry = <String, Object>{
      'date': DateTime.now().toIso8601String(),
      'score': result.score,
      'target': _job?.label ?? _career.title,
    };
    _history = [historyEntry, ..._history].take(10).toList();
    await preferences.setString(_historyKey, jsonEncode(_history));
    await _updateSkillMastery(preferences, text);

    if (!mounted) return;
    setState(() {
      _analysis = result;
      _checking = false;
      _showScoreMode = false;
      _fixedIssueCount = previousIssues
          .where(
            (previous) => !result.issues.any(
              (current) =>
                  current.kind == previous.kind &&
                  current.title == previous.title &&
                  current.lineIndex == previous.lineIndex,
            ),
          )
          .length;
    });
    if (points > 0) {
      PointsManager.instance.addCvPoints(points);
      _showCelebration(points, result.score > previousBest);
    }
  }

  Future<void> _updateSkillMastery(
    SharedPreferences preferences,
    String text,
  ) async {
    final saved = jsonDecode(preferences.getString(_careerSkillsKey) ?? '{}');
    final skillLevels = saved is Map<String, dynamic>
        ? Map<String, dynamic>.from(saved)
        : <String, dynamic>{};
    final normalizedCv = CvAnalyzer.normalizeForMatching(text);
    final skills = {
      ..._career.skills.map((skill) => skill.name),
      ...?_job?.requirements,
    };
    for (final skill in skills) {
      if (normalizedCv.contains(CvAnalyzer.normalizeForMatching(skill))) {
        final oldLevel = (skillLevels[skill] as num?)?.toInt() ?? 0;
        skillLevels[skill] = oldLevel < 3 ? 3 : oldLevel;
      }
    }
    await preferences.setString(_careerSkillsKey, jsonEncode(skillLevels));
  }

  void _showCelebration(int points, bool newBest) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF30284A),
          content: Text(
            newBest
                ? '✨ Điểm CV mới: $_bestScore/100 · +$points điểm UEHero!'
                : '🎉 +$points điểm UEHero cho lần chấm CV đầu tiên!',
          ),
        ),
      );
  }

  Future<void> _editLine(int lineIndex, String originalLine) async {
    final editor = TextEditingController(text: originalLine);
    final replacement = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _surface,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          22,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Chỉnh sửa đoạn CV',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: editor,
              autofocus: true,
              maxLines: 5,
              minLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: _background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.pop(context, editor.text),
              child: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
    editor.dispose();
    if (replacement == null || replacement == originalLine || !mounted) return;
    final lines = _cvController.text.split('\n');
    if (lineIndex >= lines.length) return;
    lines[lineIndex] = replacement;
    setState(() => _cvController.text = lines.join('\n'));
  }

  void _recheck() {
    setState(() => _analysis = null);
    _runCheck();
  }

  void _showIssue(CvIssue issue) {
    setState(() => _selectedIssueLine = issue.lineIndex);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _IssueDetailSheet(
        issue: issue,
        onAddToCareerMap: () {
          Navigator.pop(context);
          _showMessage('TODO: Kết nối kỹ năng với lộ trình Career Map.');
        },
        onPracticeFlashcards: () {
          Navigator.pop(context);
          _showMessage('TODO: Mở bộ flashcard luyện kỹ năng.');
        },
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        title: const Text(
          'CV Check',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (_analysis != null)
            TextButton.icon(
              onPressed: () => setState(() => _showScoreMode = !_showScoreMode),
              icon: Icon(
                _showScoreMode
                    ? Icons.description_outlined
                    : Icons.analytics_outlined,
              ),
              label: Text(_showScoreMode ? 'Tờ CV' : 'Xem điểm'),
            ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_background, Color(0xFF171326), _background],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : _checking
            ? _buildCheckingView()
            : _analysis == null
            ? _buildInputView()
            : _showScoreMode
            ? _buildScoreView(_analysis!)
            : _buildAnnotatedResult(_analysis!),
      ),
    );
  }

  Widget _buildInputView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTargetSummary(),
          const SizedBox(height: 15),
          _buildMascotPrompt(),
          const SizedBox(height: 16),
          TextField(
            controller: _cvController,
            minLines: 13,
            maxLines: 22,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Dán nội dung CV của bạn vào đây...',
              hintStyle: const TextStyle(color: _muted),
              filled: true,
              fillColor: _surface,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: _accent, width: 1.4),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 5, top: 7),
            child: Text(
              'Không cần dán số điện thoại/địa chỉ. CV chỉ được lưu trên thiết bị này.',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              OutlinedButton.icon(
                onPressed: _chooseJob,
                icon: const Icon(Icons.work_outline_rounded),
                label: Text(
                  _job == null ? 'So với job cụ thể' : 'Job: ${_job!.title}',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accent,
                  side: BorderSide(color: _accent.withValues(alpha: 0.45)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => JobScreen(initialCareerGoal: _career.title),
                  ),
                ),
                icon: const Icon(Icons.work_outline_rounded),
                label: const Text('So job'),
                style: TextButton.styleFrom(foregroundColor: _cyan),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _runCheck,
              icon: const Icon(Icons.fact_check_rounded),
              label: const Text(
                'Kiểm tra CV',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          _buildHistory(),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Điểm mang tính tham khảo',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.track_changes_rounded, color: _cyan),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _job == null
                  ? 'Đang so với: ${_career.title}'
                  : 'Đang so với job: ${_job!.title}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (_job != null)
            IconButton(
              tooltip: 'Bỏ job',
              onPressed: () => setState(() => _job = null),
              icon: const Icon(Icons.close_rounded, color: _muted, size: 19),
            ),
        ],
      ),
    );
  }

  Widget _buildMascotPrompt() {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF342A59), Color(0xFF211D38)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            child: ModelViewer(
              key: ValueKey('cv-${_mascot.modelPath}'),
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
              'Đưa CV cho mình xem nào! Mình sẽ rà soát ngay trên thiết bị.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 190,
              height: 190,
              child: ModelViewer(
                key: ValueKey('reading-${_mascot.modelPath}'),
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
            const SizedBox(height: 12),
            const CircularProgressIndicator(color: _cyan),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                _checkingMessages[_statusIndex],
                key: ValueKey(_statusIndex),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đang đọc CV ngoại tuyến...',
              style: TextStyle(color: _muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnotatedResult(CvAnalysis analysis) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_fixedIssueCount > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFF6CD9A5).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: const Color(0xFF6CD9A5).withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                '✓ Đã sửa $_fixedIssueCount nhận xét trong lần chấm lại này.',
                style: const TextStyle(
                  color: Color(0xFF6CD9A5),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          _buildSummaryBar(analysis),
          const SizedBox(height: 13),
          _buildAnnotatedPaper(analysis),
          const SizedBox(height: 14),
          _buildResultActions(analysis),
          const SizedBox(height: 20),
          _buildHistory(),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'Điểm mang tính tham khảo · TODO: thay nhận xét sâu bằng chatbot RAG/LLM chấm CV.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(CvAnalysis analysis) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 9,
        spacing: 9,
        children: [
          _SummaryPill(
            label: '${analysis.heavyCount} nặng',
            color: const Color(0xFFFF7373),
          ),
          _SummaryPill(
            label: '${analysis.warningCount} cảnh báo',
            color: const Color(0xFFFFD166),
          ),
          _SummaryPill(label: '${analysis.score}% khớp', color: _cyan),
          if (_job != null)
            _SummaryPill(
              label:
                  'Khớp ${analysis.jobMatchCount}/${analysis.jobRequirementCount} yêu cầu',
              color: _accent,
            ),
        ],
      ),
    );
  }

  Widget _buildAnnotatedPaper(CvAnalysis analysis) {
    final lines = _cvController.text.split('\n');
    final issuesByLine = <int, List<CvIssue>>{};
    for (final issue in analysis.issues) {
      issuesByLine.putIfAbsent(issue.lineIndex, () => []).add(issue);
    }
    final labelledLines = issuesByLine.keys.take(6).toSet();
    final selectedIssueLine =
        _selectedIssueLine ??
        (issuesByLine.isEmpty ? null : issuesByLine.keys.first);
    final compact = MediaQuery.sizeOf(context).width < 420;
    return InteractiveViewer(
      minScale: 0.75,
      maxScale: 2.4,
      constrained: true,
      boundaryMargin: const EdgeInsets.all(22),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 590),
        padding: EdgeInsets.all(compact ? 15 : 22),
        decoration: BoxDecoration(
          color: const Color(0xFFFEFDFB),
          borderRadius: BorderRadius.circular(7),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 25,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: _ScoreBadge(score: analysis.score),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 62),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < lines.length; index++)
                    _CvPaperLine(
                      line: lines[index],
                      lineIndex: index,
                      issues: issuesByLine[index] ?? const [],
                      onTap: () => _editLine(index, lines[index]),
                      onIssueTap: _showIssue,
                      showIssueTitles: compact || analysis.issues.length > 6
                          ? index == selectedIssueLine
                          : labelledLines.contains(index),
                    ),
                ],
              ),
            ),
            if (lines.isEmpty)
              const Center(
                child: Text(
                  'CV trống',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultActions(CvAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 51,
          child: FilledButton.icon(
            onPressed: _recheck,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'Chấm lại',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: _background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        if (_job != null) ...[
          const SizedBox(height: 9),
          Text(
            'Khớp ${analysis.jobMatchCount}/${analysis.jobRequirementCount} yêu cầu',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _cyan, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => JobScreen(initialCareerGoal: _career.title),
              ),
            ),
            icon: const Icon(Icons.work_outline_rounded),
            label: const Text('So job'),
            style: OutlinedButton.styleFrom(foregroundColor: _accent),
          ),
        ],
      ],
    );
  }

  Widget _buildScoreView(CvAnalysis analysis) {
    final available = analysis.matchedKeywords;
    final missing = analysis.missingKeywords;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _AnimatedScoreCircle(score: analysis.score)),
          const SizedBox(height: 14),
          const Text(
            'Độ khớp với mục tiêu',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 3),
          MatchBar(percent: analysis.score, height: 11),
          const SizedBox(height: 8),
          if (_job != null)
            Text(
              'Khớp ${analysis.jobMatchCount}/${analysis.jobRequirementCount} yêu cầu',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _cyan,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          const SizedBox(height: 18),
          _SkillChipSection(
            title: 'Kỹ năng đã có',
            icon: Icons.check_circle_outline_rounded,
            skills: available,
            bright: true,
          ),
          const SizedBox(height: 13),
          _SkillChipSection(
            title: 'Kỹ năng còn thiếu',
            icon: Icons.add_circle_outline_rounded,
            skills: missing,
            bright: false,
            onAdd: (skill) =>
                _showMessage('TODO: Thêm "$skill" vào Career Map.'),
            onPractice: (skill) =>
                _showMessage('TODO: Mở flashcard luyện "$skill".'),
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gợi ý cải thiện',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 9),
                for (final suggestion in analysis.suggestions)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.arrow_right_rounded, color: _accent),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: const TextStyle(
                              color: Color(0xFFD8D3E2),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildResultActions(analysis),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Điểm mang tính tham khảo',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lịch sử kiểm tra',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 7),
          for (final entry in _history.take(5))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.description_outlined,
                color: _accent,
                size: 20,
              ),
              title: Text(
                '${entry['target'] ?? _career.title}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              subtitle: Text(
                _formatHistoryDate(entry['date']?.toString()),
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
              trailing: Text(
                '${entry['score'] ?? 0}/100',
                style: const TextStyle(
                  color: _cyan,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatHistoryDate(String? raw) {
    final date = DateTime.tryParse(raw ?? '');
    if (date == null) return 'Lần kiểm tra trước';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _JobPickerSheet extends StatelessWidget {
  const _JobPickerSheet({required this.selectedJob});

  final CvCheckJob? selectedJob;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chọn job để đối chiếu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Danh sách minh họa — chưa có job_screen.dart hoặc kho job đã lưu.',
              style: TextStyle(color: _CvCheckScreenState._muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            for (final job in sampleCvJobs)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.work_outline_rounded,
                  color: _CvCheckScreenState._accent,
                ),
                title: Text(
                  job.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${job.company} · ${job.requirements.take(3).join(', ')}',
                  style: const TextStyle(
                    color: _CvCheckScreenState._muted,
                    fontSize: 11,
                  ),
                ),
                trailing: selectedJob?.title == job.title
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: _CvCheckScreenState._cyan,
                      )
                    : null,
                onTap: () => Navigator.pop(context, job),
              ),
          ],
        ),
      ),
    );
  }
}

class _CvPaperLine extends StatelessWidget {
  const _CvPaperLine({
    required this.line,
    required this.lineIndex,
    required this.issues,
    required this.onTap,
    required this.onIssueTap,
    required this.showIssueTitles,
  });

  final String line;
  final int lineIndex;
  final List<CvIssue> issues;
  final VoidCallback onTap;
  final ValueChanged<CvIssue> onIssueTap;
  final bool showIssueTitles;

  @override
  Widget build(BuildContext context) {
    final heading = RegExp(
      r'^\s*(HỌC VẤN|KINH NGHIỆM|DỰ ÁN|KỸ NĂNG|LIÊN HỆ|MỤC TIÊU|EDUCATION|EXPERIENCE|PROJECTS|SKILLS|CONTACT)\b',
      caseSensitive: false,
    ).hasMatch(line);
    final issue = issues.isEmpty ? null : issues.first;
    final severityColor = issue == null
        ? Colors.transparent
        : switch (issue.severity) {
            CvIssueSeverity.heavy => const Color(0xFFFF7777),
            CvIssueSeverity.warning => const Color(0xFFFFC857),
            CvIssueSeverity.suggestion => const Color(0xFF69BFFF),
          };
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              child: issue == null
                  ? null
                  : InkWell(
                      onTap: () => onIssueTap(issue),
                      child: Container(
                        width: 17,
                        height: 17,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: severityColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${issue.lineIndex + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: issue == null ? 0 : 4,
                  vertical: 2,
                ),
                decoration: issue == null
                    ? null
                    : BoxDecoration(
                        color: const Color(0xFFFFF0B8),
                        border: Border(
                          bottom: BorderSide(
                            color: issue.severity == CvIssueSeverity.heavy
                                ? const Color(0xFFDC4B4B)
                                : severityColor,
                            width: 1.2,
                          ),
                        ),
                      ),
                child: Text(
                  line.isEmpty ? ' ' : line,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 10.5,
                    height: 1.4,
                    fontWeight: heading ? FontWeight.w800 : FontWeight.w400,
                  ),
                ),
              ),
            ),
            if (issue != null && showIssueTitles) const SizedBox(width: 3),
            if (issue != null && showIssueTitles)
              CustomPaint(
                size: const Size(8, 26),
                painter: _IssueConnectorPainter(color: severityColor),
              ),
            if (issue != null && showIssueTitles)
              InkWell(
                onTap: () => onIssueTap(issue),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 88),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    issue.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IssueConnectorPainter extends CustomPainter {
  const _IssueConnectorPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width * 0.55, size.height / 2)
      ..lineTo(size.width * 0.55, size.height * 0.15)
      ..lineTo(size.width, size.height * 0.15);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _IssueConnectorPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score / 10),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF30215F),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          '${value.round()}/10',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AnimatedScoreCircle extends StatelessWidget {
  const _AnimatedScoreCircle({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => SizedBox(
        width: 184,
        height: 184,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 174,
              height: 174,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 11,
                strokeCap: StrokeCap.round,
                backgroundColor: const Color(0xFF393445),
                valueColor: const AlwaysStoppedAnimation(
                  _CvCheckScreenState._cyan,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(value * 100).round()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  '% KHỚP',
                  style: TextStyle(color: _CvCheckScreenState._muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SkillChipSection extends StatelessWidget {
  const _SkillChipSection({
    required this.title,
    required this.icon,
    required this.skills,
    required this.bright,
    this.onAdd,
    this.onPractice,
  });

  final String title;
  final IconData icon;
  final List<String> skills;
  final bool bright;
  final ValueChanged<String>? onAdd;
  final ValueChanged<String>? onPractice;

  @override
  Widget build(BuildContext context) {
    final color = bright
        ? _CvCheckScreenState._cyan
        : _CvCheckScreenState._muted;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _CvCheckScreenState._surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          if (skills.isEmpty)
            const Text(
              'Chưa phát hiện mục nào.',
              style: TextStyle(color: _CvCheckScreenState._muted),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final skill in skills)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: bright ? 0.17 : 0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: color.withValues(alpha: bright ? 0.5 : 0.25),
                      ),
                    ),
                    child: Text(
                      skill,
                      style: TextStyle(
                        color: bright
                            ? _CvCheckScreenState._cyan
                            : const Color(0xFFD8D3E2),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          if (!bright && skills.isNotEmpty)
            for (final skill in skills)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        skill,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => onAdd?.call(skill),
                      child: const Text('Career Map'),
                    ),
                    IconButton(
                      onPressed: () => onPractice?.call(skill),
                      tooltip: 'Luyện flashcard',
                      icon: const Icon(
                        Icons.style_outlined,
                        color: _CvCheckScreenState._accent,
                        size: 19,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _IssueDetailSheet extends StatelessWidget {
  const _IssueDetailSheet({
    required this.issue,
    required this.onAddToCareerMap,
    required this.onPracticeFlashcards,
  });

  final CvIssue issue;
  final VoidCallback onAddToCareerMap;
  final VoidCallback onPracticeFlashcards;

  @override
  Widget build(BuildContext context) {
    final color = switch (issue.severity) {
      CvIssueSeverity.heavy => const Color(0xFFFF7373),
      CvIssueSeverity.warning => const Color(0xFFFFD166),
      CvIssueSeverity.suggestion => const Color(0xFF69BFFF),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              issue.title,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 11),
            Text(
              issue.explanation,
              style: const TextStyle(color: Colors.white, height: 1.45),
            ),
            const SizedBox(height: 11),
            Text(
              'Cách sửa: ${issue.fix}',
              style: const TextStyle(
                color: _CvCheckScreenState._muted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 15),
            _ExampleBlock(
              label: 'TRƯỚC',
              content: issue.before,
              color: const Color(0xFFFF7373),
            ),
            const SizedBox(height: 8),
            _ExampleBlock(
              label: 'SAU',
              content: issue.after,
              color: _CvCheckScreenState._cyan,
            ),
            if (issue.skill != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onAddToCareerMap,
                icon: const Icon(Icons.route_rounded),
                label: const Text('Thêm vào Career Map'),
              ),
              OutlinedButton.icon(
                onPressed: onPracticeFlashcards,
                icon: const Icon(Icons.style_outlined),
                label: const Text('Luyện flashcard'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExampleBlock extends StatelessWidget {
  const _ExampleBlock({
    required this.label,
    required this.content,
    required this.color,
  });

  final String label;
  final String content;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            content,
            style: const TextStyle(color: Colors.white, height: 1.4),
          ),
        ],
      ),
    );
  }
}
