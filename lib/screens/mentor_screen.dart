import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/it_fields.dart';
import '../data/mentor_demo_data.dart';
import '../models/mentor_model.dart';
import '../services/mentor_booking_service.dart';
import '../services/mentor_filter.dart';
import '../widgets/mentor_avatar.dart';
import 'mentor_bookings_screen.dart';
import 'mentor_profile_screen.dart';

class MentorScreen extends StatefulWidget {
  const MentorScreen({super.key});

  @override
  State<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends State<MentorScreen> {
  static const _backgroundColor = Color(0xFF100E19);
  static const _surfaceColor = Color(0xFF211D2B);
  static const _accentColor = Color(0xFFBFA8FF);
  static const _goalFilter = '__goal__';

  final _searchController = TextEditingController();
  final _bookingService = MentorBookingService.instance;
  late final List<Mentor> _mentors;
  String _searchQuery = '';
  String? _goalId;
  String? _goalFieldId;
  String? _selectedFieldId;
  bool _onlyAvailable = false;
  bool _loadingGoal = true;
  bool _goalUnavailable = false;
  String? _bookingLoadError;

  @override
  void initState() {
    super.initState();
    _mentors = MentorRepository.getMentors();
    _bookingService.addListener(_bookingsChanged);
    _loadGoal();
    unawaited(_initializeBookings());
  }

  Future<void> _initializeBookings() async {
    try {
      await _bookingService.initialize();
    } catch (error) {
      if (!mounted) return;
      setState(() => _bookingLoadError = error.toString());
    }
  }

  void _bookingsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadGoal() async {
    final preferences = await SharedPreferences.getInstance();
    final goalId = preferences.getString('career_goal');
    final fieldId = fieldIdForGoal(goalId);
    final hasMatchingMentor =
        fieldId != null &&
        _mentors.any((mentor) => mentor.fieldIds.contains(fieldId));
    if (!mounted) return;
    setState(() {
      _goalId = goalId;
      _goalFieldId = fieldId;
      _selectedFieldId = hasMatchingMentor ? _goalFilter : null;
      _goalUnavailable = !hasMatchingMentor;
      _loadingGoal = false;
    });
  }

  List<Mentor> get _visibleMentors => filterAndSortMentors(
    mentors: _mentors,
    query: _searchQuery,
    fieldId: _selectedFieldId,
    targetFieldId: _goalFieldId,
    onlyAvailable: _onlyAvailable,
  );

  @override
  void dispose() {
    _bookingService.removeListener(_bookingsChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _openProfile(Mentor mentor) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MentorProfileScreen(mentor: mentor),
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
            if (_mentors.any((mentor) => mentor.isDemo)) _buildDemoBanner(),
            if (_bookingLoadError case final error?)
              _buildBookingError(error)
            else
              _buildUpcomingReminder(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Tìm mentor, ngành hoặc chủ đề...',
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
            _buildFilters(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
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
            if (_goalUnavailable)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text(
                  _goalId == null
                      ? 'Chưa có mục tiêu IT ánh xạ được; đang hiển thị tất cả mentor.'
                      : 'Mục tiêu hiện tại chưa có ngành mentor tương ứng; đang hiển thị tất cả.',
                  style: const TextStyle(
                    color: Color(0xFFBDB7C9),
                    fontSize: 12,
                  ),
                ),
              ),
            Expanded(
              child: _loadingGoal
                  ? const Center(
                      child: CircularProgressIndicator(color: _accentColor),
                    )
                  : mentors.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: mentors.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _MentorCard(
                          mentor: mentors[index],
                          isGoalMatch:
                              _goalFieldId != null &&
                              mentors[index].fieldIds.contains(_goalFieldId),
                          onTap: () => _openProfile(mentors[index]),
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
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 8),
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
          IconButton(
            tooltip: 'Lịch hẹn của tôi',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MentorBookingsScreen(),
              ),
            ),
            icon: const Icon(Icons.event_note_rounded, color: _accentColor),
          ),
          const Icon(Icons.auto_awesome_rounded, color: _accentColor),
        ],
      ),
    );
  }

  Widget _buildDemoBanner() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF332A48),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentColor.withValues(alpha: 0.2)),
      ),
      child: const Text(
        'Dữ liệu mẫu để thử nghiệm',
        style: TextStyle(
          color: Color(0xFFD8CDF8),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  Widget _buildBookingError(String error) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    child: Text(
      'Không tải được lịch mentor: $error',
      style: const TextStyle(color: Color(0xFFFFA6A6), fontSize: 11),
    ),
  );

  Widget _buildUpcomingReminder() {
    if (!_bookingService.isInitialized) return const SizedBox.shrink();
    final booking = _bookingService.upcomingConfirmedWithin24Hours();
    if (booking?.slot == null) return const SizedBox.shrink();
    Mentor? mentor;
    for (final item in _mentors) {
      if (item.id == booking!.mentorId) {
        mentor = item;
        break;
      }
    }
    final hours =
        (booking!.slot!.difference(DateTime.now()).inMinutes + 59) ~/ 60;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF253B3B),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: const Color(0xFF7AD8C2).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.event_available_rounded,
              color: Color(0xFF9EDCCB),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lịch với ${mentor?.name ?? 'mentor'} sau ${hours.clamp(1, 24)} giờ',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFD5F2E9),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _FilterChip(
              label: 'Tất cả',
              selected: _selectedFieldId == null,
              onTap: () => setState(() => _selectedFieldId = null),
            ),
            _FilterChip(
              label: 'Hợp mục tiêu',
              selected: _selectedFieldId == _goalFilter,
              onTap: () => setState(
                () => _selectedFieldId =
                    _goalFieldId != null &&
                        _mentors.any(
                          (mentor) => mentor.fieldIds.contains(_goalFieldId),
                        )
                    ? _goalFilter
                    : null,
              ),
            ),
            for (final field in itFields)
              _FilterChip(
                label: field.name,
                selected: _selectedFieldId == field.id,
                onTap: () => setState(() => _selectedFieldId = field.id),
              ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 2, 18, 4),
        child: Row(
          children: [
            if (_goalFieldId != null)
              Expanded(
                child: Text(
                  'Mục tiêu: ${itFieldName(_goalFieldId!) ?? _goalFieldId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFAAA5B8),
                    fontSize: 11,
                  ),
                ),
              )
            else
              const Spacer(),
            FilterChip(
              label: const Text('Còn lịch trống'),
              selected: _onlyAvailable,
              onSelected: (value) => setState(() => _onlyAvailable = value),
              avatar: const Icon(Icons.event_available_rounded, size: 16),
              labelStyle: const TextStyle(
                color: Color(0xFFD8CDF8),
                fontSize: 11,
              ),
              backgroundColor: _surfaceColor,
              selectedColor: const Color(0xFF4D3B70),
              checkmarkColor: Colors.white,
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
              showCheckmark: false,
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildEmptyState() => Center(
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
            'Chưa có mentor phù hợp, thử bỏ bớt bộ lọc',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Thử xóa từ khóa tìm kiếm hoặc chọn ngành khác nhé.',
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF211A30) : const Color(0xFFD8CDF8),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: _MentorScreenState._surfaceColor,
      selectedColor: _MentorScreenState._accentColor,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    ),
  );
}

class _MentorCard extends StatelessWidget {
  const _MentorCard({
    required this.mentor,
    required this.isGoalMatch,
    required this.onTap,
  });

  final Mentor mentor;
  final bool isGoalMatch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nextSlot = mentor.availableSlots.isEmpty
        ? null
        : (List<DateTime>.of(mentor.availableSlots)..sort()).first;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF292439), Color(0xFF191722)],
            ),
            border: Border.all(
              color: const Color(0xFFBFA8FF).withValues(alpha: 0.22),
            ),
            boxShadow: const [
              BoxShadow(
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
                  MentorAvatar(mentor: mentor, size: 58),
                  const SizedBox(width: 13),
                  Expanded(
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
                        const SizedBox(height: 4),
                        Text(
                          mentor.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFD1C5F5),
                            fontSize: 12,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${mentor.yearsExperience} năm kinh nghiệm',
                          style: const TextStyle(
                            color: Color(0xFFBDB7C9),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white54,
                  ),
                ],
              ),
              if (isGoalMatch) ...[
                const SizedBox(height: 10),
                const _InfoTag(
                  icon: Icons.stars_rounded,
                  label: 'Hợp với mục tiêu của bạn',
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final id in mentor.fieldIds)
                    _InfoTag(label: itFieldName(id) ?? id),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final topic in mentor.topics)
                    _InfoTag(label: topic.label, muted: true),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        nextSlot == null
                            ? Icons.event_busy_rounded
                            : Icons.event_available_rounded,
                        color: const Color(0xFF9EDCCB),
                        size: 17,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          nextSlot == null
                              ? 'Chưa có lịch'
                              : 'Trống: ${_formatSlot(nextSlot)}',
                          style: const TextStyle(
                            color: Color(0xFFCEC9D7),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Phản hồi trong ${mentor.responseTime}',
                    style: const TextStyle(
                      color: Color(0xFFBDB7C9),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSlot(DateTime slot) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final slotDay = DateTime(slot.year, slot.month, slot.day);
    final dayLabel = slotDay == DateTime(now.year, now.month, now.day)
        ? 'Hôm nay'
        : slotDay == tomorrow
        ? 'Ngày mai'
        : '${slot.day}/${slot.month}';
    final hour = slot.hour.toString().padLeft(2, '0');
    final minute = slot.minute.toString().padLeft(2, '0');
    return '$dayLabel · $hour:$minute';
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.label, this.icon, this.muted = false});

  final String label;
  final IconData? icon;
  final bool muted;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: muted ? const Color(0xFF302B3A) : const Color(0xFF40335A),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFFD8CDF8), size: 14),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: muted
                    ? const Color(0xFFBDB7C9)
                    : const Color(0xFFD8CDF8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
