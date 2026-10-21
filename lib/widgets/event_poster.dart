import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/event_image_resolver.dart';

class EventPoster extends StatefulWidget {
  const EventPoster({
    super.key,
    this.imagePath,
    this.imageUrl,
    this.sourceUrl,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.placeholderIcon = Icons.image_outlined,
    this.fallbackColors = const [Color(0xFF392B55), Color(0xFF1F2937)],
  });

  final String? imagePath;
  final String? imageUrl;
  final String? sourceUrl;
  final BorderRadius borderRadius;
  final IconData placeholderIcon;
  final List<Color> fallbackColors;

  @override
  State<EventPoster> createState() => _EventPosterState();
}

class _EventPosterState extends State<EventPoster>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  String? _resolvedUrl;
  int _resolveGeneration = 0;
  bool _resolving = true;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant EventPoster oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.sourceUrl != widget.sourceUrl) {
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _resolveImage() async {
    final generation = ++_resolveGeneration;
    _shimmerController.repeat();
    setState(() {
      _resolvedUrl = null;
      _resolving = true;
    });
    final imageUrl = await EventImageResolver.instance.resolve(
      imageUrl: widget.imageUrl,
      sourceUrl: widget.sourceUrl,
    );
    if (!mounted || generation != _resolveGeneration) return;
    setState(() {
      _resolvedUrl = imageUrl;
      _resolving = false;
    });
    if (imageUrl == null) _shimmerController.stop();
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.imagePath;
    final child = _resolvedUrl != null
        ? CachedNetworkImage(
            imageUrl: _resolvedUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (_, _) => _shimmer(),
            imageBuilder: (context, imageProvider) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _shimmerController.isAnimating) {
                  _shimmerController.stop();
                }
              });
              return Image(
                image: imageProvider,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            },
            errorWidget: (_, _, _) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _shimmerController.isAnimating) {
                  _shimmerController.stop();
                }
              });
              return _fallback();
            },
          )
        : imagePath != null && imagePath.isNotEmpty
        ? Image.asset(
            imagePath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, _, _) => _fallback(),
          )
        : _resolving
        ? _shimmer()
        : _fallback();
    return ClipRRect(borderRadius: widget.borderRadius, child: child);
  }

  Widget _shimmer() => AnimatedBuilder(
    animation: _shimmerController,
    builder: (context, _) {
      final shift = -1.5 + _shimmerController.value * 3;
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(shift, -1),
            end: Alignment(shift + 1.5, 1),
            colors: const [
              Color(0xFF201B2B),
              Color(0xFF383047),
              Color(0xFF201B2B),
            ],
          ),
        ),
      );
    },
  );

  Widget _fallback() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: widget.fallbackColors,
      ),
    ),
    alignment: Alignment.center,
    child: Icon(widget.placeholderIcon, color: Colors.white54, size: 32),
  );
}
