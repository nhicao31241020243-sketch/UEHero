import 'package:flutter/material.dart';

import '../data/decks/deck_helpers.dart';
import '../data/flashcard_seed.dart';
import '../models/flashcard_deck.dart';
import '../services/flashcard_service.dart';
import '../services/goal_progress_service.dart';
import '../widgets/deck_tile.dart';
import 'flashcard_study_screen.dart';
import 'career_map_screen.dart';

class FlashcardHomeScreen extends StatefulWidget {
  const FlashcardHomeScreen({super.key});

  static const heroTag = 'planet_saturn';
  static const background = Color(0xFF100E19);
  static const surface = Color(0xFF211D2B);
  static const muted = Color(0xFFAAA5B8);
  static const text = Color(0xFFFBF8FF);
  static const teal = Color(0xFF72E0C4);
  static const lime = Color(0xFFC4EC78);

  @override
  State<FlashcardHomeScreen> createState() => _FlashcardHomeScreenState();
}

class _FlashcardHomeScreenState extends State<FlashcardHomeScreen> {
  final _service = FlashcardService.instance;
  final _goalProgress = GoalProgressService.instance;
  final _searchController = TextEditingController();
  final _deckActionKeys = <String, GlobalKey>{};
  String _query = '';
  FlashcardGroup? _groupFilter;
  FlashcardLevel? _levelFilter;
  bool _loading = true;
  Object? _loadError;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _service.initialize();
      await _goalProgress.initialize();
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FlashcardDeck> get _filteredDecks {
    final query = _query.trim().toLowerCase();
    final decks = _service.decks.where((deck) {
      return (_groupFilter == null || deck.group == _groupFilter) &&
          (_levelFilter == null || deck.level == _levelFilter) &&
          (query.isEmpty ||
              '${deck.title} ${deck.description} ${deck.group.label}'
                  .toLowerCase()
                  .contains(query));
    }).toList();
    return decks;
  }

  List<FlashcardDeck> get _inProgressDecks => _filteredDecks
      .where(
        (deck) =>
            deck.cards.any((card) => card.box > 0) &&
            _service.masteredCount(deck) < deck.cards.length,
      )
      .toList();

  List<FlashcardDeck> get _otherDecks {
    final progressing = _inProgressDecks.map((deck) => deck.id).toSet();
    return _filteredDecks
        .where((deck) => !progressing.contains(deck.id))
        .toList();
  }

  Future<void> _openStudy(FlashcardDeck deck) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => FlashcardStudyScreen(deckId: deck.id),
      ),
    );
    if (!mounted) return;
    final deckContext = _deckActionKeys[deck.id]?.currentContext;
    if (deckContext == null || !deckContext.mounted) return;
    await Scrollable.ensureVisible(
      deckContext,
      alignment: 0.5,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  void _openTodayReview() {
    if (_service.dueCards.isEmpty) {
      _message('Hôm nay bạn đã ôn hết thẻ đến hạn rồi!');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const FlashcardStudyScreen(reviewAllDue: true),
      ),
    );
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _createDeck() async {
    final draft = await _showDeckEditor();
    if (draft == null) return;
    final id = 'custom-${DateTime.now().microsecondsSinceEpoch}';
    const customColors = [
      Color(0xFF72E0C4),
      Color(0xFFC4EC78),
      Color(0xFF79C8E8),
      Color(0xFF7DD6A1),
      Color(0xFF9BB4FF),
    ];
    final color = customColors[id.hashCode.abs() % customColors.length];
    await _service.createDeck(
      createSeedDeck(
        id: id,
        title: draft.title,
        icon: Icons.style_rounded,
        color: color,
        group: draft.group,
        level: draft.level,
        description: draft.description,
        cards: const [],
      ).copyWith(isCustom: true),
    );
    if (mounted) _message('Đã tạo bộ thẻ "${draft.title}".');
  }

  Future<void> _editDeck(FlashcardDeck deck) async {
    final draft = await _showDeckEditor(deck: deck);
    if (draft == null) return;
    await _service.updateDeck(
      deck.copyWith(
        title: draft.title,
        description: draft.description,
        group: draft.group,
        level: draft.level,
        colorValue: draft.color.toARGB32(),
      ),
    );
  }

  Future<_DeckDraft?> _showDeckEditor({FlashcardDeck? deck}) async {
    final titleController = TextEditingController(text: deck?.title ?? '');
    final descriptionController = TextEditingController(
      text: deck?.description ?? '',
    );
    var group = deck?.group ?? FlashcardGroup.data;
    var level = deck?.level ?? FlashcardLevel.basic;
    final draft = await showDialog<_DeckDraft>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: FlashcardHomeScreen.surface,
          title: Text(
            deck == null ? 'Tạo bộ thẻ' : 'Sửa bộ thẻ',
            style: const TextStyle(color: FlashcardHomeScreen.text),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(titleController, 'Tên gói'),
                const SizedBox(height: 10),
                _dialogField(descriptionController, 'Mô tả ngắn', maxLines: 2),
                const SizedBox(height: 10),
                _dialogEnum<FlashcardGroup>(
                  label: 'Nhóm kỹ năng',
                  value: group,
                  values: FlashcardGroup.values,
                  display: (item) => item.label,
                  onChanged: (value) => setDialogState(() => group = value),
                ),
                const SizedBox(height: 10),
                _dialogEnum<FlashcardLevel>(
                  label: 'Mức độ',
                  value: level,
                  values: FlashcardLevel.values,
                  display: (item) => item.label,
                  onChanged: (value) => setDialogState(() => level = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                Navigator.pop(
                  context,
                  _DeckDraft(
                    title: title,
                    description: descriptionController.text.trim(),
                    group: group,
                    level: level,
                    color: deck?.color ?? const Color(0xFF72E0C4),
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    descriptionController.dispose();
    return draft;
  }

  Future<void> _deleteDeck(FlashcardDeck deck) async {
    final confirm = await _confirm(
      'Xóa "${deck.title}"?',
      'Bộ thẻ và tiến độ của gói này sẽ bị xóa khỏi thư viện trên thiết bị.',
    );
    if (confirm) await _service.deleteDeck(deck.id);
  }

  Future<void> _resetDeck(FlashcardDeck deck) async {
    final confirm = await _confirm(
      'Đặt lại tiến độ?',
      'Các hộp ôn tập sẽ được đặt về ban đầu. Yêu thích và nội dung thẻ được giữ lại.',
    );
    if (confirm) await _service.resetDeckProgress(deck.id);
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: FlashcardHomeScreen.surface,
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Text(
            message,
            style: const TextStyle(color: FlashcardHomeScreen.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _showFavorites() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xE8142E52),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => AnimatedBuilder(
        animation: _service,
        builder: (context, _) {
          final favorites = _service.favoriteCards;
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.72,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Thẻ yêu thích',
                    style: TextStyle(
                      color: FlashcardHomeScreen.text,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: favorites.isEmpty
                        ? const Center(
                            child: Text(
                              'Chưa có thẻ yêu thích.',
                              style: TextStyle(
                                color: FlashcardHomeScreen.muted,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: favorites.length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final card = favorites[index];
                              final deck = _service.decks.firstWhere(
                                (item) => item.id == card.deckId,
                              );
                              return ListTile(
                                tileColor: FlashcardHomeScreen.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                leading: Icon(deck.icon, color: deck.color),
                                title: Text(
                                  card.front,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: FlashcardHomeScreen.text,
                                  ),
                                ),
                                subtitle: Text(
                                  deck.title,
                                  style: const TextStyle(
                                    color: FlashcardHomeScreen.muted,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _openStudy(deck);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _selectGroup(FlashcardGroup? group) {
    setState(() => _groupFilter = group);
  }

  void _selectLevel(FlashcardLevel? level) {
    setState(() => _levelFilter = level);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: FlashcardHomeScreen.teal),
            )
          : _loadError != null
          ? _errorState()
          : AnimatedBuilder(
              animation: Listenable.merge([_service, _goalProgress]),
              builder: (context, _) => _libraryBody(),
            ),
      bottomNavigationBar: _loading || _loadError != null ? null : _bottomBar(),
    );
  }

  Widget _errorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          const SizedBox(height: 10),
          Text(
            'Không tải được thư viện: $_loadError',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          TextButton(onPressed: _initialize, child: const Text('Thử lại')),
        ],
      ),
    ),
  );

  Widget _libraryBody() => CustomScrollView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    slivers: [
      SliverToBoxAdapter(child: _header()),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 0),
        sliver: SliverToBoxAdapter(child: _summaryCards()),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
        sliver: SliverToBoxAdapter(child: _aiCreationNotice()),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
        sliver: SliverToBoxAdapter(child: _todayReviewBanner()),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
        sliver: SliverToBoxAdapter(child: _goalBanner()),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
        sliver: SliverToBoxAdapter(child: _filters()),
      ),
      if (_inProgressDecks.isNotEmpty) ...[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
          sliver: SliverToBoxAdapter(child: _sectionTitle('Đang học')),
        ),
        _deckGrid(_inProgressDecks),
      ],
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
        sliver: SliverToBoxAdapter(
          child: _sectionTitle(
            _inProgressDecks.isEmpty ? 'Thư viện gói kỹ năng' : 'Khám phá thêm',
          ),
        ),
      ),
      if (_otherDecks.isEmpty && _inProgressDecks.isEmpty)
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              'Không tìm thấy gói phù hợp.',
              style: TextStyle(color: FlashcardHomeScreen.muted),
            ),
          ),
        )
      else
        _deckGrid(_otherDecks),
      const SliverToBoxAdapter(child: SizedBox(height: 28)),
    ],
  );

  Widget _header() => Container(
    padding: EdgeInsets.fromLTRB(
      18,
      MediaQuery.paddingOf(context).top + 6,
      18,
      20,
    ),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF202D31), Color(0xFF171622), Color(0xFF100E19)],
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Quay lại',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            const Spacer(),
            Hero(
              tag: FlashcardHomeScreen.heroTag,
              child: Image.asset(
                'assets/images/planets/saturn.png',
                width: 63,
                height: 47,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        const Text(
          'Thẻ kỹ năng nghề',
          style: TextStyle(
            color: FlashcardHomeScreen.text,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Chọn gói kỹ năng để luyện',
          style: TextStyle(color: FlashcardHomeScreen.muted, fontSize: 13),
        ),
        const SizedBox(height: 17),
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Tìm gói kỹ năng...',
            hintStyle: const TextStyle(color: FlashcardHomeScreen.muted),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: FlashcardHomeScreen.teal,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.055),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: FlashcardHomeScreen.teal),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _summaryCards() => Row(
    children: [
      Expanded(
        child: _SummaryCard(
          icon: Icons.star_rounded,
          title: 'Yêu thích',
          subtitle: '${_service.favoriteCards.length} thẻ',
          accent: FlashcardHomeScreen.lime,
          onTap: _showFavorites,
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: _SummaryCard(
          icon: Icons.add_rounded,
          title: 'Bộ mới',
          subtitle: 'Tạo gói riêng',
          accent: FlashcardHomeScreen.teal,
          onTap: _createDeck,
        ),
      ),
    ],
  );

  Widget _aiCreationNotice() => Tooltip(
    message: 'Tạo thẻ AI sẽ khả dụng khi app kết nối dịch vụ AI.',
    child: OutlinedButton.icon(
      onPressed: null,
      icon: const Icon(Icons.auto_awesome_rounded, size: 17),
      label: const Text('Tạo thẻ bằng AI · Sắp có'),
      style: OutlinedButton.styleFrom(
        disabledForegroundColor: FlashcardHomeScreen.muted.withValues(
          alpha: 0.8,
        ),
        side: BorderSide(
          color: FlashcardHomeScreen.teal.withValues(alpha: 0.16),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
  );

  Widget _todayReviewBanner() => Material(
    color: const Color(0xFF1C282A),
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: _openTodayReview,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: FlashcardHomeScreen.teal.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: FlashcardHomeScreen.lime),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ôn hôm nay: ${_service.dueCards.length} thẻ',
                    style: const TextStyle(
                      color: FlashcardHomeScreen.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'XP flashcard hôm nay: ${_goalProgress.flashcardXpToday()}/100',
                    style: const TextStyle(
                      color: FlashcardHomeScreen.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${_service.streak} ngày streak',
              style: const TextStyle(
                color: FlashcardHomeScreen.teal,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.chevron_right_rounded,
              color: FlashcardHomeScreen.muted,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _goalBanner() {
    final goal = _goalProgress.selectedGoal;
    final percent = (_goalProgress.totalProgress(goal) * 100).round();
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const CareerMapScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF30234A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.route_rounded, color: Colors.purpleAccent),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Hành trình ${goal.name} · $percent%',
                style: const TextStyle(
                  color: FlashcardHomeScreen.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _filters() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(
              'Tất cả',
              _groupFilter == null,
              () => _selectGroup(null),
            ),
            for (final group in FlashcardGroup.values)
              _filterChip(
                group.label,
                _groupFilter == group,
                () => _selectGroup(group),
              ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(
              'Mọi mức',
              _levelFilter == null,
              () => _selectLevel(null),
            ),
            for (final level in FlashcardLevel.values)
              _filterChip(
                level.label,
                _levelFilter == level,
                () => _selectLevel(level),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        backgroundColor: FlashcardHomeScreen.surface,
        selectedColor: const Color(0xFF244039),
        side: BorderSide(
          color: selected
              ? FlashcardHomeScreen.teal.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.06),
        ),
        labelStyle: TextStyle(
          color: selected
              ? FlashcardHomeScreen.lime
              : FlashcardHomeScreen.muted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: FlashcardHomeScreen.text,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      Text(
        '${_filteredDecks.length} gói',
        style: const TextStyle(color: FlashcardHomeScreen.muted, fontSize: 11),
      ),
    ],
  );

  Widget _deckGrid(List<FlashcardDeck> decks) {
    if (decks.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid.builder(
        itemCount: decks.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          mainAxisExtent: 272,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final deck = decks[index];
          final inGoal = _goalProgress.selectedGoal.deckIds.contains(deck.id);
          return Stack(
            children: [
              DeckTile(
                deck: deck,
                mastered: _service.masteredCount(deck),
                progress: _service.masteryProgress(deck),
                isInProgress: _service.masteredCount(deck) > 0,
                onTap: () => _openStudy(deck),
                onEdit: () => _editDeck(deck),
                onDelete: () => _deleteDeck(deck),
                onReset: () => _resetDeck(deck),
              ),
              if (inGoal)
                Positioned(
                  top: 10,
                  left: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF452348),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      child: Text(
                        'Thuộc lộ trình',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 0,
                left: 0,
                width: 64,
                height: 64,
                child: KeyedSubtree(
                  key: ValueKey('flashcard-deck-${deck.id}'),
                  child: GestureDetector(
                    key: _deckActionKeys.putIfAbsent(deck.id, GlobalKey.new),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openStudy(deck),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _bottomBar() => SafeArea(
    top: false,
    minimum: const EdgeInsets.fromLTRB(15, 8, 15, 10),
    child: Container(
      height: 58,
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
              0,
              Icons.grid_view_rounded,
              'Bộ thẻ',
              onTap: () => setState(() => _tabIndex = 0),
            ),
          ),
          Expanded(
            child: _bottomTab(
              1,
              Icons.style_rounded,
              'Học thẻ',
              onTap: () {
                final deck = _service.decks.firstWhere(
                  (item) => item.cards.isNotEmpty,
                  orElse: () => flashcardSeedDecks.first,
                );
                _openStudy(deck);
              },
            ),
          ),
        ],
      ),
    ),
  );

  Widget _bottomTab(
    int index,
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    final active = _tabIndex == index;
    return InkWell(
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
              color: active
                  ? FlashcardHomeScreen.background
                  : FlashcardHomeScreen.muted,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? FlashcardHomeScreen.background
                    : FlashcardHomeScreen.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) => TextField(
    controller: controller,
    maxLines: maxLines,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: FlashcardHomeScreen.muted),
      filled: true,
      fillColor: const Color(0xFF17151F),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
    ),
  );

  Widget _dialogEnum<T>({
    required String label,
    required T value,
    required List<T> values,
    required String Function(T value) display,
    required ValueChanged<T> onChanged,
  }) => DropdownButtonFormField<T>(
    initialValue: value,
    dropdownColor: FlashcardHomeScreen.surface,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: FlashcardHomeScreen.muted),
    ),
    items: values
        .map(
          (item) => DropdownMenuItem(value: item, child: Text(display(item))),
        )
        .toList(),
    onChanged: (selected) {
      if (selected != null) onChanged(selected);
    },
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: FlashcardHomeScreen.surface,
    borderRadius: BorderRadius.circular(19),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: accent.withValues(alpha: 0.19)),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: FlashcardHomeScreen.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FlashcardHomeScreen.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DeckDraft {
  const _DeckDraft({
    required this.title,
    required this.description,
    required this.group,
    required this.level,
    required this.color,
  });

  final String title;
  final String description;
  final FlashcardGroup group;
  final FlashcardLevel level;
  final Color color;
}
