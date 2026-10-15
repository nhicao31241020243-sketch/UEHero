import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/space_theme.dart';

class SpaceBackground extends StatelessWidget {
  const SpaceBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: ResizeImage(
                  const AssetImage('assets/images/space_bg.jpg'),
                  width: 720,
                  policy: ResizeImagePolicy.fit,
                ),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x52030B1B),
                  Color(0x26040D20),
                  Color(0x66020A19),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = SpaceTheme.cardRadius,
    this.blur = 14,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x42020A1C),
            blurRadius: 20,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0x90FFFFFF),
                  Color(0x28A9CCFF),
                  Color(0x128AAEFF),
                ],
                stops: [0, 0.28, 1],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: SpaceTheme.glass,
                  borderRadius: BorderRadius.circular(borderRadius - 1),
                ),
                child: Padding(padding: padding, child: child),
              ),
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
              color: const Color(0xCC0D1B34),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
