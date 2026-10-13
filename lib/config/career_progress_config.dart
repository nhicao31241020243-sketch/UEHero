import '../models/career_progress.dart';

class CareerNodeConfig {
  const CareerNodeConfig({
    required this.id,
    required this.title,
    required this.description,
    required this.threshold,
    required this.icon,
    this.tasks = const [],
  });

  final String id;
  final String title;
  final String description;
  final int threshold;
  final String icon;
  final List<String> tasks;
}

class CareerRankConfig {
  const CareerRankConfig(this.name, this.minimumPoints);

  final String name;
  final int minimumPoints;
}

const Map<ProgressEventType, int> progressPoints = {
  ProgressEventType.flashcardCompleted: 20,
  ProgressEventType.skillDrillCompleted: 20,
  ProgressEventType.cvFirstCheck: 25,
  ProgressEventType.cvScoreImproved: 10,
  ProgressEventType.weeklyTaskCompleted: 5,
  ProgressEventType.mockInterviewCompleted: 30,
  ProgressEventType.jobApplied: 10,
  ProgressEventType.mentorBooked: 10,
  ProgressEventType.mentorCompleted: 20,
  ProgressEventType.eventRegistered: 5,
  ProgressEventType.eventCheckedIn: 15,
  ProgressEventType.gpaUpdated: 5,
  ProgressEventType.profileCompleted: 5,
  ProgressEventType.debugGrant: 100,
};

const List<CareerRankConfig> careerRanks = [
  CareerRankConfig('Cadet', 0),
  CareerRankConfig('Explorer', 50),
  CareerRankConfig('Navigator', 120),
  CareerRankConfig('Commander', 220),
  CareerRankConfig('Captain', 350),
];

const List<CareerNodeConfig> careerNodes = [
  CareerNodeConfig(
    id: 'launch-pad',
    title: 'Launch Pad',
    description: 'Bắt đầu hành trình nghề nghiệp của bạn.',
    threshold: 0,
    icon: 'rocket_launch',
    tasks: ['Hoàn thiện hồ sơ cá nhân'],
  ),
  CareerNodeConfig(
    id: 'foundation',
    title: 'Foundation',
    description: 'Xây nền tảng kỹ năng và thói quen học tập.',
    threshold: 50,
    icon: 'auto_stories',
    tasks: ['Hoàn thành một bộ flashcard', 'Cập nhật GPA'],
  ),
  CareerNodeConfig(
    id: 'skill-forge',
    title: 'Skill Forge',
    description: 'Rèn luyện kỹ năng phù hợp với mục tiêu.',
    threshold: 120,
    icon: 'construction',
    tasks: ['Hoàn thành Skill Drills', 'Hoàn thành task trong Weekly Plan'],
  ),
  CareerNodeConfig(
    id: 'portfolio-station',
    title: 'Portfolio Station',
    description: 'Biến kỹ năng thành một hồ sơ nổi bật.',
    threshold: 220,
    icon: 'folder_special',
    tasks: ['Chấm CV', 'Cải thiện điểm CV'],
  ),
  CareerNodeConfig(
    id: 'interview-orbit',
    title: 'Interview Orbit',
    description: 'Luyện tập để tự tin trước nhà tuyển dụng.',
    threshold: 280,
    icon: 'record_voice_over',
    tasks: ['Hoàn thành mock interview', 'Tham gia một sự kiện'],
  ),
  CareerNodeConfig(
    id: 'job-galaxy',
    title: 'Job Galaxy',
    description: 'Sẵn sàng cất cánh tới cơ hội tiếp theo.',
    threshold: 350,
    icon: 'work',
    tasks: ['Ứng tuyển một công việc phù hợp'],
  ),
];
