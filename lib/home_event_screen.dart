import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'event_detail_screen.dart';
import 'models/event_item.dart';
import 'services/event_repository.dart';

class HomeEventScreen extends StatefulWidget {
  const HomeEventScreen({super.key});

  @override
  State<HomeEventScreen> createState() => _HomeEventScreenState();
}

class _HomeEventScreenState extends State<HomeEventScreen> {
  static const _background = Color(0xFF100E19);
  static const _surface = Color(0xFF211D2B);
  static const _muted = Color(0xFFAAA5B8);
  static const _accent = Color(0xFFBFA8FF);
  final EventRepository _repository = LocalEventRepository();
  final _filters = const [
    'Tất cả',
    'Phù hợp với tôi',
    'Cuộc thi',
    'Hackathon',
    'Hội chợ việc làm',
    'Đang mở đăng ký',
  ];
  List<EventItem> _events = const [];
  String _filter = 'Tất cả';
  String? _careerGoal;
  Map<String, dynamic> _mastery = {};
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final events = await _repository.fetchEvents();
      final raw = preferences.getString('career_map_skills');
      final decoded = raw == null ? <String, dynamic>{} : jsonDecodeSafe(raw);
      if (!mounted) return;
      setState(() {
        _events = events;
        _careerGoal = preferences.getString('career_goal');
        _mastery = decoded;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  Map<String, dynamic> jsonDecodeSafe(String value) {
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  double _match(EventItem event) {
    final goal = _careerGoal?.toLowerCase();
    final career =
        goal != null &&
        event.careerTags.any((tag) => tag.toLowerCase() == goal);
    final skillScore = event.skills.isEmpty
        ? 0.0
        : event.skills
                  .map((skill) => (_mastery[skill] as num?)?.toDouble() ?? 0)
                  .fold<double>(0, math.max) /
              10;
    return ((career ? 0.65 : 0.0) + skillScore.clamp(0, 0.35)).clamp(0, 1);
  }

  List<EventItem> _filtered(DateTime now) {
    final result = _events.where((event) {
      final status = event.statusAt(now);
      if (_filter == 'Phù hợp với tôi') return _match(event) > 0;
      if (_filter == 'Đang mở đăng ký') {
        return status == EventStatus.registrationOpen;
      }
      if (_filter == 'Cuộc thi' ||
          _filter == 'Hackathon' ||
          _filter == 'Hội chợ việc làm') {
        return event.type == _filter;
      }
      return true;
    }).toList();
    result.sort((a, b) => _match(b).compareTo(_match(a)));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final events = _filtered(now);
    final open = events
        .where((event) => event.statusAt(now) == EventStatus.registrationOpen)
        .toList();
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Launchpad', style: TextStyle(fontWeight: FontWeight.w800)),
            Text(
              'Contests, workshops & career fairs',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _error != null
          ? _errorState()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  _banner(open.isEmpty ? events : open),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        return ChoiceChip(
                          label: Text(filter),
                          selected: filter == _filter,
                          onSelected: (_) => setState(() => _filter = filter),
                          selectedColor: const Color(0xFF394A4D),
                          backgroundColor: _surface,
                          labelStyle: TextStyle(
                            color: filter == _filter ? Colors.white : _muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  _section(
                    'Đang mở đăng ký',
                    events
                        .where(
                          (e) =>
                              e.statusAt(now) == EventStatus.registrationOpen,
                        )
                        .toList(),
                    now,
                  ),
                  _section(
                    'Sắp mở và sắp diễn ra',
                    events.where((e) {
                      final status = e.statusAt(now);
                      return status == EventStatus.openingSoon ||
                          status == EventStatus.closedUpcoming;
                    }).toList(),
                    now,
                  ),
                  _section(
                    'Mùa trước, chuẩn bị cho lần sau',
                    events.where((e) {
                      final status = e.statusAt(now);
                      return status == EventStatus.ended ||
                          status == EventStatus.newSeasonUnknown;
                    }).toList(),
                    now,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _errorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: _muted, size: 42),
          const SizedBox(height: 12),
          const Text(
            'Không thể tải dữ liệu Launchpad',
            textAlign: TextAlign.center,
          ),
          TextButton(onPressed: _load, child: const Text('Thử lại')),
        ],
      ),
    ),
  );

  Widget _banner(List<EventItem> events) {
    final event = events.isEmpty ? null : events.first;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF3C3065), Color(0xFF1B3D47)],
        ),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.rocket_launch_rounded,
            color: Color(0xFF8CE6CF),
            size: 30,
          ),
          const SizedBox(height: 12),
          Text(
            event == null
                ? 'Chưa có đợt đăng ký nào đang mở, đây là các cuộc thi nên chuẩn bị cho mùa tới'
                : event.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          if (event != null) ...[
            const SizedBox(height: 6),
            Text(event.organizer, style: const TextStyle(color: _muted)),
            const SizedBox(height: 12),
            _matchChip(event),
            TextButton(
              onPressed: () => _open(event),
              child: const Text('Xem chi tiết'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _section(String title, List<EventItem> events, DateTime now) {
    if (events.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...events.map((event) => _eventCard(event, now)),
        ],
      ),
    );
  }

  Widget _eventCard(EventItem event, DateTime now) {
    final status = event.statusAt(now);
    return Card(
      color: _surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _open(event),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _matchChip(event),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                event.organizer,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _tag(event.type),
                  _tag(_statusText(event, status, now)),
                  if (event.notes != null)
                    _tag('Cần kiểm tra thông tin', warning: true),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                'Bạn sẽ luyện: ${event.skills.join(', ')}',
                style: const TextStyle(color: Color(0xFFB9F2DF), fontSize: 12),
              ),
              if (event.sourceUrl != null)
                Text(
                  'Đã xác minh ${_date(event.verifiedAt)} · Nguồn: ${Uri.tryParse(event.sourceUrl!)?.host ?? event.sourceUrl}',
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _matchChip(EventItem event) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFF344B4D),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      'Khớp ${(_match(event) * 100).round()}%',
      style: const TextStyle(
        color: Color(0xFFB9F2DF),
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _tag(String label, {bool warning = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFF594A2D) : const Color(0xFF302A3B),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: warning ? const Color(0xFFFFD98A) : _muted,
        fontSize: 10,
      ),
    ),
  );

  String _statusText(EventItem event, EventStatus status, DateTime now) {
    switch (status) {
      case EventStatus.registrationOpen:
        final days = event.registrationDeadline
            ?.difference(DateTime(now.year, now.month, now.day))
            .inDays;
        return days == null ? 'Đang mở đăng ký' : 'Còn $days ngày';
      case EventStatus.openingSoon:
        return 'Mở từ ${_date(event.registrationOpen, short: true)}';
      case EventStatus.closedUpcoming:
        return 'Đã đóng đăng ký, sắp diễn ra';
      case EventStatus.newSeasonUnknown:
        return 'Chưa có thông tin mùa mới';
      case EventStatus.ended:
        return 'Đã kết thúc';
    }
  }

  String _date(DateTime? date, {bool short = false}) => date == null
      ? ''
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}${short ? '' : '/${date.year}'}';

  void _open(EventItem event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
    );
  }
}
