import 'package:flutter/material.dart';

import 'models/character_data.dart';

class HomeWidgetsScreen extends StatefulWidget {
  const HomeWidgetsScreen({super.key});

  @override
  State<HomeWidgetsScreen> createState() => _HomeWidgetsScreenState();
}

class _HomeWidgetsScreenState extends State<HomeWidgetsScreen> {
  static const _backgroundColor = Color(0xFF0D0C13);
  static const _surfaceColor = Color(0xFF1A1824);
  static const _accentColor = Color(0xFF9A78FF);
  static const _backgroundImageUrl =
      'https://i.pinimg.com/736x/3d/87/97/3d8797deef62a5812b394ea3a1a762a0.jpg';

  static const _categories = [
    _EventCategory('Tất cả', Icons.grid_view_rounded),
    _EventCategory('Âm nhạc', Icons.music_note_rounded),
    _EventCategory('Hội thảo', Icons.lightbulb_outline_rounded),
    _EventCategory('Sân khấu', Icons.theater_comedy_rounded),
    _EventCategory('Thể thao', Icons.sports_basketball_rounded),
  ];

  static const _events = [
    _FeaturedEvent(
      title: 'CHUYỆN SÀI GÒN: GÁNH SHOW',
      organizer: '4ll-In Performance Art',
      category: 'Sân khấu',
      date: '20 THÁNG 10',
      icon: Icons.theater_comedy_rounded,
      colors: [Color(0xFFB3264A), Color(0xFF38162F)],
    ),
    _FeaturedEvent(
      title: 'PERSPECTIVES 2027',
      organizer: 'Robb Report Vietnam',
      category: 'Hội thảo',
      date: '25 THÁNG 10',
      icon: Icons.lightbulb_outline_rounded,
      colors: [Color(0xFF176B87), Color(0xFF172541)],
    ),
    _FeaturedEvent(
      title: '1T SUMMIT — THE NEW RACE',
      organizer: 'Vietnam Vanguard',
      category: 'Công nghệ',
      date: '02 THÁNG 11',
      icon: Icons.rocket_launch_rounded,
      colors: [Color(0xFF8752A1), Color(0xFF302044)],
    ),
    _FeaturedEvent(
      title: 'SAIGON MUSIC WEEK',
      organizer: 'UEH Music Club',
      category: 'Âm nhạc',
      date: '08 THÁNG 11',
      icon: Icons.graphic_eq_rounded,
      colors: [Color(0xFFD36B34), Color(0xFF492333)],
    ),
    _FeaturedEvent(
      title: 'GREEN CAMPUS DAY',
      organizer: 'UEH Green Campus',
      category: 'Cộng đồng',
      date: '12 THÁNG 11',
      icon: Icons.eco_rounded,
      colors: [Color(0xFF34836E), Color(0xFF173A42)],
    ),
    _FeaturedEvent(
      title: 'STARTUP LAUNCHPAD',
      organizer: 'UEH Innovation',
      category: 'Khởi nghiệp',
      date: '18 THÁNG 11',
      icon: Icons.rocket_launch_rounded,
      colors: [Color(0xFFB48B35), Color(0xFF443020)],
    ),
  ];

  final _searchController = TextEditingController();
  final _eventsSearchController = TextEditingController();
  int _selectedTab = 0;
  int _selectedCategory = 0;
  String _searchQuery = '';

  CharacterData get _companion =>
      CharacterSelection.selected ?? characterData.first;

  List<_FeaturedEvent> get _filteredEvents {
    final category = _categories[_selectedCategory].label;
    return _events
        .where((event) {
          final matchesCategory =
              category == 'Tất cả' || event.category == category;
          final query = _searchQuery.trim().toLowerCase();
          final matchesSearch =
              query.isEmpty ||
              event.title.toLowerCase().contains(query) ||
              event.organizer.toLowerCase().contains(query) ||
              event.category.toLowerCase().contains(query);
          return matchesCategory && matchesSearch;
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _eventsSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(_backgroundImageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _selectedTab,
            children: [
              _buildHomeTab(),
              _buildEventsTab(),
              _buildSimpleTab(
                icon: Icons.card_giftcard_rounded,
                title: 'Đổi quà cùng UEH Hero',
                description: 'Khám phá ưu đãi và phần quà dành riêng cho những sự kiện bạn yêu thích.',
                actionLabel: 'Khám phá sự kiện',
                onAction: () => setState(() => _selectedTab = 1),
              ),
              _buildSimpleTab(
                icon: Icons.account_circle_rounded,
                title: 'Hồ sơ của bạn',
                description:
                    'Linh vật ${_companion.name} luôn sẵn sàng đồng hành trong mỗi hành trình.',
                actionLabel: 'Về trang chủ',
                onAction: () => setState(() => _selectedTab = 0),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF15131D),
        indicatorColor: _accentColor.withValues(alpha: 0.22),
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_num_outlined),
            selectedIcon: Icon(Icons.confirmation_num_rounded),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard_rounded),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final companion = _companion;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildTopBar(),
              const SizedBox(height: 22),
              _buildSearchField(_searchController),
              const SizedBox(height: 20),
              _buildCompanionBanner(companion),
              const SizedBox(height: 28),
              _buildSectionHeading('Khám phá theo sở thích', 'Xem tất cả'),
              const SizedBox(height: 14),
              _buildCategoryRail(),
              const SizedBox(height: 28),
              _buildOfferCard(),
              const SizedBox(height: 28),
              _buildSectionHeading('Sự kiện nổi bật', 'Xem tất cả'),
              const SizedBox(height: 14),
              _buildFeaturedEvents(),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: _accentColor,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UEH HERO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: _accentColor,
                    size: 13,
                  ),
                  SizedBox(width: 3),
                  Text(
                    'TP. Hồ Chí Minh',
                    style: TextStyle(color: Color(0xFFAAA6B8), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Thông báo',
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(TextEditingController controller) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: TextField(
        controller: controller,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Tìm sự kiện, hoạt động...',
          hintStyle: const TextStyle(color: Color(0xFF807B8C), fontSize: 14),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _accentColor,
            size: 22,
          ),
          suffixIcon: IconButton(
            tooltip: 'Chọn địa điểm',
            onPressed: () {},
            icon: const Icon(
              Icons.tune_rounded,
              color: Color(0xFFA9A4B5),
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 17),
        ),
      ),
    );
  }

  Widget _buildCompanionBanner(CharacterData companion) {
    return Container(
      constraints: const BoxConstraints(minHeight: 174),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF38286D), Color(0xFF211B3D), Color(0xFF1B1930)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -52,
            child: Container(
              width: 155,
              height: 155,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.045),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(19, 19, 14, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'CHÀO MỪNG BẠN TRỞ LẠI',
                        style: TextStyle(
                          color: Color(0xFFC8B9FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        companion.name,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'đang đồng hành cùng bạn 🚀',
                        style: TextStyle(
                          color: Color(0xFFE7E2F4),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Text(
                          'Hãy chọn sự kiện bên dưới để bắt đầu hành trình nhé! ✨',
                          style: TextStyle(
                            color: Color(0xFFE7E2F4),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                SizedBox(
                  width: 91,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: companion.primaryColor.withValues(alpha: 0.2),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            companion.emoji,
                            style: const TextStyle(fontSize: 42),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'CÙNG BẠN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String title, String action) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _selectedTab = 1),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFB8A5FF),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: Text(action, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildCategoryRail() {
    return SizedBox(
      height: 91,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = index == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: SizedBox(
              width: 70,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: selected ? _accentColor : _surfaceColor,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(
                        color: selected
                            ? _accentColor
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Icon(
                      category.icon,
                      color: selected ? Colors.white : const Color(0xFFB7B2C3),
                      size: 23,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFAAA6B8),
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

  Widget _buildOfferCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedTab = 2),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 137,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF6442C5), Color(0xFFB05BC8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -6,
                bottom: -25,
                child: Icon(
                  Icons.confirmation_num_rounded,
                  size: 139,
                  color: Colors.white.withValues(alpha: 0.11),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 17, 105, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ĐẶC QUYỀN UEH HERO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'Sẵn sàng cho\nsự kiện tiếp theo?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    const Row(
                      children: [
                        Text(
                          'Khám phá ngay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
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

  Widget _buildFeaturedEvents() {
    final events = _filteredEvents;
    if (events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'Chưa tìm thấy sự kiện phù hợp. Thử từ khóa khác nhé!',
          style: TextStyle(color: Color(0xFFAAA6B8), fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      height: 207,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(width: 13),
        itemBuilder: (context, index) => _buildEventCard(events[index]),
      ),
    );
  }

  Widget _buildEventCard(_FeaturedEvent event) {
    return Container(
      width: 258,
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 112,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(19),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: event.colors,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Icon(
                    event.icon,
                    size: 76,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 13,
                  bottom: 11,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        event.date,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 10, 13, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.groups_2_outlined,
                      size: 13,
                      color: Color(0xFFA39EAF),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        event.organizer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFA39EAF),
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.favorite_border_rounded,
                      color: Color(0xFFA39EAF),
                      size: 17,
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

  Widget _buildEventsTab() {
    final events = _filteredEvents;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const Text(
                'Khám phá sự kiện',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Những trải nghiệm đang chờ bạn ở TP. Hồ Chí Minh',
                style: TextStyle(color: Color(0xFFAAA6B8), fontSize: 13),
              ),
              const SizedBox(height: 19),
              _buildSearchField(_eventsSearchController),
              const SizedBox(height: 20),
              _buildCategoryRail(),
              const SizedBox(height: 21),
              Text(
                '${events.length} sự kiện dành cho bạn',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 13),
              if (events.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    'Không tìm thấy sự kiện phù hợp.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFAAA6B8)),
                  ),
                )
              else
                ...events.map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: _buildEventListTile(event),
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildEventListTile(_FeaturedEvent event) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: event.colors,
              ),
            ),
            child: Icon(
              event.icon,
              color: Colors.white.withValues(alpha: 0.86),
              size: 31,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.category,
                  style: const TextStyle(
                    color: Color(0xFFB8A5FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${event.date} · ${event.organizer}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFAAA6B8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Color(0xFFAAA6B8),
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTab({
    required IconData icon,
    required String title,
    required String description,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(icon, color: _accentColor, size: 43),
            ),
            const SizedBox(height: 22),
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
              style: const TextStyle(
                color: Color(0xFFAAA6B8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCategory {
  const _EventCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _FeaturedEvent {
  const _FeaturedEvent({
    required this.title,
    required this.organizer,
    required this.category,
    required this.date,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String organizer;
  final String category;
  final String date;
  final IconData icon;
  final List<Color> colors;
}
