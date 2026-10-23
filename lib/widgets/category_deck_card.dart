import 'package:flutter/material.dart';

import '../models/flashcard_deck.dart';
import 'deck_card_parts.dart';

class CategoryDeckCard extends StatelessWidget {
  const CategoryDeckCard({
    required this.deck,
    required this.progress,
    required this.inGoal,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onReset,
    super.key,
  });

  final FlashcardDeck deck;
  final double progress;
  final bool inGoal;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    final dark = Color.lerp(deck.color, const Color(0xFF1E1B2E), 0.55)!;
    final tint = Color.lerp(deck.color, Colors.white, 0.86)!;
    final iconColors = [
      deck.color,
      Color.lerp(deck.color, Colors.white, 0.25)!,
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 2, 0),
                  child: Row(
                    children: [
                      if (inGoal)
                        Tooltip(
                          message: 'Trong lộ trình',
                          child: Icon(
                            Icons.route_rounded,
                            color: deck.color,
                            size: 16,
                          ),
                        ),
                      const Spacer(),
                      DeckActionsMenu(
                        onEdit: onEdit,
                        onReset: onReset,
                        onDelete: onDelete,
                        color: dark,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Center(
                    child: FittedBox(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: iconColors),
                          boxShadow: [
                            BoxShadow(
                              color: deck.color.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(deck.icon, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    deck.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: dark,
                      fontSize: 14,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [deck.color, dark]),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${deck.cards.length} thẻ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (percent > 0)
                          Text(
                            '$percent%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
