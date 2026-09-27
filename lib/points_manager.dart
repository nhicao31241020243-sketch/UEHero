import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'models/event_item.dart';
import 'services/points_manager.dart';
import 'event_detail_screen.dart';
import 'widgets/event_poster.dart';

class HomeEventScreen extends StatefulWidget {
  const HomeEventScreen({Key? key}) : super(key: key);

  @override
  State<HomeEventScreen> createState() => _HomeEventScreenState();
}

class _HomeEventScreenState extends State<HomeEventScreen> {
  int _currentBannerIndex = 0;
  int _selectedNavIndex = 0;
  int _selectedCategoryIndex = 0;

  final List<String> navTabs = ['Trang chủ', 'Sự kiện', 'Mới & Nổi bật', 'Của tôi'];
  final List<String> categories = ['Tất cả', 'Âm nhạc', 'Hội thảo', 'Sân khấu', 'Thể thao'];

  // Dữ liệu sự kiện mẫu — image để null, add ảnh thật vào sau (assets/images/...)
  final List<EventItem> featuredEvents = const [
    EventItem(
      title: 'CHUYỆN SÀI GÒN: GÁNH SHOW',
      organizer: '4ll-In Performance Art',
      image: null,
      tag: 'Trực tiếp',
      trainingPoints: 5,
    ),
    EventItem(
      title: 'PERSPECTIVES 2027',
      organizer: 'Robb Report Vietnam',
      image: null,
      tag: 'Hot Event',
      trainingPoints: 8,
    ),
    EventItem(
      title: '1T SUMMIT - The New Race',
      organizer: 'Vietnam Vanguard',
      image: null,
      tag: 'Hội thảo',
      trainingPoints: 10,
    ),
  ];

  // Tên thể loại cho dải "Thể loại nổi bật" — image null, add sau
  final List<String> showcaseGenres = const ['Âm nhạc', 'Hội thảo', 'Sân khấu', 'Thể thao'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0C13),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 8),
              _buildNavTabs(),
              const SizedBox(height: 14),
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildBannerCarousel(),
              const SizedBox(height: 20),
              _buildCategoryChips(),
              const SizedBox(height: 24),
              _buildJoinedSection(),
              _buildEventSection('🔥 Trending Now'),
              const SizedBox(height: 24),
              _buildEventSection('⭐ Popular Events'),
              const SizedBox(height: 24),
              _buildGenreShowcase(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(EventItem event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)),
    ).then((_) => setState(() {}));
  }

  // ── Thanh trên cùng: logo + badge điểm + avatar ────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.play_circle_fill, color: Color(0xFF8B5CF6), size: 26),
          const SizedBox(width: 8),
          const Text(
            'UEHEvent',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: PointsManager.instance,
            builder: (context, _) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF8B5CF6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.military_tech, color: Color(0xFF8B5CF6), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${PointsManager.instance.totalPoints}',
                      style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          const CircleAvatar(radius: 15, backgroundColor: Color(0xFF1F1D2B), child: Icon(Icons.person, color: Colors.white54, size: 16)),
        ],
      ),
    );
  }

  // ── Tab điều hướng ngang, tab đang chọn có gạch chân tím ───────────────
  Widget _buildNavTabs() {
    return SizedBox(
      height: 30,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: navTabs.length,
        itemBuilder: (context, index) {
          final selected = _selectedNavIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedNavIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 22),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? const Color(0xFF8B5CF6) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                navTabs[index],
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey[500],
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Ô tìm kiếm dạng bo tròn tối ─────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1D2B),
          borderRadius: BorderRadius.circular(21),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey[500], size: 18),
            const SizedBox(width: 8),
            Text('Tìm sự kiện, câu lạc bộ...', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── Banner carousel: EventPoster nền + gradient + rating/tag + 2 nút ───
  Widget _buildBannerCarousel() {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 260,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            onPageChanged: (index, reason) => setState(() => _currentBannerIndex = index),
          ),
          items: featuredEvents.map((event) {
            return Builder(
              builder: (context) {
                return GestureDetector(
                  onTap: () => _openDetail(event),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: EventPoster(
                          imagePath: event.image,
                          borderRadius: BorderRadius.circular(20),
                          placeholderIcon: Icons.event,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text('+${event.trainingPoints} điểm',
                                    style: TextStyle(color: Colors.grey[300], fontSize: 11)),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(event.tag,
                                      style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              event.title,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(event.organizer, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _openDetail(event),
                                  icon: const Icon(Icons.play_arrow, color: Colors.black, size: 18),
                                  label: const Text('Xem Chi Tiết',
                                      style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _openDetail(event),
                                  icon: const Icon(Icons.add, color: Colors.white, size: 16),
                                  label: const Text('Lưu', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white54),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: featuredEvents.asMap().entries.map((entry) {
            return Container(
              width: _currentBannerIndex == entry.key ? 18.0 : 6.0,
              height: 6.0,
              margin: const EdgeInsets.symmetric(horizontal: 3.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentBannerIndex == entry.key ? const Color(0xFF8B5CF6) : Colors.grey[700],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF1F1D2B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[400],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Dải "Sự kiện đã tham gia" — tương đương Continue Watching ──────────
  Widget _buildJoinedSection() {
    return AnimatedBuilder(
      animation: PointsManager.instance,
      builder: (context, _) {
        final joined = PointsManager.instance.joinedEvents;
        if (joined.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionPosterRow('✅ Sự kiện đã tham gia', joined),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // Poster + caption (tên, điểm) bên dưới ảnh — image null -> placeholder
  Widget _buildEventSection(String title) {
    final sectionEvents = List.generate(
      6,
      (index) => EventItem(
        title: '$title #${index + 1}',
        organizer: 'UEH Club',
        image: null,
        tag: title,
        trainingPoints: 3 + index,
      ),
    );
    return _sectionPosterRow(title, sectionEvents);
  }

  Widget _sectionPosterRow(String title, List<EventItem> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return GestureDetector(
                onTap: () => _openDetail(event),
                child: Container(
                  width: 125,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 150,
                        width: 125,
                        child: EventPoster(imagePath: event.image),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 11),
                          const SizedBox(width: 3),
                          Text('${event.trainingPoints} điểm',
                              style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Dải thể loại lớn, giống "Popular Genres" ────────────────────────────
  Widget _buildGenreShowcase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Thể loại nổi bật', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: showcaseGenres.length,
            itemBuilder: (context, index) {
              final genre = showcaseGenres[index];
              return Container(
                width: 140,
                height: 90,
                margin: const EdgeInsets.only(right: 12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    EventPoster(
                      imagePath: null, // add ảnh thể loại vào sau
                      borderRadius: BorderRadius.circular(14),
                      placeholderIcon: Icons.category_outlined,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.black.withOpacity(0.25),
                      ),
                      alignment: Alignment.center,
                      child: Text(genre,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}