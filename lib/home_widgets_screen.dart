import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import 'home_event_screen.dart';
import 'models/character_data.dart';
import 'screens/chatbot_screen.dart';

class HomeWidgetsScreen extends StatefulWidget {
  const HomeWidgetsScreen({super.key});

  @override
  State<HomeWidgetsScreen> createState() => _HomeWidgetsScreenState();
}

class _HomeWidgetsScreenState extends State<HomeWidgetsScreen>
    with TickerProviderStateMixin {
  static const _backgroundColor = Color(0xFF100E19);
  static const _accentColor = Color(0xFFBFA8FF);

  static const _features = [
    _DashboardFeature('Sao Thủy', 'Xem Job sinh viên', Color(0xFFB9A2FF), [
      Color(0xFFEEE6FF),
      Color(0xFFA98DFF),
      Color(0xFF5033A8),
    ], 'assets/images/planets/mercury.png'),
    _DashboardFeature('Sao Kim', 'Chợ đồ cũ', Color(0xFFFFC18E), [
      Color(0xFFFFE7C9),
      Color(0xFFFFB56F),
      Color(0xFFB35445),
    ], 'assets/images/planets/venus.png'),
    _DashboardFeature('Trái Đất', 'Hỏi bài', Color(0xFF8DD8D1), [
      Color(0xFFB3F4DF),
      Color(0xFF55BFA6),
      Color(0xFF246E82),
    ], 'assets/images/planets/earth.png'),
    _DashboardFeature('Sao Hỏa', 'To-Do List', Color(0xFFFF9EBD), [
      Color(0xFFFFC19E),
      Color(0xFFFF704E),
      Color(0xFF9B263D),
    ], 'assets/images/planets/mars.png'),
    _DashboardFeature('Sao Mộc', 'Đồ ăn Căn tin', Color(0xFFFFD36E), [
      Color(0xFFFFE8A1),
      Color(0xFFE6A83F),
      Color(0xFF8F4C2C),
    ], 'assets/images/planets/jupiter.png'),
    _DashboardFeature('Sao Thổ', 'Flashcard', Color(0xFF9DBBFF), [
      Color(0xFFFFE6A2),
      Color(0xFFCC9F55),
      Color(0xFF704A56),
    ], 'assets/images/planets/saturn.png'),
    _DashboardFeature(
      'Sao Thiên Vương',
      'Quét & tích điểm CV',
      Color(0xFFB7E59B),
      [Color(0xFFD8FFF4), Color(0xFF73D7CF), Color(0xFF287AA3)],
      'assets/images/planets/uranus.png',
    ),
    _DashboardFeature('Sao Hải Vương', 'Career Map', Color(0xFFFFA878), [
      Color(0xFF90E8FF),
      Color(0xFF278BFF),
      Color(0xFF2430A8),
    ], 'assets/images/planets/neptune.png'),
  ];

  late final AnimationController _floatController;
  late final AnimationController _planetController;
  late final Animation<double> _floatOffset;
  late final Animation<double> _ufoFloatOffset;
  final _searchController = TextEditingController();
  int _selectedTab = 0;
  int? _selectedFeatureIndex;
  String _searchQuery = '';

  CharacterData get _companion =>
      CharacterSelection.selected ?? characterData.first;

  List<_DashboardFeature> get _visibleFeatures {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _features;
    return _features
        .where(
          (feature) =>
              feature.planet.toLowerCase().contains(query) ||
              feature.label.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    _planetController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
    _floatOffset = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _ufoFloatOffset = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _planetController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _selectFeature(int index) {
    setState(() {
      _selectedFeatureIndex = index == _selectedFeatureIndex ? null : index;
    });
  }

  void _openChatbot() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ChatbotScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildHomeTab(),
      const HomeEventScreen(),
      _buildInfoTab(
        icon: Icons.map_rounded,
        title: 'Bản đồ 3D UEH',
        description: 'Khám phá các cơ sở và không gian học tập UEH.',
      ),
      _buildInfoTab(
        icon: Icons.calculate_rounded,
        title: 'Tính toán GPA',
        description: 'Theo dõi kết quả học tập và mục tiêu GPA của bạn.',
      ),
      _buildInfoTab(
        icon: Icons.account_circle_rounded,
        title: 'Hồ sơ của bạn',
        description:
            'Linh vật ${_companion.name} luôn sẵn sàng đồng hành cùng bạn.',
      ),
    ];

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: IndexedStack(index: _selectedTab, children: tabs),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Semantics(
        button: true,
        label: 'Mở UEH AI Assistant',
        child: SizedBox(
          width: 64,
          height: 64,
          child: Material(
            color: const Color(0xFFBFA8FF),
            elevation: 2,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _openChatbot,
              child: AnimatedBuilder(
                animation: _ufoFloatOffset,
                child: Image.asset(
                  'assets/images/rocket-removebg-preview.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  semanticLabel: 'Tên lửa UEH Hero',
                ),
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _ufoFloatOffset.value),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomAppBar(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          color: const Color(0xFF191622),
          elevation: 16,
          shape: const CircularNotchedRectangle(),
          notchMargin: 7,
          child: Row(
            children: [
              Expanded(
                child: _buildNavButton(
                  1,
                  Icons.calendar_month_rounded,
                  'Events',
                ),
              ),
              Expanded(child: _buildNavButton(2, Icons.map_rounded, '3D Map')),
              const SizedBox(width: 58),
              Expanded(
                child: _buildNavButton(3, Icons.calculate_rounded, 'GPA Calc'),
              ),
              Expanded(
                child: _buildNavButton(4, Icons.person_rounded, 'Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(int index, IconData icon, String label) {
    final selected = _selectedTab == index;
    final color = selected ? _accentColor : const Color(0xFF928DA0);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => _selectedTab = index),
        child: SizedBox(
          height: 54,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 21),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    height: 1,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final headerHeight = (screenHeight * 0.66).clamp(380.0, 420.0).toDouble();
    final features = _visibleFeatures;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(child: _buildGalaxyHeader(headerHeight)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 7),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Khám phá UEH',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${features.length} hành tinh',
                      style: const TextStyle(
                        color: Color(0xFFAAA5B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                if (features.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Không tìm thấy tính năng phù hợp.',
                      style: TextStyle(color: Color(0xFFAAA5B8)),
                    ),
                  )
                else
                  GridView.builder(
                    itemCount: features.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                    itemBuilder: (context, index) {
                      final feature = features[index];
                      final featureIndex = _features.indexOf(feature);
                      return _PlanetButton(
                        feature: feature,
                        selected: featureIndex == _selectedFeatureIndex,
                        rotation: _planetController,
                        phase: featureIndex * 0.8,
                        onTap: () => _selectFeature(featureIndex),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGalaxyHeader(double height) {
    final topInset = MediaQuery.paddingOf(context).top;
    final companion = _companion;
    final mascotSize = math.min(284.0, height - topInset - 99);

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipPath(
            clipper: _GalaxyWaveClipper(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/welcome_bg.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x660B0718),
                        Color(0x33130D23),
                        Color(0xCC100E19),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: topInset + 8,
            left: 20,
            right: 20,
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: _accentColor,
                  size: 23,
                ),
                const SizedBox(width: 8),
                const Text(
                  'UEH HERO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  'TP. HỒ CHÍ MINH',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 9,
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.location_on_rounded,
                  color: _accentColor,
                  size: 15,
                ),
              ],
            ),
          ),
          Positioned.fill(
            top: topInset + 32,
            bottom: 67,
            child: TickerMode(
              enabled: _selectedTab == 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _floatOffset,
                  child: SizedBox(
                    width: mascotSize,
                    height: mascotSize,
                    child: ModelViewer(
                      key: ValueKey(companion.modelPath),
                      src: companion.modelPath,
                      alt: companion.name,
                      autoPlay: true,
                      animationName: companion.animationName,
                      autoRotate: false,
                      autoRotateDelay: 0,
                      cameraControls: true,
                      disableZoom: true,
                      backgroundColor: Colors.transparent,
                      debugLogging: false,
                    ),
                  ),
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _floatOffset.value),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: topInset + 52,
            left: 12,
            child: const _SpeechBubble(),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 25,
            child: _buildSearchField(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 13, sigmaY: 13),
        child: Container(
          height: 51,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() {
              _searchQuery = value;
              if (value.isNotEmpty) _selectedFeatureIndex = null;
            }),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tìm sự kiện, món ăn, cơ hội...',
              hintStyle: const TextStyle(
                color: Color(0xFFE1DFE8),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 21,
              ),
              suffixIcon: _searchQuery.isEmpty
                  ? const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 19,
                    )
                  : IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: _accentColor, size: 54),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB4B0BE), height: 1.5),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => setState(() => _selectedTab = 0),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Về trang chủ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 125,
      child: Text(
        'Chào bạn!\nKhám phá UEH nhé! 🚀',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          height: 1.3,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xCC100E19), blurRadius: 5)],
        ),
      ),
    );
  }
}

class _PlanetButton extends StatelessWidget {
  const _PlanetButton({
    required this.feature,
    required this.selected,
    required this.rotation,
    required this.phase,
    required this.onTap,
  });

  final _DashboardFeature feature;
  final bool selected;
  final Animation<double> rotation;
  final double phase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${feature.planet}: ${feature.label}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedScale(
            scale: selected ? 1.035 : 1,
            duration: const Duration(milliseconds: 180),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: selected
                      ? [
                          feature.gradientColors[1].withValues(alpha: 0.4),
                          const Color(0xFF211C31),
                        ]
                      : [
                          feature.gradientColors[2].withValues(alpha: 0.32),
                          const Color(0xFF1B1825),
                        ],
                ),
                border: Border.all(
                  color: selected
                      ? feature.color.withValues(alpha: 0.95)
                      : feature.color.withValues(alpha: 0.48),
                  width: selected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: feature.color.withValues(
                      alpha: selected ? 0.38 : 0.16,
                    ),
                    blurRadius: selected ? 22 : 12,
                    spreadRadius: selected ? 1 : 0,
                  ),
                  const BoxShadow(
                    color: Color(0xAA07050D),
                    blurRadius: 12,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 11),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: rotation,
                          child: Image.asset(
                            feature.imagePath,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                          builder: (context, child) {
                            final angle = rotation.value * 2 * math.pi + phase;
                            return Transform.translate(
                              offset: Offset(0, math.sin(angle * 2) * 3),
                              child: Transform.rotate(
                                angle: angle,
                                child: child,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      feature.planet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? feature.color : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      feature.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFD0CBD9),
                        fontSize: 10,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
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

class _GalaxyWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 28)
      ..cubicTo(
        size.width * 0.22,
        size.height + 5,
        size.width * 0.72,
        size.height - 58,
        size.width,
        size.height - 18,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DashboardFeature {
  const _DashboardFeature(
    this.planet,
    this.label,
    this.color,
    this.gradientColors,
    this.imagePath,
  );

  final String planet;
  final String label;
  final Color color;
  final List<Color> gradientColors;
  final String imagePath;
}
