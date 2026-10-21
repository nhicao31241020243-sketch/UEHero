import 'package:flutter/material.dart';

import '../models/event_item.dart';
import 'event_poster.dart';
import 'match_bar.dart';
import 'space_glass_widgets.dart';

const _eventMuted = Color(0xFFB7B2C7);

IconData eventTypeIcon(String type) {
  final value = type.toLowerCase();
  if (value.contains('hack')) return Icons.terminal_rounded;
  if (value.contains('datathon') || value.contains('data')) {
    return Icons.query_stats_rounded;
  }
  if (value.contains('workshop')) return Icons.handyman_outlined;
  if (value.contains('hội chợ') || value.contains('career')) {
    return Icons.work_outline_rounded;
  }
  if (value.contains('case')) return Icons.business_center_outlined;
  return Icons.emoji_events_outlined;
}

List<Color> eventTypeColors(String type) {
  final value = type.toLowerCase();
  if (value.contains('hack')) {
    return const [Color(0xFF15445A), Color(0xFF413568)];
  }
  if (value.contains('data')) {
    return const [Color(0xFF3B286A), Color(0xFF15506C)];
  }
  if (value.contains('workshop')) {
    return const [Color(0xFF315C5B), Color(0xFF1E2E53)];
  }
  if (value.contains('hội chợ') || value.contains('career')) {
    return const [Color(0xFF764B38), Color(0xFF33264F)];
  }
  if (value.contains('case')) {
    return const [Color(0xFF6A443B), Color(0xFF29264D)];
  }
  return const [Color(0xFF493C74), Color(0xFF1D3554)];
}

String eventStatusLabel(EventItem event, DateTime now) {
  switch (event.statusAt(now)) {
    case EventStatus.registrationOpen:
      return event.daysUntilDeadline(now) == null
          ? 'Đang mở đăng ký'
          : 'Còn ${event.daysUntilDeadline(now)} ngày';
    case EventStatus.openingSoon:
      return 'Sắp mở đăng ký';
    case EventStatus.closedUpcoming:
      return 'Sắp diễn ra';
    case EventStatus.ended:
      return 'Đã kết thúc';
    case EventStatus.newSeasonUnknown:
      return 'Chờ mùa mới';
    case EventStatus.dateUnknown:
      return 'Chưa công bố ngày';
  }
}

String eventDateLabel(DateTime? date) {
  if (date == null) return 'Chưa công bố ngày';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class EventCategoryIcon extends StatelessWidget {
  const EventCategoryIcon({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 76,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? const Color(0xFF7B5CC7)
                  : const Color(0xB5232031),
              border: Border.all(
                color: selected
                    ? const Color(0xFFDACBFF)
                    : Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              height: 1.15,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class EventSectionTitle extends StatelessWidget {
  const EventSectionTitle({required this.title, this.onSeeAll, super.key});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      if (onSeeAll != null)
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(44, 36),
          ),
          child: const Text('Xem tất cả'),
        ),
    ],
  );
}

class EventPosterCard extends StatelessWidget {
  const EventPosterCard({
    required this.event,
    required this.onTap,
    required this.onSave,
    required this.saved,
    this.matchPercent,
    this.width = 148,
    this.height = 226,
    super.key,
  });

  final EventItem event;
  final VoidCallback onTap;
  final VoidCallback onSave;
  final bool saved;
  final int? matchPercent;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: event.statusAt(DateTime.now()) == EventStatus.ended ? 0.5 : 1,
    child: SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: const Color(0xFF211D2B),
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                EventPoster(
                  imageUrl: event.posterUrl,
                  borderRadius: BorderRadius.zero,
                  placeholderIcon: eventTypeIcon(event.type),
                  fallbackColors: eventTypeColors(event.type),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xF10A0B17)],
                      stops: [0.24, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    children: [
                      Flexible(child: _SmallBadge(label: event.type)),
                      const Spacer(),
                      if (matchPercent != null)
                        _SmallBadge(
                          label: '$matchPercent%',
                          color: const Color(0xD9385942),
                        ),
                      IconButton(
                        tooltip: saved ? 'Bỏ lưu' : 'Lưu sự kiện',
                        constraints: const BoxConstraints.tightFor(
                          width: 30,
                          height: 30,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: onSave,
                        icon: Icon(
                          saved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border,
                          size: 18,
                          color: saved ? const Color(0xFFFF8AA0) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (event.needsVerification)
                  const Positioned(
                    top: 42,
                    right: 10,
                    child: Tooltip(
                      message: 'Cần kiểm tra thông tin',
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFFFD166),
                        size: 17,
                      ),
                    ),
                  ),
                Positioned(
                  left: 10,
                  right: 9,
                  bottom: 9,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          height: 1.12,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        eventStatusLabel(event, DateTime.now()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _eventMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class EventListTile extends StatelessWidget {
  const EventListTile({
    required this.event,
    required this.saved,
    required this.matchPercent,
    required this.onTap,
    required this.onSave,
    super.key,
  });

  final EventItem event;
  final bool saved;
  final int matchPercent;
  final VoidCallback onTap;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: GlassCard(
      padding: const EdgeInsets.all(10),
      borderRadius: 18,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            SizedBox(
              width: 82,
              height: 82,
              child: EventPoster(
                imageUrl: event.posterUrl,
                borderRadius: BorderRadius.circular(13),
                placeholderIcon: eventTypeIcon(event.type),
                fallbackColors: eventTypeColors(event.type),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.organizer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _eventMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _SmallBadge(
                        label: eventStatusLabel(event, DateTime.now()),
                        color: const Color(0x77335D50),
                      ),
                      _SmallBadge(label: '$matchPercent% khớp'),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: saved ? 'Bỏ lưu' : 'Lưu sự kiện',
                  visualDensity: VisualDensity.compact,
                  onPressed: onSave,
                  icon: Icon(
                    saved ? Icons.favorite : Icons.favorite_border,
                    color: saved ? const Color(0xFFFF8AA0) : Colors.white70,
                    size: 21,
                  ),
                ),
                if (event.needsVerification)
                  const Tooltip(
                    message: 'Cần kiểm tra thông tin',
                    child: Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFFFD166),
                      size: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 84,
              child: MatchBar(percent: matchPercent, height: 3),
            ),
          ],
        ),
      ),
    ),
  );
}

class EventEmptyState extends StatelessWidget {
  const EventEmptyState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 44),
    child: Column(
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF7658B3), Color(0xFF2A5970)],
            ),
          ),
          child: const Icon(Icons.rocket_launch_rounded, size: 38),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _eventMuted, height: 1.4),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}

class EventMatchTag extends StatelessWidget {
  const EventMatchTag({required this.percent, super.key});

  final int percent;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 70,
    child: Column(
      children: [
        Text(
          '$percent% phù hợp',
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
        ),
        MatchBar(percent: percent, height: 3),
      ],
    ),
  );
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.label,
    this.color = const Color(0xA81B1A29),
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 112),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        height: 1,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
