import 'package:flutter/material.dart';

enum _CampusMapFilter {
  all,
  recruitment,
  clubs,
  amenities;

  String get label => switch (this) {
    all => 'Tất cả',
    recruitment => 'Tuyển dụng & Job Fair',
    clubs => 'CLB & Đội nhóm',
    amenities => 'Tiện ích (WC/Y tế/Gửi xe)',
  };
}

class _CampusSpot {
  const _CampusSpot({
    required this.name,
    required this.category,
    required this.icon,
    required this.color,
    required this.x,
    required this.y,
    required this.shortLabel,
    required this.isEvent,
    required this.activity,
    required this.gift,
  });

  final String name;
  final _CampusMapFilter category;
  final IconData icon;
  final Color color;
  final double x;
  final double y;
  final String shortLabel;
  final bool isEvent;
  final String activity;
  final String gift;
}

class CampusMap3DScreen extends StatefulWidget {
  const CampusMap3DScreen({super.key});

  @override
  State<CampusMap3DScreen> createState() => _CampusMap3DScreenState();
}

class _CampusMap3DScreenState extends State<CampusMap3DScreen>
    with SingleTickerProviderStateMixin {
  static const _backgroundColor = Color(0xFF100E19);
  static const _accentColor = Color(0xFFBFA8FF);

  static const _spots = <_CampusSpot>[
    _CampusSpot(
      name: 'Cổng chính Nguyễn Tri Phương',
      category: _CampusMapFilter.amenities,
      icon: Icons.door_front_door_rounded,
      color: Color(0xFF74D3C4),
      x: 0.19,
      y: 0.88,
      shortLabel: 'Cổng chính',
      isEvent: false,
      activity: 'Lối vào chính cơ sở B từ đường Nguyễn Tri Phương.',
      gift: 'Check-in bản đồ để nhận huy hiệu UEH Campus Explorer.',
    ),
    _CampusSpot(
      name: 'Cổng Đào Duy Từ',
      category: _CampusMapFilter.amenities,
      icon: Icons.login_rounded,
      color: Color(0xFF74D3C4),
      x: 0.77,
      y: 0.85,
      shortLabel: 'Đào Duy Từ',
      isEvent: false,
      activity: 'Lối ra vào phụ phía đường Đào Duy Từ.',
      gift: 'Quét QR sự kiện tại cổng để nhận điểm hoạt động.',
    ),
    _CampusSpot(
      name: 'Cổng 3 Đào Duy Từ',
      category: _CampusMapFilter.amenities,
      icon: Icons.login_rounded,
      color: Color(0xFF74D3C4),
      x: 0.82,
      y: 0.72,
      shortLabel: 'Cổng 3',
      isEvent: false,
      activity: 'Lối ra vào phía Đào Duy Từ, gần khu vực sân trường.',
      gift: 'Check-in nhận sticker UEH theo chủ đề sự kiện.',
    ),
    _CampusSpot(
      name: 'Bãi xe sinh viên',
      category: _CampusMapFilter.amenities,
      icon: Icons.two_wheeler_rounded,
      color: Color(0xFF7FB9FF),
      x: 0.17,
      y: 0.31,
      shortLabel: 'Xe SV',
      isEvent: false,
      activity: 'Khu vực gửi xe dành cho sinh viên.',
      gift: 'Tra cứu sơ đồ bãi xe và lối đi bộ tới sảnh chính.',
    ),
    _CampusSpot(
      name: 'Bãi xe GV-CBCC',
      category: _CampusMapFilter.amenities,
      icon: Icons.local_parking_rounded,
      color: Color(0xFF7FB9FF),
      x: 0.79,
      y: 0.2,
      shortLabel: 'Xe GV',
      isEvent: false,
      activity: 'Khu vực gửi xe dành cho giảng viên và cán bộ, công chức.',
      gift: 'Xem hướng dẫn khu vực gửi xe phù hợp.',
    ),
    _CampusSpot(
      name: 'Căn tin',
      category: _CampusMapFilter.amenities,
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFFBE78),
      x: 0.2,
      y: 0.58,
      shortLabel: 'Căn tin',
      isEvent: false,
      activity: 'Ghé căn tin, khám phá các lựa chọn ăn uống trong trường.',
      gift: 'Gợi ý món ăn sinh viên và ưu đãi theo sự kiện.',
    ),
    _CampusSpot(
      name: 'Quầy lưu niệm UEH',
      category: _CampusMapFilter.amenities,
      icon: Icons.storefront_rounded,
      color: Color(0xFFFFBE78),
      x: 0.79,
      y: 0.56,
      shortLabel: 'Lưu niệm',
      isEvent: false,
      activity: 'Khám phá các sản phẩm và vật phẩm lưu niệm UEH.',
      gift: 'Sticker hoặc quà lưu niệm theo chương trình trong ngày.',
    ),
    _CampusSpot(
      name: 'Phòng Y tế B027',
      category: _CampusMapFilter.amenities,
      icon: Icons.medical_services_rounded,
      color: Color(0xFFFF858E),
      x: 0.83,
      y: 0.4,
      shortLabel: 'Y tế B027',
      isEvent: false,
      activity: 'Khu vực hỗ trợ y tế trong khuôn viên cơ sở B.',
      gift: 'Tìm thông tin hỗ trợ và đường đi tới phòng B027.',
    ),
    _CampusSpot(
      name: 'Job Fair & Tuyển dụng Data/AI',
      category: _CampusMapFilter.recruitment,
      icon: Icons.work_rounded,
      color: Color(0xFFB999FF),
      x: 0.35,
      y: 0.38,
      shortLabel: 'JOB',
      isEvent: true,
      activity:
          'Minigame kết nối kỹ năng với cơ hội tuyển dụng Data/AI và thực tập.',
      gift: 'Quà UEH và vật phẩm từ doanh nghiệp tham gia Job Fair.',
    ),
    _CampusSpot(
      name: 'Check-in CLB & Đội Nhóm UEH',
      category: _CampusMapFilter.clubs,
      icon: Icons.groups_rounded,
      color: Color(0xFF65D9B3),
      x: 0.52,
      y: 0.48,
      shortLabel: 'CLB',
      isEvent: true,
      activity:
          'Check-in và tham gia minigame làm quen với các CLB, đội nhóm UEH.',
      gift: 'Sticker check-in và thông tin tuyển thành viên.',
    ),
    _CampusSpot(
      name: 'Gian hàng Hội Sinh Viên',
      category: _CampusMapFilter.clubs,
      icon: Icons.celebration_rounded,
      color: Color(0xFFFF87B5),
      x: 0.62,
      y: 0.32,
      shortLabel: 'HSV',
      isEvent: true,
      activity: 'Minigame khám phá hoạt động và phong trào sinh viên UEH.',
      gift: 'Quà lưu niệm và vật phẩm từ Hội Sinh Viên.',
    ),
    _CampusSpot(
      name: 'Cây đàn piano',
      category: _CampusMapFilter.amenities,
      icon: Icons.piano_rounded,
      color: Color(0xFFFFD36E),
      x: 0.6,
      y: 0.79,
      shortLabel: 'Piano',
      isEvent: false,
      activity: 'Cây đàn piano đặt tại khu vực sân trường khối B1.',
      gift: 'Ghé nghe hoặc chơi một giai điệu tại không gian chung.',
    ),
    _CampusSpot(
      name: 'Khối phòng B1',
      category: _CampusMapFilter.amenities,
      icon: Icons.apartment_rounded,
      color: Color(0xFF7FB9FF),
      x: 0.47,
      y: 0.72,
      shortLabel: 'B1',
      isEvent: false,
      activity: 'Khu phòng B1 nằm ở nửa dưới sơ đồ tầng.',
      gift: 'Dùng tên phòng trên sơ đồ để tìm vị trí cần đến.',
    ),
    _CampusSpot(
      name: 'Khối phòng B2',
      category: _CampusMapFilter.amenities,
      icon: Icons.apartment_rounded,
      color: Color(0xFF7FB9FF),
      x: 0.48,
      y: 0.28,
      shortLabel: 'B2',
      isEvent: false,
      activity: 'Khu phòng B2 nằm ở nửa trên sơ đồ tầng.',
      gift: 'Dùng tên phòng trên sơ đồ để tìm vị trí cần đến.',
    ),
  ];

  _CampusMapFilter _selectedFilter = _CampusMapFilter.all;
  final TransformationController _transformationController =
      TransformationController();
  late final AnimationController _boothPulseController;
  late final Animation<double> _boothPulseScale;

  List<_CampusSpot> get _visibleSpots => _selectedFilter == _CampusMapFilter.all
      ? _spots
      : _spots
            .where((spot) => spot.category == _selectedFilter)
            .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _boothPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _boothPulseScale = Tween<double>(
      begin: 0.88,
      end: 1.12,
    ).animate(
      CurvedAnimation(
        parent: _boothPulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _boothPulseController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _resetMapView() {
    _transformationController.value = Matrix4.identity();
  }

  void _showSpotDetails(_CampusSpot spot) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _buildSpotSheet(sheetContext, spot),
    );
  }

  Widget _buildSpotSheet(BuildContext sheetContext, _CampusSpot spot) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1B1825),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: spot.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(spot.icon, color: spot.color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spot.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          spot.category.label,
                          style: TextStyle(
                            color: spot.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _buildDetailRow(
                icon: Icons.local_activity_outlined,
                title: spot.isEvent ? 'Minigame' : 'Hoạt động',
                description: spot.activity,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                icon: Icons.card_giftcard_rounded,
                title: 'Quà tặng',
                description: spot.gift,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _showCareerMapInfo();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: const Color(0xFF211A30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.route_rounded),
                  label: const Text(
                    'Bổ trợ Lộ trình Nghề nghiệp (Career Map)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _accentColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFFBDB7C9),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCareerMapInfo() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1B1825),
      showDragHandle: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Career Map UEH',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Khám phá doanh nghiệp, kết nối câu lạc bộ và tìm hoạt động giúp bạn phát triển kỹ năng nghề nghiệp.',
                style: TextStyle(color: Color(0xFFCBC6D3), height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: _buildInteractiveMap(),
              ),
            ),
            _buildFilterBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 18, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quay lại',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bản đồ 3D UEH',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Cơ sở B · Tầng trệt · Sơ đồ minh họa',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Đặt lại bản đồ',
            onPressed: _resetMapView,
            icon: const Icon(Icons.center_focus_strong, color: _accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveMap() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapSize = constraints.biggest;
        final imageRect = Offset.zero & mapSize;
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFDFE9D7),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1,
              maxScale: 4,
              boundaryMargin: const EdgeInsets.all(80),
              constrained: true,
              child: SizedBox(
                width: mapSize.width,
                height: mapSize.height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const _IsometricCampusIllustration(),
                    const Positioned(left: 14, top: 14, child: _MapLegend()),
                    ..._visibleSpots.map(
                      (spot) => _buildMapPin(spot, imageRect),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xE6100E19),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'UEH · CƠ SỞ B',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapPin(_CampusSpot spot, Rect imageRect) {
    final marker = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xF51B1825),
            shape: BoxShape.circle,
            border: Border.all(color: spot.color, width: 2),
            boxShadow: [
              BoxShadow(
                color: spot.color.withValues(alpha: 0.42),
                blurRadius: spot.isEvent ? 16 : 9,
                spreadRadius: spot.isEvent ? 2 : 0,
              ),
            ],
          ),
          child: Icon(spot.icon, color: spot.color, size: 20),
        ),
        const SizedBox(height: 2),
        Container(
          constraints: const BoxConstraints(maxWidth: 52),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xE81B1825),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            spot.shortLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
    final pin = spot.isEvent
        ? AnimatedBuilder(
            animation: _boothPulseScale,
            child: marker,
            builder: (context, child) => Transform.scale(
              scale: _boothPulseScale.value,
              child: child,
            ),
          )
        : marker;

    return Positioned(
      left: imageRect.left + spot.x * imageRect.width - 28,
      top: imageRect.top + spot.y * imageRect.height - 21,
      child: Semantics(
        button: true,
        label: spot.name,
        child: Tooltip(
          message: spot.name,
          child: GestureDetector(
            onTap: () => _showSpotDetails(spot),
            child: SizedBox(
              width: 56,
              height: 60,
              child: Center(child: pin),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
        scrollDirection: Axis.horizontal,
        itemCount: _CampusMapFilter.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _CampusMapFilter.values[index];
          final selected = filter == _selectedFilter;
          return ChoiceChip(
            label: Text(filter.label),
            selected: selected,
            onSelected: (value) {
              setState(() => _selectedFilter = filter);
              _resetMapView();
            },
            backgroundColor: const Color(0xFF211D2B),
            selectedColor: _accentColor,
            side: BorderSide(
              color: selected
                  ? _accentColor
                  : Colors.white.withValues(alpha: 0.12),
            ),
            labelStyle: TextStyle(
              color: selected ? const Color(0xFF211A30) : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xE6100E19),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_rounded, color: Colors.white70, size: 13),
          SizedBox(width: 5),
          Text(
            'Chạm ghim để khám phá',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IsometricCampusIllustration extends StatelessWidget {
  const _IsometricCampusIllustration();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _IsometricCampusPainter(),
      child: SizedBox.expand(),
    );
  }
}

class _IsometricCampusPainter extends CustomPainter {
  const _IsometricCampusPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFD9E5CF);
    canvas.drawRect(Offset.zero & size, background);

    _drawGroundGrid(canvas, size);
    _drawRoad(canvas, size);
    _drawBuilding(
      canvas,
      Rect.fromLTWH(
        size.width * 0.06,
        size.height * 0.2,
        size.width * 0.25,
        size.height * 0.19,
      ),
      const Color(0xFFDF9F70),
    );
    _drawBuilding(
      canvas,
      Rect.fromLTWH(
        size.width * 0.69,
        size.height * 0.13,
        size.width * 0.24,
        size.height * 0.22,
      ),
      const Color(0xFFE5B675),
    );
    _drawBuilding(
      canvas,
      Rect.fromLTWH(
        size.width * 0.07,
        size.height * 0.66,
        size.width * 0.23,
        size.height * 0.16,
      ),
      const Color(0xFFD98B70),
    );
    _drawBuilding(
      canvas,
      Rect.fromLTWH(
        size.width * 0.7,
        size.height * 0.67,
        size.width * 0.23,
        size.height * 0.16,
      ),
      const Color(0xFFE2AA75),
    );
    _drawGarden(canvas, size, 0.44, 0.2, 0.12);
    _drawGarden(canvas, size, 0.47, 0.68, 0.1);
    _drawCourtyard(canvas, size);
    _drawTrees(canvas, size);
    _drawBuildingLabels(canvas, size);
  }

  void _drawGroundGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1F557A53)
      ..strokeWidth = 0.7;
    const spacing = 26.0;
    for (var x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x.toDouble(), 0),
        Offset(x - size.height, size.height),
        paint,
      );
    }
    for (var x = 0.0; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  void _drawRoad(Canvas canvas, Size size) {
    final road = Paint()..color = const Color(0xFFB7B9AC);
    final sidewalk = Paint()..color = const Color(0xFFF0E8D8);
    final roadRect = Rect.fromLTWH(
      size.width * 0.02,
      size.height * 0.88,
      size.width * 0.96,
      size.height * 0.1,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(roadRect, const Radius.circular(12)),
      road,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(roadRect.deflate(5), const Radius.circular(9)),
      sidewalk,
    );
    final roadLabel = _textPainter(
      'ĐƯỜNG NGUYỄN TRI PHƯƠNG  ·  ĐÀO DUY TỪ',
      fontSize: 8,
      color: const Color(0xFF68685F),
      weight: FontWeight.w800,
    );
    roadLabel.layout(maxWidth: size.width * 0.8);
    roadLabel.paint(
      canvas,
      Offset(
        roadRect.center.dx - roadLabel.width / 2,
        roadRect.center.dy - roadLabel.height / 2,
      ),
    );
  }

  void _drawBuilding(Canvas canvas, Rect rect, Color frontColor) {
    final depth = Size(rect.width * 0.17, rect.height * 0.2);
    final shadow = Paint()..color = const Color(0x300D1B14);
    final front = Paint()..color = frontColor;
    final side = Paint()..color = Color.lerp(frontColor, Colors.black, 0.18)!;
    final roof = Paint()..color = Color.lerp(frontColor, Colors.white, 0.22)!;

    final shadowPath = Path()
      ..moveTo(rect.left + depth.width, rect.bottom + depth.height)
      ..lineTo(rect.right + depth.width, rect.bottom + depth.height)
      ..lineTo(rect.right + depth.width, rect.top + depth.height)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.left, rect.top)
      ..lineTo(rect.left, rect.bottom)
      ..close();
    canvas.drawPath(shadowPath, shadow);

    final sidePath = Path()
      ..moveTo(rect.right, rect.top)
      ..lineTo(rect.right + depth.width, rect.top + depth.height)
      ..lineTo(rect.right + depth.width, rect.bottom + depth.height)
      ..lineTo(rect.right, rect.bottom)
      ..close();
    canvas.drawPath(sidePath, side);
    canvas.drawRect(rect, front);

    final roofPath = Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.left + depth.width, rect.top - depth.height)
      ..lineTo(rect.right + depth.width, rect.top - depth.height)
      ..lineTo(rect.right, rect.top)
      ..close();
    canvas.drawPath(roofPath, roof);

    final windowPaint = Paint()..color = const Color(0xFFFFE8B7);
    final windowWidth = rect.width * 0.08;
    final windowHeight = rect.height * 0.2;
    for (var row = 0; row < 2; row++) {
      for (var column = 0; column < 3; column++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              rect.left + rect.width * (0.18 + column * 0.25),
              rect.top + rect.height * (0.2 + row * 0.36),
              windowWidth,
              windowHeight,
            ),
            const Radius.circular(2),
          ),
          windowPaint,
        );
      }
    }
  }

  void _drawGarden(
    Canvas canvas,
    Size size,
    double x,
    double y,
    double radius,
  ) {
    final center = Offset(size.width * x, size.height * y);
    final gardenRect = Rect.fromCenter(
      center: center,
      width: size.width * radius * 1.5,
      height: size.height * radius * 0.75,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(gardenRect, const Radius.circular(18)),
      Paint()..color = const Color(0xFF94BD7F),
    );
    final path = Path()
      ..moveTo(gardenRect.left, center.dy)
      ..lineTo(center.dx, gardenRect.top)
      ..lineTo(gardenRect.right, center.dy)
      ..lineTo(center.dx, gardenRect.bottom)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFB7D89C));
  }

  void _drawCourtyard(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.29,
      size.height * 0.31,
      size.width * 0.42,
      size.height * 0.35,
    );
    final path = Path()
      ..moveTo(rect.left, rect.top + rect.height * 0.13)
      ..lineTo(rect.left + rect.width * 0.84, rect.top)
      ..lineTo(rect.right, rect.top + rect.height * 0.44)
      ..lineTo(rect.left + rect.width * 0.17, rect.bottom)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFEBDAB8));

    final walkwayPaint = Paint()
      ..color = const Color(0xFFFAF2E1)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(
        Offset(rect.left + rect.width * 0.48, rect.top + rect.height * 0.05),
        Offset(rect.left + rect.width * 0.54, rect.bottom),
        walkwayPaint,
      )
      ..drawLine(
        Offset(rect.left + rect.width * 0.06, rect.top + rect.height * 0.56),
        Offset(rect.right, rect.top + rect.height * 0.42),
        walkwayPaint,
      );

    final lawn = Paint()..color = const Color(0xFFA8CA8B);
    final circleCenter = Offset(rect.center.dx, rect.center.dy);
    canvas.drawOval(
      Rect.fromCenter(
        center: circleCenter,
        width: size.width * 0.14,
        height: size.height * 0.1,
      ),
      lawn,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: circleCenter,
        width: size.width * 0.075,
        height: size.height * 0.05,
      ),
      Paint()..color = const Color(0xFF77A66C),
    );
  }

  void _drawTrees(Canvas canvas, Size size) {
    const positions = <Offset>[
      Offset(0.39, 0.24),
      Offset(0.57, 0.23),
      Offset(0.65, 0.27),
      Offset(0.36, 0.69),
      Offset(0.62, 0.69),
      Offset(0.33, 0.78),
      Offset(0.65, 0.79),
      Offset(0.49, 0.17),
    ];
    for (var i = 0; i < positions.length; i++) {
      final point = positions[i];
      final center = Offset(size.width * point.dx, size.height * point.dy);
      final shadowCenter = center.translate(4, 5);
      canvas.drawCircle(
        shadowCenter,
        size.shortestSide * 0.024,
        Paint()..color = const Color(0x2252683D),
      );
      canvas.drawCircle(
        center,
        size.shortestSide * 0.022,
        Paint()
          ..color = i.isEven
              ? const Color(0xFF4F8B5D)
              : const Color(0xFF6A9D65),
      );
      canvas.drawCircle(
        center.translate(-2, -2),
        size.shortestSide * 0.013,
        Paint()..color = const Color(0xFF9DC27D),
      );
    }
  }

  void _drawBuildingLabels(Canvas canvas, Size size) {
    final label = _textPainter(
      'SÂN TRƯỜNG UEH',
      fontSize: 9,
      color: const Color(0xFF516148),
      weight: FontWeight.w900,
    );
    label.layout();
    label.paint(
      canvas,
      Offset(
        size.width * 0.5 - label.width / 2,
        size.height * 0.63 - label.height / 2,
      ),
    );
  }

  TextPainter _textPainter(
    String text, {
    required double fontSize,
    required Color color,
    required FontWeight weight,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'sans-serif',
          fontSize: fontSize,
          color: color,
          fontWeight: weight,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
  }

  @override
  bool shouldRepaint(covariant _IsometricCampusPainter oldDelegate) => false;
}
