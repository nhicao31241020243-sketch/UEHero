enum MentorTopic {
  cv,
  interview,
  careerDirection,
  portfolio,
  technical;

  String get label => switch (this) {
    MentorTopic.cv => 'CV',
    MentorTopic.interview => 'Phỏng vấn',
    MentorTopic.careerDirection => 'Định hướng nghề',
    MentorTopic.portfolio => 'Portfolio',
    MentorTopic.technical => 'Kỹ thuật',
  };
}

class MentorReview {
  const MentorReview({
    required this.author,
    required this.rating,
    required this.comment,
  });

  final String author;
  final int rating;
  final String comment;
}

class Mentor {
  const Mentor({
    required this.id,
    required this.name,
    required this.title,
    required this.yearsExperience,
    required this.organizationLabel,
    required this.bio,
    required this.topics,
    required this.fieldIds,
    required this.availableSlots,
    this.responseTime = '~24h',
    this.avatarAsset,
    this.avatarUrl,
    this.rating,
    this.sessionsCount = 0,
    this.reviews = const [],
    this.isDemo = false,
  });

  final String id;
  final String name;
  final String title;
  final int yearsExperience;
  final String organizationLabel;
  final String bio;
  final List<MentorTopic> topics;
  final List<String> fieldIds;
  final List<DateTime> availableSlots;
  final String responseTime;
  final String? avatarAsset;
  final String? avatarUrl;
  final double? rating;
  final int sessionsCount;
  final List<MentorReview> reviews;
  final bool isDemo;

  Mentor copyWith({
    String? responseTime,
    String? avatarAsset,
    String? avatarUrl,
    double? rating,
    int? sessionsCount,
    List<MentorReview>? reviews,
    List<DateTime>? availableSlots,
  }) => Mentor(
    id: id,
    name: name,
    title: title,
    yearsExperience: yearsExperience,
    organizationLabel: organizationLabel,
    bio: bio,
    topics: topics,
    fieldIds: fieldIds,
    availableSlots: availableSlots ?? this.availableSlots,
    responseTime: responseTime ?? this.responseTime,
    avatarAsset: avatarAsset ?? this.avatarAsset,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    rating: rating ?? this.rating,
    sessionsCount: sessionsCount ?? this.sessionsCount,
    reviews: reviews ?? this.reviews,
    isDemo: isDemo,
  );
}
