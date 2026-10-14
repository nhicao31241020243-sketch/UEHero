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
  final bool isDemo;
}
