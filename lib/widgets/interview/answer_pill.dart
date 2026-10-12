import 'package:flutter/material.dart';

class AnswerPill extends StatelessWidget {
  const AnswerPill({
    required this.text,
    required this.onEdit,
    required this.onSend,
    required this.enabled,
    super.key,
  });

  final String text;
  final VoidCallback onEdit;
  final VoidCallback onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xCC211D2B),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: enabled ? onEdit : null,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 7, 7, 7),
          child: Row(
            children: [
              const Icon(
                Icons.keyboard_alt_outlined,
                color: Color(0xFF70D8F2),
                size: 19,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  text.isEmpty
                      ? 'Nhấn mic để trả lời hoặc gõ bằng bàn phím'
                      : text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: text.isEmpty
                        ? const Color(0xFFAAA5B8)
                        : Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: enabled && text.trim().isNotEmpty ? onSend : null,
                tooltip: 'Gửi',
                constraints: const BoxConstraints.tightFor(
                  width: 38,
                  height: 38,
                ),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFBFA8FF),
                  foregroundColor: const Color(0xFF211A30),
                  disabledBackgroundColor: const Color(0xFF393445),
                  disabledForegroundColor: const Color(0xFF777181),
                ),
                icon: const Icon(Icons.check_rounded, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
