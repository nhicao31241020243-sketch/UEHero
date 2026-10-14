import 'package:flutter/material.dart';

import '../models/mentor_model.dart';

const mentorAvatarPalettes = <List<Color>>[
  [Color(0xFF9274E8), Color(0xFF41B7D8)],
  [Color(0xFFDB76B6), Color(0xFF705AE3)],
  [Color(0xFF54B8A6), Color(0xFF547FE1)],
  [Color(0xFFDE9B54), Color(0xFFB75FD0)],
  [Color(0xFF558DE0), Color(0xFF5CC7C0)],
  [Color(0xFFD66D7B), Color(0xFF805DE0)],
  [Color(0xFF8A66D6), Color(0xFF4EABC2)],
  [Color(0xFF62AD73), Color(0xFF4F83D5)],
];

String mentorInitial(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? '?' : String.fromCharCode(trimmed.runes.first).toUpperCase();
}

int mentorPaletteIndex(String id) {
  var hash = 0;
  for (final rune in id.runes) {
    hash = (hash * 31 + rune) & 0x7fffffff;
  }
  return hash % mentorAvatarPalettes.length;
}

class MentorAvatar extends StatelessWidget {
  const MentorAvatar({
    required this.mentor,
    this.size = 54,
    super.key,
  });

  final Mentor mentor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = mentorAvatarPalettes[mentorPaletteIndex(mentor.id)];
    final asset = mentor.avatarAsset;

    Widget initials() => DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
      ),
      child: Center(
        child: Text(
          mentorInitial(mentor.name),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );

    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: asset == null
            ? initials()
            : Image.asset(
                asset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => initials(),
              ),
      ),
    );
  }
}
