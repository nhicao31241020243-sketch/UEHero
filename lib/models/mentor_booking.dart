class MentorBookingStatus {
  static const pending = 'pending';
  static const confirmed = 'confirmed';
  static const completed = 'completed';
  static const cancelled = 'cancelled';

  static const values = [pending, confirmed, completed, cancelled];
}

class MentorBooking {
  const MentorBooking({
    required this.id,
    required this.mentorId,
    required this.slot,
    required this.purpose,
    required this.question,
    required this.status,
    required this.actionItems,
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String mentorId;
  final DateTime? slot;
  final String purpose;
  final String question;
  final String status;
  final List<String> actionItems;
  final DateTime createdAt;
  final DateTime? completedAt;

  MentorBooking copyWith({
    DateTime? slot,
    String? purpose,
    String? question,
    String? status,
    List<String>? actionItems,
    DateTime? completedAt,
  }) => MentorBooking(
    id: id,
    mentorId: mentorId,
    slot: slot ?? this.slot,
    purpose: purpose ?? this.purpose,
    question: question ?? this.question,
    status: status ?? this.status,
    actionItems: actionItems ?? this.actionItems,
    createdAt: createdAt,
    completedAt: completedAt ?? this.completedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'mentorId': mentorId,
    'slot': slot?.toIso8601String(),
    'purpose': purpose,
    'question': question,
    'status': status,
    'actionItems': actionItems,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory MentorBooking.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String;
    if (!MentorBookingStatus.values.contains(status)) {
      throw FormatException('Trạng thái lịch mentor không hợp lệ: $status');
    }
    final actionItems = (json['actionItems'] as List<dynamic>? ?? const [])
        .cast<String>();
    if (actionItems.length > 3) {
      throw const FormatException('Một lịch mentor chỉ được có tối đa 3 việc.');
    }
    return MentorBooking(
      id: json['id'] as String,
      mentorId: json['mentorId'] as String,
      slot: json['slot'] == null
          ? null
          : DateTime.parse(json['slot'] as String),
      purpose: json['purpose'] as String,
      question: json['question'] as String? ?? '',
      status: status,
      actionItems: List.unmodifiable(actionItems),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );
  }
}

String mentorPurposeLabel(String purpose) => switch (purpose) {
  'cv' => 'CV',
  'interview' => 'Phỏng vấn',
  'career_direction' => 'Định hướng nghề',
  _ => purpose,
};

String mentorBookingStatusLabel(String status) => switch (status) {
  MentorBookingStatus.pending => 'Chờ xác nhận',
  MentorBookingStatus.confirmed => 'Đã hẹn',
  MentorBookingStatus.completed => 'Đã gặp',
  MentorBookingStatus.cancelled => 'Đã hủy',
  _ => status,
};
