import 'package:flutter/material.dart';

class MatchBar extends StatelessWidget {
  const MatchBar({required this.percent, this.height = 9, super.key})
    : assert(percent >= 0 && percent <= 100);

  final int percent;
  final double height;

  static const _gradientColors = [
    Color(0xFFFF8A4C),
    Color(0xFFFFD166),
    Color(0xFF82D977),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 220.0;
        final markerSize = (height * 1.35).clamp(9.0, 13.0);
        final travel = (width - markerSize).clamp(0.0, double.infinity);
        return SizedBox(
          height: markerSize + height + 5,
          child: Stack(
            alignment: Alignment.topLeft,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: percent / 100),
                  duration: const Duration(milliseconds: 750),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Transform.translate(
                    offset: Offset(travel * value, 0),
                    child: child,
                  ),
                  child: SizedBox(
                    width: markerSize,
                    height: markerSize,
                    child: CustomPaint(
                      painter: _MatchMarkerPainter(color: _colorFor(percent)),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: markerSize + 3,
                left: 0,
                right: 0,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height),
                    gradient: const LinearGradient(colors: _gradientColors),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Color _colorFor(int percent) {
    if (percent < 50) return const Color(0xFFFFA04D);
    if (percent < 80) return const Color(0xFFFFD166);
    return const Color(0xFF82D977);
  }
}

class _MatchMarkerPainter extends CustomPainter {
  const _MatchMarkerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _MatchMarkerPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Thanh năng lượng độ khớp: gradient cam sang xanh lá, phần chưa đạt mờ đi.
class JobMatchEnergyBar extends StatelessWidget {
  const JobMatchEnergyBar({
    required this.percent,
    this.height = 10,
    this.color = const Color(0xFF82D977),
    super.key,
  });

  final double percent;
  final double height;
  final Color color;

  static const _gradient = LinearGradient(
    colors: [Color(0xFFFF8A4C), Color(0xFFFFD166), Color(0xFF82D977)],
  );

  @override
  Widget build(BuildContext context) {
    final target = (percent.clamp(0, 100)) / 100;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text(
              'Độ khớp',
              style: TextStyle(
                color: Color(0xFFAAA5B8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${percent.round()}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: SizedBox(
            height: height,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: reduceMotion ? target : 0, end: target),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 750),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: .22,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(gradient: _gradient),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) => ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: SizedBox(
                          width: constraints.maxWidth,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(gradient: _gradient),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
