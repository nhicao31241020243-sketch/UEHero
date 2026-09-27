import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomeEventScreen extends StatefulWidget {
  const HomeEventScreen({Key? key}) : super(key: key);

  @override
  State<HomeEventScreen> createState() => _HomeEventScreenState();
}

class _HomeEventScreenState extends State<HomeEventScreen> {
  int _currentBannerIndex = 0;
  int _selectedCategoryIndex = 0;

  final List<String> categories = ['Tất cả', 'Âm nhạc', 'Hội thảo', 'Sân khấu', 'Thể thao'];

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
            Text('UEHEvent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
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
                            Colors.black.withOpacity(0.85),
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
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event['organizer']!,
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B5CF6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                ),
                                child: const Text("Mua Vé Ngay", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white54),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text("Chi Tiết", style: TextStyle(color: Colors.white, fontSize: 12)),
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
                color: _currentBannerIndex == entry.key ? const Color(0xFF8B5CF6) : Colors.grey[700],
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

  // Section Poster Sự Kiện Đứng
  Widget _buildEventSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 185,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Container(
                width: 125,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  image: DecorationImage(
                    image: NetworkImage('https://picsum.photos/300/450?random=${index + 10}'),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}