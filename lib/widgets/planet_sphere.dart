import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/hub_visuals.dart';

class PlanetSphere extends StatelessWidget {
  const PlanetSphere({
    required this.asset,
    required this.planet,
    required this.glowColor,
    required this.rotation,
    this.phase = 0,
    this.ringed = false,
    super.key,
  });

  final String asset;
  final String planet;
  final Color glowColor;
  final Animation<double> rotation;
  final double phase;
  final bool ringed;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final tickerEnabled = TickerMode.valuesOf(context).enabled;
    final animate = tickerEnabled && !reduceMotion;
    final rotationSeconds = PlanetAssets.rotationSeconds[planet] ?? 12;

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = math.min(constraints.maxWidth, constraints.maxHeight);
          return AnimatedBuilder(
            animation: rotation,
            builder: (context, _) {
              final radians = animate
                  ? 2 *
                            math.pi *
                            (rotation.value *
                                PlanetAssets.animationCycleSeconds /
                                rotationSeconds) +
                        phase
                  : phase;
              final yaw = animate ? math.sin(radians) * 0.29 : 0.0;
              final scaleX = animate ? 0.96 + 0.04 * math.cos(radians) : 1.0;
              final tilt = ringed && animate
                  ? math.sin(radians * 0.55) * 0.052
                  : 0.0;

              return Center(
                child: Transform.rotate(
                  angle: tilt,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateY(yaw)
                      ..scaleByDouble(scaleX, 1.0, 1.0, 1.0),
                    child: SizedBox(
                      width: side,
                      height: side,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ShaderMask(
                            blendMode: BlendMode.srcATop,
                            shaderCallback: (bounds) => RadialGradient(
                              center: const Alignment(-0.28, -0.32),
                              radius: 1.05,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.03),
                                Colors.black.withValues(alpha: 0.24),
                              ],
                              stops: const [0.42, 0.76, 1],
                            ).createShader(bounds),
                            child: Image.asset(
                              asset,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.public_rounded,
                                    size: side * 0.68,
                                    color: glowColor,
                                  ),
                            ),
                          ),
                          if (animate)
                            IgnorePointer(
                              child: ShaderMask(
                                blendMode: BlendMode.srcATop,
                                shaderCallback: (bounds) {
                                  final offset =
                                      (math.sin(radians * 0.7) * 0.5 + 0.5);
                                  return LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.transparent,
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: 0.18),
                                      Colors.transparent,
                                      Colors.transparent,
                                    ],
                                    stops: const [0, 0.42, 0.5, 0.58, 1],
                                    transform: _MovingSheen(offset),
                                  ).createShader(bounds);
                                },
                                child: Image.asset(
                                  asset,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox.expand(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MovingSheen extends GradientTransform {
  const _MovingSheen(this.progress);

  final double progress;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final shift = (progress - 0.5) * bounds.width * 1.5;
    return Matrix4.translationValues(shift, 0, 0);
  }
}
