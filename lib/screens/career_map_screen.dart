import 'package:flutter/material.dart';

import '../config/career_progress_config.dart';
import '../services/progress_service.dart';

class CareerMapScreen extends StatefulWidget {
  const CareerMapScreen({this.embedded = false, super.key});

  final bool embedded;

  @override
  State<CareerMapScreen> createState() => _CareerMapScreenState();
}

class _CareerMapScreenState extends State<CareerMapScreen> {
  static const _background = Color(0xFF100E19);
  static const _accent = Color(0xFF90E8FF);
  final _progress = ProgressService.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _progress.initialize();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        automaticallyImplyLeading: !widget.embedded,
        title: const Text(
          'Career Map',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : AnimatedBuilder(
              animation: _progress,
              builder: (context, _) => _buildMap(context),
            ),
    );
  }

  Widget _buildMap(BuildContext context) {
    final points = _progress.totalPoints;
    final nextNode = _progress.nextNodeFor(points);
    final nextGap = _progress.pointsToNextNode(points);
    return Stack(
      children: [
        const Positioned.fill(child: _Starfield()),
        ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
          children: [
            _buildHeader(points, nextNode, nextGap),
            const SizedBox(height: 18),
            _buildRoute(points),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(int points, CareerNodeConfig? nextNode, int nextGap) {
    final progress = nextNode == null
        ? 1.0
        : ((points - _progress.currentNodeFor(points).threshold) /
                  (nextNode.threshold -
                      _progress.currentNodeFor(points).threshold))
              .clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF30295A), Color(0xFF1B263F)],
        ),
        border: Border.all(color: Colors.white12),
        boxShadow: const [BoxShadow(color: Color(0x442A8BFF), blurRadius: 24)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: _accent),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Galaxy Route',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _progress.rankFor(points),
                style: const TextStyle(
                  color: Color(0xFFFFD36E),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$points',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 6),
                child: Text(
                  'Stardust',
                  style: TextStyle(color: _accent, fontWeight: FontWeight.w700),
                ),
              ),
              const Spacer(),
              if (nextNode != null)
                Text(
                  'Còn $nextGap',
                  style: const TextStyle(color: Color(0xFFCAC5D7)),
                )
              else
                const Text(
                  'Đã tới đích',
                  style: TextStyle(color: Color(0xFF77D6AE)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(_accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nextNode == null
                ? 'Bạn đã hoàn thành Galaxy Route.'
                : 'Chặng tiếp theo: ${nextNode.title}',
            style: const TextStyle(color: Color(0xFFCAC5D7), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRoute(int points) {
    return Column(
      children: [
        for (var index = 0; index < careerNodes.length; index++) ...[
          _NodeTile(
            node: careerNodes[index],
            state: _nodeState(careerNodes[index], points),
            offset: index.isEven ? 0 : 36,
            onTap: () => _showNode(careerNodes[index], points),
          ),
          if (index < careerNodes.length - 1)
            const SizedBox(
              height: 28,
              child: Align(
                child: Icon(
                  Icons.south_rounded,
                  color: Color(0xFF6B6384),
                  size: 22,
                ),
              ),
            ),
        ],
        if (points == 0)
          const Padding(
            padding: EdgeInsets.only(top: 18),
            child: Text(
              'Bắt đầu bằng một hoạt động nhỏ: học flashcard hoặc cập nhật hồ sơ.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFBDB7C9), height: 1.4),
            ),
          ),
      ],
    );
  }

  _NodeState _nodeState(CareerNodeConfig node, int points) {
    if (points >= node.threshold) {
      return node.id == _progress.currentNodeFor(points).id
          ? _NodeState.current
          : _NodeState.completed;
    }
    return _NodeState.locked;
  }

  void _showNode(CareerNodeConfig node, int points) {
    final state = _nodeState(node, points);
    showModalBottomSheet<void>(
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
              Text(
                node.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                node.description,
                style: const TextStyle(color: Color(0xFFCFC7DC), height: 1.4),
              ),
              const SizedBox(height: 14),
              Text(
                state == _NodeState.locked
                    ? 'Mở khóa ở ${node.threshold} Stardust'
                    : 'Mốc ${node.threshold} Stardust · ${_stateLabel(state)}',
                style: const TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              for (final task in node.tasks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        state == _NodeState.completed
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: state == _NodeState.completed
                            ? const Color(0xFF77D6AE)
                            : Colors.white38,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task,
                          style: const TextStyle(color: Colors.white70),
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

  String _stateLabel(_NodeState state) => switch (state) {
    _NodeState.locked => 'Locked',
    _NodeState.current => 'Current',
    _NodeState.completed => 'Completed',
  };
}

enum _NodeState { locked, current, completed }

class _NodeTile extends StatelessWidget {
  const _NodeTile({
    required this.node,
    required this.state,
    required this.offset,
    required this.onTap,
  });

  final CareerNodeConfig node;
  final _NodeState state;
  final double offset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _NodeState.locked => const Color(0xFF6D687B),
      _NodeState.current => const Color(0xFF90E8FF),
      _NodeState.completed => const Color(0xFF77D6AE),
    };
    return Transform.translate(
      offset: Offset(offset, 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xDD211D2B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: color.withValues(
                alpha: state == _NodeState.locked ? 0.3 : 0.85,
              ),
              width: state == _NodeState.current ? 2 : 1,
            ),
            boxShadow: [
              if (state != _NodeState.locked)
                BoxShadow(color: color.withValues(alpha: 0.24), blurRadius: 20),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: 0.8),
                      color.withValues(alpha: 0.15),
                    ],
                  ),
                ),
                child: Icon(_iconFor(node.icon), color: color, size: 27),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.title,
                      style: TextStyle(
                        color: state == _NodeState.locked
                            ? Colors.white54
                            : Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      node.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFAAA5B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                state == _NodeState.locked
                    ? Icons.lock_outline
                    : state == _NodeState.current
                    ? Icons.radio_button_checked
                    : Icons.check_circle,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String icon) => switch (icon) {
    'rocket_launch' => Icons.rocket_launch_rounded,
    'auto_stories' => Icons.auto_stories_rounded,
    'construction' => Icons.construction_rounded,
    'folder_special' => Icons.folder_special_rounded,
    'record_voice_over' => Icons.record_voice_over_rounded,
    'work' => Icons.work_rounded,
    _ => Icons.stars_rounded,
  };
}

class _Starfield extends StatelessWidget {
  const _Starfield();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _StarfieldPainter());
}

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.15);
    for (var index = 0; index < 80; index++) {
      final x = (index * 73.0) % size.width;
      final y = (index * 131.0) % size.height;
      canvas.drawCircle(Offset(x, y), index % 7 == 0 ? 1.4 : 0.7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
