import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../models/character_data.dart';
import '../theme/space_theme.dart';

typedef CareerMapModelBuilder = Widget Function(CharacterData character);

const careerMapMascotWidth = 68.0;
const careerMapMascotHeight = 76.0;

Offset careerMapMascotPosition(Offset nodeCenter, {required double nodeSize}) =>
    Offset(
      nodeCenter.dx - careerMapMascotWidth / 2,
      nodeCenter.dy - nodeSize / 2 - careerMapMascotHeight,
    );

double careerMapPinOffset(
  double trackWidth,
  double progress, {
  double pinWidth = 48,
}) {
  final maxOffset = (trackWidth - pinWidth).clamp(0.0, double.infinity);
  final desiredOffset = trackWidth * progress.clamp(0.0, 1.0) - pinWidth / 2;
  return desiredOffset.clamp(0.0, maxOffset);
}

class MapMascot extends StatelessWidget {
  const MapMascot({
    required this.character,
    required this.animation,
    required this.reduceMotion,
    this.modelBuilder,
    super.key,
  });

  final CharacterData character;
  final Animation<double> animation;
  final bool reduceMotion;
  final CareerMapModelBuilder? modelBuilder;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: careerMapMascotWidth,
    height: careerMapMascotHeight,
    child: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Transform.scale(
            scaleX: reduceMotion ? 1 : 1 - animation.value * .12,
            child: Opacity(
              opacity: reduceMotion ? .2 : .28 - animation.value * .08,
              child: child,
            ),
          ),
          child: Container(
            width: 38,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF03030A),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: character.primaryColor.withValues(alpha: .35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          bottom: 4,
          child: AnimatedBuilder(
            animation: animation,
            child: IgnorePointer(
              child:
                  modelBuilder?.call(character) ??
                  ModelViewer(
                    key: ValueKey('career-map-mascot-${character.id}'),
                    src: character.modelPath,
                    alt: character.name,
                    autoPlay: true,
                    animationName: character.animationName,
                    autoRotate: false,
                    cameraControls: false,
                    disableZoom: true,
                    backgroundColor: Colors.transparent,
                    cameraOrbit: '0deg 75deg 105%',
                    fieldOfView: '30deg',
                    loading: Loading.eager,
                    reveal: Reveal.auto,
                    debugLogging: false,
                  ),
            ),
            builder: (context, child) => Transform.translate(
              offset: Offset(0, reduceMotion ? 0 : -4 * animation.value),
              child: child,
            ),
          ),
        ),
      ],
    ),
  );
}

class CareerProgressCard extends StatelessWidget {
  const CareerProgressCard({
    required this.role,
    required this.zone,
    required this.progress,
    required this.completed,
    required this.total,
    required this.stardust,
    required this.mascot,
    required this.reduceMotion,
    this.modelBuilder,
    super.key,
  });

  final String role;
  final String zone;
  final double progress;
  final int completed;
  final int total;
  final Widget stardust;
  final CharacterData mascot;
  final bool reduceMotion;
  final CareerMapModelBuilder? modelBuilder;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(14, 4, 14, 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xF5272440), Color(0xF510172E)],
      ),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: SpaceTheme.glassBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x65000000),
          blurRadius: 18,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Row(
      children: [
        _MascotPortrait(character: mascot),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  letterSpacing: .7,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Đang ở vùng: $zone',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFC8C1DA),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              _ProgressTrack(
                progress: progress,
                mascot: mascot,
                reduceMotion: reduceMotion,
                modelBuilder: modelBuilder,
              ),
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: SpaceTheme.glow,
                    size: 12,
                  ),
                  const SizedBox(width: 3),
                  stardust,
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.flag_rounded,
                    color: Color(0xFFB7A6FF),
                    size: 12,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$completed/$total nhiệm vụ',
                    style: const TextStyle(
                      color: Color(0xFFE5E0F2),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MascotPortrait extends StatelessWidget {
  const _MascotPortrait({required this.character});

  final CharacterData character;

  @override
  Widget build(BuildContext context) => Container(
    width: 58,
    height: 58,
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        colors: [Color(0xFFBFA8FF), Color(0xFF68D5F4)],
      ),
      boxShadow: [
        BoxShadow(
          color: character.primaryColor.withValues(alpha: .24),
          blurRadius: 13,
        ),
      ],
    ),
    child: ClipOval(
      child: ColoredBox(
        color: const Color(0xFF25223B),
        child: Transform.scale(
          scale: 1.65,
          alignment: Alignment.topCenter,
          child: Image.asset(
            character.previewAsset,
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.person_rounded,
              color: Color(0xFFD8CCFF),
              size: 30,
            ),
          ),
        ),
      ),
    ),
  );
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({
    required this.progress,
    required this.mascot,
    required this.reduceMotion,
    required this.modelBuilder,
  });

  final double progress;
  final CharacterData mascot;
  final bool reduceMotion;
  final CareerMapModelBuilder? modelBuilder;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 59,
    child: LayoutBuilder(
      builder: (context, constraints) => Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  const SizedBox(
                    height: 8,
                    width: double.infinity,
                    child: ColoredBox(color: Color(0x35FFFFFF)),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: progress.clamp(0, 1)),
                    duration: Duration(milliseconds: reduceMotion ? 0 : 650),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => FractionallySizedBox(
                      widthFactor: value,
                      alignment: Alignment.centerLeft,
                      child: const SizedBox(
                        height: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF8C70F5),
                                Color(0xFF62D5F4),
                                Color(0xFFFFC66D),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(end: progress.clamp(0, 1)),
            duration: Duration(milliseconds: reduceMotion ? 0 : 650),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Positioned(
                left: careerMapPinOffset(constraints.maxWidth, value),
                top: 0,
                child: child!,
              );
            },
            child: MascotLocationPin(
              mascot: mascot,
              modelBuilder: modelBuilder,
            ),
          ),
        ],
      ),
    ),
  );
}

class MascotLocationPin extends StatelessWidget {
  const MascotLocationPin({required this.mascot, this.modelBuilder, super.key});

  final CharacterData mascot;
  final CareerMapModelBuilder? modelBuilder;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 48,
    height: 47,
    child: Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 0,
          child: Container(
            width: 45,
            height: 45,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFBDA8FF),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9D83FF).withValues(alpha: .45),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: ColoredBox(
                color: const Color(0xFF201D35),
                child:
                    modelBuilder?.call(mascot) ??
                    ModelViewer(
                      key: ValueKey('career-map-pin-${mascot.id}'),
                      src: mascot.modelPath,
                      alt: mascot.name,
                      autoPlay: true,
                      animationName: mascot.animationName,
                      autoRotate: false,
                      cameraControls: false,
                      disableZoom: true,
                      backgroundColor: Colors.transparent,
                      cameraOrbit: '0deg 75deg 105%',
                      fieldOfView: '30deg',
                      loading: Loading.eager,
                      reveal: Reveal.auto,
                      debugLogging: false,
                    ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 40,
          child: CustomPaint(
            size: const Size(12, 7),
            painter: const _PinTipPainter(),
          ),
        ),
      ],
    ),
  );
}

class _PinTipPainter extends CustomPainter {
  const _PinTipPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFBDA8FF));
  }

  @override
  bool shouldRepaint(covariant _PinTipPainter oldDelegate) => false;
}
