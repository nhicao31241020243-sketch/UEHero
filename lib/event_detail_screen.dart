import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/event_item.dart';
import 'models/career_progress.dart';
import 'services/points_manager.dart';
import 'services/progress_service.dart';

class EventDetailScreen extends StatefulWidget {
  final EventItem event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  static const _background = Color(0xFF100E19);
  static const _surface = Color(0xFF211D2B);
  static const _muted = Color(0xFFAAA5B8);
  static const _accent = Color(0xFFBFA8FF);
  late SharedPreferences _preferences;
  bool _ready = false;
  bool _registered = false;
  bool _attended = false;
  bool _reminder = false;

  String get _id =>
      widget.event.id.isEmpty ? widget.event.title : widget.event.id;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    _preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _registered = _preferences.getBool('event_registered_$_id') ?? false;
      _attended = _preferences.getBool('event_attended_$_id') ?? false;
      _reminder = _preferences.getBool('event_reminder_$_id') ?? false;
      _ready = true;
    });
  }

  Future<void> _markRegistered() async {
    if (_registered) return;
    await _preferences.setBool('event_registered_$_id', true);
    PointsManager.instance.joinEvent(widget.event);
    await ProgressService.instance.initialize();
    await ProgressService.instance.awardPoints(
      ProgressEventType.eventRegistered,
      refId: 'event-registration-$_id',
      metadata: {'eventId': _id},
    );
    if (!mounted) return;
    setState(() => _registered = true);
    _message('Đã đánh dấu đăng ký sự kiện');
  }

  Future<void> _markAttended() async {
    if (!_registered || _attended) return;
    await _preferences.setBool('event_attended_$_id', true);
    await _increaseMastery();
    await ProgressService.instance.initialize();
    await ProgressService.instance.awardPoints(
      ProgressEventType.eventCheckedIn,
      refId: 'event-checkin-$_id',
      metadata: {'eventId': _id},
    );
    if (!mounted) return;
    setState(() => _attended = true);
    _message('Đã ghi nhận tham gia và cập nhật kỹ năng');
  }

  Future<void> _increaseMastery() async {
    final raw = _preferences.getString('career_map_skills');
    final mastery = <String, dynamic>{};
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) mastery.addAll(decoded.cast<String, dynamic>());
      } catch (_) {
        // An invalid legacy value is replaced with a valid skills map.
      }
    }
    for (final skill in widget.event.skills) {
      final current = (mastery[skill] as num?)?.toDouble() ?? 0;
      mastery[skill] = (current + 0.5).clamp(0, 10);
    }
    await _preferences.setString('career_map_skills', jsonEncode(mastery));
  }

  Future<void> _toggleReminder() async {
    final next = !_reminder;
    await _preferences.setBool('event_reminder_$_id', next);
    if (!mounted) return;
    setState(() => _reminder = next);
    _message(
      next
          ? 'Đã bật nhắc tôi khi mở đơn (TODO thông báo đẩy)'
          : 'Đã tắt nhắc tôi',
    );
  }

  Future<void> _openUrl(String? value) async {
    if (value == null) return;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) _message('Không thể mở liên kết: $value');
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final now = DateTime.now();
    final canAttend =
        _registered &&
        (event.eventStart == null || !now.isBefore(event.eventStart!));
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: const Text('Launchpad'),
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(event.organizer, style: const TextStyle(color: _muted)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(event.type),
                    _chip(event.statusAt(now).name),
                  ],
                ),
                const SizedBox(height: 20),
                _infoCard('Nghề liên quan', event.careerTags.join(' · ')),
                _infoCard('Bạn sẽ luyện', event.skills.join(' · ')),
                if (event.registrationDeadline != null)
                  _infoCard('Hạn đăng ký', _date(event.registrationDeadline)),
                if (event.eventStart != null || event.eventEnd != null)
                  _infoCard(
                    'Thời gian',
                    '${_date(event.eventStart)} - ${_date(event.eventEnd)}',
                  ),
                if (event.location != null)
                  _infoCard('Địa điểm', event.location!),
                if (event.fee != null) _infoCard('Lệ phí', event.fee!),
                if (event.lastSeason != null)
                  _infoCard('Mùa trước', event.lastSeason!),
                if (event.notes != null) ...[
                  const SizedBox(height: 12),
                  _infoCard('Cần kiểm tra thông tin', event.notes!),
                ],
                const SizedBox(height: 18),
                if (event.officialUrl != null)
                  OutlinedButton.icon(
                    onPressed: () => _openUrl(event.officialUrl),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Xem trang chính thức'),
                  ),
                if (event.sourceUrl != null)
                  OutlinedButton.icon(
                    onPressed: () => _openUrl(event.sourceUrl),
                    icon: const Icon(Icons.source_outlined),
                    label: const Text('Xem nguồn tin'),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _toggleReminder,
                        icon: Icon(
                          _reminder
                              ? Icons.notifications_active
                              : Icons.notifications_none,
                        ),
                        label: Text(_reminder ? 'Đã nhắc tôi' : 'Nhắc tôi'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _message('TODO: nối sự kiện vào Kế hoạch tuần'),
                        icon: const Icon(Icons.add_task),
                        label: const Text('Thêm vào kế hoạch'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _registered ? null : _markRegistered,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    _registered ? 'Đã đánh dấu đăng ký' : 'Đánh dấu đã đăng ký',
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: canAttend && !_attended ? _markAttended : null,
                  child: Text(
                    _attended
                        ? 'Đã đánh dấu đã tham gia'
                        : 'Đánh dấu đã tham gia',
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Thông tin mang tính tham khảo, hãy kiểm tra trang chính thức của ban tổ chức trước khi đăng ký',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
                ),
              ],
            ),
    );
  }

  Widget _infoCard(String title, String value) => Card(
    color: _surface,
    child: Padding(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: _accent, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(value),
        ],
      ),
    ),
  );

  Widget _chip(String text) => Chip(
    label: Text(text),
    backgroundColor: _surface,
    labelStyle: const TextStyle(color: _muted, fontSize: 12),
  );

  String _date(DateTime? date) => date == null
      ? 'Chưa có thông tin'
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
