import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/event_image_resolver.dart';
import 'event_image_placeholder.dart';

class EventPoster extends StatefulWidget {
  const EventPoster({
    super.key,
    this.imagePath,
    this.imageUrl,
    this.sourceUrl,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.placeholderIcon = Icons.image_outlined,
    this.fallbackColors = const [Color(0xFF392B55), Color(0xFF1F2937)],
    this.eventType = 'Sự kiện',
    this.organizer,
  });

  final String? imagePath;
  final String? imageUrl;
  final String? sourceUrl;
  final BorderRadius borderRadius;
  final IconData placeholderIcon;
  final List<Color> fallbackColors;
  final String eventType;
  final String? organizer;

  @override
  State<EventPoster> createState() => _EventPosterState();
}

class _EventPosterState extends State<EventPoster> {
  String? _resolvedUrl;
  int _resolveGeneration = 0;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant EventPoster oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.sourceUrl != widget.sourceUrl ||
        oldWidget.eventType != widget.eventType ||
        oldWidget.organizer != widget.organizer) {
      _resolveImage();
    }
  }

  Future<void> _resolveImage() async {
    final generation = ++_resolveGeneration;
    setState(() {
      _resolvedUrl = null;
    });
    final imageUrl = await EventImageResolver.instance.resolve(
      imageUrl: widget.imageUrl,
      sourceUrl: widget.sourceUrl,
    );
    if (!mounted || generation != _resolveGeneration) return;
    setState(() {
      _resolvedUrl = imageUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.imagePath;
    final url = _resolvedUrl;
    final hasAsset = imagePath != null && imagePath.isNotEmpty;
    final child = url != null
        ? CachedNetworkImage(
            key: ValueKey(url),
            imageUrl: url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            fadeInDuration: const Duration(milliseconds: 320),
            placeholder: (_, _) => _fallback(),
            errorWidget: (_, _, _) => _fallback(),
          )
        : hasAsset
        ? Image.asset(
            imagePath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, _, _) => _fallback(),
          )
        : _fallback();
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(
              key: ValueKey<Object?>(
                url ?? (hasAsset ? imagePath : 'fallback'),
              ),
              child: child,
            ),
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xE6000716)],
                  stops: [0.34, 1],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() => EventImagePlaceholder(
    icon: widget.placeholderIcon,
    colors: widget.fallbackColors,
    eventType: widget.eventType,
    organizer: widget.organizer,
  );
}
