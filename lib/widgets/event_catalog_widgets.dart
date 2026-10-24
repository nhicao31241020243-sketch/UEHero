import 'dart:async';

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
    return const [Color(0xFF145B85), Color(0xFF37306F)];
  }
  if (value.contains('data')) {
    return const [Color(0xFF43317A), Color(0xFF17627A)];
  }
  if (value.contains('workshop')) {
    return const [Color(0xFF347658), Color(0xFF1F4D55)];
  }
  if (value.contains('hội chợ') || value.contains('career')) {
    return const [Color(0xFF8B5436), Color(0xFF49334D)];
  }
  if (value.contains('case')) {
    return const [Color(0xFF945536), Color(0xFF57354C)];
  }
  return const [Color(0xFF51477F), Color(0xFF213E5B)];
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

class EventHeroCarousel extends StatefulWidget {
  const EventHeroCarousel({
    required this.events,
    required this.savedIds,
    required this.onOpen,
    required this.onShare,
    required this.onToggleSaved,
    super.key,
  });

  final List<EventItem> events;
  final Set<String> savedIds;
  final ValueChanged<EventItem> onOpen;
  final ValueChanged<EventItem> onShare;
  final ValueChanged<EventItem> onToggleSaved;

  @override
  State<EventHeroCarousel> createState() => _EventHeroCarouselState();
}

class _EventHeroCarouselState extends State<EventHeroCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant EventHeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events.length != widget.events.length) {
      _index = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.events.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients || widget.events.isEmpty) return;
      final next = (_index + 1) % widget.events.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AspectRatio(
        aspectRatio: 16 / 9,
        child: PageView.builder(
          controller: _controller,
          itemCount: widget.events.length,
          onPageChanged: (index) => setState(() => _index = index),
          itemBuilder: (context, index) {
            final event = widget.events[index];
            return EventHero(
              event: event,
              saved: widget.savedIds.contains(event.id),
              onOpen: () => widget.onOpen(event),
              onShare: () => widget.onShare(event),
              onToggleSaved: () => widget.onToggleSaved(event),
            );
          },
        ),
      ),
      if (widget.events.length > 1) ...[
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.events.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: index == _index ? 18 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: index == _index
                    ? const Color(0xFFBFA8FF)
                    : Colors.white38,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

class EventCategoryChips extends StatelessWidget {
  const EventCategoryChips({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  static const categories = [
    'Tất cả',
    'Hackathon',
    'Business Case',
    'Workshop',
    'Cuộc thi',
    'Kỹ năng',
  ];

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = category == selected;
        return ChoiceChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (_) => onSelected(category),
          showCheckmark: false,
          backgroundColor: const Color(0xAA242236),
          selectedColor: const Color(0xFF6751A5),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFFBFA8FF)
                : Colors.white.withValues(alpha: 0.1),
          ),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFD0CCDC),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 5),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      },
    ),
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
      borderRadius: BorderRadius.circular(20),
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
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x18030818),
                      Color(0x16030818),
                      Color(0xF208101F),
                    ],
                    stops: [0, 0.28, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 12,
            child: _SmallBadge(
              label: event.type,
              color: const Color(0xD81B1830),
            ),
          ),
          Positioned(
            top: 40,
            left: 12,
            child: _SmallBadge(
              label: countdown,
              color: const Color(0xB81B1830),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              tooltip: saved ? 'Bỏ lưu sự kiện' : 'Lưu sự kiện',
              onPressed: onToggleSaved,
              icon: Icon(
                saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: saved ? const Color(0xFFFF91A9) : Colors.white,
              ),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0x88302B44),
                foregroundColor: Colors.white,
                minimumSize: const Size(38, 38),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 10,
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
                    fontSize: 17,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.organizer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE2DDF2),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        deadline == null
                            ? eventDateLabel(event.eventStart)
                            : 'Hạn ${eventDateLabel(deadline)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFFFFD889),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: onOpen,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD8CCFF),
                          foregroundColor: const Color(0xFF211B35),
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Xem chi tiết',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _HeroActionButton(
                      icon: Icons.share_outlined,
                      label: 'Chia sẻ',
                      onPressed: onShare,
                    ),
                    const SizedBox(width: 6),
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
    padding: EdgeInsets.zero,
    style: IconButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: const Color(0x66302B44),
      minimumSize: const Size(36, 34),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    icon: Icon(icon, size: 18),
  );
}

class EventSectionRow extends StatelessWidget {
  const EventSectionRow({
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
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EventSectionTitle(title: title, onSeeAll: onSeeAll),
          const SizedBox(height: 9),
          SizedBox(
            height: 252,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final event = events[index];
                return EventCard(
                  event: event,
                  saved: isSaved(event),
                  matchPercent: matchPercent(event),
                  onTap: () => onOpen(event),
                  onSave: () => onSave(event),
                  width: 168,
                  height: 252,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EventSection extends EventSectionRow {
  const EventSection({
    required super.title,
    required super.events,
    required super.matchPercent,
    required super.onSeeAll,
    required super.onOpen,
    required super.onSave,
    required super.isSaved,
    super.key,
  });
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
            const SizedBox(height: 14),
            block(height: 48, radius: 24),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  block(height: 34, width: 76, radius: 18),
                  const SizedBox(width: 8),
                  block(height: 34, width: 92, radius: 18),
                  const SizedBox(width: 8),
                  block(height: 34, width: 102, radius: 18),
                  const SizedBox(width: 8),
                  block(height: 34, width: 80, radius: 18),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: block(height: 184, radius: 20),
            ),
            const SizedBox(height: 20),
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
        daysLeft <= 3 &&
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
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: const Color(0xFF211D2B),
              child: InkWell(
                onTap: widget.onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
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
                            top: 7,
                            left: 7,
                            right: 7,
                            child: Row(
                              children: [
                                Flexible(
                                  child: _SmallBadge(
                                    label: event.type,
                                    color: const Color(0xD51B1830),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: widget.saved
                                      ? 'Bỏ lưu sự kiện'
                                      : 'Lưu sự kiện',
                                  constraints: const BoxConstraints.tightFor(
                                    width: 32,
                                    height: 32,
                                  ),
                                  padding: EdgeInsets.zero,
                                  onPressed: widget.onSave,
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xAA302B44),
                                  ),
                                  icon: Icon(
                                    widget.saved
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 17,
                                    color: widget.saved
                                        ? const Color(0xFFFF91A9)
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              event.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                height: 1.12,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Wrap(
                              spacing: 4,
                              runSpacing: 3,
                              children: [
                                _SmallBadge(
                                  label: dateLabel,
                                  color: isUrgent
                                      ? const Color(0xE4A64432)
                                      : const Color(0xC91B1830),
                                ),
                                if (widget.matchPercent > 0)
                                  _SmallBadge(
                                    label: 'Khớp ${widget.matchPercent}%',
                                    color: const Color(0xC9345C49),
                                  ),
                              ],
                            ),
                            Text(
                              event.registrationDeadline != null
                                  ? 'Hạn ${eventDateLabel(event.registrationDeadline)}'
                                  : eventDateLabel(event.eventStart),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFD2C3FF),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              event.organizer,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFD4D0DE),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (event.needsVerification)
                              const _SmallBadge(
                                label: 'Cần kiểm tra',
                                color: Color(0xDD795722),
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
    constraints: const BoxConstraints(maxWidth: 180),
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
