import 'package:flutter/material.dart';

class JobSearchHeader extends StatelessWidget {
  const JobSearchHeader({
    required this.controller,
    required this.mascotEmoji,
    required this.onChanged,
    this.onFilter,
    this.showAvatar = true,
    super.key,
  });

  final TextEditingController controller;
  final String mascotEmoji;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilter;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: const Color(0xFF211D2B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: Color(0xFFAAA5B8),
                size: 21,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Tìm vị trí, công ty, kỹ năng',
                    hintStyle: TextStyle(
                      color: Color(0xFFAAA5B8),
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (controller.text.isNotEmpty)
                IconButton(
                  tooltip: 'Xóa tìm kiếm',
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 44,
                  ),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFFAAA5B8),
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
      if (onFilter != null) ...[
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Bộ lọc',
          onPressed: onFilter,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF211D2B),
            foregroundColor: const Color(0xFFBFA8FF),
          ),
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
      if (showAvatar) ...[
        const SizedBox(width: 8),
        MascotAvatar(emoji: mascotEmoji),
      ],
    ],
  );
}

class MascotAvatar extends StatelessWidget {
  const MascotAvatar({required this.emoji, super.key});

  final String emoji;

  @override
  Widget build(BuildContext context) => Container(
    width: 43,
    height: 43,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFF302744),
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFFBFA8FF).withValues(alpha: .45)),
    ),
    child: Text(emoji, style: const TextStyle(fontSize: 21)),
  );
}
