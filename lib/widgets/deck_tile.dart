import 'package:flutter/material.dart';

import '../models/flashcard_deck.dart';

class DeckTile extends StatelessWidget {
  const DeckTile({
    required this.deck,
    required this.mastered,
    required this.progress,
    required this.isInProgress,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onReset,
    super.key,
  });

  final FlashcardDeck deck;
  final int mastered;
  final double progress;
  final bool isInProgress;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReset;

  static const _text = Color(0xFFFBF8FF);
  static const _muted = Color(0xFFAAA5B8);

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF211D2B),
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: deck.color.withValues(alpha: isInProgress ? 0.55 : 0.2),
            width: isInProgress ? 1.2 : 0.8,
          ),
          boxShadow: isInProgress
              ? [
                  BoxShadow(
                    color: deck.color.withValues(alpha: 0.08),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: deck.color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(deck.icon, color: deck.color, size: 24),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  tooltip: 'Tùy chọn bộ thẻ',
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: _muted,
                    size: 22,
                  ),
                  color: const Color(0xFF302B3A),
                  onSelected: (action) {
                    switch (action) {
                      case 'edit':
                        onEdit();
                      case 'delete':
                        onDelete();
                      case 'reset':
                        onReset();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Sửa bộ thẻ'),
                    ),
                    const PopupMenuItem(
                      value: 'reset',
                      child: Text('Đặt lại tiến độ'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Xóa bộ thẻ'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              deck.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _text,
                fontSize: 16,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              deck.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, fontSize: 11, height: 1.3),
            ),
            const Spacer(),
            Row(
              children: [
                _Chip(text: deck.group.label, color: deck.color),
                const SizedBox(width: 6),
                _Chip(text: deck.level.label, color: const Color(0xFF9DCBC0)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(deck.color),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$mastered/${deck.cards.length} đã thuộc',
                    style: const TextStyle(color: _muted, fontSize: 10),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    color: deck.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Flexible(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
