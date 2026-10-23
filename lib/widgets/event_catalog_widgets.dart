import 'package:flutter/material.dart';

import '../models/event_item.dart';
import '../services/career_board_service.dart';
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
          style: const TextStyle(
            fontSize: 18,
            height: 1.15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      if (onSeeAll != null)
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFD2C3FF),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(44, 36),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: const Text('Xem tất cả'),
        ),
    ],
  );
}

class EventHero extends StatelessWidget {
  const EventHero({
    required this.event,
    required this.saved,
    required this.onOpen,
    required this.onShare,
    required this.onToggleSaved,
    super.key,
  });

  final EventItem event;
  final bool saved;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final deadline = event.registrationDeadline;
    final daysLeft = event.daysUntilDeadline(now);
    final countdown =
        daysLeft != null && event.statusAt(now) == EventStatus.registrationOpen
        ? 'Còn $daysLeft ngày'
        : eventStatusLabel(event, now);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          EventPoster(
            imageUrl: event.posterUrl,
            sourceUrl: event.sourceUrl,
            borderRadius: BorderRadius.zero,
            placeholderIcon: eventTypeIcon(event.type),
            fallbackColors: eventTypeColors(event.type),
            eventType: event.type,
            organizer: event.organizer,
          ),
          Positioned(
            top: 16,
            left: 16,
            child: _SmallBadge(
              label: countdown,
              color: const Color(0xD81B1830),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              tooltip: saved ? 'Bỏ lưu sự kiện' : 'Lưu sự kiện',
              onPressed: onToggleSaved,
              icon: Icon(
                saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: saved ? const Color(0xFFFF91A9) : Colors.white,
              ),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0x66302B44),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 12)],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  event.organizer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE2DDF2),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  deadline == null
                      ? eventDateLabel(event.eventStart)
                      : 'Hạn đăng ký ${eventDateLabel(deadline)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFFD889),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: onOpen,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD8CCFF),
                          foregroundColor: const Color(0xFF211B35),
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Xem chi tiết',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _HeroActionButton(
                      icon: Icons.share_outlined,
                      label: 'Chia sẻ',
                      onPressed: onShare,
                    ),
                    const SizedBox(width: 8),
                    _HeroActionButton(
                      icon: saved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: saved ? 'Bỏ lưu' : 'Lưu',
                      onPressed: onToggleSaved,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: const Color(0x66302B44),
      minimumSize: const Size(44, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
    icon: Icon(icon, size: 20),
  );
}

class EventSection extends StatelessWidget {
  const EventSection({
    required this.title,
    required this.events,
    required this.matchPercent,
    required this.onSeeAll,
    required this.onOpen,
    required this.onSave,
    required this.isSaved,
    super.key,
  });

  final String title;
  final List<EventItem> events;
  final int Function(EventItem event) matchPercent;
  final VoidCallback onSeeAll;
  final ValueChanged<EventItem> onOpen;
  final ValueChanged<EventItem> onSave;
  final bool Function(EventItem event) isSaved;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EventSectionTitle(title: title, onSeeAll: onSeeAll),
          const SizedBox(height: 10),
          SizedBox(
            height: 278,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final event = events[index];
                return EventCard(
                  event: event,
                  saved: isSaved(event),
                  matchPercent: matchPercent(event),
                  onTap: () => onOpen(event),
                  onSave: () => onSave(event),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EventHomeSkeleton extends StatefulWidget {
  const EventHomeSkeleton({super.key});

  @override
  State<EventHomeSkeleton> createState() => _EventHomeSkeletonState();
}

class _EventHomeSkeletonState extends State<EventHomeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (reducedMotion == _reducedMotion) return;
    _reducedMotion = reducedMotion;
    if (reducedMotion) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shift = _reducedMotion ? 0.0 : -1.2 + _controller.value * 2.4;
        Widget block({
          required double height,
          double? width,
          double radius = 20,
        }) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(shift, -0.2),
              end: Alignment(shift + 1.2, 0.2),
              colors: const [
                Color(0xFF211D2B),
                Color(0xFF39314D),
                Color(0xFF211D2B),
              ],
            ),
          ),
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Row(
              children: [
                Expanded(child: block(height: 24, width: 180, radius: 8)),
                const SizedBox(width: 12),
                block(height: 42, width: 42, radius: 14),
              ],
            ),
            const SizedBox(height: 18),
            block(height: 404, radius: 28),
            const SizedBox(height: 30),
            for (var row = 0; row < 3; row++) ...[
              Row(
                children: [
                  Expanded(child: block(height: 20, width: 160, radius: 7)),
                  block(height: 18, width: 74, radius: 7),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 258,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, _) =>
                      block(height: 258, width: 172, radius: 20),
                ),
              ),
              const SizedBox(height: 26),
            ],
          ],
        );
      },
    );
  }
}

class EventCard extends StatefulWidget {
  const EventCard({
    required this.event,
    required this.saved,
    required this.matchPercent,
    required this.onTap,
    required this.onSave,
    this.width = 172,
    this.height = 258,
    super.key,
  });

  final EventItem event;
  final bool saved;
  final int matchPercent;
  final VoidCallback onTap;
  final VoidCallback onSave;
  final double width;
  final double height;

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final now = DateTime.now();
    final daysLeft = event.daysUntilDeadline(now);
    final isUrgent =
        daysLeft != null &&
        daysLeft < 3 &&
        event.statusAt(now) == EventStatus.registrationOpen;
    final dateLabel =
        daysLeft != null && event.statusAt(now) == EventStatus.registrationOpen
        ? 'Còn $daysLeft ngày'
        : eventStatusLabel(event, now);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: const Color(0xFF211D2B),
              child: InkWell(
                onTap: widget.onTap,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    EventPoster(
                      imageUrl: event.posterUrl,
                      sourceUrl: event.sourceUrl,
                      borderRadius: BorderRadius.zero,
                      placeholderIcon: eventTypeIcon(event.type),
                      fallbackColors: eventTypeColors(event.type),
                      eventType: event.type,
                      organizer: event.organizer,
                    ),
                    Positioned(
                      top: 9,
                      left: 9,
                      right: 8,
                      child: Row(
                        children: [
                          Flexible(
                            child: _SmallBadge(
                              label: event.type,
                              color: const Color(0xC91B1830),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: widget.saved
                                ? 'Bỏ lưu sự kiện'
                                : 'Lưu sự kiện',
                            constraints: const BoxConstraints.tightFor(
                              width: 34,
                              height: 34,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: widget.onSave,
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0x88302B44),
                            ),
                            icon: Icon(
                              widget.saved
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 18,
                              color: widget.saved
                                  ? const Color(0xFFFF91A9)
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: [
                              Tooltip(
                                message: 'Hạn đăng ký / trạng thái',
                                child: _SmallBadge(
                                  label: dateLabel,
                                  color: isUrgent
                                      ? const Color(0xE4A64432)
                                      : const Color(0xC91B1830),
                                ),
                              ),
                              if (widget.matchPercent > 0)
                                Tooltip(
                                  message: 'Mức độ phù hợp với hồ sơ của bạn',
                                  child: _SmallBadge(
                                    label: 'Khớp ${widget.matchPercent}%',
                                    color: const Color(0xC9345C49),
                                  ),
                                ),
                              if (event.needsVerification)
                                const Tooltip(
                                  message: 'Cần kiểm tra thông tin sự kiện',
                                  child: _SmallBadge(
                                    label: 'Cần kiểm tra',
                                    color: Color(0xDD795722),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.12,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 8),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            event.organizer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFE1DDEC),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

class EventPosterCard extends EventCard {
  const EventPosterCard({
    required super.event,
    required super.onTap,
    required super.onSave,
    required super.saved,
    super.matchPercent = 0,
    super.width = 172,
    super.height = 258,
    super.key,
  });
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: CareerBoardService.instance,
    builder: (context, _) {
      final service = CareerBoardService.instance;
      final fitsZone = service.fitsCurrentZone(service.currentRole(), [
        ...event.relatedCareers,
        ...event.skills,
      ]);
      return _buildCard(context, fitsZone: fitsZone);
    },
  );

  Widget _buildCard(BuildContext context, {required bool fitsZone}) => Padding(
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
                sourceUrl: event.sourceUrl,
                borderRadius: BorderRadius.circular(13),
                placeholderIcon: eventTypeIcon(event.type),
                fallbackColors: eventTypeColors(event.type),
                eventType: event.type,
                organizer: event.organizer,
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
                      if (matchPercent > 0)
                        Tooltip(
                          message: 'Mức độ phù hợp với hồ sơ của bạn',
                          child: _SmallBadge(label: 'Khớp $matchPercent%'),
                        ),
                      if (event.needsVerification)
                        const Tooltip(
                          message: 'Cần kiểm tra thông tin sự kiện',
                          child: _SmallBadge(
                            label: 'Cần kiểm tra',
                            color: Color(0xDD795722),
                          ),
                        ),
                      if (fitsZone)
                        const _SmallBadge(
                          label: 'Hợp với vùng bạn đang học',
                          color: Color(0x88B86A2E),
                        ),
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
              ],
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
