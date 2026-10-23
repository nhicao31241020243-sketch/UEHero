import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/event_item.dart';
import 'widgets/event_catalog_widgets.dart';
import 'widgets/event_poster.dart';
import 'widgets/space_glass_widgets.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    required this.event,
    required this.matchPercent,
    required this.saved,
    required this.planned,
    required this.reminderEnabled,
    required this.onToggleSaved,
    required this.onAddToPlan,
    required this.onToggleReminder,
    super.key,
  });

  final EventItem event;
  final int matchPercent;
  final bool saved;
  final bool planned;
  final bool reminderEnabled;
  final Future<bool> Function() onToggleSaved;
  final Future<bool> Function() onAddToPlan;
  final Future<bool> Function(bool enabled) onToggleReminder;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _expanded = false;
  bool _busy = false;
  late bool _saved = widget.saved;
  late bool _planned = widget.planned;
  late bool _reminderEnabled = widget.reminderEnabled;

  @override
  void didUpdateWidget(covariant EventDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.saved != widget.saved) _saved = widget.saved;
    if (oldWidget.planned != widget.planned) _planned = widget.planned;
    if (oldWidget.reminderEnabled != widget.reminderEnabled) {
      _reminderEnabled = widget.reminderEnabled;
    }
  }

  Future<void> _run(
    Future<bool> Function() action, {
    VoidCallback? onSuccess,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (await action() && mounted) onSuccess?.call();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openUrl(String? value) async {
    if (value == null) {
      _message('Chưa có liên kết chính thức được xác minh.');
      return;
    }
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      _message('Liên kết này không hợp lệ.');
      return;
    }
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _message('Không thể mở liên kết: $value');
      }
    } on PlatformException {
      _message('Không thể mở liên kết trên thiết bị này.');
    }
  }

  Future<void> _share() async {
    final url = widget.event.officialUrl ?? widget.event.sourceUrl;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: url == null
              ? widget.event.title
              : '${widget.event.title}\n$url',
        ),
      );
    } on PlatformException {
      _message('Không thể chia sẻ sự kiện lúc này.');
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Chi tiết sự kiện'),
        actions: [
          IconButton(
            tooltip: _saved ? 'Bỏ lưu' : 'Lưu sự kiện',
            onPressed: () => _run(
              widget.onToggleSaved,
              onSuccess: () => setState(() => _saved = !_saved),
            ),
            icon: Icon(
              _saved ? Icons.favorite : Icons.favorite_border,
              color: _saved ? const Color(0xFFFF8AA0) : Colors.white,
            ),
          ),
          IconButton(
            tooltip: 'Chia sẻ sự kiện',
            onPressed: _share,
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 1.72,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  EventPoster(
                    imageUrl: event.posterUrl,
                    sourceUrl: event.sourceUrl,
                    borderRadius: BorderRadius.zero,
                    placeholderIcon: eventTypeIcon(event.type),
                    fallbackColors: eventTypeColors(event.type),
                    eventType: event.type,
                    organizer: event.organizer,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xF00B0D19)],
                        stops: [0.2, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            event.organizer,
            style: const TextStyle(
              color: Color(0xFFD7D0E6),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge(event.type, const Color(0x773D3473)),
              _badge(eventStatusLabel(event, now), const Color(0x77305A4F)),
              if (event.needsVerification)
                _badge('Cần kiểm tra thông tin', const Color(0x77765130)),
            ],
          ),
          const SizedBox(height: 18),
          _infoSection(now),
          const SizedBox(height: 18),
          const Text(
            'Giới thiệu',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    event.description.isEmpty
                        ? 'Ban tổ chức chưa cung cấp phần giới thiệu chi tiết. Hãy xem trang chính thức để kiểm tra thông tin mới nhất.'
                        : event.description,
                    maxLines: _expanded ? null : 4,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFD6D2E1),
                      height: 1.45,
                    ),
                  ),
                ),
                if (event.description.length > 180)
                  TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(_expanded ? 'Thu gọn' : 'Xem thêm'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _tagSection('Nghề liên quan', event.relatedCareers),
          const SizedBox(height: 16),
          _tagSection('Kỹ năng sẽ luyện', event.skills),
          if (event.previousSeason != null) ...[
            const SizedBox(height: 18),
            const Text(
              'Mùa trước',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            GlassCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.history_rounded, color: Color(0xFFFFD166)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(event.previousSeason!)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Đơn vị tổ chức',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _organizationLogos(event),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  event.organizer,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Nguồn thông tin',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.verifiedAt == null
                      ? 'Ngày xác minh: Chưa xác minh'
                      : 'Đã xác minh ${eventDateLabel(event.verifiedAt)}',
                  style: const TextStyle(color: Color(0xFFD6D2E1)),
                ),
                if (event.sourceUrl != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _openUrl(event.sourceUrl),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Mở trang nguồn'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 150),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: const Color(0xEE10101C),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassButton(
                onPressed: _busy || event.officialUrl == null
                    ? null
                    : () => _openUrl(event.officialUrl),
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.open_in_new, size: 18),
                    SizedBox(width: 8),
                    Text('Xem trang chính thức'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                      onPressed: _busy || event.registrationDeadline == null
                          ? null
                          : () => _run(
                              () => widget.onToggleReminder(!_reminderEnabled),
                              onSuccess: () => setState(() {
                                _reminderEnabled = !_reminderEnabled;
                                _planned = true;
                              }),
                            ),
                      icon: Icon(
                        _reminderEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_none,
                        size: 18,
                      ),
                      label: Text(
                        _reminderEnabled ? 'Đang nhắc' : 'Nhắc tôi',
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                      onPressed: _busy || _planned
                          ? null
                          : () => _run(
                              widget.onAddToPlan,
                              onSuccess: () => setState(() => _planned = true),
                            ),
                      icon: Icon(
                        _planned ? Icons.check_circle : Icons.add_task,
                        size: 18,
                      ),
                      label: Text(
                        _planned ? 'Trong kế hoạch' : 'Thêm vào kế hoạch',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Widget _organizationLogos(EventItem event) {
    final sponsors = event.sponsorLogoUrls.take(4).toList();
    return SizedBox(
      width: 44 + sponsors.length * 24,
      height: 44,
      child: Stack(
        children: [
          _logoCircle(event.organizerLogoUrl, event.organizer, 0),
          for (var index = 0; index < sponsors.length; index++)
            _logoCircle(sponsors[index], 'Nhà tài trợ', 28 * (index + 1)),
        ],
      ),
    );
  }

  Widget _logoCircle(String? url, String label, double left) => Positioned(
    left: left,
    top: 0,
    child: ClipOval(
      child: SizedBox(
        width: 44,
        height: 44,
        child: url == null
            ? _logoFallback(label)
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, _) => _logoFallback(label),
                errorWidget: (_, _, _) => _logoFallback(label),
              ),
      ),
    ),
  );

  Widget _logoFallback(String label) => ColoredBox(
    color: const Color(0xFF55477B),
    child: Center(
      child: Text(
        label.isEmpty ? '?' : label.substring(0, 1).toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );

  Widget _infoSection(DateTime now) => GlassCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      children: [
        _infoRow(
          Icons.hourglass_bottom_rounded,
          'Hạn đăng ký',
          eventDateLabel(widget.event.registrationDeadline),
          widget.event.registrationDeadline == null
              ? null
              : _countdown(widget.event, now),
        ),
        _divider(),
        _infoRow(
          Icons.event_available_outlined,
          'Thời gian diễn ra',
          widget.event.eventStart == null && widget.event.eventEnd == null
              ? 'Chưa công bố'
              : '${eventDateLabel(widget.event.eventStart)}${widget.event.eventEnd == null ? '' : ' – ${eventDateLabel(widget.event.eventEnd)}'}',
        ),
        _divider(),
        _infoRow(
          Icons.wifi_tethering_rounded,
          'Hình thức',
          widget.event.format ?? 'Chưa công bố',
        ),
        if (widget.event.audience != null) ...[
          _divider(),
          _infoRow(
            Icons.groups_2_outlined,
            'Đối tượng',
            widget.event.audience!,
          ),
        ],
        if (widget.event.location != null) ...[
          _divider(),
          _infoRow(Icons.place_outlined, 'Địa điểm', widget.event.location!),
        ],
        if (widget.event.participationUrl != null) ...[
          _divider(),
          _infoRow(
            Icons.link_rounded,
            'Link tham gia',
            widget.event.participationUrl!,
          ),
        ],
      ],
    ),
  );

  String? _countdown(EventItem event, DateTime now) {
    final duration = event.countdownAt(now);
    if (duration == null) return null;
    if (duration == Duration.zero) return 'Đã hết hạn';
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    return days > 0 ? 'Còn $days ngày $hours giờ' : 'Còn $hours giờ';
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, [
    String? extra,
  ]) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: const Color(0xFFBFA8FF), size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFFB7B2C7), fontSize: 11),
            ),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (extra != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  extra,
                  style: const TextStyle(
                    color: Color(0xFFFFD166),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
  );

  Widget _tagSection(String title, List<String> values) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      if (values.isEmpty)
        const Text(
          'Chưa có thông tin',
          style: TextStyle(color: Color(0xFFB7B2C7)),
        )
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              Chip(
                label: Text(value),
                backgroundColor: const Color(0xAA242236),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
          ],
        ),
    ],
  );

  Widget _badge(String label, Color color) => Container(
    constraints: const BoxConstraints(maxWidth: 220),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}
