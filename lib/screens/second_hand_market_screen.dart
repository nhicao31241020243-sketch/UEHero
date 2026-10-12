import 'package:flutter/material.dart';

class SecondHandMarketScreen extends StatelessWidget {
  const SecondHandMarketScreen({super.key});

  static const _background = Color(0xFF100E19);
  static const _surface = Color(0xFF211D2B);
  static const _accent = Color(0xFFFFC18E);
  static const _muted = Color(0xFFAAA5B8);

  static const _items = [
    _MarketItem(
      title: 'Giáo trình Marketing căn bản',
      price: '45.000đ',
      seller: 'Minh Anh',
      category: 'Sách',
      icon: Icons.menu_book_rounded,
    ),
    _MarketItem(
      title: 'Máy tính cầm tay Casio',
      price: '180.000đ',
      seller: 'Hoàng Nam',
      category: 'Đồ học tập',
      icon: Icons.calculate_rounded,
    ),
    _MarketItem(
      title: 'Áo khoác UEH',
      price: '120.000đ',
      seller: 'Thảo Vy',
      category: 'Thời trang',
      icon: Icons.checkroom_rounded,
    ),
    _MarketItem(
      title: 'Bàn phím cơ mini',
      price: '350.000đ',
      seller: 'Quốc Bảo',
      category: 'Điện tử',
      icon: Icons.keyboard_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chợ đồ cũ',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng món đồ',
            onPressed: () => _showComingSoon(context),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text(
            'Mua bán cùng sinh viên UEH',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tìm món đồ phù hợp hoặc trao đổi những món bạn không còn dùng.',
            style: TextStyle(color: _muted, height: 1.35),
          ),
          const SizedBox(height: 18),
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm món đồ...',
              hintStyle: const TextStyle(color: _muted),
              prefixIcon: const Icon(Icons.search_rounded, color: _accent),
              filled: true,
              fillColor: _surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Món đồ mới đăng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${_items.length} món',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._items.map((item) => _MarketItemCard(item: item)),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng đăng món đồ đang được hoàn thiện.'),
      ),
    );
  }
}

class _MarketItemCard extends StatelessWidget {
  const _MarketItemCard({required this.item});

  final _MarketItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: SecondHandMarketScreen._surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: SecondHandMarketScreen._accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(item.icon, color: SecondHandMarketScreen._accent),
        ),
        title: Text(
          item.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${item.category}  •  ${item.seller}',
            style: const TextStyle(color: SecondHandMarketScreen._muted),
          ),
        ),
        trailing: Text(
          item.price,
          style: const TextStyle(
            color: SecondHandMarketScreen._accent,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MarketItem {
  const _MarketItem({
    required this.title,
    required this.price,
    required this.seller,
    required this.category,
    required this.icon,
  });

  final String title;
  final String price;
  final String seller;
  final String category;
  final IconData icon;
}
