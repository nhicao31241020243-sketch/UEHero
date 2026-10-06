import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/mentor_model.dart';

class MentorScreen extends StatefulWidget {
  const MentorScreen({super.key});

  @override
  State<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends State<MentorScreen> {
  static const _backgroundColor = Color(0xFF100E19);
  static const _surfaceColor = Color(0xFF211D2B);
  static const _accentColor = Color(0xFFBFA8FF);

  static const _mentors = <MentorModel>[
    MentorModel(
      name: 'Minh Anh Nguyễn',
      jobTitle: 'Senior UX Designer',
      rating: 4.9,
      menteeCount: 12,
      avatarAsset: '',
      bio: 'Cùng bạn biến ý tưởng thành trải nghiệm người dùng đáng nhớ.',
      avatarColor: Color(0xFFBDA0FF),
    ),
    MentorModel(
      name: 'Quang Huy Trần',
      jobTitle: 'Data Science Expert',
      rating: 4.8,
      menteeCount: 18,
      avatarAsset: '',
      bio: 'Khám phá dữ liệu, machine learning và lộ trình Data thực tế.',
      avatarColor: Color(0xFF62D3CF),
    ),
    MentorModel(
      name: 'Thảo My Lê',
      jobTitle: 'Product Manager',
      rating: 5.0,
      menteeCount: 9,
      avatarAsset: '',
      bio: 'Chia sẻ cách xây sản phẩm và phối hợp cùng đội ngũ đa ngành.',
      avatarColor: Color(0xFFFF9CB9),
    ),
    MentorModel(
      name: 'Gia Bảo Phạm',
      jobTitle: 'Software Engineer',
      rating: 4.9,
      menteeCount: 24,
      avatarAsset: '',
      bio: 'Đồng hành ôn phỏng vấn và xây nền tảng lập trình vững chắc.',
      avatarColor: Color(0xFFFFC36E),
    ),
    MentorModel(
      name: 'Khánh Linh Võ',
      jobTitle: 'Digital Marketing Lead',
      rating: 4.7,
      menteeCount: 15,
      avatarAsset: '',
      bio: 'Tìm hướng đi trong marketing số, nội dung và tăng trưởng.',
      avatarColor: Color(0xFF8DB9FF),
    ),
  ];

  final _searchController = TextEditingController();
  String _searchQuery = '';

  List<MentorModel> get _visibleMentors {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _mentors;
    return _mentors
        .where(
          (mentor) =>
              mentor.name.toLowerCase().contains(query) ||
              mentor.jobTitle.toLowerCase().contains(query) ||
              mentor.bio.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showBookingInfo(MentorModel mentor) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF211D2B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 22),
            Text(
              'Kết nối với ${mentor.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${mentor.jobTitle} · ${mentor.rating.toStringAsFixed(1)} ★',
              style: const TextStyle(
                color: Color(0xFFD1C5F5),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Lịch mentoring sẽ được cập nhật khi mentor mở khung giờ kết nối.',
              style: TextStyle(
                color: Color(0xFFBDB7C9),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: const Color(0xFF211A30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'ĐÃ HIỂU',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mentors = _visibleMentors;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Tìm mentor hoặc chuyên môn...',
                  hintStyle: const TextStyle(
                    color: Color(0xFFAAA5B8),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: _accentColor,
                  ),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Xóa tìm kiếm',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                          ),
                        ),
                  filled: true,
                  fillColor: _surfaceColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Mentor đồng hành',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${mentors.length} mentor',
                    style: const TextStyle(
                      color: Color(0xFFAAA5B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: mentors.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: mentors.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _MentorCard(
                          mentor: mentors[index],
                          onBook: () => _showBookingInfo(mentors[index]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 12),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quay lại',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UEH Mentor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Kết nối cùng người đi trước',
                  style: TextStyle(color: Color(0xFFBDB7C9), fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.auto_awesome_rounded, color: _accentColor),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.travel_explore_rounded,
              color: _accentColor,
              size: 44,
            ),
            const SizedBox(height: 12),
            const Text(
              'Chưa tìm thấy mentor phù hợp',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Thử tìm bằng tên hoặc lĩnh vực chuyên môn khác nhé.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MentorCard extends StatelessWidget {
  const _MentorCard({required this.mentor, required this.onBook});

  final MentorModel mentor;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF292439), Color(0xFF191722)],
        ),
        border: Border.all(color: mentor.avatarColor.withValues(alpha: 0.36)),
        boxShadow: [
          BoxShadow(
            color: mentor.avatarColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          const BoxShadow(
            color: Color(0x44000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MentorAvatar(mentor: mentor),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mentor.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        mentor.jobTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: mentor.avatarColor,
                          fontSize: 12,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFD36E),
                            size: 17,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            mentor.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              '· ${mentor.menteeCount} mentees',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFBDB7C9),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            mentor.bio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFCEC9D7),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.groups_rounded,
                      color: mentor.avatarColor,
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Đã nhận: ${mentor.menteeCount} mentees',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFBDB7C9),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _BookingButton(color: mentor.avatarColor, onPressed: onBook),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingButton extends StatelessWidget {
  const _BookingButton({required this.color, required this.onPressed});

  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, const Color(0xFF684AB5), 0.55)!],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Text(
              'ĐẶT LỊCH',
              style: TextStyle(
                color: Color(0xFF1C1726),
                fontSize: 10,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MentorAvatar extends StatelessWidget {
  const _MentorAvatar({required this.mentor});

  final MentorModel mentor;

  @override
  Widget build(BuildContext context) {
    final avatar = mentor.avatarAsset.isEmpty
        ? _AstronautIllustration(color: mentor.avatarColor)
        : Image.asset(
            mentor.avatarAsset,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _AstronautIllustration(color: mentor.avatarColor),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(19),
      child: SizedBox(width: 88, height: 96, child: avatar),
    );
  }
}

class _AstronautIllustration extends StatelessWidget {
  const _AstronautIllustration({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AstronautPainter(color: color),
      child: const SizedBox.expand(),
    );
  }
}

class _AstronautPainter extends CustomPainter {
  const _AstronautPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.42),
          const Color(0xFF171421),
          const Color(0xFF100E19),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, backgroundPaint);

    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.72);
    final points = <Offset>[
      Offset(size.width * 0.16, size.height * 0.18),
      Offset(size.width * 0.82, size.height * 0.16),
      Offset(size.width * 0.85, size.height * 0.48),
      Offset(size.width * 0.13, size.height * 0.58),
    ];
    for (var index = 0; index < points.length; index++) {
      canvas.drawCircle(points[index], index.isEven ? 1.2 : 0.8, starPaint);
    }

    final center = Offset(size.width * 0.5, size.height * 0.56);
    final scale = size.shortestSide;
    final shadow = Paint()..color = const Color(0x44000000);
    final suit = Paint()..color = Color.lerp(color, Colors.white, 0.14)!;
    final suitShade = Paint()..color = Color.lerp(color, Colors.black, 0.2)!;
    final helmet = Paint()..color = color;

    final bodyRect = Rect.fromCenter(
      center: Offset(center.dx, size.height * 0.92),
      width: size.width * 0.78,
      height: size.height * 0.66,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bodyRect.shift(Offset(0, scale * 0.035)),
        Radius.circular(scale * 0.22),
      ),
      shadow,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(scale * 0.22)),
      suitShade,
    );
    final chest = Rect.fromLTWH(
      size.width * 0.3,
      size.height * 0.73,
      size.width * 0.4,
      size.height * 0.2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(chest, Radius.circular(scale * 0.07)),
      suit,
    );
    canvas.drawCircle(
      Offset(center.dx, size.height * 0.82),
      scale * 0.045,
      Paint()..color = const Color(0xFF172033),
    );

    final helmetCenter = Offset(size.width * 0.5, size.height * 0.4);
    canvas.drawCircle(helmetCenter, scale * 0.34, shadow);
    canvas.drawCircle(helmetCenter, scale * 0.32, helmet);
    canvas.drawCircle(
      helmetCenter,
      scale * 0.255,
      Paint()..color = const Color(0xFF20243C),
    );

    final visorRect = Rect.fromCenter(
      center: Offset(helmetCenter.dx, helmetCenter.dy + scale * 0.015),
      width: scale * 0.4,
      height: scale * 0.31,
    );
    canvas.drawOval(
      visorRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.32)!,
            const Color(0xFF34466D),
            const Color(0xFF161C31),
          ],
        ).createShader(visorRect),
    );
    final reflection = Paint()
      ..color = Colors.white.withValues(alpha: 0.58)
      ..strokeWidth = scale * 0.018
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.39, size.height * 0.34),
      Offset(size.width * 0.45, size.height * 0.3),
      reflection,
    );
    canvas.drawCircle(
      Offset(size.width * 0.63, size.height * 0.42),
      scale * 0.018,
      Paint()..color = Colors.white.withValues(alpha: 0.78),
    );

    canvas.drawCircle(
      Offset(size.width * 0.79, size.height * 0.72),
      scale * 0.055,
      Paint()..color = const Color(0xFF29344C),
    );
    canvas.drawCircle(
      Offset(size.width * 0.79, size.height * 0.72),
      scale * 0.027,
      Paint()..color = const Color(0xFF7BF0D7),
    );

    final orbitPaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = scale * 0.018;
    canvas.drawArc(
      Rect.fromCenter(
        center: helmetCenter,
        width: scale * 0.78,
        height: scale * 0.48,
      ),
      math.pi * 0.12,
      math.pi * 0.76,
      false,
      orbitPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AstronautPainter oldDelegate) =>
      oldDelegate.color != color;
}
