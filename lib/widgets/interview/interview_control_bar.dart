import 'package:flutter/material.dart';

class InterviewControlBar extends StatelessWidget {
  const InterviewControlBar({
    required this.onHint,
    required this.onKeyboard,
    required this.onSkip,
    required this.onEnd,
    required this.enabled,
    required this.hintsRemaining,
    super.key,
  });

  final VoidCallback onHint;
  final VoidCallback onKeyboard;
  final VoidCallback onSkip;
  final VoidCallback onEnd;
  final bool enabled;
  final int hintsRemaining;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ControlAction(
        icon: Icons.mic_none_rounded,
        label: 'Mic · Sắp có',
        onTap: null,
        color: const Color(0xFF70D8F2),
      ),
      _ControlAction(
        icon: Icons.lightbulb_outline_rounded,
        label: 'Gợi ý · $hintsRemaining',
        onTap: enabled ? onHint : null,
        color: const Color(0xFFFFD36E),
      ),
      _ControlAction(
        icon: Icons.keyboard_rounded,
        label: 'Bàn phím',
        onTap: enabled ? onKeyboard : null,
        color: const Color(0xFFBFA8FF),
        primary: true,
      ),
      _ControlAction(
        icon: Icons.skip_next_rounded,
        label: 'Bỏ qua',
        onTap: enabled ? onSkip : null,
        color: Colors.white70,
      ),
      _ControlAction(
        icon: Icons.call_end_rounded,
        label: 'Kết thúc',
        onTap: onEnd,
        color: const Color(0xFFFF7D8A),
      ),
    ];
    return Row(
      children: [
        for (final action in actions)
          Expanded(
            child: Tooltip(
              message: action.label,
              child: Center(
                child: Material(
                  color: action.primary
                      ? const Color(0xFFBFA8FF)
                      : const Color(0x88211D2B),
                  shape: CircleBorder(
                    side: BorderSide(
                      color: action.color.withValues(alpha: 0.52),
                      width: action.primary ? 1.5 : 1,
                    ),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: action.onTap,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        action.icon,
                        size: 21,
                        color: action.onTap == null
                            ? action.color.withValues(alpha: 0.38)
                            : action.primary
                            ? const Color(0xFF211A30)
                            : action.color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ControlAction {
  const _ControlAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final bool primary;
}
