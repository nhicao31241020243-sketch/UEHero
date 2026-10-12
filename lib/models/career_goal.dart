import 'package:flutter/material.dart';

class CareerGoal {
  const CareerGoal({
    required this.title,
    required this.icon,
    required this.skills,
  });

  final String title;
  final IconData icon;
  final List<CareerSkill> skills;
}

class CareerSkill {
  const CareerSkill(this.name, this.level);

  final String name;
  final int level;
}

const careerGoals = <CareerGoal>[
  CareerGoal(
    title: 'Business Analyst',
    icon: Icons.query_stats_rounded,
    skills: [
      CareerSkill('SQL', 6),
      CareerSkill('Power BI', 5),
      CareerSkill('Excel', 8),
      CareerSkill('Tư duy phân tích', 7),
      CareerSkill('Giao tiếp', 6),
      CareerSkill('Viết tài liệu yêu cầu', 5),
    ],
  ),
  CareerGoal(
    title: 'Data Analyst',
    icon: Icons.bar_chart_rounded,
    skills: [
      CareerSkill('SQL', 7),
      CareerSkill('Excel', 8),
      CareerSkill('Python', 5),
      CareerSkill('Power BI', 6),
      CareerSkill('Thống kê', 5),
      CareerSkill('Trực quan dữ liệu', 6),
    ],
  ),
  CareerGoal(
    title: 'Frontend Developer',
    icon: Icons.web_rounded,
    skills: [
      CareerSkill('HTML & CSS', 7),
      CareerSkill('JavaScript', 6),
      CareerSkill('Flutter', 5),
      CareerSkill('Git', 6),
      CareerSkill('Responsive UI', 6),
      CareerSkill('Debugging', 5),
    ],
  ),
  CareerGoal(
    title: 'Digital Marketing',
    icon: Icons.campaign_rounded,
    skills: [
      CareerSkill('Content Marketing', 7),
      CareerSkill('SEO', 5),
      CareerSkill('Social Media', 7),
      CareerSkill('Google Analytics', 5),
      CareerSkill('Quảng cáo số', 6),
      CareerSkill('Sáng tạo nội dung', 8),
    ],
  ),
  CareerGoal(
    title: 'E-commerce Specialist',
    icon: Icons.shopping_bag_rounded,
    skills: [
      CareerSkill('Quản lý sàn TMĐT', 6),
      CareerSkill('Excel', 7),
      CareerSkill('Phân tích bán hàng', 6),
      CareerSkill('Vận hành đơn hàng', 7),
      CareerSkill('Digital Marketing', 5),
      CareerSkill('Chăm sóc khách hàng', 7),
    ],
  ),
  CareerGoal(
    title: 'Product Manager',
    icon: Icons.rocket_launch_rounded,
    skills: [
      CareerSkill('Product Thinking', 6),
      CareerSkill('Agile & Scrum', 5),
      CareerSkill('Phân tích dữ liệu', 6),
      CareerSkill('Giao tiếp', 7),
      CareerSkill('Roadmap sản phẩm', 5),
      CareerSkill('Nghiên cứu người dùng', 6),
    ],
  ),
];

CareerGoal? careerGoalByTitle(String? title) {
  for (final goal in careerGoals) {
    if (goal.title == title) return goal;
  }
  return null;
}
