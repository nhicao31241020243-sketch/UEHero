import 'package:flutter/material.dart';

import '../config/deck_visuals.dart';
import '../models/flashcard_deck.dart';
import 'deck_card_parts.dart';
import 'deck_icon_art.dart';

class CategoryDeckCard extends StatefulWidget {
  const CategoryDeckCard({
    required this.deck,
    required this.progress,
    required this.inGoal,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onReset,
    this.accentColor,
    super.key,
  });

  final FlashcardDeck deck;
  final double progress;
  final bool inGoal;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReset;
  final Color? accentColor;

  @override
  State<CategoryDeckCard> createState() => _CategoryDeckCardState();
}

class _CategoryDeckCardState extends State<CategoryDeckCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final deck = widget.deck;
    final accent = widget.accentColor ?? DeckPalette.colorFor(deck);
    final foreground = DeckPalette.foreground(accent);
    final percent = (widget.progress * 100).round();
    final dark = DeckPalette.darker(accent, 0.34);
    final tint = Color.lerp(accent, Colors.white, 0.08)!;
    final iconColors = [tint, DeckPalette.darker(accent, 0.16)];
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tint, DeckPalette.darker(accent, 0.18)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.24),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 2, 0),
                  child: Row(
                    children: [
                      if (widget.inGoal)
                        Tooltip(
                          message: 'Trong lộ trình',
                          child: Icon(
                            Icons.route_rounded,
                            color: foreground.withValues(alpha: 0.92),
                            size: 16,
                          ),
                        ),
                      const Spacer(),
                      DeckActionsMenu(
                        onEdit: widget.onEdit,
                        onReset: widget.onReset,
                        onDelete: widget.onDelete,
                        color: foreground.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Center(
                    child: FittedBox(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: iconColors),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: 76,
                          height: 76,
                          child: Center(
                            child: DeckIconArt(
                              deck: deck,
                              size: 43,
                              pressed: _pressed,
                            ),
                          ),
                        ),
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
                      color: foreground,
                      fontSize: 14,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [dark, DeckPalette.darker(accent, 0.48)],
                    ),
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
