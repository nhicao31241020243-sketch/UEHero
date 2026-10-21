import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/career_roadmap_config.dart';
import '../models/character_data.dart';
import '../models/xp_entry.dart';
import '../services/mascot_selection_store.dart';
import '../services/points_manager.dart';
import '../theme/space_theme.dart';
import '../widgets/space_glass_widgets.dart';
import '../widgets/space_home_widgets.dart';

const _planetPalettes = <List<Color>>[
  [Color(0xFF7DE8FF), Color(0xFF2E7BD6)],
  [Color(0xFFFFB86B), Color(0xFFD1581F)],
  [Color(0xFFB89BFF), Color(0xFF5B3BC7)],
  [Color(0xFF8CFFC4), Color(0xFF1E9B6B)],
  [Color(0xFFFF9FD8), Color(0xFFB8328F)],
  [Color(0xFFFFE27A), Color(0xFFE08A1E)],
];

const _lockedPalette = [Color(0xFF6B7088), Color(0xFF2A2D40)];
const _gold = Color(0xFFFFD36E);

enum _NodeState { completed, current, locked }

class CareerMapScreen extends StatefulWidget {
  const CareerMapScreen({this.embedded = false, super.key});

  final bool embedded;

  @override
  State<CareerMapScreen> createState() => _CareerMapScreenState();
}

class _CareerMapScreenState extends State<CareerMapScreen>
    with SingleTickerProviderStateMixin {
  static const _spacing = 168.0;
  static const _topPad = 70.0;
  static const _bottomPad = 90.0;

  final _scroll = ScrollController();
  late final AnimationController _pulse;
  String _role = defaultRoadmapRole;
  Set<int> _done = {};
  String _mascot = '🚀';
  bool _loading = true;
  bool _scrolled = false;

  List<Milestone> get _milestones => roadmapFor(_role);
  String get _doneKey => 'roadmap_done_$_role';

  int get _currentIndex {
    var index = 0;
    while (index < _milestones.length && _done.contains(index)) {
      index++;
    }
    return index;
  }

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    await PointsManager.instance.initialize();
    final role = resolveRoadmapRole(prefs.getString('career_goal'));
    final done = (prefs.getStringList('roadmap_done_$role') ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
    var mascot = '🚀';
    try {
      final mascots = await MascotSelectionStore.instance.read();
      mascot = (mascots.primary ?? CharacterSelection.selected)?.emoji ?? '🚀';
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _role = role;
      _done = done;
      _mascot = mascot;
      _loading = false;
    });
  }

  double _mapHeight(int count) => _topPad + _bottomPad + (count - 1) * _spacing;

  double _nodeY(int index, int count) =>
      _mapHeight(count) - _bottomPad - index * _spacing;

  Offset _nodeCenter(int index, int count, double width) {
    final x = width * (0.5 + 0.26 * (index.isEven ? -1 : 1));
    return Offset(x, _nodeY(index, count));
  }

  void _scrollToCurrent(BoxConstraints box) {
    if (_scrolled || !_scroll.hasClients) return;
    _scrolled = true;
    final count = _milestones.length;
    final index = math.min(_currentIndex, count - 1);
    final target = _nodeY(index, count) - box.maxHeight * 0.6;
    _scroll.jumpTo(target.clamp(0, _scroll.position.maxScrollExtent));
  }

  Future<void> _complete(int index) async {
    final milestone = _milestones[index];
    final prefs = await SharedPreferences.getInstance();
    final next = {..._done, index};
    await prefs.setStringList(
      _doneKey,
      (next.toList()..sort()).map((e) => '$e').toList(),
    );
    await PointsManager.instance.addXP(
      thanh: XpBar.kienThuc,
      luong: milestone.xp,
      nguon: 'roadmap',
      skill: _role,
      sourceRef: '$_role#$index',
    );
    if (!mounted) return;
    setState(() => _done = next);
  }

  void _openMilestone(int index, _NodeState state) {
    final milestone = _milestones[index];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _MilestoneSheet(
        number: index + 1,
        milestone: milestone,
        state: state,
        onComplete: () async {
          await _complete(index);
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          if (!mounted) return;
          final isLast = index == _milestones.length - 1;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isLast
                    ? 'Hoàn thành lộ trình! +${milestone.xp} XP'
                    : '+${milestone.xp} XP · Đã mở chặng ${index + 2}',
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: !widget.embedded,
        title: const Text(
          'Career Map',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildRoadmap()),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final total = _milestones.length;
    final progress = _done.length.clamp(0, total) / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LỘ TRÌNH: ${_role.toUpperCase()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ListenableBuilder(
                  listenable: PointsManager.instance,
                  builder: (_, _) => Text(
                    formatXp(PointsManager.instance.totalXp),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 6, bottom: 4),
                  child: Text(
                    'STARDUST',
                    style: TextStyle(
                      color: SpaceTheme.glow,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).round()}% · ${_done.length}/$total chặng',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: progress),
                duration: const Duration(milliseconds: 600),
                builder: (_, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(_gold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmap() {
    final milestones = _milestones;
    final count = milestones.length;
    final current = _currentIndex;
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToCurrent(box),
        );
        final centers = [
          for (var i = 0; i < count; i++) _nodeCenter(i, count, width),
        ];
        return SingleChildScrollView(
          controller: _scroll,
          child: SizedBox(
            width: width,
            height: _mapHeight(count),
            child: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _PathPainter(centers: centers, reached: current),
                    ),
                  ),
                ),
                for (var i = 0; i < count; i++)
                  _buildNode(i, milestones[i], centers[i], current),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNode(int i, Milestone milestone, Offset center, int current) {
    final state = _done.contains(i)
        ? _NodeState.completed
        : (i == current ? _NodeState.current : _NodeState.locked);
    final size = state == _NodeState.current ? 96.0 : 76.0;
    const slotWidth = 140.0;
    const slotHeight = 190.0;
    final palette = state == _NodeState.locked
        ? _lockedPalette
        : _planetPalettes[i % _planetPalettes.length];

    final planet = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (state != _NodeState.locked)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) {
                final t = state == _NodeState.current ? _pulse.value : 0.5;
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: palette.first.withValues(alpha: 0.35 + 0.3 * t),
                        blurRadius: 20 + 18 * t,
                        spreadRadius: 2 + 4 * t,
                      ),
                    ],
                  ),
                );
              },
            ),
          PlanetOrb(
            colors: palette,
            style: state == _NodeState.current
                ? PlanetStyle.ringed
                : (i.isEven ? PlanetStyle.bands : PlanetStyle.rocky),
            seed: i + 3,
          ),
          if (state == _NodeState.locked)
            const Icon(Icons.lock_rounded, color: Colors.white70, size: 28),
          if (state == _NodeState.completed)
            Positioned(top: -4, left: -4, child: _NumberBadge(number: i + 1)),
        ],
      ),
    );

    return Positioned(
      left: center.dx - slotWidth / 2,
      top: center.dy - slotHeight / 2 + 12,
      width: slotWidth,
      height: slotHeight,
      child: PressScale(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openMilestone(i, state),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 44,
                child: state == _NodeState.current
                    ? AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(0, -6 * _pulse.value),
                          child: child,
                        ),
                        child: Text(
                          _mascot,
                          style: const TextStyle(fontSize: 34),
                        ),
                      )
                    : null,
              ),
              planet,
              const SizedBox(height: 8),
              Text(
                'Chặng ${i + 1}: ${milestone.shortLabel}',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: state == _NodeState.locked
                      ? Colors.white54
                      : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(
                height: 20,
                child: state == _NodeState.completed
                    ? const Text('⭐⭐⭐', style: TextStyle(fontSize: 12))
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF141A47),
      border: Border.all(color: _gold, width: 1.5),
    ),
    child: Text(
      '$number',
      style: const TextStyle(
        color: _gold,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _PathPainter extends CustomPainter {
  const _PathPainter({required this.centers, required this.reached});

  final List<Offset> centers;
  final int reached;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < centers.length - 1; i++) {
      final a = centers[i];
      final b = centers[i + 1];
      final mid = (a.dy + b.dy) / 2;
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, mid, b.dx, mid, b.dx, b.dy);
      final lit = i < reached;
      final color = lit ? SpaceTheme.glow : Colors.white24;
      final glow = Paint()
        ..color = color.withValues(alpha: lit ? 0.35 : 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      final line = Paint()
        ..color = color.withValues(alpha: lit ? 0.95 : 0.5)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.5;
      for (final metric in path.computeMetrics()) {
        var distance = 0.0;
        while (distance < metric.length) {
          final segment = metric.extractPath(distance, distance + 9);
          canvas.drawPath(segment, glow);
          canvas.drawPath(segment, line);
          distance += 17;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.reached != reached || old.centers != centers;
}

class _MilestoneSheet extends StatefulWidget {
  const _MilestoneSheet({
    required this.number,
    required this.milestone,
    required this.state,
    required this.onComplete,
  });

  final int number;
  final Milestone milestone;
  final _NodeState state;
  final Future<void> Function() onComplete;

  @override
  State<_MilestoneSheet> createState() => _MilestoneSheetState();
}

class _MilestoneSheetState extends State<_MilestoneSheet> {
  late final List<bool> _checked = List.filled(
    widget.milestone.tasks.length,
    widget.state == _NodeState.completed,
  );
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final milestone = widget.milestone;
    final state = widget.state;
    final enabled = state == _NodeState.current && !_busy;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHẶNG ${widget.number}',
                  style: const TextStyle(
                    color: SpaceTheme.glow,
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  milestone.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < milestone.tasks.length; i++)
                  CheckboxListTile(
                    value: _checked[i],
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    activeColor: _gold,
                    checkColor: Colors.black,
                    title: Text(
                      milestone.tasks[i],
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    onChanged: state == _NodeState.completed
                        ? null
                        : (value) =>
                              setState(() => _checked[i] = value ?? false),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Opacity(
                    opacity: enabled || state == _NodeState.completed ? 1 : 0.5,
                    child: GlassButton(
                      onPressed: enabled
                          ? () async {
                              setState(() => _busy = true);
                              await widget.onComplete();
                            }
                          : null,
                      child: Center(
                        child: Text(
                          switch (state) {
                            _NodeState.completed => 'Đã hoàn thành',
                            _NodeState.locked =>
                              'Hoàn thành chặng trước để mở khóa',
                            _NodeState.current =>
                              'Đánh dấu hoàn thành · +${milestone.xp} XP',
                          },
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
