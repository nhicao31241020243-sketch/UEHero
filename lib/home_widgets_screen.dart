import 'dart:async';
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
  static const _surfaceColor = Color(0xFF211E2D);
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

  static const _defaultFeed = [
    _FeedItem(
      eyebrow: 'SỰ KIỆN HOT',
      title: 'Khám phá những trải nghiệm mới tại UEH',
      subtitle: 'Sự kiện nổi bật • Cập nhật hôm nay',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFF8A75),
      action: 'Khám phá',
    ),
    _FeedItem(
      eyebrow: 'NHIỆM VỤ NỔI BẬT',
      title: 'Hoàn thiện hồ sơ, sẵn sàng cho cơ hội mới',
      subtitle: 'Career Map • 3 bước gợi ý',
      icon: Icons.flag_rounded,
      color: Color(0xFFBFA8FF),
      action: 'Xem nhiệm vụ',
    ),
  ];

  static const _feedByFeature = <int, List<_FeedItem>>{
    0: [
      _FeedItem(
        eyebrow: 'CƠ HỘI MỚI',
        title: 'Thực tập sinh Marketing',
        subtitle: 'Bán thời gian • TP. Hồ Chí Minh',
        icon: Icons.campaign_rounded,
        color: Color(0xFFB9A2FF),
        action: 'Xem công việc',
      ),
      _FeedItem(
        eyebrow: 'ĐANG TUYỂN',
        title: 'Thực tập sinh Phân tích kinh doanh',
        subtitle: 'Linh hoạt • Sinh viên năm 3-4',
        icon: Icons.query_stats_rounded,
        color: Color(0xFF8DD8D1),
        action: 'Tìm hiểu',
      ),
    ],
    1: [
      _FeedItem(
        eyebrow: 'CHỢ ĐỒ CŨ',
        title: 'Giáo trình Kinh tế vi mô',
        subtitle: 'Sách học tập • Đăng gần đây',
        icon: Icons.menu_book_rounded,
        color: Color(0xFFFFC18E),
        action: 'Xem món đồ',
      ),
      _FeedItem(
        eyebrow: 'GÓC SINH VIÊN',
        title: 'Máy tính cầm tay còn tốt',
        subtitle: 'Đồ dùng học tập • Có thể thương lượng',
        icon: Icons.calculate_rounded,
        color: Color(0xFFFFD36E),
        action: 'Xem món đồ',
      ),
    ],
    2: [
      _FeedItem(
        eyebrow: 'CẦN HỖ TRỢ',
        title: 'Bạn học đang cần trợ giúp môn Thống kê',
        subtitle: 'Câu hỏi mới • Thống kê ứng dụng',
        icon: Icons.query_stats_rounded,
        color: Color(0xFF8DD8D1),
        action: 'Mở trợ lý AI',
      ),
      _FeedItem(
        eyebrow: 'CÙNG HỌC UEH',
        title: 'Thảo luận bài tập Kinh tế lượng',
        subtitle: 'Đang chờ câu trả lời từ cộng đồng',
        icon: Icons.forum_rounded,
        color: Color(0xFF9DBBFF),
        action: 'Tham gia',
      ),
    ],
    3: [
      _FeedItem(
        eyebrow: 'NHIỆM VỤ CỦA BẠN',
        title: 'Hoàn thành bài tập nhóm',
        subtitle: 'Hạn chót hôm nay • Học tập',
        icon: Icons.groups_rounded,
        color: Color(0xFFFF9EBD),
        action: 'Cập nhật tiến độ',
      ),
      _FeedItem(
        eyebrow: 'SẮP ĐẾN HẠN',
        title: 'Ôn tập trước buổi thuyết trình',
        subtitle: 'Còn 2 ngày • Ưu tiên cao',
        icon: Icons.alarm_rounded,
        color: Color(0xFFFFC18E),
        action: 'Xem To-Do List',
      ),
    ],
    4: [
      _FeedItem(
        eyebrow: 'MÓN HOT HÔM NAY',
        title: 'Cơm gà sốt mật ong',
        subtitle: 'Căn tin UEH • Gợi ý hôm nay',
        icon: Icons.lunch_dining_rounded,
        color: Color(0xFFFFD36E),
        action: 'Xem thực đơn',
      ),
      _FeedItem(
        eyebrow: 'ĂN NGON Ở UEH',
        title: 'Trà đào cam sả',
        subtitle: 'Đồ uống được yêu thích trong campus',
        icon: Icons.local_cafe_rounded,
        color: Color(0xFFFFA878),
        action: 'Khám phá',
      ),
    ],
    5: [
      _FeedItem(
        eyebrow: 'ÔN TẬP NHANH',
        title: 'Flashcard Marketing căn bản',
        subtitle: '12 thẻ • Ôn tập 5 phút',
        icon: Icons.style_rounded,
        color: Color(0xFF9DBBFF),
        action: 'Bắt đầu học',
      ),
      _FeedItem(
        eyebrow: 'GỢI Ý CHO BẠN',
        title: 'Thuật ngữ Tài chính doanh nghiệp',
        subtitle: '18 thẻ • Đang chờ bạn khám phá',
        icon: Icons.auto_stories_rounded,
        color: Color(0xFFBFA8FF),
        action: 'Mở flashcard',
      ),
    ],
    6: [
      _FeedItem(
        eyebrow: 'HỒ SƠ NGHỀ NGHIỆP',
        title: 'Quét CV để nhận gợi ý hoàn thiện',
        subtitle: 'Theo dõi tiến độ tích điểm của bạn',
        icon: Icons.document_scanner_rounded,
        color: Color(0xFFB7E59B),
        action: 'Xem hồ sơ',
      ),
    ],
    7: [
      _FeedItem(
        eyebrow: 'CAREER MAP',
        title: 'Khám phá lộ trình nghề nghiệp phù hợp',
        subtitle: 'Bắt đầu từ kỹ năng và mục tiêu của bạn',
        icon: Icons.map_rounded,
        color: Color(0xFFFFA878),
        action: 'Mở bản đồ',
      ),
    ],
  };

  late final AnimationController _floatController;
  late final AnimationController _planetController;
  late final Animation<double> _floatOffset;
  late final PageController _feedPageController;
  Timer? _feedAutoScrollTimer;
  final _searchController = TextEditingController();
  int _selectedTab = 0;
  int? _selectedFeatureIndex;
  int _currentFeedPage = 0;
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

  List<_FeedItem> get _visibleFeed {
    final items = _selectedFeatureIndex == null
        ? _defaultFeed
        : _feedByFeature[_selectedFeatureIndex] ?? _defaultFeed;
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items
        .where(
          (item) =>
              item.title.toLowerCase().contains(query) ||
              item.subtitle.toLowerCase().contains(query) ||
              item.eyebrow.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _feedPageController = PageController();
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
    _startFeedAutoScroll();
  }

  @override
  void dispose() {
    _feedAutoScrollTimer?.cancel();
    _feedPageController.dispose();
    _floatController.dispose();
    _planetController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startFeedAutoScroll() {
    _feedAutoScrollTimer?.cancel();
    _feedAutoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final pageCount = _visibleFeed.length;
      if (!mounted || _selectedTab != 0 || pageCount < 2) return;
      _currentFeedPage = (_currentFeedPage + 1) % pageCount;
      _feedPageController.animateToPage(
        _currentFeedPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _resetFeedCarousel() {
    _currentFeedPage = 0;
    if (_feedPageController.hasClients) {
      _feedPageController.jumpToPage(0);
    }
  }

  void _selectFeature(int index) {
    setState(() {
      _selectedFeatureIndex = index == _selectedFeatureIndex ? null : index;
      _resetFeedCarousel();
    });
  }

  void _openChatbot() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ChatbotScreen()));
  }

  void _onFeedItemTap(_FeedItem item) {
    if (item.action == 'Mở trợ lý AI') {
      _openChatbot();
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${item.action} sẽ sớm có mặt trong UEH Hero.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
      floatingActionButton: FloatingActionButton(
        onPressed: _openChatbot,
        tooltip: 'Mở UEH AI Assistant',
        backgroundColor: const Color(0xFFBFA8FF),
        foregroundColor: const Color(0xFF201A35),
        elevation: 8,
        shape: const CircleBorder(),
        child: const Text('🌍', style: TextStyle(fontSize: 27)),
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
    final headerHeight = screenHeight * 0.33;
    final features = _visibleFeatures;
    final feed = _visibleFeed;

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
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
          sliver: SliverToBoxAdapter(child: _buildFeedCarousel(feed)),
        ),
      ],
    );
  }

  Widget _buildFeedCarousel(List<_FeedItem> feed) {
    final selected = _selectedFeatureIndex == null
        ? 'Dành cho bạn'
        : _features[_selectedFeatureIndex!].label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                selected,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (_selectedFeatureIndex != null)
              TextButton(
                onPressed: () => setState(() {
                  _selectedFeatureIndex = null;
                  _resetFeedCarousel();
                }),
                child: const Text('Xóa lọc'),
              ),
          ],
        ),
        if (feed.isEmpty)
          const SizedBox(
            height: 150,
            child: Center(
              child: Text(
                'Không có nội dung khớp từ khóa tìm kiếm.',
                style: TextStyle(color: Color(0xFFAAA5B8)),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else ...[
          SizedBox(
            height: 164,
            child: PageView.builder(
              controller: _feedPageController,
              itemCount: feed.length,
              onPageChanged: (index) => setState(() {
                _currentFeedPage = index;
              }),
              itemBuilder: (context, index) {
                final item = feed[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _FeedCard(
                    item: item,
                    onTap: () => _onFeedItemTap(item),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 11),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(feed.length, (index) {
              final active = index == _currentFeedPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: active ? 20 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active ? _accentColor : const Color(0xFF575263),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildGalaxyHeader(double height) {
    final topInset = MediaQuery.paddingOf(context).top;
    final companion = _companion;

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
            top: topInset + 48,
            right: 10,
            bottom: 69,
            child: Align(
              alignment: Alignment.centerRight,
              child: TickerMode(
                enabled: _selectedTab == 0,
                child: AnimatedBuilder(
                  animation: _floatOffset,
                  child: SizedBox(
                    width: 142,
                    height: 142,
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
                    offset: Offset(0, _floatOffset.value + 20),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: topInset + 47,
            left: 17,
            child: _SpeechBubble(text: 'Chào bạn! Cùng khám phá UEH nhé! 🚀'),
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
              _resetFeedCarousel();
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
                          _resetFeedCarousel();
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
  const _SpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 165,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              height: 1.3,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(color: Color(0xCC070311), blurRadius: 10),
                Shadow(color: Color(0xAA9C77FF), blurRadius: 15),
              ],
            ),
          ),
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

class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.item, required this.onTap});

  final _FeedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _HomeWidgetsScreenState._surfaceColor,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          constraints: const BoxConstraints(minHeight: 142),
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item.color.withValues(alpha: 0.2),
                _HomeWidgetsScreenState._surfaceColor,
              ],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.eyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: item.color,
                        fontSize: 9,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFBEB9C8),
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          item.action,
                          style: TextStyle(
                            color: item.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: item.color,
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(item.icon, color: item.color, size: 29),
              ),
            ],
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

class _FeedItem {
  const _FeedItem({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.action,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String action;
}
