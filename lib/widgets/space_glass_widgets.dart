import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/space_theme.dart';

class SpaceBackground extends StatefulWidget {
  const SpaceBackground({super.key});

  @override
  State<SpaceBackground> createState() => _SpaceBackgroundState();
}

class _SpaceBackgroundState extends State<SpaceBackground> {
  // Low-rate timer keeps the twinkle cheap on mid-range phones.
  final ValueNotifier<double> _phase = ValueNotifier<double>(0);
  Timer? _timer;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _timer?.cancel();
    _timer = null;
    if (!_reduceMotion) {
      _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        _phase.value = (_phase.value + 0.25 / 9) % 1;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const RepaintBoundary(
              child: CustomPaint(painter: _NebulaPainter()),
            ),
            RepaintBoundary(
              child: CustomPaint(
                painter: _StarPainter(_reduceMotion ? null : _phase),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NebulaPainter extends CustomPainter {
  const _NebulaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: SpaceTheme.backgroundColors,
          stops: SpaceTheme.backgroundStops,
        ).createShader(rect),
    );
    void cloud(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    final w = size.width;
    final h = size.height;
    cloud(Offset(w * 0.15, h * 0.22), w * 0.7, const Color(0x2E4C5BD6));
    cloud(Offset(w * 0.95, h * 0.42), w * 0.65, const Color(0x265A3FA8));
    cloud(Offset(w * 0.2, h * 0.7), w * 0.75, const Color(0x2E8A4A8F));
    cloud(Offset(w * 0.8, h * 0.95), w * 0.8, const Color(0x38C2607D));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.animation) : super(repaint: animation);

  final ValueListenable<double>? animation;

  static final List<({double x, double y, double r, double phase})> _stars =
      () {
        final random = math.Random(42);
        return List.generate(
          56,
          (_) => (
            x: random.nextDouble(),
            y: random.nextDouble(),
            r: 0.5 + random.nextDouble() * 1.1,
            phase: random.nextDouble(),
          ),
        );
      }();

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation?.value ?? 0;
    final paint = Paint();
    for (final star in _stars) {
      final pulse = animation == null
          ? 0.7
          : 0.45 + 0.4 * math.sin((t + star.phase) * 2 * math.pi);
      paint.color = Colors.white.withValues(alpha: pulse.clamp(0.15, 0.9));
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

/// Thin constellation lines for empty areas; purely decorative.
class ConstellationDecor extends StatelessWidget {
  const ConstellationDecor({super.key});

  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(painter: _ConstellationPainter()),
    ),
  );
}

class _ConstellationPainter extends CustomPainter {
  const _ConstellationPainter();

  static const _groups = <List<Offset>>[
    [
      Offset(0.62, 0.2),
      Offset(0.74, 0.14),
      Offset(0.84, 0.22),
      Offset(0.9, 0.12),
    ],
    [
      Offset(0.08, 0.62),
      Offset(0.17, 0.52),
      Offset(0.12, 0.74),
      Offset(0.24, 0.66),
    ],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = SpaceTheme.constellation.withValues(alpha: 0.22)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    final dot = Paint()
      ..color = SpaceTheme.constellation.withValues(alpha: 0.7);
    for (final group in _groups) {
      final points = [
        for (final p in group) Offset(p.dx * size.width, p.dy * size.height),
      ];
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, line);
      for (final p in points) {
        canvas.drawCircle(p, 1.8, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = SpaceTheme.cardRadius,
    this.blur = 14,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;

  /// Optional nebula tint painted inside the card (one hue per card).
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x59040620),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: SpaceTheme.glassBorder),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0x33FFFFFF),
                  SpaceTheme.glassTint,
                  SpaceTheme.glassTint,
                ],
                stops: const [0, 0.18, 1],
              ),
            ),
            child: Stack(
              children: [
                if (tint != null)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.55),
                          radius: 0.95,
                          colors: [
                            tint!.withValues(alpha: 0.32),
                            tint!.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 0,
                  left: borderRadius,
                  right: borderRadius,
                  height: 1,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x00FFFFFF),
                          SpaceTheme.glassHighlight,
                          Color(0x00FFFFFF),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(padding: padding, child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlassButton extends StatelessWidget {
  const GlassButton({
    required this.onPressed,
    required this.child,
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
    this.borderRadius = SpaceTheme.controlRadius,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: SpaceTheme.blueGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x663C8CFF),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              child: IconTheme(
                data: const IconThemeData(color: Colors.white),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassBottomBar extends StatelessWidget {
  const GlassBottomBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x52020716),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xCC0C0F33),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: SpaceTheme.glassBorder),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
