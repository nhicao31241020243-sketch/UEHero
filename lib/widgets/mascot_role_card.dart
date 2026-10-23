import 'package:flutter/material.dart';

import 'dart:ui' as ui;

import '../models/character_data.dart';
import '../services/mascot_selection_store.dart';
import 'space_glass_widgets.dart';

class MascotRoleCard extends StatelessWidget {
  const MascotRoleCard({
    required this.role,
    required this.character,
    required this.onTap,
    super.key,
  });

  final MascotRole role;
  final CharacterData? character;
  final VoidCallback onTap;

  bool get _isPrimary => role == MascotRole.primary;

  @override
  Widget build(BuildContext context) {
    final color = character?.primaryColor ?? const Color(0xFF312B43);
    final title = _isPrimary ? 'Mascot chính' : 'Bạn đồng hành AI';
    final description = _isPrimary
        ? 'Phi hành gia đồng hành cùng hành trình của bạn'
        : 'Trợ lý AI đi cùng bạn qua mọi màn hình';

    return Semantics(
      button: true,
      label: '$title. ${character?.name ?? 'Chưa chọn'}',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: 226,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipPath(
                  clipper: const _DiagonalCardClipper(),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.fromLTRB(132, 24, 21, 21),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(
                              alpha: character == null ? .12 : .2,
                            ),
                            const Color(0xD9142E52),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(27),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .15),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xB9000000),
                            blurRadius: 19,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .83),
                              fontSize: 11,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            character?.name ?? 'Chưa chọn',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 38,
                            child: GlassButton(
                              onPressed: onTap,
                              borderRadius: 19,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 17,
                                vertical: 8,
                              ),
                              child: Text(character == null ? 'Chọn' : 'Đổi'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: -13,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(character?.id),
                  tween: Tween(begin: .78, end: 1),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) => Transform.scale(
                    scale: scale,
                    alignment: Alignment.bottomCenter,
                    child: child,
                  ),
                  child: _PreviewBadge(character: character),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge({required this.character});

  final CharacterData? character;

  @override
  Widget build(BuildContext context) {
    final chosen = character != null;
    return Container(
      width: 112,
      height: 132,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: chosen
            ? character!.primaryColor.withValues(alpha: .62)
            : const Color(0xFF211D2B),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withValues(alpha: .28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0xB9000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: chosen
          ? Image.asset(
              character!.previewAsset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Text(character!.emoji, style: const TextStyle(fontSize: 58)),
            )
          : const Icon(
              Icons.question_mark_rounded,
              color: Color(0xFFAAA5B8),
              size: 58,
            ),
    );
  }
}

class _DiagonalCardClipper extends CustomClipper<Path> {
  const _DiagonalCardClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 27)
    ..quadraticBezierTo(0, 0, 27, 0)
    ..lineTo(size.width - 28, 0)
    ..lineTo(size.width, 34)
    ..lineTo(size.width - 27, size.height)
    ..lineTo(27, size.height)
    ..quadraticBezierTo(0, size.height, 0, size.height - 27)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
