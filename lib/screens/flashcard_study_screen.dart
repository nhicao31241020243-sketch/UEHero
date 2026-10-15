import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/flashcard_skill_map.dart';
import '../models/flashcard.dart';
import '../models/flashcard_deck.dart';
import '../models/xp_entry.dart';
import '../services/flashcard_service.dart';
import '../services/points_manager.dart';
import '../widgets/code_block.dart';
import '../widgets/flip_card.dart';
import 'flashcard_home_screen.dart';

class FlashcardStudyScreen extends StatefulWidget {
  const FlashcardStudyScreen({
    this.deckId,
    this.reviewAllDue = false,
    super.key,
  }) : assert(deckId != null || reviewAllDue);

  final String? deckId;
  final bool reviewAllDue;

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  final _service = FlashcardService.instance;
  final _random = Random();
  List<_StudyItem> _queue = [];
  FlashcardType? _typeFilter;
  String? _topicFilter;
  FlashcardDifficulty? _difficultyFilter;
  bool _unmasteredOnly = false;
  bool _loading = true;
  Object? _loadError;
  int _index = 0;
  int _sessionReviewed = 0;
  int _sessionCorrect = 0;
  int _sessionXp = 0;
  int? _selectedChoice;
  double _swipeDx = 0;
  bool _completionAwarded = false;

  static const _teal = FlashcardHomeScreen.teal;
  static const _lime = FlashcardHomeScreen.lime;
  static const _text = FlashcardHomeScreen.text;
  static const _muted = FlashcardHomeScreen.muted;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    try {
      await _service.initialize();
      if (!mounted) return;
      _rebuildQueue();
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  List<_StudyItem> _sourceItems() {
    if (widget.reviewAllDue) {
      final dueIds = _service.dueCards.map((card) => card.id).toSet();
      final items = [
        for (final deck in _service.decks)
          for (final card in deck.cards)
            if (dueIds.contains(card.id)) _StudyItem(deck: deck, card: card),
      ];
      items.sort(
        (a, b) =>
            (a.card.nextReviewAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(
                  b.card.nextReviewAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                ),
      );
      return items.take(12).toList();
    }
    final deck = _service.decks.firstWhere(
      (item) => item.id == widget.deckId,
      orElse: () => throw StateError('Không tìm thấy bộ thẻ đã chọn.'),
    );
    return deck.cards
        .map((card) => _StudyItem(deck: deck, card: card))
        .toList();
  }

  void _rebuildQueue({bool resetSession = false}) {
    final source = _sourceItems();
    _queue = source.where((item) {
      final card = item.card;
      return (_typeFilter == null || card.type == _typeFilter) &&
          (_topicFilter == null || card.subTopic == _topicFilter) &&
          (_difficultyFilter == null || card.difficulty == _difficultyFilter) &&
          (!_unmasteredOnly || card.box < 3);
    }).toList();
    if (resetSession) {
      _index = 0;
      _sessionReviewed = 0;
      _sessionCorrect = 0;
      _sessionXp = 0;
    } else if (_index >= _queue.length) {
      _index = 0;
    }
    _selectedChoice = null;
    _swipeDx = 0;
  }

  _StudyItem? get _current => _index < _queue.length ? _queue[_index] : null;

  void _flip() {
    HapticFeedback.selectionClick();
    setState(() => _isFlipped = !_isFlipped);
  }

  bool _isFlipped = false;

  Future<void> _rate(bool known) async {
    final item = _current;
    if (item == null) return;
    HapticFeedback.lightImpact();
    final isQuiz = item.card.quizOptions.isNotEmpty;
    final wasCorrect = isQuiz
        ? _selectedChoice != null && _selectedChoice == item.card.correctChoice
        : known;
    await _service.recordReview(
      item.deck.id,
      item.card.id,
      known: known && wasCorrect,
    );
    if (wasCorrect) {
      final now = DateTime.now();
      final date =
          '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final added = await PointsManager.instance.addXP(
        thanh: XpBar.kienThuc,
        skill: skillForDeck(item.deck.id),
        luong: 5,
        nguon: 'flashcard',
        sourceRef: '${item.card.id}_$date',
      );
      if (added > 0) {
        _sessionXp += added;
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hôm nay đủ XP từ flashcard rồi, vẫn ôn thoải mái nhé',
            ),
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() {
      _sessionReviewed++;
      if (wasCorrect) _sessionCorrect++;
      _index++;
      _selectedChoice = null;
      _isFlipped = false;
      _swipeDx = 0;
    });
    if (_index >= _queue.length && !_completionAwarded) {
      _completionAwarded = true;
      final refId = widget.reviewAllDue
          ? 'flashcard-review-${DateTime.now().toIso8601String().substring(0, 10)}'
          : 'flashcard-deck-${item.deck.id}';
      await PointsManager.instance.addXP(
        thanh: XpBar.kienThuc,
        luong: 20,
        nguon: 'flashcard_completed',
        sourceRef: refId,
      );
    }
  }

  void _handleSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_swipeDx > 70 || velocity > 500) {
      _rate(true);
    } else if (_swipeDx < -70 || velocity < -500) {
      _rate(false);
    }
  }

  Future<void> _shuffle() async {
    if (_queue.length < 2) return;
    HapticFeedback.selectionClick();
    setState(() {
      _queue.shuffle(_random);
      _index = 0;
      _selectedChoice = null;
      _isFlipped = false;
    });
  }

  Future<void> _showFilter() async {
    final topics =
        _sourceItems()
            .map((item) => item.card.subTopic)
            .where((topic) => topic.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    var type = _typeFilter;
    var topic = _topicFilter;
    var difficulty = _difficultyFilter;
    var unmastered = _unmasteredOnly;
    final result = await showModalBottomSheet<_StudyFilter>(
      context: context,
      backgroundColor: const Color(0xF0142E52),
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lọc thẻ',
                style: TextStyle(
                  color: _text,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 15),
              _filterDropdown<FlashcardType>(
                label: 'Loại thẻ',
                value: type,
                values: FlashcardType.values,
                display: (item) => item.label,
                onChanged: (value) => setSheetState(() => type = value),
              ),
              const SizedBox(height: 11),
              _filterDropdown<String>(
                label: 'Chủ đề con',
                value: topic,
                values: topics,
                display: (item) => item,
                onChanged: (value) => setSheetState(() => topic = value),
              ),
              const SizedBox(height: 11),
              _filterDropdown<FlashcardDifficulty>(
                label: 'Độ khó',
                value: difficulty,
                values: FlashcardDifficulty.values,
                display: (item) => item.label,
                onChanged: (value) => setSheetState(() => difficulty = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: _teal,
                title: const Text(
                  'Chỉ thẻ chưa thuộc',
                  style: TextStyle(color: _text),
                ),
                value: unmastered,
                onChanged: (value) => setSheetState(() => unmastered = value),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, const _StudyFilter()),
                    child: const Text('Xóa lọc'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      _StudyFilter(
                        type: type,
                        topic: topic,
                        difficulty: difficulty,
                        unmastered: unmastered,
                      ),
                    ),
                    child: const Text('Áp dụng'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _typeFilter = result.type;
      _topicFilter = result.topic;
      _difficultyFilter = result.difficulty;
      _unmasteredOnly = result.unmastered;
      _rebuildQueue(resetSession: true);
    });
  }

  Future<void> _editCurrentCard({Flashcard? original}) async {
    final item = _current;
    final deck = original == null
        ? item?.deck
        : _service.decks.firstWhere((entry) => entry.id == original.deckId);
    if (deck == null) return;
    final frontController = TextEditingController(text: original?.front ?? '');
    final backController = TextEditingController(text: original?.back ?? '');
    final exampleController = TextEditingController(
      text: original?.example ?? '',
    );
    final topicController = TextEditingController(
      text: original?.subTopic ?? '',
    );
    final tagsController = TextEditingController(
      text: original?.tags.join(', ') ?? '',
    );
    FlashcardType? type = original?.type ?? FlashcardType.concept;
    FlashcardCodeLanguage? codeLanguage =
        original?.codeLanguage ?? FlashcardCodeLanguage.none;
    final draft = await showDialog<_CardDraft>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: FlashcardHomeScreen.surface,
          title: Text(
            original == null ? 'Thêm thẻ' : 'Sửa thẻ',
            style: const TextStyle(color: _text),
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(frontController, 'Mặt trước / câu hỏi', maxLines: 3),
                  const SizedBox(height: 9),
                  _field(backController, 'Mặt sau / giải thích', maxLines: 4),
                  const SizedBox(height: 9),
                  _field(topicController, 'Chủ đề con, ví dụ JOIN'),
                  const SizedBox(height: 9),
                  _field(
                    exampleController,
                    'Ví dụ code (không bắt buộc)',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 9),
                  _field(tagsController, 'Tags, phân cách bằng dấu phẩy'),
                  const SizedBox(height: 9),
                  _filterDropdown<FlashcardType>(
                    label: 'Loại thẻ',
                    value: type,
                    values: FlashcardType.values,
                    display: (value) => value.label,
                    onChanged: (value) => setDialogState(() => type = value),
                  ),
                  const SizedBox(height: 9),
                  _filterDropdown<FlashcardCodeLanguage>(
                    label: 'Ngôn ngữ code',
                    value: codeLanguage,
                    values: FlashcardCodeLanguage.values,
                    display: (value) => value.name.toUpperCase(),
                    onChanged: (value) =>
                        setDialogState(() => codeLanguage = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                if (frontController.text.trim().isEmpty ||
                    backController.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(
                  context,
                  _CardDraft(
                    front: frontController.text.trim(),
                    back: backController.text.trim(),
                    example: exampleController.text.trim(),
                    subTopic: topicController.text.trim(),
                    tags: tagsController.text
                        .split(',')
                        .map((tag) => tag.trim())
                        .where((tag) => tag.isNotEmpty)
                        .toList(),
                    type: type ?? FlashcardType.concept,
                    codeLanguage: codeLanguage ?? FlashcardCodeLanguage.none,
                  ),
                );
              },
              child: const Text('Lưu thẻ'),
            ),
          ],
        ),
      ),
    );
    frontController.dispose();
    backController.dispose();
    exampleController.dispose();
    topicController.dispose();
    tagsController.dispose();
    if (draft == null || !mounted) return;
    if (original == null) {
      await _service.addCard(
        Flashcard(
          id: 'custom-card-${DateTime.now().microsecondsSinceEpoch}',
          deckId: deck.id,
          type: draft.type,
          front: draft.front,
          back: draft.back,
          example: draft.example,
          subTopic: draft.subTopic,
          tags: draft.tags,
          codeLanguage: draft.codeLanguage,
        ),
      );
      setState(() {
        _rebuildQueue(resetSession: true);
        final addedIndex = _queue.indexWhere(
          (entry) => entry.card.front == draft.front,
        );
        if (addedIndex >= 0) _index = addedIndex;
      });
    } else {
      await _service.updateCard(
        original.copyWith(
          type: draft.type,
          front: draft.front,
          back: draft.back,
          example: draft.example,
          subTopic: draft.subTopic,
          tags: draft.tags,
          codeLanguage: draft.codeLanguage,
        ),
      );
      setState(() => _rebuildQueue());
    }
  }

  Future<void> _deleteCurrentCard() async {
    final item = _current;
    if (item == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlashcardHomeScreen.surface,
        title: const Text('Xóa thẻ này?', style: TextStyle(color: _text)),
        content: const Text(
          'Thao tác này sẽ xóa thẻ khỏi bộ thẻ trên thiết bị.',
          style: TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.deleteCard(item.deck.id, item.card.id);
    if (!mounted) return;
    setState(() {
      _rebuildQueue();
      if (_index >= _queue.length && _queue.isNotEmpty) {
        _index = _queue.length - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: _loading || _loadError != null ? null : _appBar(),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: _teal))
        : _loadError != null
        ? _errorState()
        : AnimatedBuilder(
            animation: _service,
            builder: (context, _) => _studyBody(),
          ),
    bottomNavigationBar: _loading || _loadError != null ? null : _bottomBar(),
  );

  PreferredSizeWidget _appBar() {
    final item = _current;
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: _text,
      elevation: 0,
      leading: IconButton(
        tooltip: 'Về bộ thẻ',
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      titleSpacing: 0,
      title: Text(
        item?.deck.title ?? (widget.reviewAllDue ? 'Ôn hôm nay' : 'Học thẻ'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          tooltip: 'Thêm thẻ',
          onPressed: () => _editCurrentCard(),
          icon: const Icon(Icons.add_circle_outline_rounded, color: _teal),
        ),
        IconButton(
          tooltip: 'Trộn thẻ',
          onPressed: _shuffle,
          icon: const Icon(Icons.shuffle_rounded, color: _muted),
        ),
        IconButton(
          tooltip: 'Lọc thẻ',
          onPressed: _showFilter,
          icon: const Icon(Icons.tune_rounded, color: _muted),
        ),
        if (item != null)
          PopupMenuButton<String>(
            color: FlashcardHomeScreen.surface,
            onSelected: (value) {
              if (value == 'edit') _editCurrentCard(original: item.card);
              if (value == 'delete') _deleteCurrentCard();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Sửa thẻ')),
              PopupMenuItem(value: 'delete', child: Text('Xóa thẻ')),
            ],
          ),
      ],
    );
  }

  Widget _errorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Không tải được bộ thẻ: $_loadError',
        style: const TextStyle(color: _text),
        textAlign: TextAlign.center,
      ),
    ),
  );

  Widget _studyBody() {
    final current = _current;
    if (current == null) {
      return _sessionReviewed == 0 ? _emptyStudyState() : _sessionSummary();
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 7, 18, 14),
        child: Column(
          children: [
            _progressHeader(current),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      top: 13,
                      left: 12,
                      right: 12,
                      bottom: -2,
                      child: _cardBackplate(current.deck.color, 0.12),
                    ),
                    Positioned.fill(
                      top: 6,
                      left: 6,
                      right: 6,
                      bottom: 3,
                      child: _cardBackplate(current.deck.color, 0.2),
                    ),
                    Positioned.fill(
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          setState(() => _swipeDx += details.primaryDelta ?? 0);
                        },
                        onHorizontalDragEnd: _handleSwipe,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          transform: Matrix4.identity()
                            ..rotateZ((_swipeDx / 900).clamp(-0.12, 0.12))
                            ..translateByDouble(
                              _swipeDx.clamp(-35, 35).toDouble(),
                              0,
                              0,
                              1,
                            ),
                          child: _currentCard(current),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            _actionRow(),
            const SizedBox(height: 12),
            _swipeHint(),
          ],
        ),
      ),
    );
  }

  Widget _cardBackplate(Color accent, double alpha) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF1C1C29),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: accent.withValues(alpha: alpha)),
    ),
  );

  Widget _progressHeader(_StudyItem current) => Column(
    children: [
      Row(
        children: [
          Icon(current.deck.icon, color: current.deck.color, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              current.deck.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ),
          Text(
            '${_index + 1}/${_queue.length}',
            style: const TextStyle(
              color: _text,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'XP phiên: +$_sessionXp',
            style: const TextStyle(color: _lime, fontSize: 11),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: LinearProgressIndicator(
          value: _queue.isEmpty ? 0 : (_index + 1) / _queue.length,
          minHeight: 5,
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          valueColor: const AlwaysStoppedAnimation(_teal),
        ),
      ),
    ],
  );

  Widget _currentCard(_StudyItem item) {
    final card = item.card;
    final isQuiz = card.quizOptions.isNotEmpty;
    return Stack(
      children: [
        Positioned.fill(
          child: FlipCard(
            key: ValueKey(card.id),
            accent: item.deck.color,
            isFlipped: _isFlipped,
            onFlip: _flip,
            front: _cardFace(
              card: card,
              sideLabel: 'CÂU HỎI',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    card.front,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 21,
                      height: 1.4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (isQuiz) ...[
                    const SizedBox(height: 20),
                    ...List.generate(
                      card.quizOptions.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedChoice = index),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _selectedChoice == index
                                  ? _teal.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.035),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _selectedChoice == index
                                    ? _teal
                                    : Colors.white.withValues(alpha: 0.09),
                              ),
                            ),
                            child: Text(
                              card.quizOptions[index],
                              style: const TextStyle(
                                color: _text,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            back: _cardFace(
              card: card,
              sideLabel: 'GIẢI THÍCH',
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isQuiz)
                      _quizResult(card)
                    else
                      Text(
                        card.back,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 16,
                          height: 1.55,
                        ),
                      ),
                    if (card.example.isNotEmpty)
                      FlashcardCodeBlock(
                        code: card.example,
                        language: switch (card.codeLanguage) {
                          FlashcardCodeLanguage.sql => 'SQL',
                          FlashcardCodeLanguage.dax => 'DAX',
                          FlashcardCodeLanguage.none => 'VÍ DỤ',
                        },
                      ),
                    if (isQuiz) ...[
                      const SizedBox(height: 12),
                      Text(
                        card.back,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: _badge(card.type.label, item.deck.color),
        ),
        if (card.subTopic.isNotEmpty)
          Positioned(
            top: 12,
            left: card.type.label.length * 6.5 + 75,
            child: _badge(card.subTopic, const Color(0xFF8BBFB3)),
          ),
        Positioned(
          top: 5,
          right: 5,
          child: IconButton(
            tooltip: card.isFavorite ? 'Bỏ yêu thích' : 'Thêm vào yêu thích',
            onPressed: () {
              HapticFeedback.selectionClick();
              _service.toggleFavorite(item.deck.id, card.id);
            },
            icon: Icon(
              card.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: card.isFavorite ? _lime : Colors.white54,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }

  Widget _cardFace({
    required Flashcard card,
    required String sideLabel,
    required Widget child,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(23, 48, 23, 24),
    child: Column(
      children: [
        Text(
          sideLabel,
          style: const TextStyle(
            color: _teal,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: Center(child: SingleChildScrollView(child: child)),
        ),
        const SizedBox(height: 6),
        const Text(
          'Chạm để lật',
          style: TextStyle(color: _muted, fontSize: 10),
        ),
      ],
    ),
  );

  Widget _quizResult(Flashcard card) {
    final choice = _selectedChoice;
    final correct = choice != null && choice == card.correctChoice;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (correct ? _teal : const Color(0xFFFF9C86)).withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        choice == null
            ? 'Chưa chọn đáp án. Hãy xem lại các lựa chọn và thử lần nữa ở lượt sau.'
            : correct
            ? 'Chính xác! Bạn đã chọn đúng query.'
            : 'Chưa đúng lần này. Đáp án đúng là ${String.fromCharCode(65 + (card.correctChoice ?? 0))}.',
        style: TextStyle(
          color: correct ? _teal : const Color(0xFFFFB09E),
          fontSize: 15,
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 115),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );

  Widget _actionRow() => LayoutBuilder(
    builder: (context, constraints) {
      final eye = _squareAction(
        icon: _isFlipped
            ? Icons.visibility_off_rounded
            : Icons.visibility_rounded,
        tooltip: _isFlipped ? 'Ẩn đáp án' : 'Hiện đáp án',
        onPressed: _flip,
      );
      final retry = OutlinedButton.icon(
        onPressed: () => _rate(false),
        icon: const Icon(Icons.replay_rounded, size: 17),
        label: const Text('Ôn lại'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFFA68D),
          side: BorderSide(
            color: const Color(0xFFFFA68D).withValues(alpha: 0.6),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth < 350 ? 7 : 17,
            vertical: 12,
          ),
        ),
      );
      final mastered = FilledButton.icon(
        onPressed: () => _rate(true),
        icon: const Icon(Icons.check_rounded, size: 18),
        label: const Text('Đã thuộc'),
        style: FilledButton.styleFrom(
          foregroundColor: const Color(0xFF10221F),
          backgroundColor: _teal,
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth < 350 ? 7 : 17,
            vertical: 12,
          ),
        ),
      );
      if (constraints.maxWidth < 350) {
        return Row(
          children: [
            eye,
            const SizedBox(width: 6),
            Expanded(child: retry),
            const SizedBox(width: 6),
            Expanded(child: mastered),
          ],
        );
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          eye,
          const SizedBox(width: 12),
          retry,
          const SizedBox(width: 9),
          mastered,
        ],
      );
    },
  );

  Widget _squareAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.045),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    ),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: _teal),
    ),
  );

  Widget _swipeHint() => const Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Icon(Icons.swipe_rounded, color: _muted, size: 15),
      SizedBox(width: 6),
      Text(
        'Vuốt trái: ôn lại · Vuốt phải: đã thuộc',
        style: TextStyle(color: _muted, fontSize: 10),
      ),
    ],
  );

  Widget _sessionSummary() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: FlashcardHomeScreen.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _teal.withValues(alpha: 0.24)),
          boxShadow: [
            BoxShadow(color: _teal.withValues(alpha: 0.08), blurRadius: 24),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: _lime, size: 43),
            const SizedBox(height: 13),
            const Text(
              'Hoàn thành phiên học!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '$_sessionCorrect / $_sessionReviewed thẻ trả lời đúng',
              style: const TextStyle(color: _teal, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text(
              'Độ chính xác: ${_sessionReviewed == 0 ? 0 : (_sessionCorrect * 100 / _sessionReviewed).round()}%',
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              'XP phiên: +$_sessionXp',
              style: const TextStyle(
                color: _lime,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_service.streak} ngày streak · tổng ${_service.totalReviewed} lượt ôn',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('Về thư viện'),
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: FlashcardHomeScreen.background,
              ),
            ),
            if (widget.reviewAllDue && _service.dueCards.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const FlashcardStudyScreen(reviewAllDue: true),
                  ),
                ),
                child: const Text('Ôn tiếp 12 thẻ'),
              ),
            if (!widget.reviewAllDue)
              TextButton(
                onPressed: () {
                  setState(() {
                    _rebuildQueue(resetSession: true);
                    _isFlipped = false;
                  });
                },
                child: const Text('Học lại bộ này'),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _emptyStudyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: _teal,
            size: 46,
          ),
          const SizedBox(height: 12),
          Text(
            widget.reviewAllDue
                ? 'Bạn đã ôn hết thẻ đến hạn!'
                : 'Không có thẻ phù hợp',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _text,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Có thể đổi bộ lọc hoặc quay lại thư viện để chọn gói khác.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.grid_view_rounded),
            label: const Text('Về thư viện'),
          ),
        ],
      ),
    ),
  );

  Widget _bottomBar() => SafeArea(
    top: false,
    minimum: const EdgeInsets.fromLTRB(15, 7, 15, 10),
    child: Container(
      height: 56,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1C27),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _bottomTab(
              icon: Icons.grid_view_rounded,
              label: 'Bộ thẻ',
              active: false,
              onTap: () => Navigator.maybePop(context),
            ),
          ),
          Expanded(
            child: _bottomTab(
              icon: Icons.style_rounded,
              label: 'Học thẻ',
              active: true,
              onTap: () {},
            ),
          ),
        ],
      ),
    ),
  );

  Widget _bottomTab({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      decoration: active
          ? BoxDecoration(
              gradient: const LinearGradient(
                colors: [FlashcardHomeScreen.teal, FlashcardHomeScreen.lime],
              ),
              borderRadius: BorderRadius.circular(18),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 17,
            color: active ? FlashcardHomeScreen.background : _muted,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: active ? FlashcardHomeScreen.background : _muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) => TextField(
    controller: controller,
    maxLines: maxLines,
    style: const TextStyle(color: _text),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _muted, fontSize: 12),
      filled: true,
      fillColor: const Color(0xFF17151F),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  Widget _filterDropdown<T>({
    required String label,
    required T? value,
    required List<T> values,
    required String Function(T) display,
    required ValueChanged<T?> onChanged,
  }) => DropdownButtonFormField<T?>(
    initialValue: value,
    dropdownColor: FlashcardHomeScreen.surface,
    style: const TextStyle(color: _text, fontSize: 13),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _muted),
      filled: true,
      fillColor: FlashcardHomeScreen.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    items: [
      DropdownMenuItem<T?>(value: null, child: Text('Tất cả $label')),
      ...values.map(
        (item) => DropdownMenuItem<T?>(value: item, child: Text(display(item))),
      ),
    ],
    onChanged: onChanged,
  );
}

class _StudyItem {
  const _StudyItem({required this.deck, required this.card});

  final FlashcardDeck deck;
  final Flashcard card;
}

class _StudyFilter {
  const _StudyFilter({
    this.type,
    this.topic,
    this.difficulty,
    this.unmastered = false,
  });

  final FlashcardType? type;
  final String? topic;
  final FlashcardDifficulty? difficulty;
  final bool unmastered;
}

class _CardDraft {
  const _CardDraft({
    required this.front,
    required this.back,
    required this.example,
    required this.subTopic,
    required this.tags,
    required this.type,
    required this.codeLanguage,
  });

  final String front;
  final String back;
  final String example;
  final String subTopic;
  final List<String> tags;
  final FlashcardType type;
  final FlashcardCodeLanguage codeLanguage;
}
