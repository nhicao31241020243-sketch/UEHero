class JobSkillRequirement {
  const JobSkillRequirement(this.name, this.level);

  final String name;
  final int level;
}

class StudentJob {
  const StudentJob({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.workMode,
    required this.type,
    required this.postedHoursAgo,
    required this.category,
    required this.url,
    required this.requirements,
    required this.responsibilities,
  });

  final String id;
  final String title;
  final String company;
  final String location;
  final String salary;
  final String workMode;
  final String type;
  final int postedHoursAgo;
  final String category;
  final String url;
  final List<JobSkillRequirement> requirements;
  final List<String> responsibilities;

  String get logoLetter => company.substring(0, 1).toUpperCase();
}

const studentJobs = <StudentJob>[
  StudentJob(
    id: 'ba-intern-nova',
    title: 'Business Analyst Intern',
    company: 'Nova Analytics',
    location: 'TP. Hồ Chí Minh',
    salary: '4–6 triệu/tháng',
    workMode: 'Hybrid',
    type: 'Thực tập',
    postedHoursAgo: 2,
    category: 'Job Fair',
    url: 'https://example.com/jobs/business-analyst-intern',
    requirements: [
      JobSkillRequirement('SQL', 6),
      JobSkillRequirement('Excel', 6),
      JobSkillRequirement('Power BI', 5),
      JobSkillRequirement('Tư duy phân tích', 6),
    ],
    responsibilities: [
      'Thu thập và phân tích yêu cầu từ các phòng ban.',
      'Xây dựng báo cáo theo dõi hoạt động bằng Excel và Power BI.',
      'Hỗ trợ kiểm thử quy trình và ghi nhận phản hồi.',
    ],
  ),
  StudentJob(
    id: 'data-intern-lumen',
    title: 'Data Analyst Intern',
    company: 'Lumen Digital',
    location: 'TP. Hồ Chí Minh',
    salary: '5–8 triệu/tháng',
    workMode: 'Onsite',
    type: 'Thực tập',
    postedHoursAgo: 5,
    category: 'Thực tập',
    url: 'https://example.com/jobs/data-analyst-intern',
    requirements: [
      JobSkillRequirement('SQL', 6),
      JobSkillRequirement('Python', 5),
      JobSkillRequirement('Excel', 6),
      JobSkillRequirement('Power BI', 5),
      JobSkillRequirement('Thống kê', 5),
    ],
    responsibilities: [
      'Làm sạch dữ liệu và xây dựng báo cáo phân tích.',
      'Tìm xu hướng trong dữ liệu hành vi khách hàng.',
      'Trình bày phát hiện cho nhóm sản phẩm và marketing.',
    ],
  ),
  StudentJob(
    id: 'frontend-parttime-orbit',
    title: 'Frontend Developer',
    company: 'Orbit Studio',
    location: 'Quận 3, TP. Hồ Chí Minh',
    salary: '40–60 nghìn/giờ',
    workMode: 'Hybrid',
    type: 'Part-time',
    postedHoursAgo: 9,
    category: 'Part-time',
    url: 'https://example.com/jobs/frontend-part-time',
    requirements: [
      JobSkillRequirement('HTML & CSS', 6),
      JobSkillRequirement('JavaScript', 6),
      JobSkillRequirement('Git', 4),
      JobSkillRequirement('Responsive UI', 5),
    ],
    responsibilities: [
      'Phát triển giao diện web tương thích nhiều kích thước màn hình.',
      'Phối hợp với designer để hoàn thiện trải nghiệm người dùng.',
      'Tham gia review và kiểm thử tính năng trước khi phát hành.',
    ],
  ),
  StudentJob(
    id: 'marketing-fresher-mint',
    title: 'Digital Marketing Fresher',
    company: 'Mint Creative',
    location: 'TP. Hồ Chí Minh',
    salary: '7–10 triệu/tháng',
    workMode: 'Remote',
    type: 'Fresher',
    postedHoursAgo: 16,
    category: 'Fresher',
    url: 'https://example.com/jobs/digital-marketing-fresher',
    requirements: [
      JobSkillRequirement('SEO', 5),
      JobSkillRequirement('Content Marketing', 6),
      JobSkillRequirement('Social Media', 5),
      JobSkillRequirement('Google Analytics', 4),
    ],
    responsibilities: [
      'Lên lịch nội dung cho các kênh mạng xã hội.',
      'Theo dõi hiệu quả chiến dịch và đề xuất tối ưu.',
      'Phối hợp sản xuất nội dung theo định hướng thương hiệu.',
    ],
  ),
  StudentJob(
    id: 'ecommerce-intern-peak',
    title: 'E-commerce Operations Intern',
    company: 'Peak Retail',
    location: 'Bình Thạnh, TP. Hồ Chí Minh',
    salary: '4–5 triệu/tháng',
    workMode: 'Onsite',
    type: 'Thực tập',
    postedHoursAgo: 22,
    category: 'Thực tập',
    url: 'https://example.com/jobs/ecommerce-operations-intern',
    requirements: [
      JobSkillRequirement('Quản lý sàn TMĐT', 5),
      JobSkillRequirement('Excel', 5),
      JobSkillRequirement('Vận hành đơn hàng', 5),
      JobSkillRequirement('Phân tích bán hàng', 4),
    ],
    responsibilities: [
      'Cập nhật nội dung sản phẩm trên các sàn thương mại điện tử.',
      'Theo dõi đơn hàng, tồn kho và chương trình khuyến mãi.',
      'Tổng hợp kết quả bán hàng theo tuần.',
    ],
  ),
  StudentJob(
    id: 'product-intern-spark',
    title: 'Associate Product Intern',
    company: 'Spark Labs',
    location: 'TP. Hồ Chí Minh',
    salary: '5–7 triệu/tháng',
    workMode: 'Hybrid',
    type: 'Thực tập',
    postedHoursAgo: 31,
    category: 'Job Fair',
    url: 'https://example.com/jobs/associate-product-intern',
    requirements: [
      JobSkillRequirement('Product Thinking', 5),
      JobSkillRequirement('Agile & Scrum', 4),
      JobSkillRequirement('Roadmap sản phẩm', 4),
      JobSkillRequirement('Nghiên cứu người dùng', 5),
    ],
    responsibilities: [
      'Tổng hợp phản hồi và nhu cầu của người dùng.',
      'Hỗ trợ xây dựng user story và sắp xếp backlog.',
      'Theo dõi tiến độ tính năng với nhóm thiết kế và kỹ thuật.',
    ],
  ),
];

enum JobApplicationStatus {
  saved('Đã lưu'),
  applied('Đã ứng tuyển'),
  interview('Phỏng vấn'),
  result('Kết quả');

  const JobApplicationStatus(this.label);

  final String label;

  static JobApplicationStatus fromName(String? name) {
    return JobApplicationStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => JobApplicationStatus.saved,
    );
  }
}

const studentJobFilters = [
  'Tất cả',
  'Phù hợp với tôi',
  'Thực tập',
  'Part-time',
  'Fresher',
  'Job Fair',
];
