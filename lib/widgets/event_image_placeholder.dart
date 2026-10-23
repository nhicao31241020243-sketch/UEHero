import 'dart:math' as math;

import 'package:flutter/material.dart';

class EventImagePlaceholder extends StatelessWidget {
  const EventImagePlaceholder({
    required this.icon,
    required this.colors,
    this.eventType = 'Sự kiện',
    this.organizer,
    super.key,
  });

  final IconData icon;
  final List<Color> colors;
  final String eventType;
  final String? organizer;

  String get _organizerMark {
    final words = (organizer ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    return words
        .take(2)
        .map((word) => word.substring(0, 1))
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: _EventPatternPainter()),
        Positioned(
          top: -52,
          right: -38,
          child: _orb(210, Colors.white.withValues(alpha: 0.055)),
        ),
        Positioned(
          bottom: -86,
          left: -60,
          child: _orb(220, Colors.black.withValues(alpha: 0.12)),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final shortest = math.min(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            final iconBox = (shortest * 0.38).clamp(32.0, 84.0);
            final iconSize = iconBox * 0.52;
            final markSize = (iconBox * 0.34).clamp(12.0, 29.0);
            final showType = shortest >= 120;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: iconBox,
                    height: iconBox,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.13),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(icon, color: Colors.white, size: iconSize),
                        if (_organizerMark.isNotEmpty)
                          Positioned(
                            right: 1,
                            bottom: 1,
                            child: Container(
                              width: markSize,
                              height: markSize,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF151323),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                _organizerMark,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: (markSize * 0.32).clamp(6.0, 9.0),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (showType) ...[
                    const SizedBox(height: 12),
                    Text(
                      eventType.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    ),
  );

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _EventPatternPainter extends CustomPainter {
  const _EventPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.11)
      ..style = PaintingStyle.fill;
    const spacing = 19.0;
    for (var y = 10.0; y < size.height; y += spacing) {
      for (var x = 10.0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EventPatternPainter oldDelegate) => false;
}
