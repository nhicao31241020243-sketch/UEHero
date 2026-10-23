import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import 'home_event_screen.dart';
import 'models/character_data.dart';
import 'models/notebook_activity.dart';
import 'screens/calendar_screen.dart';
import 'screens/career_board_screen.dart';
import 'screens/cv_check_screen.dart';
import 'screens/flashcard_home_screen.dart';
import 'screens/career_notebook_screen.dart';
import 'screens/interview/interview_home_screen.dart';
import 'screens/job_screen.dart';
import 'screens/mentor_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/second_hand_market_screen.dart';
import 'screens/uehero_camera_screen.dart';
import 'services/route_observer.dart';
import 'services/points_manager.dart';
import 'services/career_map_visibility.dart';
import 'theme/space_theme.dart';
import 'widgets/xp_float_overlay.dart';
import 'widgets/space_glass_widgets.dart';
import 'widgets/space_home_widgets.dart';

class HomeWidgetsScreen extends StatefulWidget {
  const HomeWidgetsScreen({super.key});

  @override
  State<HomeWidgetsScreen> createState() => _HomeWidgetsScreenState();
}

class _HomeWidgetsScreenState extends State<HomeWidgetsScreen>
    with TickerProviderStateMixin, RouteAware {
  static const _accentColor = SpaceTheme.glow;

  static const _features = [
    _DashboardFeature(
      'Job Match',
      'Jobs that fit you',
      Color(0xFFB9A2FF),
      [Color(0xFFEAE2FA), Color(0xFF9A8DC8), Color(0xFF3B3266)],
      PlanetStyle.rocky,
      'mercury',
    ),
    _DashboardFeature(
      'Book Swap',
      'Books & study gear',
      Color(0xFFFFC18E),
      [Color(0xFFFFE3B8), Color(0xFFE0A25B), Color(0xFF8A4B2E)],
      PlanetStyle.bands,
      'venus',
    ),
    _DashboardFeature(
      'Study Buddy',
      'Ask, learn, practice',
      Color(0xFF8DD8D1),
      [Color(0xFFBDEBFF), Color(0xFF3E8FD0), Color(0xFF123A73)],
      PlanetStyle.rocky,
      'earth',
    ),
    _DashboardFeature(
      'Weekly Plan',
      'Your next steps',
      Color(0xFFFF9EBD),
      [Color(0xFFFFB894), Color(0xFFD8573A), Color(0xFF6A1F22)],
      PlanetStyle.rocky,
      'mars',
    ),
    _DashboardFeature(
      'UEH Mentor',
      'Mentors for your goal',
      Color(0xFFFFD36E),
      [Color(0xFFFFE6B0), Color(0xFFD49A55), Color(0xFF7A4A2E)],
      PlanetStyle.bands,
      'jupiter',
    ),
    _DashboardFeature(
      'Skill Drills',
      'Practice what you need',
      Color(0xFF9DBBFF),
      [Color(0xFFFFEFC2), Color(0xFFD9B26A), Color(0xFF6E4F6B)],
      PlanetStyle.ringed,
      'saturn',
    ),
    _DashboardFeature(
      'CV Check',
      'Score & fix your CV',
      Color(0xFFB7E59B),
      [Color(0xFFD9FFF8), Color(0xFF6FD3D0), Color(0xFF247C9B)],
      PlanetStyle.ice,
      'uranus',
    ),
    _DashboardFeature(
      'Events',
      'Sự kiện & workshop',
      Color(0xFFFFC76E),
      [Color(0xFFFFF0B5), Color(0xFFFF9F43), Color(0xFF8E3D73)],
      PlanetStyle.ice,
      'events',
    ),
  ];

  late final AnimationController _floatController;
  late final AnimationController _planetController;
  late final Animation<double> _floatOffset;
  late final Animation<double> _ufoFloatOffset;
  final _xp = PointsManager.instance;
  final _xpOverlayKey = GlobalKey<XpFloatOverlayState>();
  final _homeScroll = ScrollController();
  bool _routeSubscribed = false;
  int _selectedTab = 0;
  int? _selectedFeatureIndex;

  CharacterData get _companion =>
      CharacterSelection.selected ?? characterData.first;

  List<_DashboardFeature> get _visibleFeatures => _features;

  @override
  void initState() {
    super.initState();
    CareerMapVisibility.isActive.value = false;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    for (final controller in [_floatController, _planetController]) {
      if (reduce) {
        controller.stop();
      } else if (!controller.isAnimating) {
        controller.repeat(reverse: controller == _floatController);
      }
    }
    final route = ModalRoute.of(context);
    if (route != null && !_routeSubscribed) {
      ueHeroRouteObserver.subscribe(this, route);
      _routeSubscribed = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _drainPendingGains());
  }

  @override
  void didPopNext() => _drainPendingGains();

  void _drainPendingGains() {
    if (!mounted) return;
    _xpOverlayKey.currentState?.showGains(_xp.drainPending());
  }

  @override
  void dispose() {
    CareerMapVisibility.isActive.value = false;
    ueHeroRouteObserver.unsubscribe(this);
    _floatController.dispose();
    _planetController.dispose();
    _homeScroll.dispose();
    super.dispose();
  }

  void _selectFeature(int index) {
    setState(() {
      _selectedFeatureIndex = index == _selectedFeatureIndex ? null : index;
    });
  }

  void _selectTab(int index) {
    setState(() => _selectedTab = index);
    CareerMapVisibility.isActive.value = index == 1;
  }

  void _openQuestionCamera() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/camera'),
        builder: (_) => const UEHeroCameraScreen(),
      ),
    );
  }

  void _openMentors() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const MentorScreen()));
  }

  void _openSecondHandMarket() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SecondHandMarketScreen()),
    );
  }

  void _openCalendar() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/weekly-plan'),
        builder: (_) => const CalendarScreen(),
      ),
    );
  }

  void _openEvents() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/events'),
        builder: (_) => const HomeEventScreen(),
      ),
    );
  }

  void _openFlashcards() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/flashcards'),
        builder: (_) => const FlashcardHomeScreen(),
      ),
    );
  }

  void _openNotebookAction(NotebookAction action) {
    switch (action) {
      case NotebookAction.cvCheck:
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const CvCheckScreen()));
        break;
      case NotebookAction.skillDrills:
        _openFlashcards();
        break;
      case NotebookAction.interview:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const InterviewHomeScreen()),
        );
        break;
      case NotebookAction.jobMatch:
        _openJobs();
        break;
      case NotebookAction.mentor:
        _openMentors();
        break;
      case NotebookAction.events:
        _openEvents();
        break;
      case NotebookAction.studyBuddy:
        _openQuestionCamera();
        break;
      case NotebookAction.weeklyPlan:
        _openCalendar();
        break;
    }
  }

  void _openJobs({String query = ''}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => JobScreen(initialQuery: query)),
    );
  }

  Future<void> _openProfile() async {
    _selectTab(4);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/profile'),
        builder: (_) => const ProfileScreen(),
      ),
    );
    if (mounted) {
      _selectTab(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildHomeTab(),
      CareerBoardScreen(
        key: ValueKey(_companion.id),
        embedded: true,
        isActive: _selectedTab == 1,
      ),
      const InterviewHomeScreen(),
      CareerNotebookScreen(onOpenAction: _openNotebookAction),
      _buildInfoTab(
        icon: Icons.account_circle_rounded,
        title: 'Hồ sơ của bạn',
        description:
            'Linh vật ${_companion.name} luôn sẵn sàng đồng hành cùng bạn.',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(index: _selectedTab, children: tabs),
      bottomNavigationBar: SpaceDock(
        onCenterTap: _goHome,
        center: AnimatedBuilder(
          animation: _ufoFloatOffset,
          child: Image.asset(
            'assets/images/rocket-removebg-preview.png',
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            semanticLabel: 'Tên lửa UEH Hero',
          ),
          builder: (context, child) => Transform.translate(
            offset: Offset(0, _ufoFloatOffset.value),
            child: child,
          ),
        ),
        items: [
          SpaceDockItem(
            icon: Icons.route_rounded,
            label: 'Career Map',
            selected: _selectedTab == 1,
            onTap: () => _selectTab(1),
          ),
          SpaceDockItem(
            icon: Icons.record_voice_over_outlined,
            label: 'Phỏng vấn',
            selected: _selectedTab == 2,
            onTap: () => _selectTab(2),
          ),
          SpaceDockItem(
            icon: Icons.menu_book_rounded,
            label: 'Sổ tay',
            selected: _selectedTab == 3,
            onTap: () => _selectTab(3),
          ),
          SpaceDockItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            selected: _selectedTab == 4,
            onTap: _openProfile,
          ),
        ],
      ),
    );
  }

  void _goHome() {
    if (_selectedTab != 0) {
      _selectTab(0);
    } else if (_homeScroll.hasClients) {
      _homeScroll.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _buildHomeTab() {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final headerHeight = (screenHeight * 0.66).clamp(380.0, 420.0).toDouble();
    final features = _visibleFeatures;

    return CustomScrollView(
      controller: _homeScroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(child: _buildGalaxyHeader(headerHeight)),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${features.length} hành tinh',
                      style: const TextStyle(
                        color: SpaceTheme.textMuted,
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
                      style: TextStyle(color: SpaceTheme.textMuted),
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
                        onTap: () {
                          if (feature.actionKey == 'earth') {
                            _openQuestionCamera();
                          } else if (feature.actionKey == 'mercury') {
                            _openJobs();
                          } else if (feature.actionKey == 'mars') {
                            _openCalendar();
                          } else if (feature.actionKey == 'jupiter') {
                            _openMentors();
                          } else if (feature.actionKey == 'venus') {
                            _openSecondHandMarket();
                          } else if (feature.actionKey == 'saturn') {
                            _openFlashcards();
                          } else if (feature.actionKey == 'uranus') {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                settings: const RouteSettings(
                                  name: '/cv-check',
                                ),
                                builder: (_) => const CvCheckScreen(),
                              ),
                            );
                          } else if (feature.actionKey == 'events') {
                            _openEvents();
                          } else {
                            _selectFeature(featureIndex);
                          }
                        },
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
          const ConstellationDecor(),
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
                    child: XpFloatOverlay(
                      key: _xpOverlayKey,
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
            child: XpEnergyBar(onTap: () => _selectTab(1)),
          ),
        ],
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
                onPressed: () => _selectTab(0),
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
                color: selected
                    ? feature.gradientColors[1].withValues(alpha: 0.1)
                    : null,
                border: Border.all(
                  color: selected
                      ? feature.color.withValues(alpha: 0.7)
                      : feature.color.withValues(alpha: 0.24),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: PressScale(
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: SpaceTheme.cardRadius,
                  tint: feature.gradientColors[1],
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: rotation,
                              child: feature.actionKey == 'saturn'
                                  ? Hero(
                                      tag: FlashcardHomeScreen.heroTag,
                                      child: PlanetOrb(
                                        colors: feature.gradientColors,
                                        style: feature.style,
                                        seed: feature.planet.length,
                                      ),
                                    )
                                  : PlanetOrb(
                                      colors: feature.gradientColors,
                                      style: feature.style,
                                      seed: feature.planet.length,
                                    ),
                              builder: (context, child) {
                                final reduce =
                                    MediaQuery.maybeDisableAnimationsOf(
                                      context,
                                    ) ??
                                    false;
                                if (reduce) return child!;
                                final angle =
                                    rotation.value * 2 * math.pi + phase;
                                return Transform.translate(
                                  offset: Offset(0, math.sin(angle) * 3),
                                  child: child,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feature.planet,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected ? feature.color : Colors.white,
                            fontSize: 17,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          feature.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: SpaceTheme.textMuted,
                            fontSize: 12,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardFeature {
  const _DashboardFeature(
    this.planet,
    this.label,
    this.color,
    this.gradientColors,
    this.style,
    this.actionKey,
  );

  final String planet;
  final String label;
  final Color color;
  final List<Color> gradientColors;
  final PlanetStyle style;
  final String actionKey;
}
