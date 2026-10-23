import 'package:flutter/material.dart';

enum VoiceOrbState { idle, listening, thinking, error }

class VoiceOrb extends StatefulWidget {
  const VoiceOrb({required this.state, this.onRetry, super.key});

  final VoiceOrbState state;
  final VoidCallback? onRetry;

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.state == VoiceOrbState.thinking ? 3600 : 2200,
      ),
    )..repeat(reverse: widget.state != VoiceOrbState.thinking);
  }

  @override
  void didUpdateWidget(covariant VoiceOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _controller.duration = Duration(
        milliseconds: widget.state == VoiceOrbState.thinking ? 3600 : 2200,
      );
      _controller.repeat(reverse: widget.state != VoiceOrbState.thinking);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.state == VoiceOrbState.error;
    final thinking = widget.state == VoiceOrbState.thinking;
    final label = switch (widget.state) {
      VoiceOrbState.idle => 'Tới lượt bạn',
      VoiceOrbState.listening => 'Đang nghe...',
      VoiceOrbState.thinking => 'Phi hành trưởng đang suy nghĩ...',
      VoiceOrbState.error => 'Mất kết nối',
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final scale = 1 + (_controller.value * 0.05);
            return Transform.scale(
              scale: scale,
              child: Transform.rotate(
                angle: thinking ? _controller.value * 2 * 3.14159 : 0,
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: error
                          ? const [Color(0xFFFFD7A6), Color(0xFFB55A67)]
                          : const [Color(0xFF70D8F2), Color(0xFF8D64D8)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (error
                                    ? const Color(0xFFFFA878)
                                    : const Color(0xFF70D8F2))
                                .withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    thinking
                        ? Icons.auto_awesome_rounded
                        : error
                        ? Icons.wifi_off_rounded
                        : Icons.graphic_eq_rounded,
                    color: const Color(0xFF171326),
                    size: 32,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        if (thinking)
          const Text(
            '•••',
            style: TextStyle(
              color: Color(0xFF70D8F2),
              letterSpacing: 4,
              fontWeight: FontWeight.w900,
            ),
          ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFCFC7DC), fontSize: 12),
        ),
        if (error)
          TextButton(onPressed: widget.onRetry, child: const Text('Thử lại')),
      ],
    );
  }
}
