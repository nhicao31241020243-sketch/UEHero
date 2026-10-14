import 'package:flutter/material.dart';

import '../config/it_fields.dart';
import '../models/mentor_model.dart';
import '../services/mentor_booking_service.dart';
import '../widgets/mentor_avatar.dart';

class MentorProfileScreen extends StatefulWidget {
  const MentorProfileScreen({required this.mentor, super.key});

  final Mentor mentor;

  @override
  State<MentorProfileScreen> createState() => _MentorProfileScreenState();
}

class _MentorProfileScreenState extends State<MentorProfileScreen> {
  Mentor get mentor => widget.mentor;

  static const _background = Color(0xFF100E19);
  static const _surface = Color(0xFF211D2B);
  static const _accent = Color(0xFFBFA8FF);

  Future<void> _openBookingForm() async {
    final slots = List<DateTime>.of(mentor.availableSlots)..sort();
    final formKey = GlobalKey<FormState>();
    var selectedSlot = slots.isEmpty ? null : slots.first;
    var selectedPurpose = 'cv';
    var question = '';

    try {
      final request = await showModalBottomSheet<_BookingRequest>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, setSheetState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
              decoration: const BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        slots.isEmpty
                            ? 'Gửi câu hỏi cho ${mentor.name}'
                            : 'Đặt lịch với ${mentor.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (mentor.isDemo) ...[
                        const SizedBox(height: 7),
                        const Text(
                          'Mentor mẫu, yêu cầu chỉ lưu trên máy này',
                          style: TextStyle(
                            color: Color(0xFFBDB7C9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (slots.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        DropdownButtonFormField<DateTime>(
                          initialValue: selectedSlot,
                          dropdownColor: _surface,
                          decoration: const InputDecoration(
                            labelText: 'Khung giờ',
                            labelStyle: TextStyle(color: Color(0xFFCEC9D7)),
                          ),
                          style: const TextStyle(color: Colors.white),
                          items: [
                            for (final slot in slots)
                              DropdownMenuItem(
                                value: slot,
                                child: Text(_formatSlot(slot)),
                              ),
                          ],
                          onChanged: (value) =>
                              setSheetState(() => selectedSlot = value),
                        ),
                      ],
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPurpose,
                        dropdownColor: _surface,
                        decoration: const InputDecoration(
                          labelText: 'Mục đích gặp',
                          labelStyle: TextStyle(color: Color(0xFFCEC9D7)),
                        ),
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: 'cv', child: Text('CV')),
                          DropdownMenuItem(
                            value: 'interview',
                            child: Text('Phỏng vấn'),
                          ),
                          DropdownMenuItem(
                            value: 'career_direction',
                            child: Text('Định hướng nghề'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setSheetState(() => selectedPurpose = value);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        maxLength: 200,
                        minLines: 3,
                        maxLines: 4,
                        onChanged: (value) => question = value,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: slots.isEmpty
                              ? 'Câu hỏi của bạn'
                              : 'Bạn muốn trao đổi điều gì?',
                          labelStyle: const TextStyle(color: Color(0xFFCEC9D7)),
                          hintText: 'Nhập nội dung tối đa 200 ký tự',
                          hintStyle: const TextStyle(color: Color(0xFF888294)),
                        ),
                        validator: (value) =>
                            slots.isEmpty &&
                                (value == null || value.trim().isEmpty)
                            ? 'Hãy nhập câu hỏi để gửi cho mentor.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            Navigator.of(sheetContext).pop(
                              _BookingRequest(
                                slot: selectedSlot,
                                purpose: selectedPurpose,
                                question: question.trim(),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: const Color(0xFF211A30),
                          ),
                          child: Text(
                            slots.isEmpty ? 'Gửi câu hỏi' : 'Gửi yêu cầu',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      if (!mounted || request == null) return;
      await MentorBookingService.instance.create(
        mentorId: mentor.id,
        slot: request.slot,
        purpose: request.purpose,
        question: request.question,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi yêu cầu, trạng thái: Chờ xác nhận'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể gửi yêu cầu: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = List<DateTime>.of(mentor.availableSlots)..sort();
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        title: const Text('Hồ sơ mentor'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            Center(child: MentorAvatar(mentor: mentor, size: 104)),
            const SizedBox(height: 16),
            Text(
              mentor.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mentor.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _accent,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${mentor.yearsExperience} năm kinh nghiệm · ${mentor.organizationLabel}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFBDB7C9), fontSize: 12),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Ngành chuyên môn',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final id in mentor.fieldIds)
                    _Tag(label: itFieldName(id) ?? id),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Giới thiệu',
              child: Text(
                mentor.bio,
                style: const TextStyle(
                  color: Color(0xFFCEC9D7),
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Có thể giúp bạn',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final topic in mentor.topics) _Tag(label: topic.label),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Khung giờ tham khảo',
              child: slots.isEmpty
                  ? const Text(
                      'Chưa có lịch trống được cập nhật.',
                      style: TextStyle(color: Color(0xFFBDB7C9)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final slot in slots)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: Text(
                              _formatSlot(slot),
                              style: const TextStyle(
                                color: Color(0xFFCEC9D7),
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            const _SectionCard(
              title: 'Gặp mentor để làm gì?',
              child: Text(
                'Trao đổi về CV, phỏng vấn, portfolio hoặc định hướng học tập và nghề nghiệp.',
                style: TextStyle(
                  color: Color(0xFFCEC9D7),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _openBookingForm,
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: const Color(0xFF211A30),
                ),
                child: Text(
                  mentor.availableSlots.isEmpty ? 'Gửi câu hỏi' : 'Đặt lịch',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSlot(DateTime dateTime) {
    final date = '${dateTime.day}/${dateTime.month}';
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$date · $hour:$minute';
  }
}

class _BookingRequest {
  const _BookingRequest({
    required this.slot,
    required this.purpose,
    required this.question,
  });

  final DateTime? slot;
  final String purpose;
  final String question;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF211D2B),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFF363044),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFD8CDF8),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
