import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../config/xp_stages.dart';
import '../services/points_manager.dart';
import '../theme/space_theme.dart';

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Scales its child slightly while pressed.
class PressScale extends StatefulWidget {
  const PressScale({required this.child, this.scale = 0.96, super.key});

  final Widget child;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down ? widget.scale : 1,
      duration: _reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 110),
      child: widget.child,
    ),
  );
}

enum PlanetStyle { bands, rocky, ringed, ice }

/// Procedurally shaded planet: soft lighting, terminator shadow, rim light.
class PlanetOrb extends StatelessWidget {
  const PlanetOrb({
    required this.colors,
    required this.style,
    this.seed = 1,
    super.key,
  });

  final List<Color> colors;
  final PlanetStyle style;
  final int seed;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _PlanetPainter(colors, style, seed),
      child: const SizedBox.expand(),
    ),
  );
}

class _PlanetPainter extends CustomPainter {
  _PlanetPainter(this.colors, this.style, this.seed);

  final List<Color> colors;
  final PlanetStyle style;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final ringed = style == PlanetStyle.ringed;
    final side = math.min(size.width, size.height);
    final radius = side * (ringed ? 0.29 : 0.38);
    final center = size.center(Offset.zero);
    final sphere = Rect.fromCircle(center: center, radius: radius);
    final light = colors[0];
    final mid = colors[1];
    final dark = colors[2];

    // Soft outer glow.
    canvas.drawCircle(
      center,
      radius * 1.12,
      Paint()
        ..color = mid.withValues(alpha: 0.42)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.5),
    );

    final ringRect = Rect.fromCenter(
      center: center,
      width: radius * 3.0,
      height: radius * 0.78,
    );
    void ring(Canvas c, {required bool front}) {
      c.save();
      c.translate(center.dx, center.dy);
      c.rotate(-0.28);
      c.translate(-center.dx, -center.dy);
      if (front) {
        c.clipRect(Rect.fromLTRB(0, center.dy, size.width, size.height * 2));
      }
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..shader = LinearGradient(
          colors: [
            light.withValues(alpha: 0.2),
            light.withValues(alpha: 0.9),
            mid.withValues(alpha: 0.55),
          ],
        ).createShader(ringRect);
      c.drawOval(ringRect, ringPaint..strokeWidth = radius * 0.2);
      c.drawOval(
        ringRect.deflate(radius * 0.17),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.05
          ..color = light.withValues(alpha: 0.45),
      );
      c.restore();
    }

    if (ringed) ring(canvas, front: false);

    // Lit sphere.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.5),
          radius: 1.05,
          colors: [light, mid, dark],
          stops: const [0, 0.5, 1],
        ).createShader(sphere),
    );

    // Surface texture.
    canvas.save();
    canvas.clipPath(Path()..addOval(sphere));
    final random = math.Random(seed);
    final texture = Paint();
    switch (style) {
      case PlanetStyle.bands:
      case PlanetStyle.ringed:
        for (var i = 0; i < 7; i++) {
          final y = sphere.top + sphere.height * (0.12 + i * 0.125);
          final path = Path()..moveTo(sphere.left, y);
          for (var x = 0; x <= 8; x++) {
            path.lineTo(
              sphere.left + sphere.width * x / 8,
              y + math.sin(x * 1.3 + i + seed) * radius * 0.04,
            );
          }
          canvas.drawPath(
            path,
            texture
              ..style = PaintingStyle.stroke
              ..strokeWidth = radius * (0.06 + random.nextDouble() * 0.1)
              ..color = (i.isEven ? dark : light).withValues(alpha: 0.28),
          );
        }
      case PlanetStyle.rocky:
        texture.style = PaintingStyle.fill;
        for (var i = 0; i < 9; i++) {
          final p = Offset(
            sphere.left + sphere.width * random.nextDouble(),
            sphere.top + sphere.height * random.nextDouble(),
          );
          texture.color = dark.withValues(
            alpha: 0.2 + random.nextDouble() * 0.12,
          );
          canvas.drawCircle(
            p,
            radius * (0.07 + random.nextDouble() * 0.14),
            texture,
          );
        }
      case PlanetStyle.ice:
        texture.style = PaintingStyle.stroke;
        for (var i = 0; i < 5; i++) {
          final y = sphere.top + sphere.height * (0.2 + i * 0.16);
          texture
            ..strokeWidth = radius * 0.1
            ..color = (i.isEven ? Colors.white : dark).withValues(alpha: 0.18);
          canvas.drawArc(
            Rect.fromLTWH(
              sphere.left - radius * 0.2,
              y,
              sphere.width * 1.4,
              radius * 0.5,
            ),
            math.pi,
            math.pi,
            false,
            texture,
          );
        }
    }

    // Terminator: darken the side facing away from the light.
    canvas.drawRect(
      sphere,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.55, -0.6),
          radius: 1.25,
          colors: const [
            Color(0x00000000),
            Color(0x00000000),
            Color(0x8C050818),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(sphere),
    );
    canvas.restore();

    // Rim light.
    canvas.drawCircle(
      center,
      radius - 0.6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xCCFFFFFF), Color(0x00FFFFFF), Color(0x33FFFFFF)],
          stops: [0, 0.55, 1],
        ).createShader(sphere),
    );

    if (ringed) ring(canvas, front: true);
  }

  @override
  bool shouldRepaint(covariant _PlanetPainter old) =>
      old.style != style || old.seed != seed || old.colors != colors;
}

String formatXp(int value) {
  final digits = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
    out.write(digits[i]);
  }
  return out.toString();
}

/// XP pill fed by [PointsManager] and the stages in `xp_stages.dart`.
class XpEnergyBar extends StatelessWidget {
  const XpEnergyBar({this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PointsManager.instance,
      builder: (context, _) {
        final xp = PointsManager.instance.totalXp;
        final stage = stageForXp(xp);
        final nextIndex = xpStages.indexOf(stage) + 1;
        final next = nextIndex < xpStages.length ? xpStages[nextIndex] : null;
        final label = next == null
            ? '${formatXp(xp)} XP'
            : '${formatXp(xp)} / ${formatXp(next.requiredXp)} XP';
        final progress = stageProgressForXp(xp);
        return Semantics(
          button: onTap != null,
          label: 'Level ${stage.id} ${stage.name}, $label',
          child: PressScale(
            child: GestureDetector(
              onTap: onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    height: 51,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: SpaceTheme.glassTint,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: SpaceTheme.glassBorder),
                    ),
                    child: Row(
                      children: [
                        _LevelBadge(level: stage.id),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stage.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: SpaceTheme.textMuted,
                                  fontSize: 10,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _XpTrack(progress: progress),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF241B5C),
      border: Border.all(color: SpaceTheme.glow, width: 1.4),
      boxShadow: [
        BoxShadow(
          color: SpaceTheme.glow.withValues(alpha: 0.55),
          blurRadius: 12,
        ),
      ],
    ),
    child: Text(
      '$level',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    ),
  );
}

class _XpTrack extends StatelessWidget {
  const _XpTrack({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(end: progress),
    duration: _reduceMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 600),
    curve: Curves.easeOutCubic,
    builder: (context, value, _) => Container(
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0x66050818),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: SpaceTheme.xpGradient,
              boxShadow: [
                BoxShadow(
                  color: SpaceTheme.glow.withValues(alpha: 0.55),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class SpaceDockItem {
  const SpaceDockItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool badge;
}

/// Curved glass dock: four round buttons around a raised, glowing centre.
class SpaceDock extends StatelessWidget {
  const SpaceDock({
    required this.items,
    required this.center,
    required this.onCenterTap,
    this.centerLabel = 'Về trang chủ',
    super.key,
  }) : assert(items.length == 4);

  final List<SpaceDockItem> items;
  final Widget center;
  final VoidCallback onCenterTap;
  final String centerLabel;

  static const double height = 104;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    final slot = [
      for (var i = 0; i < 4; i++)
        Expanded(
          child: Padding(
            // Inner buttons sit lower than the outer ones to form an arc.
            padding: EdgeInsets.only(top: (i == 1 || i == 2) ? 38 : 26),
            child: _DockButton(item: items[i]),
          ),
        ),
    ];
    return SizedBox(
      height: height + inset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipPath(
              clipper: const _DockClipper(),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: CustomPaint(
                  painter: const _DockPainter(),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            top: 0,
            height: height,
            child: Row(
              children: [
                slot[0],
                slot[1],
                const SizedBox(width: 84),
                slot[2],
                slot[3],
              ],
            ),
          ),
          Positioned(
            top: 4,
            left: 0,
            right: 0,
            child: Center(
              child: Semantics(
                button: true,
                label: centerLabel,
                child: PressScale(
                  scale: 0.92,
                  child: GestureDetector(
                    onTap: onCenterTap,
                    child: Container(
                      width: 68,
                      height: 68,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: SpaceTheme.glow.withValues(alpha: 0.5),
                            blurRadius: 24,
                            spreadRadius: 1,
                          ),
                          const BoxShadow(
                            color: Color(0x665B7CFF),
                            blurRadius: 30,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Path _dockPath(Size size) => Path()
  ..moveTo(0, 26)
  ..quadraticBezierTo(size.width / 2, -10, size.width, 26)
  ..lineTo(size.width, size.height)
  ..lineTo(0, size.height)
  ..close();

class _DockClipper extends CustomClipper<Path> {
  const _DockClipper();

  @override
  Path getClip(Size size) => _dockPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DockPainter extends CustomPainter {
  const _DockPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = _dockPath(size);
    canvas.drawPath(path, Paint()..color = const Color(0xB30B0E33));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = SpaceTheme.glassBorder,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DockButton extends StatelessWidget {
  const _DockButton({required this.item});

  final SpaceDockItem item;

  @override
  Widget build(BuildContext context) {
    final selected = item.selected;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: PressScale(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: item.onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SpaceTheme.navyButton,
                      border: Border.all(
                        color: selected
                            ? SpaceTheme.glow.withValues(alpha: 0.9)
                            : Colors.white.withValues(alpha: 0.22),
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: SpaceTheme.glow.withValues(alpha: 0.4),
                                blurRadius: 14,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(item.icon, color: Colors.white, size: 21),
                  ),
                  if (item.badge)
                    Positioned(
                      top: 1,
                      right: 1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: SpaceTheme.glowOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : SpaceTheme.textMuted,
                  fontSize: 10,
                  height: 1,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
