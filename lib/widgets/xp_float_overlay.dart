import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/xp_gain.dart';
import '../services/points_manager.dart';

class XpFloatOverlay extends StatefulWidget {
  const XpFloatOverlay({required this.child, super.key});

  final Widget child;

  @override
  XpFloatOverlayState createState() => XpFloatOverlayState();
}

class XpFloatOverlayState extends State<XpFloatOverlay>
    with TickerProviderStateMixin {
  final _xp = PointsManager.instance;
  final _random = math.Random();
  final List<_VisibleGain> _visible = [];
  final List<XpGain> _queue = [];
  StreamSubscription<XpGain>? _subscription;
  Timer? _queueTimer;
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    _subscription = _xp.gains.listen(_onGain);
  }

  void _onGain(XpGain gain) {
    // Home đang mở thì đánh dấu các gain đã được phát.
    _xp.drainPending();
    showGains([gain]);
  }

  void showGains(List<XpGain> gains) {
    if (!mounted || gains.isEmpty) return;
    if (_queue.length + gains.length > 5) {
      final combined = _combine([..._queue, ...gains]);
      _queue
        ..clear()
        ..add(combined);
    } else {
      _queue.addAll(gains);
    }
    _startNext();
  }

  XpGain _combine(List<XpGain> gains) => XpGain(
    amount: gains.fold(0, (total, gain) => total + gain.amount),
    skill: null,
    bar: gains.first.bar,
    leveledUp: gains.any((gain) => gain.leveledUp),
    at: gains.last.at,
  );

  void _startNext() {
    if (_queueTimer != null || _queue.isEmpty || !mounted) return;
    final gain = _queue.removeAt(0);
    final visible = _VisibleGain(
      id: _nextId++,
      gain: gain,
      left: _random.nextBool() ? -95 : 45,
      top: -_random.nextInt(51) - 48,
      controller: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      ),
    );
    _visible.add(visible);
    setState(() {});
    visible.controller.forward().whenCompleteOrCancel(() {
      if (!mounted) return;
      visible.controller.dispose();
      _visible.removeWhere((item) => item.id == visible.id);
      setState(() {});
    });
    _queueTimer = Timer(const Duration(milliseconds: 250), () {
      _queueTimer = null;
      _startNext();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _queueTimer?.cancel();
    for (final item in _visible) {
      item.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final item in _visible)
                  _FloatingGain(
                    key: ValueKey(item.id),
                    gain: item.gain,
                    controller: item.controller,
                    left: item.left,
                    top: item.top,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VisibleGain {
  _VisibleGain({
    required this.id,
    required this.gain,
    required this.left,
    required this.top,
    required this.controller,
  });

  final int id;
  final XpGain gain;
  final double left;
  final double top;
  final AnimationController controller;
}

class _FloatingGain extends StatelessWidget {
  const _FloatingGain({
    required this.gain,
    required this.controller,
    required this.left,
    required this.top,
    super.key,
  });

  final XpGain gain;
  final AnimationController controller;
  final double left;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) => Opacity(
          opacity: controller.value < 0.2
              ? controller.value / 0.2
              : controller.value > 0.72
              ? (1 - controller.value) / 0.28
              : 1,
          child: Transform.translate(
            offset: Offset(0, -50 * Curves.easeOut.transform(controller.value)),
            child: child,
          ),
        ),
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFB66DFF), Color(0xFF59C9F5)],
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '+${gain.amount} XP${gain.leveledUp ? '  Level up!' : ''}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Color(0xAA0D0A1A), blurRadius: 3)],
                ),
              ),
              if (gain.skill != null)
                Text(
                  gain.skill!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
