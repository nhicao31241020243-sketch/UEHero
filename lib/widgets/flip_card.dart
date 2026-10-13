import 'dart:math' as math;

import 'package:flutter/material.dart';

class FlipCard extends StatefulWidget {
  const FlipCard({
    required this.front,
    required this.back,
    required this.accent,
    required this.isFlipped,
    required this.onFlip,
    super.key,
  });

  final Widget front;
  final Widget back;
  final Color accent;
  final bool isFlipped;
  final VoidCallback onFlip;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: widget.isFlipped ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFlipped != widget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onFlip,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _controller.value * math.pi;
        final showBack = angle >= math.pi / 2;
        final visible = showBack ? widget.back : widget.front;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY(angle),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [
                  Color(0xFF29293B),
                  Color(0xFF1E202D),
                  Color(0xFF191B25),
                ],
              ),
              border: Border.all(
                color: widget.accent.withValues(alpha: 0.65),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.11),
                  blurRadius: 28,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: const Color(0xFF9B84D8).withValues(alpha: 0.08),
                  blurRadius: 46,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(27),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(showBack ? math.pi : 0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: KeyedSubtree(key: ValueKey(showBack), child: visible),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
