import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/career_map_layout.dart';
import '../config/career_progress_config.dart';
import '../models/career_progress.dart';
import '../models/character_data.dart';
import '../services/progress_service.dart';

class CareerMapScreen extends StatefulWidget {
  const CareerMapScreen({this.embedded = false, super.key});

  final bool embedded;

  @override
  State<CareerMapScreen> createState() => _CareerMapScreenState();
}

class _CareerMapScreenState extends State<CareerMapScreen>
    with TickerProviderStateMixin {
  static const _background = Color(0xFF0D0A1A);
  static const _accent = Color(0xFFFF8FD8);
  static const _cyan = Color(0xFF8DE9FF);

  final _progress = ProgressService.instance;
  final _steps = buildCareerMapSteps();
  final _scrollController = ScrollController();
  late final AnimationController _travelController;
  late final AnimationController _pulseController;
  CharacterData _companion = characterData.first;
  double _displayStone = 0;
  int _targetStone = 0;
  bool _loading = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _travelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() => setState(() {}));
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
    _progress.addListener(_onProgressChanged);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _progress.initialize();
      final preferences = await SharedPreferences.getInstance();
      _companion =
          characterById(preferences.getString('selected_mascot')) ??
          CharacterSelection.selected ??
          characterData.first;
      _targetStone = stoneIndexForPoints(_progress.totalPoints, _steps);
      _displayStone = _targetStone.toDouble();
      await _progress.consumePendingAnimation();
      if (mounted) {
        setState(() => _loading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToMascot());
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError = error;
          _loading = false;
        });
      }
    }
  }

  void _onProgressChanged() {
    if (!_progress.isInitialized || !mounted) return;
    final next = stoneIndexForPoints(_progress.totalPoints, _steps);
    if (next == _targetStone) return;
    final start = _displayStone;
    _targetStone = next;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _displayStone = next.toDouble();
      _scrollToMascot();
      setState(() {});
      return;
    }
    _travelController
      ..reset()
      ..addStatusListener(_finishTravel)
      ..forward();
    _displayStone = start;
  }

  void _finishTravel(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _travelController.removeStatusListener(_finishTravel);
    _displayStone = _targetStone.toDouble();
    _scrollToMascot();
  }

  void _skipTravel() {
    if (_travelController.isAnimating) {
      _travelController.value = 1;
      _displayStone = _targetStone.toDouble();
    }
  }

  void _scrollToMascot() {
    if (!_scrollController.hasClients) return;
    final contentHeight = _mapHeight;
    final stone = _steps[_targetStone];
    final target = (1 - stone.y) * contentHeight - 150;
    _scrollController.animateTo(
      target.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
    );
  }

  double get _mapHeight => math.max(1500, _steps.length * 92.0);

  @override
  void dispose() {
    _progress.removeListener(_onProgressChanged);
    _scrollController.dispose();
    _travelController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background.withValues(alpha: 0.92),
        elevation: 0,
        automaticallyImplyLeading: !widget.embedded,
        title: const Text(
          'Career Map',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _cyan))
          : _loadError != null
          ? _errorState()
          : GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _skipTravel,
              child: Stack(
                children: [
                  ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 48),
                    children: [
                      _buildHeader(),
                      _buildMapCanvas(),
                    ],
                  ),
                  _buildTopHint(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final points = _progress.totalPoints;
    final next = _progress.nextNodeFor(points);
    final current = _progress.currentNodeFor(points);
    final progress = next == null
        ? 1.0
        : ((points - current.threshold) / (next.threshold - current.threshold))
              .clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(17, 14, 17, 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF452348), Color(0xFF20204A)],
          ),
          border: Border.all(color: const Color(0x66FF9FD9)),
          boxShadow: const [BoxShadow(color: Color(0x443B1B6B), blurRadius: 22)],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: _accent, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'STEPPING STONE PATH',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  _progress.rankFor(points),
                  style: const TextStyle(
                    color: Color(0xFFFFD36E),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$points',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 7, bottom: 5),
                  child: Text(
                    'STARDUST',
                    style: TextStyle(
                      color: _cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  next == null ? 'Đã tới đích' : 'Còn ${next.threshold - points}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(_accent),
              ),
            ),
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                next == null
                    ? 'Job Galaxy đã mở'
                    : 'Tiếp theo: ${next.title}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCanvas() {
    return SizedBox(
      height: _mapHeight,
      child: RepaintBoundary(
        child: Stack(
          children: [
            const Positioned.fill(child: _SpaceBackdrop()),
            _planet(
              'assets/images/planets/neptune.png',
              left: -70,
              top: 155,
              size: 220,
              opacity: 0.68,
            ),
            _planet(
              'assets/images/planets/uranus.png',
              right: -88,
              top: 535,
              size: 230,
              opacity: 0.55,
            ),
            _planet(
              'assets/images/planets/jupiter.png',
              left: -78,
              top: 930,
              size: 220,
              opacity: 0.6,
            ),
            _planet(
              'assets/images/planets/mars.png',
              right: -58,
              top: 1250,
              size: 180,
              opacity: 0.55,
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _PathPainter(
                  steps: _steps,
                  mapHeight: _mapHeight,
                  currentStone: _targetStone,
                ),
              ),
            ),
            for (final step in _steps)
              _buildStone(step, step.index == _targetStone),
            _buildMascot(),
            if (kDebugMode)
              Positioned(
                top: 12,
                right: 16,
                child: OutlinedButton.icon(
                  onPressed: _grantDebugStardust,
                  icon: const Icon(Icons.bolt_rounded, size: 16),
                  label: const Text('+100 Stardust'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _cyan,
                    side: const BorderSide(color: _cyan),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _planet(
    String asset, {
    double? left,
    double? right,
    required double top,
    required double size,
    required double opacity,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Opacity(
        opacity: opacity,
        child: Image.asset(asset, width: size, height: size),
      ),
    );
  }

  Widget _buildStone(StoneStep step, bool current) {
    final points = _progress.totalPoints;
    final reached = step.progress <= points;
    final isMilestone = step.isMilestone;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final size = isMilestone ? 106.0 : 62.0;
    final left = step.x * MediaQuery.sizeOf(context).width - size / 2;
    final top = (1 - step.y) * _mapHeight - size / 2;
    final color = reached
        ? (isMilestone ? const Color(0xFFE477B8) : const Color(0xFF9D4E9D))
        : const Color(0xFF332743);
    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: isMilestone ? () => _showNode(step.milestoneId!) : null,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) => Transform.rotate(
            angle: reduceMotion || !isMilestone
                ? 0
                : math.sin(_pulseController.value * math.pi) * 0.025,
            child: child,
          ),
          child: CustomPaint(
            painter: _StonePainter(
              color: color,
              glow: current || isMilestone && reached,
              milestone: isMilestone,
            ),
            child: Center(
              child: isMilestone
                  ? Icon(
                      reached ? Icons.flag_rounded : Icons.lock_rounded,
                      color: reached ? Colors.white : Colors.white38,
                      size: 27,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMascot() {
    final index = _displayStone.round().clamp(0, _steps.length - 1);
    final step = _steps[index];
    final baseX = step.x * MediaQuery.sizeOf(context).width;
    final baseY = (1 - step.y) * _mapHeight - 76;
    final travel = _travelController.value;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final hop = !reduceMotion && _travelController.isAnimating
        ? math.sin(travel * math.pi) * 52
        : reduceMotion
        ? 0
        : math.sin(_pulseController.value * math.pi * 2) * 4;
    return Positioned(
      left: baseX - 39,
      top: baseY - hop,
      width: 78,
      height: 82,
      child: IgnorePointer(
        child: Column(
          children: [
            Expanded(
              child: ModelViewer(
                key: ValueKey(_companion.modelPath),
                src: _companion.modelPath,
                alt: _companion.name,
                autoPlay: true,
                animationName: _companion.animationName,
                cameraControls: false,
                disableZoom: true,
                backgroundColor: Colors.transparent,
                debugLogging: false,
              ),
            ),
            Container(
              width: 30,
              height: 7,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(99),
                boxShadow: const [
                  BoxShadow(color: Color(0x66FF7BCB), blurRadius: 9),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHint() => Positioned(
    left: 20,
    right: 20,
    bottom: 14,
    child: IgnorePointer(
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xDD1B1630),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: Colors.white12),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            child: Text(
              'Chạm vào bậc lớn để xem chặng  •  Chạm màn hình để bỏ qua hop',
              style: TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _grantDebugStardust() async {
    final awarded = await _progress.awardPoints(
      ProgressEventType.debugGrant,
      refId: 'debug-${DateTime.now().microsecondsSinceEpoch}',
      metadata: const {'source': 'debug_button'},
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          awarded == 0
              ? 'Đã chạm giới hạn Stardust hôm nay.'
              : 'Đã nhận +$awarded Stardust demo.',
        ),
      ),
    );
  }

  Widget _errorState() => Center(
    child: TextButton(
      onPressed: () {
        setState(() {
          _loading = true;
          _loadError = null;
        });
        _initialize();
      },
      child: const Text('Không thể tải Career Map · Thử lại'),
    ),
  );

  void _showNode(String nodeId) {
    final node = careerNodes.firstWhere((item) => item.id == nodeId);
    final unlocked = _progress.totalPoints >= node.threshold;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF211A31),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                node.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                node.description,
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 13),
              Text(
                unlocked
                    ? 'Đã mở · ${node.threshold} Stardust'
                    : 'Khóa · cần ${node.threshold} Stardust',
                style: const TextStyle(
                  color: _cyan,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              for (final task in node.tasks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        unlocked
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        color: unlocked ? const Color(0xFF77D6AE) : Colors.white38,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(task, style: const TextStyle(color: Colors.white70)),
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
}

class _SpaceBackdrop extends StatelessWidget {
  const _SpaceBackdrop();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _SpaceBackdropPainter());
}

class _SpaceBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF211239), Color(0xFF100D28), Color(0xFF241132)],
        ).createShader(rect),
    );
    final stars = Paint()..color = Colors.white.withValues(alpha: 0.28);
    for (var index = 0; index < 150; index++) {
      final x = (index * 97.0) % size.width;
      final y = (index * 173.0) % size.height;
      canvas.drawCircle(Offset(x, y), index % 11 == 0 ? 1.4 : 0.65, stars);
    }
    final nebula = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x664F176E), Color(0x001E123A)],
      ).createShader(Rect.fromCircle(center: Offset(size.width * .52, 370), radius: 270));
    canvas.drawCircle(Offset(size.width * .52, 370), 270, nebula);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PathPainter extends CustomPainter {
  const _PathPainter({
    required this.steps,
    required this.mapHeight,
    required this.currentStone,
  });

  final List<StoneStep> steps;
  final double mapHeight;
  final int currentStone;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var index = 0; index < steps.length; index++) {
      final step = steps[index];
      final point = Offset(step.x * size.width, (1 - step.y) * mapHeight);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        final previous = steps[index - 1];
        final previousPoint = Offset(
          previous.x * size.width,
          (1 - previous.y) * mapHeight,
        );
        path.cubicTo(
          (previousPoint.dx + point.dx) / 2,
          previousPoint.dy,
          (previousPoint.dx + point.dx) / 2,
          point.dy,
          point.dx,
          point.dy,
        );
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xAAE879C6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x886E4AB0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) =>
      oldDelegate.currentStone != currentStone;
}

class _StonePainter extends CustomPainter {
  const _StonePainter({
    required this.color,
    required this.glow,
    required this.milestone,
  });

  final Color color;
  final bool glow;
  final bool milestone;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * (milestone ? .46 : .43);
    final path = Path();
    for (var index = 0; index < 7; index++) {
      final angle = -math.pi / 2 + index * 2 * math.pi / 7;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    if (glow) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: .65)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: .95), color.withValues(alpha: .3)],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: glow ? .95 : .45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = glow ? 2.5 : 1,
    );
  }

  @override
  bool shouldRepaint(covariant _StonePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.glow != glow ||
      oldDelegate.milestone != milestone;
}
