import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../models/character_data.dart';

class InterviewStage extends StatefulWidget {
  const InterviewStage({
    required this.mascot,
    required this.question,
    required this.visibleCharacters,
    required this.speaking,
    super.key,
  });

  final CharacterData mascot;
  final String question;
  final int visibleCharacters;
  final bool speaking;

  @override
  State<InterviewStage> createState() => _InterviewStageState();
}

class _InterviewStageState extends State<InterviewStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleText = widget.question.characters
        .take(widget.visibleCharacters)
        .toString();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF70D8F2), Color(0xFFBFA8FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF70D8F2).withValues(alpha: 0.15),
            blurRadius: 20,
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.1, -0.1),
                  radius: 1.2,
                  colors: [Color(0xFF292244), Color(0xFF11101B)],
                ),
              ),
            ),
            for (final star in const [
              (32.0, 82.0),
              (0.0, 138.0),
              (85.0, 64.0),
              (0.0, 210.0),
            ])
              Positioned(
                top: star.$2,
                left: star.$1 == 0 ? null : star.$1,
                right: star.$1 == 0 ? 38 : null,
                child: AnimatedBuilder(
                  animation: _floatController,
                  builder: (context, child) => Opacity(
                    opacity: 0.2 + _floatController.value * 0.55,
                    child: child,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFCFC7FF),
                    size: 11,
                  ),
                ),
              ),
            Positioned(
              right: -22,
              top: 24,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFBFA8FF).withValues(alpha: 0.16),
                      const Color(0xFF70D8F2).withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: _GlassBadge(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.speaking
                          ? Icons.graphic_eq_rounded
                          : Icons.volume_up,
                      color: const Color(0xFF70D8F2),
                      size: 17,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.speaking ? '•••' : '••',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              top: 12,
              right: 12,
              child: _GlassBadge(
                child: Text(
                  'Phi hành trưởng · Nhà tuyển dụng',
                  style: TextStyle(color: Colors.white, fontSize: 9),
                ),
              ),
            ),
            Positioned.fill(
              top: 22,
              bottom: 78,
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 1300),
                curve: Curves.easeInOut,
                alignment: widget.speaking
                    ? const Alignment(0, -0.03)
                    : const Alignment(0, 0.08),
                child: AnimatedBuilder(
                  animation: _floatController,
                  child: SizedBox(
                    width: 176,
                    child: ModelViewer(
                      key: ValueKey(widget.mascot.modelPath),
                      src: widget.mascot.modelPath,
                      alt: widget.mascot.name,
                      autoPlay: true,
                      animationName: widget.mascot.animationName,
                      autoRotate: true,
                      autoRotateDelay: 0,
                      cameraControls: false,
                      disableZoom: true,
                      backgroundColor: Colors.transparent,
                      debugLogging: false,
                    ),
                  ),
                  builder: (context, child) => Transform.translate(
                    offset: Offset(
                      0,
                      (_floatController.value - 0.5) *
                          (widget.speaking ? 16 : 8),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 76),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xCC100E19),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    visibleText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.35,
                    ),
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

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0x88211D2B),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
    ),
    child: child,
  );
}
