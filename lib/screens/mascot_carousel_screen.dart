import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../home_widgets_screen.dart';
import '../models/character_data.dart';

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

  void _selectCharacter(CharacterData character) {
    CharacterSelection.selected = character;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => const HomeWidgetsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final characters = characterData
        .where((character) => character.group == 'blob')
        .toList(growable: false);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: characters[_currentIndex].primaryColor,
        child: PageView.builder(
          controller: _pageController,
          itemCount: characters.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) => _CharacterCarouselPage(
            character: characters[index],
            index: index,
            total: characters.length,
            showViewer: index == _currentIndex,
            onSelect: () => _selectCharacter(characters[index]),
          ),
        ),
      ),
    );
  }
}

class _CharacterCarouselPage extends StatelessWidget {
  const _CharacterCarouselPage({
    required this.character,
    required this.index,
    required this.total,
    required this.showViewer,
    required this.onSelect,
  });

  final CharacterData character;
  final int index;
  final int total;
  final bool showViewer;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
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
                        if (showViewer)
                          ModelViewer(
                            src: character.modelPath,
                            alt: character.name,
                            autoPlay: true,
                            animationName: character.animationName,
                            autoRotate: true,
                            autoRotateDelay: 0,
                            cameraControls: true,
                            disableZoom: true,
                            backgroundColor: Colors.transparent,
                            debugLogging: true,
                          )
                        else
                          Center(
                            child: Text(
                              character.emoji,
                              style: const TextStyle(fontSize: 96),
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
                              '${index + 1} / $total',
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
                            character.primaryColor.withValues(alpha: 0),
                            character.primaryColor.withValues(alpha: 0.28),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            character.name.toUpperCase(),
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
                            '“${character.description}”',
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
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final tag in character.tags)
                                Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.45,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              onPressed: onSelect,
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
