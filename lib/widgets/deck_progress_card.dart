import 'package:flutter/material.dart';

import '../config/deck_visuals.dart';
import '../models/flashcard_deck.dart';
import 'deck_card_parts.dart';
import 'deck_icon_art.dart';

class DeckProgressCard extends StatefulWidget {
  const DeckProgressCard({
    required this.deck,
    required this.mastered,
    required this.progress,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onReset,
    this.accentColor,
    super.key,
  });

  final FlashcardDeck deck;
  final int mastered;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReset;
  final Color? accentColor;

  @override
  State<DeckProgressCard> createState() => _DeckProgressCardState();
}

class _DeckProgressCardState extends State<DeckProgressCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final deck = widget.deck;
    final accent = widget.accentColor ?? DeckPalette.colorFor(deck);
    final foreground = DeckPalette.foreground(accent);
    final percent = (widget.progress * 100).round();
    final dark = DeckPalette.darker(accent, 0.3);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(accent, Colors.white, 0.08)!, dark],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.play_circle_outline_rounded,
                    color: foreground.withValues(alpha: 0.85),
                    size: 19,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ĐANG HỌC',
                    style: TextStyle(
                      color: foreground.withValues(alpha: 0.86),
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
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
              const SizedBox(height: 3),
              Align(
                alignment: Alignment.centerRight,
                heightFactor: 0.9,
                child: DeckIconArt(deck: deck, size: 52, pressed: _pressed),
              ),
              Text(
                deck.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 16,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: widget.progress,
                  minHeight: 6,
                  backgroundColor: foreground.withValues(alpha: 0.18),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${widget.mastered}/${deck.cards.length} đã thuộc',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.78),
                        fontSize: 11,
                      ),
                    ),
                  ),
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
              const SizedBox(height: 9),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: foreground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: dark, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Tiếp tục',
                        style: TextStyle(
                          color: dark,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
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
    );
  }
}
