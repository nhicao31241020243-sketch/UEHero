import 'dart:async';

import 'package:flutter/material.dart';

import '../models/event_item.dart';
import '../models/tech_event.dart';

class EventStreamCategoryChips extends StatelessWidget {
  const EventStreamCategoryChips({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  static const categories = [
    'Tất cả',
    'Hackathon',
    'Cuộc thi',
    'Workshop',
    'Chương trình',
  ];

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = selected == category;
        return ChoiceChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (_) => onSelected(category),
          showCheckmark: false,
          selectedColor: const Color(0xFF7052B8),
          backgroundColor: const Color(0xBB252039),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFFC3AEFF)
                : Colors.white.withValues(alpha: 0.12),
          ),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFD2CBE4),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 7),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      },
    ),
  );
}

class EventStreamHeroCarousel extends StatefulWidget {
  const EventStreamHeroCarousel({
    required this.events,
    required this.onOpen,
    super.key,
  });

  final List<EventItem> events;
  final ValueChanged<EventItem> onOpen;

  @override
  State<EventStreamHeroCarousel> createState() =>
      _EventStreamHeroCarouselState();
}

class _EventStreamHeroCarouselState extends State<EventStreamHeroCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant EventStreamHeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events.length != widget.events.length) {
      _page = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.events.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients || widget.events.isEmpty) return;
      _controller.animateToPage(
        (_page + 1) % widget.events.length,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
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
    children: [
      AspectRatio(
        aspectRatio: 1.55,
        child: PageView.builder(
          controller: _controller,
          itemCount: widget.events.length,
          onPageChanged: (page) => setState(() => _page = page),
          itemBuilder: (context, index) => _EventStreamHero(
            event: widget.events[index],
            onOpen: () => widget.onOpen(widget.events[index]),
          ),
        ),
      ),
      if (widget.events.length > 1) ...[
        const SizedBox(height: 9),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.events.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: index == _page ? 18 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: index == _page
                    ? const Color(0xFFC5AEFF)
                    : Colors.white38,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

class _EventStreamHero extends StatelessWidget {
  const _EventStreamHero({required this.event, required this.onOpen});

  final EventItem event;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final group = techEventGroup(event.title, event.type);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: group.colors.last,
        child: InkWell(
          onTap: onOpen,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: group.colors,
                  ),
                ),
              ),
              Positioned(
                right: -16,
                top: -12,
                child: Icon(
                  group.icon,
                  size: 190,
                  color: Colors.white.withValues(alpha: 0.09),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x080A0814), Color(0xE90A0818)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EventGenrePill(label: group.label),
                    const Spacer(),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      event.organizer.isEmpty
                          ? 'Đơn vị tổ chức đang cập nhật'
                          : event.organizer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFDAD4EA),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: FilledButton(
                        onPressed: onOpen,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE6DCFF),
                          foregroundColor: const Color(0xFF201833),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Xem chi tiết',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EventStreamSectionRow extends StatelessWidget {
  const EventStreamSectionRow({
    required this.title,
    required this.events,
    required this.onOpen,
    super.key,
  });

  final String title;
  final List<EventItem> events;
  final ValueChanged<EventItem> onOpen;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${events.length}',
                style: const TextStyle(
                  color: Color(0xFFBDB4D0),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) => EventStreamCard(
                event: events[index],
                onTap: () => onOpen(events[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventStreamCard extends StatelessWidget {
  const EventStreamCard({
    required this.event,
    required this.onTap,
    this.width = 150,
    this.height = 210,
    super.key,
  });

  final EventItem event;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final group = techEventGroup(event.title, event.type);
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: group.colors.last,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: group.colors,
                    ),
                  ),
                ),
                Positioned(
                  right: -18,
                  top: 22,
                  child: Icon(
                    group.icon,
                    size: 124,
                    color: Colors.white.withValues(alpha: 0.09),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x06090813), Color(0xCC090812)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _EventGenrePill(label: group.label, compact: true),
                      const Spacer(),
                      Text(
                        event.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
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
    );
  }
}

class _EventGenrePill extends StatelessWidget {
  const _EventGenrePill({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xAA171321),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}
