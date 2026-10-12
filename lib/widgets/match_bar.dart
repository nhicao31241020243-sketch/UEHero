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
