import 'package:flutter/material.dart';

/// Gradient sáng cho thẻ "Đang học" và dải màu đáy, pha từ màu chủ đề của bộ.
LinearGradient deckVividGradient(Color base) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [base, Color.lerp(base, const Color(0xFF4B2F8F), 0.45)!],
);

class DeckActionsMenu extends StatelessWidget {
  const DeckActionsMenu({
    required this.onEdit,
    required this.onReset,
    required this.onDelete,
    this.color = Colors.white70,
    super.key,
  });

  final VoidCallback onEdit;
  final VoidCallback onReset;
  final VoidCallback onDelete;
  final Color color;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Tùy chọn bộ thẻ',
    icon: Icon(Icons.more_horiz_rounded, color: color, size: 18),
    padding: const EdgeInsets.all(4),
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
    itemBuilder: (context) => const [
      PopupMenuItem(value: 'edit', child: Text('Sửa bộ thẻ')),
      PopupMenuItem(value: 'reset', child: Text('Đặt lại tiến độ')),
      PopupMenuItem(value: 'delete', child: Text('Xóa bộ thẻ')),
    ],
  );
}
