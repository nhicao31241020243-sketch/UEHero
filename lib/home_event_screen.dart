import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'screens/campus_map_3d_screen.dart';

class HomeEventScreen extends StatefulWidget {
  const HomeEventScreen({super.key});

  @override
  State<HomeEventScreen> createState() => _HomeEventScreenState();
}

class _HomeEventScreenState extends State<HomeEventScreen> {
  int _currentBannerIndex = 0;
  int _selectedCategoryIndex = 0;

  final List<String> categories = [
    'Tất cả',
    'Âm nhạc',
    'Hội thảo',
    'Sân khấu',
    'Thể thao',
  ];

  // Dữ liệu sự kiện mẫu
  final List<Map<String, String>> featuredEvents = [
    {
      'title': 'CHUYỆN SÀI GÒN: GÁNH SHOW',
      'organizer': '4ll-In Performance Art',
      'image': 'https://picsum.photos/800/400?random=1',
      'tag': 'Trực tiếp',
    },
    {
      'title': 'PERSPECTIVES 2027',
      'organizer': 'Robb Report Vietnam',
      'image': 'https://picsum.photos/800/400?random=2',
      'tag': 'Hot Event',
    },
    {
      'title': '1T SUMMIT - The New Race',
      'organizer': 'Vietnam Vanguard',
      'image': 'https://picsum.photos/800/400?random=3',
      'tag': 'Hội thảo',
    },
  ];

  final List<Map<String, String>> eventPosters = [
    {
      'title': 'CHUYỆN SÀI GÒN: GÁNH SHOW',
      'organizer': '4ll-In Performance Art',
      'image': 'https://picsum.photos/300/450?random=10',
      'tag': 'Sân khấu',
    },
    {
      'title': 'PERSPECTIVES 2027',
      'organizer': 'Robb Report Vietnam',
      'image': 'https://picsum.photos/300/450?random=11',
      'tag': 'Hội thảo',
    },
    {
      'title': '1T SUMMIT - THE NEW RACE',
      'organizer': 'Vietnam Vanguard',
      'image': 'https://picsum.photos/300/450?random=12',
      'tag': 'Công nghệ',
    },
    {
      'title': 'SAIGON MUSIC WEEK',
      'organizer': 'UEH Music Club',
      'image': 'https://picsum.photos/300/450?random=13',
      'tag': 'Âm nhạc',
    },
    {
      'title': 'GREEN CAMPUS DAY',
      'organizer': 'UEH Green Campus',
      'image': 'https://picsum.photos/300/450?random=14',
      'tag': 'Cộng đồng',
    },
    {
      'title': 'STARTUP LAUNCHPAD',
      'organizer': 'UEH Innovation',
      'image': 'https://picsum.photos/300/450?random=15',
      'tag': 'Khởi nghiệp',
    },
  ];

  final List<List<Color>> _posterPalettes = const [
    [Color(0xFFB3264A), Color(0xFF38162F)],
    [Color(0xFF176B87), Color(0xFF172541)],
    [Color(0xFF8752A1), Color(0xFF302044)],
    [Color(0xFFD36B34), Color(0xFF492333)],
    [Color(0xFF34836E), Color(0xFF173A42)],
    [Color(0xFFB48B35), Color(0xFF443020)],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0C13), // Nền tối chuẩn Streaming
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.play_circle_fill, color: Color(0xFF8B5CF6), size: 28),
            SizedBox(width: 8),
            Text(
              'UEHEvent',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/100'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildCampusMapCard(),
            const SizedBox(height: 18),
            _buildBannerCarousel(),
            const SizedBox(height: 20),
            _buildCategoryChips(),
            const SizedBox(height: 24),
            _buildEventSection('🔥 Trending Now'),
            const SizedBox(height: 24),
            _buildEventSection('⭐ Popular Events'),
            const SizedBox(height: 24),
            _buildEventSection('🎪 Sự Kiện Sắp Ra Mắt'),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCampusMapCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: const Color(0xFF1D1928),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CampusMap3DScreen(),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBFA8FF).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: Color(0xFFBFA8FF),
                    size: 25,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sự kiện tại UEH',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Khám phá booth và tiện ích trên bản đồ 3D',
                        style: TextStyle(
                          color: Color(0xFFBDB7C9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Banner Carousel Slider lớn phía trên
  Widget _buildBannerCarousel() {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 210,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.88,
            onPageChanged: (index, reason) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
          ),
          items: featuredEvents.map((event) {
            return Builder(
              builder: (BuildContext context) {
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: NetworkImage(event['image']!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.85),
                            Colors.transparent,
                          ],
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
                          Text(
                            event['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event['organizer']!,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B5CF6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text(
                                  "Mua Vé Ngay",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text(
                                  "Chi Tiết",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
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
                color: _currentBannerIndex == entry.key
                    ? const Color(0xFF8B5CF6)
                    : Colors.grey[700],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Danh mục Lướt Ngang
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
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF1F1D2B),
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

  // Section Poster Sự Kiện Đứng
  Widget _buildEventSection(String title) {
    final isTrending = title.contains('Trending');
    final events = isTrending
        ? eventPosters.take(3).toList()
        : eventPosters.skip(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 185,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final palette = _posterPalettes[index + (isTrending ? 0 : 3)];

              return Container(
                width: 132,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: palette.first.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        event['image']!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                            ? child
                            : _posterArtwork(event, palette),
                        errorBuilder: (context, error, stackTrace) =>
                            _posterArtwork(event, palette),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                            stops: [0.35, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 9,
                        left: 9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.42),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            event['tag']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        right: 8,
                        bottom: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              event['title']!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              event['organizer']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
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

  Widget _posterArtwork(Map<String, String> event, List<Color> palette) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 34,
            right: -12,
            child: Icon(
              Icons.circle,
              size: 100,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: 48,
            left: 12,
            child: Icon(
              Icons.auto_awesome,
              size: 34,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          Positioned(
            top: 92,
            right: 18,
            child: Icon(
              Icons.star,
              size: 22,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
