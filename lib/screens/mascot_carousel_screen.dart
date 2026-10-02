import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

import '../home_event_screen.dart';
import '../models/mascot_model.dart';

class MascotCarouselScreen extends StatefulWidget {
  const MascotCarouselScreen({super.key});

  @override
  State<MascotCarouselScreen> createState() => _MascotCarouselScreenState();
}

class _MascotCarouselScreenState extends State<MascotCarouselScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectMascot(Mascot mascot) {
    MascotSelection.selected = mascot;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => const HomeEventScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mascots = Mascot.collection;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: mascots[_currentIndex].primaryColor,
        child: PageView.builder(
          controller: _pageController,
          itemCount: mascots.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) => _MascotCarouselPage(
            mascot: mascots[index],
            index: index,
            total: mascots.length,
            onSelect: () => _selectMascot(mascots[index]),
          ),
        ),
      ),
    );
  }
}

class _MascotCarouselPage extends StatefulWidget {
  const _MascotCarouselPage({
    required this.mascot,
    required this.index,
    required this.total,
    required this.onSelect,
  });

  final Mascot mascot;
  final int index;
  final int total;
  final VoidCallback onSelect;

  @override
  State<_MascotCarouselPage> createState() => _MascotCarouselPageState();
}

class _MascotCarouselPageState extends State<_MascotCarouselPage> {
  final _controller = Flutter3DController();
  double _loadProgress = 0;
  bool _loaded = false;
  bool _failed = false;

  Future<void> _playFirstAnimation() async {
    final animations = await _controller.getAvailableAnimations();
    if (!mounted || animations.isEmpty) return;
    _controller.playAnimation(animationName: animations.first);
  }

  @override
  Widget build(BuildContext context) {
    final mascot = widget.mascot;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pageHeight = constraints.maxHeight < 680
              ? 680.0
              : constraints.maxHeight;

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              height: pageHeight,
              child: Column(
                children: [
                  Expanded(
                    flex: 55,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                          child: Container(
                            width: constraints.maxWidth * 0.78,
                            height: constraints.maxWidth * 0.78,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.46),
                                  Colors.white.withValues(alpha: 0.04),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            mascot.emoji,
                            style: const TextStyle(fontSize: 96),
                          ),
                        ),
                        if (!_failed)
                          Flutter3DViewer(
                            src: mascot.model3dUrl,
                            controller: _controller,
                            enableTouch: true,
                            activeGestureInterceptor: true,
                            progressBarColor: Colors.transparent,
                            onProgress: (progress) {
                              if (mounted) {
                                setState(() => _loadProgress = progress);
                              }
                            },
                            onLoad: (_) {
                              if (mounted) setState(() => _loaded = true);
                              _playFirstAnimation();
                            },
                            onError: (_) {
                              if (mounted) setState(() => _failed = true);
                            },
                          ),
                        if (!_loaded && !_failed)
                          Center(
                            child: CircularProgressIndicator(
                              value: _loadProgress > 0 ? _loadProgress : null,
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                        Positioned(
                          left: 20,
                          top: 12,
                          child: Text(
                            'CHỌN LINH VẬT',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                              shadows: const [
                                Shadow(color: Colors.black26, blurRadius: 8),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: 18,
                          top: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              '${widget.index + 1} / ${widget.total}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const Positioned(
                          bottom: 14,
                          left: 0,
                          right: 0,
                          child: Text(
                            'Vuốt để xoay • Lướt để đổi linh vật',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(color: Colors.black26, blurRadius: 8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 45,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            mascot.primaryColor.withValues(alpha: 0),
                            mascot.primaryColor.withValues(alpha: 0.28),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            mascot.name.toUpperCase(),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                              shadows: [
                                Shadow(
                                  color: Color(0x55000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            '“${mascot.title}”',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.96),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              shadows: const [
                                Shadow(color: Colors.black26, blurRadius: 8),
                              ],
                            ),
                          ),
                          const SizedBox(height: 19),
                          SizedBox(
                            height: 38,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: true,
                              itemCount: mascot.traits.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) => Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                ),
                                child: Text(
                                  mascot.traits[index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              onPressed: widget.onSelect,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF30215F),
                                foregroundColor: Colors.white,
                                elevation: 7,
                                shadowColor: Colors.black26,
                                shape: const StadiumBorder(),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Đồng hành ngay',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
