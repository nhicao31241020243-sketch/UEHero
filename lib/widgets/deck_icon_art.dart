import 'package:flutter/material.dart';

import '../config/deck_visuals.dart';
import '../models/flashcard_deck.dart';

class DeckIconArt extends StatelessWidget {
  const DeckIconArt({
    required this.deck,
    required this.size,
    this.pressed = false,
    super.key,
  });

  final FlashcardDeck deck;
  final double size;
  final bool pressed;

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: pressed ? 1.08 : 1,
    duration: const Duration(milliseconds: 160),
    curve: Curves.easeOutBack,
    child: Transform.rotate(
      angle: -0.12,
      child: Text(
        DeckIconMap.emojiFor(deck),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: size,
          height: 1.1,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
            Shadow(
              color: Colors.white.withValues(alpha: 0.2),
              blurRadius: 3,
              offset: const Offset(-2, -2),
            ),
          ],
        ),
      ),
    ),
  );
}
