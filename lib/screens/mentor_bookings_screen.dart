import 'dart:async';

import 'package:flutter/material.dart';

import '../config/demo_config.dart';
import '../data/mentor_demo_data.dart';
import '../models/mentor_booking.dart';
import '../models/mentor_model.dart';
import '../services/mentor_booking_service.dart';

class MentorBookingsScreen extends StatefulWidget {
  const MentorBookingsScreen({super.key});

  @override
  State<MentorBookingsScreen> createState() => _MentorBookingsScreenState();
}

class _MentorBookingsScreenState extends State<MentorBookingsScreen> {
  static const _background = Color(0xFF100E19);
  static const _accent = Color(0xFFBFA8FF);

  final _service = MentorBookingService.instance;
  late final Map<String, Mentor> _mentorsById = {
    for (final mentor in MentorRepository.getMentors()) mentor.id: mentor,
  };
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _service.addListener(_changed);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await _service.initialize();
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error.toString());
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_changed);
    super.dispose();
  }

  Future<void> _cancel(MentorBooking booking) async {
    try {
      await _service.cancel(booking.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã hủy lịch hẹn.')));
    } catch (error) {
      _showError('Không thể hủy lịch: $error');
    }
  }

  Future<void> _confirmDemo(MentorBooking booking) async {
    try {
      await _service.markConfirmed(booking.id);
    } catch (error) {
      _showError('Không thể xác nhận lịch: $error');
    }
  }

  Future<void> _completeDemo(MentorBooking booking) async {
    try {
      await _service.markCompleted(booking.id);
      if (!mounted) return;
      final actionItems = await showModalBottomSheet<List<String>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _ActionItemsSheet(),
      );
      if (!mounted || actionItems == null) return;
      await _service.addActionItems(booking.id, actionItems);
    } catch (error) {
      _showError('Không thể cập nhật buổi gặp: $error');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final groups = [
      (
        status: MentorBookingStatus.pending,
        title: 'Chờ xác nhận',
        color: const Color(0xFFFFD782),
      ),
      (
        status: MentorBookingStatus.confirmed,
        title: 'Đã hẹn',
        color: const Color(0xFF9EDCCB),
      ),
      (status: MentorBookingStatus.completed, title: 'Đã gặp', color: _accent),
      (
        status: MentorBookingStatus.cancelled,
        title: 'Đã hủy',
        color: const Color(0xFFBDB7C9),
      ),
    ];
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        title: const Text('Lịch hẹn của tôi'),
      ),
      body: SafeArea(
        child: !_service.isInitialized && _loadError == null
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : _loadError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Không tải được lịch hẹn: $_loadError',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFFFA6A6)),
                  ),
                ),
              )
            : _service.bookings.isEmpty
            ? const _EmptyBookings()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  for (final group in groups)
                    if (_service.listByStatus(group.status).isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                        child: Text(
                          '${group.title} · ${_service.listByStatus(group.status).length}',
                          style: TextStyle(
                            color: group.color,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      for (final booking in _service.listByStatus(group.status))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BookingCard(
                            booking: booking,
                            mentor: _mentorsById[booking.mentorId],
                            onCancel:
                                booking.status == MentorBookingStatus.pending ||
                                    booking.status ==
                                        MentorBookingStatus.confirmed
                                ? () => _cancel(booking)
                                : null,
                            onDemoConfirm:
                                kMentorDemoControls &&
                                    booking.status ==
                                        MentorBookingStatus.pending
                                ? () => _confirmDemo(booking)
                                : null,
                            onDemoComplete:
                                kMentorDemoControls &&
                                    booking.status ==
                                        MentorBookingStatus.confirmed
                                ? () => _completeDemo(booking)
                                : null,
                          ),
                        ),
                    ],
                ],
              ),
      ),
    );
  }
}

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.event_note_rounded,
            color: Color(0xFFBFA8FF),
            size: 44,
          ),
          const SizedBox(height: 12),
          const Text(
            'Bạn chưa có lịch hẹn nào',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Quay lại danh sách mentor để gửi yêu cầu đặt lịch.',
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

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.mentor,
    required this.onCancel,
    required this.onDemoConfirm,
    required this.onDemoComplete,
  });

  final MentorBooking booking;
  final Mentor? mentor;
  final VoidCallback? onCancel;
  final VoidCallback? onDemoConfirm;
  final VoidCallback? onDemoComplete;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFF211D2B),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.person_pin_circle_rounded,
              color: Color(0xFFBFA8FF),
              size: 21,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mentor?.name ?? 'Mentor mẫu',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _StatusBadge(status: booking.status),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          booking.slot == null
              ? 'Chưa có khung giờ · gửi câu hỏi'
              : _formatSlot(booking.slot!),
          style: const TextStyle(color: Color(0xFFCEC9D7), fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          'Mục đích: ${mentorPurposeLabel(booking.purpose)}',
          style: const TextStyle(color: Color(0xFFBDB7C9), fontSize: 12),
        ),
        if (booking.question.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            booking.question,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFCEC9D7),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
        if (booking.actionItems.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'Việc cần làm',
            style: TextStyle(
              color: Color(0xFFD8CDF8),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          for (final item in booking.actionItems)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '• $item',
                style: const TextStyle(color: Color(0xFFCEC9D7), fontSize: 12),
              ),
            ),
        ],
        if (onCancel != null || onDemoConfirm != null || onDemoComplete != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onCancel != null)
                  OutlinedButton(
                    onPressed: onCancel,
                    child: const Text('Hủy lịch'),
                  ),
                if (onDemoConfirm != null)
                  FilledButton.tonal(
                    onPressed: onDemoConfirm,
                    child: const Text('Demo · Giả lập mentor xác nhận'),
                  ),
                if (onDemoComplete != null)
                  FilledButton.tonal(
                    onPressed: onDemoComplete,
                    child: const Text('Demo · Giả lập đã gặp'),
                  ),
              ],
            ),
          ),
      ],
    ),
  );

  String _formatSlot(DateTime slot) {
    final local = slot.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} · $hour:$minute';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MentorBookingStatus.pending => const Color(0xFFFFD782),
      MentorBookingStatus.confirmed => const Color(0xFF9EDCCB),
      MentorBookingStatus.completed => const Color(0xFFBFA8FF),
      _ => const Color(0xFFBDB7C9),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        mentorBookingStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionItemsSheet extends StatefulWidget {
  const _ActionItemsSheet();

  @override
  State<_ActionItemsSheet> createState() => _ActionItemsSheetState();
}

class _ActionItemsSheetState extends State<_ActionItemsSheet> {
  final _controllers = List.generate(3, (_) => TextEditingController());
  bool _showValidation = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final items = _controllers
        .map((controller) => controller.text.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (items.isEmpty) {
      setState(() => _showValidation = true);
      return;
    }
    Navigator.of(context).pop(items);
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    decoration: const BoxDecoration(
      color: Color(0xFF211D2B),
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ghi 1-3 việc cần làm sau buổi gặp',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < _controllers.length; index++) ...[
            TextField(
              controller: _controllers[index],
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Việc ${index + 1}',
                labelStyle: const TextStyle(color: Color(0xFFCEC9D7)),
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (_showValidation)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Ghi ít nhất một việc hoặc chọn Bỏ qua.',
                style: TextStyle(color: Color(0xFFFFD782), fontSize: 12),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Bỏ qua'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Lưu việc'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
