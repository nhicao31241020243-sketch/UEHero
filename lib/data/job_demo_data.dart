import '../models/student_job.dart';
import 'job_demo_data_extra.dart';

class JobField {
  const JobField(this.id, this.label);

  final String id;
  final String label;
}

const jobFields = <JobField>[
  JobField('software-engineering', 'Kỹ thuật phần mềm'),
  JobField('data-analytics', 'Phân tích dữ liệu'),
  JobField('cybersecurity', 'An ninh mạng'),
  JobField('cloud-devops', 'Cloud & DevOps'),
  JobField('ai-machine-learning', 'AI & Machine Learning'),
  JobField('ux-ui-design', 'UX/UI Design'),
  JobField('product-management', 'Product Management'),
  JobField('quality-assurance', 'Kiểm thử phần mềm'),
  JobField('business-analysis', 'Business Analysis'),
  JobField('database-engineering', 'Database Engineering'),
  JobField('game-development', 'Game Development'),
  JobField('blockchain-web3', 'Blockchain & Web3'),
  JobField('marketing', 'Marketing'),
  JobField('finance', 'Tài chính - Kế toán'),
  JobField('human-resources', 'Nhân sự'),
];

String jobFieldLabel(String fieldId) => jobFields
    .firstWhere(
      (field) => field.id == fieldId,
      orElse: () => const JobField('', 'Công nghệ thông tin'),
    )
    .label;

String? fieldIdForGoal(String? goal) {
  if (goal == null || goal.trim().isEmpty) return null;
  final normalized = goal.toLowerCase();
  if (normalized.contains('business analyst')) return 'business-analysis';
  if (normalized.contains('data analyst') || normalized.contains('data /')) {
    return 'data-analytics';
  }
  if (normalized.contains('frontend') ||
      normalized.contains('developer') ||
      normalized.contains('software')) {
    return 'software-engineering';
  }
  if (normalized.contains('security')) return 'cybersecurity';
  if (normalized.contains('cloud') || normalized.contains('devops')) {
    return 'cloud-devops';
  }
  if (normalized.contains('product')) return 'product-management';
  if (normalized.contains('design') || normalized.contains('ux')) {
    return 'ux-ui-design';
  }
  if (normalized.contains('test') || normalized.contains('quality')) {
    return 'quality-assurance';
  }
  if (normalized.contains('database')) return 'database-engineering';
  if (normalized.contains('game')) return 'game-development';
  if (normalized.contains('blockchain') || normalized.contains('web3')) {
    return 'blockchain-web3';
  }
  if (normalized.contains('ai') || normalized.contains('machine learning')) {
    return 'ai-machine-learning';
  }
  return null;
}

final jobDemoData = List<StudentJob>.unmodifiable([
  ..._buildDemoJobs(),
  ...buildExtraDemoJobs(),
]);

List<StudentJob> _buildDemoJobs() {
  final now = DateTime.now();
  StudentJob job({
    required String id,
    required String title,
    required String company,
    required String fieldId,
    required List<JobSkillRequirement> skills,
    required String salary,
    required double salaryMin,
    required String location,
    required JobWorkMode mode,
    required JobType type,
    required int postedHoursAgo,
    required String description,
  }) => StudentJob(
    id: id,
    title: title,
    company: company,
    fieldId: fieldId,
    requiredSkills: skills,
    salaryLabel: salary,
    salaryMin: salaryMin,
    location: location,
    workMode: mode,
    jobType: type,
    postedAt: now.subtract(Duration(hours: postedHoursAgo)),
    description: description,
    isDemo: true,
  );

  JobSkillRequirement skill(String key, String label, int level) =>
      JobSkillRequirement(skillKey: key, label: label, requiredLevel: level);

  return [
    job(
      id: 'ba-intern-nova',
      title: 'Business Analyst Intern',
      company: 'Nova Analytics',
      fieldId: 'business-analysis',
      skills: [
        skill('skill-sql', 'SQL', 5),
        skill('skill-excel', 'Excel', 5),
        skill('skill-power-bi', 'Power BI', 4),
      ],
      salary: '5–8 triệu/tháng',
      salaryMin: 5,
      location: 'TP. Hồ Chí Minh',
      mode: JobWorkMode.hybrid,
      type: JobType.internship,
      postedHoursAgo: 2,
      description: 'Thu thập yêu cầu từ các nhóm nghiệp vụ và mô tả thành user story.\nHỗ trợ dựng báo cáo theo dõi bằng Excel và Power BI.\nTham gia kiểm thử quy trình và ghi nhận phản hồi.',
    ),
    job(
      id: 'data-intern-lumen',
      title: 'Data Analyst Intern',
      company: 'Lumen Digital',
      fieldId: 'data-analytics',
      skills: [
        skill('skill-sql', 'SQL', 5),
        skill('skill-excel', 'Excel', 5),
        skill('skill-power-bi', 'Power BI', 4),
      ],
      salary: '5–8 triệu/tháng',
      salaryMin: 5,
      location: 'TP. Hồ Chí Minh',
      mode: JobWorkMode.onsite,
      type: JobType.internship,
      postedHoursAgo: 5,
      description: 'Làm sạch dữ liệu, xây dựng báo cáo và kiểm tra chất lượng chỉ số.\nHỗ trợ nhóm phân tích tìm xu hướng từ dữ liệu vận hành.\nTrình bày kết quả ngắn gọn cho các nhóm liên quan.',
    ),
    job(
      id: 'frontend-parttime-orbit',
      title: 'Frontend Developer',
      company: 'Orbit Studio',
      fieldId: 'software-engineering',
      skills: [
        skill('skill-figma-wireframe', 'Figma & Wireframe', 4),
        skill('skill-jira-confluence', 'Jira & Confluence', 3),
        skill('skill-agile-scrum', 'Agile & Scrum', 3),
      ],
      salary: '45–65 nghìn/giờ',
      salaryMin: 7,
      location: 'TP. Hồ Chí Minh',
      mode: JobWorkMode.hybrid,
      type: JobType.parttime,
      postedHoursAgo: 8,
      description: 'Phát triển giao diện web thích ứng với nhiều kích thước màn hình.\nPhối hợp cùng nhóm thiết kế để hoàn thiện trải nghiệm sản phẩm.\nTham gia review và kiểm thử tính năng trong từng sprint.',
    ),
    job(
      id: 'marketing-fresher-mint',
      title: 'UX/UI Design Intern',
      company: 'Mint Creative',
      fieldId: 'ux-ui-design',
      skills: [
        skill('skill-figma-wireframe', 'Figma & Wireframe', 5),
        skill('skill-requirements', 'Phân tích yêu cầu', 3),
        skill('skill-stakeholder-communication', 'Giao tiếp liên phòng ban', 3),
      ],
      salary: '4–7 triệu/tháng',
      salaryMin: 4,
      location: 'Đà Nẵng',
      mode: JobWorkMode.hybrid,
      type: JobType.internship,
      postedHoursAgo: 12,
      description: 'Hỗ trợ thiết kế luồng người dùng và nguyên mẫu trên Figma.\nTổng hợp phản hồi kiểm thử khả dụng cùng nhóm sản phẩm.\nChuẩn hóa thư viện thành phần giao diện.',
    ),
    job(
      id: 'ecommerce-intern-peak',
      title: 'Cloud Engineer Intern',
      company: 'Peak Cloud',
      fieldId: 'cloud-devops',
      skills: [
        skill('skill-python-data', 'Python', 4),
        skill('skill-jira-confluence', 'Jira & Confluence', 3),
        skill('skill-english-jd', 'Tiếng Anh chuyên ngành', 3),
      ],
      salary: '11–16 triệu/tháng',
      salaryMin: 11,
      location: 'TP. Hồ Chí Minh',
      mode: JobWorkMode.remote,
      type: JobType.fulltime,
      postedHoursAgo: 18,
      description: 'Hỗ trợ vận hành môi trường cloud và theo dõi dịch vụ.\nViết script tự động hóa các công việc lặp lại bằng Python.\nCập nhật hướng dẫn triển khai và xử lý sự cố.',
    ),
    job(
      id: 'product-intern-spark',
      title: 'Associate Product Intern',
      company: 'Spark Labs',
      fieldId: 'product-management',
      skills: [
        skill('skill-agile-scrum', 'Agile & Scrum', 4),
        skill('skill-requirements', 'Phân tích yêu cầu', 4),
        skill('skill-stakeholder-communication', 'Giao tiếp liên phòng ban', 4),
      ],
      salary: '5–8 triệu/tháng',
      salaryMin: 5,
      location: 'TP. Hồ Chí Minh',
      mode: JobWorkMode.hybrid,
      type: JobType.internship,
      postedHoursAgo: 25,
      description: 'Tổng hợp phản hồi và nhu cầu của người dùng sản phẩm.\nHỗ trợ viết user story, sắp xếp backlog và theo dõi tiến độ.\nPhối hợp với nhóm thiết kế, kỹ thuật trong các buổi sprint.',
    ),
    job(
      id: 'demo-07',
      title: 'Application Security Intern',
      company: 'Shield Works',
      fieldId: 'cybersecurity',
      skills: [
        skill('skill-python-data', 'Python', 4),
        skill('skill-sql', 'SQL', 3),
        skill('skill-english-jd', 'Tiếng Anh chuyên ngành', 4),
      ],
      salary: '5–9 triệu/tháng',
      salaryMin: 5,
      location: 'Hà Nội',
      mode: JobWorkMode.hybrid,
      type: JobType.internship,
      postedHoursAgo: 31,
      description: 'Hỗ trợ rà soát cấu hình và ghi nhận rủi ro bảo mật ứng dụng.\nThực hành phân tích log trong môi trường mô phỏng.\nSoạn hướng dẫn an toàn thông tin cho nhóm nội bộ.',
    ),
    job(
      id: 'demo-08',
      title: 'Junior Data Engineer',
      company: 'Delta Data',
      fieldId: 'database-engineering',
      skills: [
        skill('skill-sql', 'SQL', 6),
        skill('skill-python-data', 'Python', 5),
        skill('skill-excel', 'Excel', 3),
      ],
      salary: '14–20 triệu/tháng',
      salaryMin: 14,
      location: 'Đà Nẵng',
      mode: JobWorkMode.remote,
      type: JobType.fulltime,
      postedHoursAgo: 37,
      description: 'Xây dựng và duy trì quy trình xử lý dữ liệu theo lịch.\nKiểm tra độ tin cậy của dữ liệu trước khi đưa vào báo cáo.\nLàm việc cùng nhóm phân tích để cải thiện mô hình dữ liệu.',
    ),
    job(
      id: 'demo-09',
      title: 'Applied AI Intern',
      company: 'Neuron Labs',
      fieldId: 'ai-machine-learning',
      skills: [
        skill('skill-python-data', 'Python', 6),
        skill('skill-sql', 'SQL', 3),
        skill('skill-english-jd', 'Tiếng Anh chuyên ngành', 4),
      ],
      salary: '6–10 triệu/tháng',
      salaryMin: 6,
      location: 'TP. Hồ Chí Minh',
      mode: JobWorkMode.onsite,
      type: JobType.internship,
      postedHoursAgo: 44,
      description: 'Chuẩn bị dữ liệu và đánh giá kết quả mô hình thử nghiệm.\nThực hiện các notebook phân tích bằng Python.\nTóm tắt tài liệu kỹ thuật cho nhóm nghiên cứu.',
    ),
    job(
      id: 'demo-10',
      title: 'Assistant Product Manager',
      company: 'Prism Product',
      fieldId: 'product-management',
      skills: [
        skill('skill-agile-scrum', 'Agile & Scrum', 5),
        skill('skill-stakeholder-communication', 'Giao tiếp liên phòng ban', 5),
        skill('skill-business-frameworks', 'Khung tư duy kinh doanh', 4),
      ],
      salary: '10–15 triệu/tháng',
      salaryMin: 10,
      location: 'Hà Nội',
      mode: JobWorkMode.hybrid,
      type: JobType.fulltime,
      postedHoursAgo: 51,
      description: 'Theo dõi backlog, lịch phát hành và chỉ số sản phẩm.\nTổng hợp ý kiến người dùng để hỗ trợ sắp xếp ưu tiên.\nPhối hợp với thiết kế và kỹ thuật trong các buổi sprint.',
    ),
    job(
      id: 'demo-11',
      title: '2D Game Developer',
      company: 'Skyfin Interactive',
      fieldId: 'game-development',
      skills: [
        skill('skill-python-data', 'Python', 4),
        skill('skill-figma-wireframe', 'Figma & Wireframe', 3),
        skill('skill-agile-scrum', 'Agile & Scrum', 2),
      ],
      salary: '12–18 triệu/tháng',
      salaryMin: 12,
      location: 'Đà Nẵng',
      mode: JobWorkMode.onsite,
      type: JobType.fulltime,
      postedHoursAgo: 59,
      description: 'Phát triển cơ chế chơi và giao diện cho trò chơi 2D.\nTối ưu hiệu năng trên thiết bị di động phổ thông.\nPhối hợp thử nghiệm và cân bằng trải nghiệm chơi.',
    ),
    job(
      id: 'demo-12',
      title: 'Blockchain Intern',
      company: 'Blockwave Labs',
      fieldId: 'blockchain-web3',
      skills: [
        skill('skill-python-data', 'Python', 4),
        skill('skill-sql', 'SQL', 3),
        skill('skill-english-jd', 'Tiếng Anh chuyên ngành', 4),
      ],
      salary: '5–8 triệu/tháng',
      salaryMin: 5,
      location: 'TP. Hồ Chí Minh',
      mode: JobWorkMode.remote,
      type: JobType.internship,
      postedHoursAgo: 66,
      description: 'Nghiên cứu nguyên lý hợp đồng thông minh trong môi trường thử nghiệm.\nHỗ trợ viết kiểm thử và ghi nhận lỗi logic.\nTổng hợp tài liệu kỹ thuật cho nhóm sản phẩm.',
    ),
    job(
      id: 'demo-13',
      title: 'Backend Engineer',
      company: 'Violet Systems',
      fieldId: 'software-engineering',
      skills: [
        skill('skill-python-data', 'Python', 6),
        skill('skill-sql', 'SQL', 6),
        skill('skill-jira-confluence', 'Jira & Confluence', 3),
      ],
      salary: '16–24 triệu/tháng',
      salaryMin: 16,
      location: 'Hà Nội',
      mode: JobWorkMode.hybrid,
      type: JobType.fulltime,
      postedHoursAgo: 73,
      description: 'Thiết kế API và dịch vụ backend phục vụ sản phẩm nội bộ.\nTối ưu truy vấn dữ liệu và bổ sung kiểm thử tự động.\nPhối hợp cùng nhóm ứng dụng trong quá trình tích hợp.',
    ),
    job(
      id: 'demo-14',
      title: 'Data Visualization Collaborator',
      company: 'Kite BI',
      fieldId: 'data-analytics',
      skills: [
        skill('skill-power-bi', 'Power BI', 5),
        skill('skill-excel', 'Excel', 6),
        skill('skill-sql', 'SQL', 4),
      ],
      salary: '50–70 nghìn/giờ',
      salaryMin: 8,
      location: 'Đà Nẵng',
      mode: JobWorkMode.remote,
      type: JobType.parttime,
      postedHoursAgo: 81,
      description: 'Thiết kế dashboard theo nhu cầu của nhóm vận hành.\nKiểm tra tính nhất quán của báo cáo định kỳ.\nChuẩn hóa cách trình bày dữ liệu và chỉ số.',
    ),
    job(
      id: 'demo-15',
      title: 'Test Automation Specialist',
      company: 'Stepwise QA',
      fieldId: 'quality-assurance',
      skills: [
        skill('skill-python-data', 'Python', 5),
        skill('skill-jira-confluence', 'Jira & Confluence', 4),
        skill('skill-agile-scrum', 'Agile & Scrum', 4),
      ],
      salary: '13–19 triệu/tháng',
      salaryMin: 13,
      location: 'TP. Hồ Chí Minh',
      mode: JobWorkMode.onsite,
      type: JobType.fulltime,
      postedHoursAgo: 92,
      description: 'Xây dựng kịch bản tự động cho các luồng kiểm thử chính.\nPhân tích kết quả chạy và phối hợp xử lý lỗi.\nCải thiện độ ổn định của bộ kiểm thử hồi quy.',
    ),
    job(
      id: 'demo-16',
      title: 'Digital Product Design Intern',
      company: 'Apricot Studio',
      fieldId: 'ux-ui-design',
      skills: [
        skill('skill-figma-wireframe', 'Figma & Wireframe', 5),
        skill('skill-business-frameworks', 'Khung tư duy kinh doanh', 2),
        skill('skill-stakeholder-communication', 'Giao tiếp liên phòng ban', 3),
      ],
      salary: '4–7 triệu/tháng',
      salaryMin: 4,
      location: 'TP. Hồ Chí Minh',
      mode: JobWorkMode.remote,
      type: JobType.internship,
      postedHoursAgo: 108,
      description: 'Phác thảo luồng sản phẩm và tạo nguyên mẫu có thể kiểm thử.\nTham gia tổng hợp phản hồi từ người dùng thử.\nChuẩn bị tài liệu bàn giao thiết kế cho kỹ sư.',
    ),
    job(
      id: 'demo-17',
      title: 'Platform Operations Engineer',
      company: 'Nimbus Station',
      fieldId: 'cloud-devops',
      skills: [
        skill('skill-python-data', 'Python', 5),
        skill('skill-jira-confluence', 'Jira & Confluence', 4),
        skill('skill-english-jd', 'Tiếng Anh chuyên ngành', 3),
      ],
      salary: '15–22 triệu/tháng',
      salaryMin: 15,
      location: 'Hà Nội',
      mode: JobWorkMode.hybrid,
      type: JobType.fulltime,
      postedHoursAgo: 121,
      description: 'Theo dõi tình trạng nền tảng và xử lý cảnh báo vận hành.\nTự động hóa công việc định kỳ bằng script.\nCập nhật quy trình khôi phục và tài liệu nội bộ.',
    ),
    job(
      id: 'demo-18',
      title: 'Business Analysis Intern',
      company: 'Linkwork Digital',
      fieldId: 'business-analysis',
      skills: [
        skill('skill-requirements', 'Phân tích yêu cầu', 4),
        skill('skill-process-modeling', 'Mô hình hóa quy trình', 4),
        skill('skill-excel', 'Excel', 3),
      ],
      salary: '5–8 triệu/tháng',
      salaryMin: 5,
      location: 'Hà Nội',
      mode: JobWorkMode.onsite,
      type: JobType.internship,
      postedHoursAgo: 136,
      description: 'Hỗ trợ phỏng vấn người dùng và ghi nhận yêu cầu.\nMô tả luồng nghiệp vụ bằng sơ đồ dễ theo dõi.\nChuẩn bị dữ liệu kiểm thử cho các tính năng mới.',
    ),
    job(
      id: 'demo-19',
      title: 'Junior Database Engineer',
      company: 'Shell Data',
      fieldId: 'database-engineering',
      skills: [
        skill('skill-sql', 'SQL', 6),
        skill('skill-excel', 'Excel', 3),
        skill('skill-python-data', 'Python', 4),
      ],
      salary: '13–19 triệu/tháng',
      salaryMin: 13,
      location: 'TP. Hồ Chí Minh',
      mode: JobWorkMode.remote,
      type: JobType.fulltime,
      postedHoursAgo: 151,
      description: 'Theo dõi chất lượng dữ liệu và hỗ trợ tối ưu truy vấn.\nThực hiện sao lưu, kiểm tra và cập nhật cấu trúc dữ liệu.\nLàm việc cùng nhóm sản phẩm để đáp ứng nhu cầu báo cáo.',
    ),
    job(
      id: 'demo-20',
      title: 'Machine Learning Research Assistant',
      company: 'Night Owl AI',
      fieldId: 'ai-machine-learning',
      skills: [
        skill('skill-python-data', 'Python', 6),
        skill('skill-sql', 'SQL', 3),
        skill('skill-english-jd', 'Tiếng Anh chuyên ngành', 5),
      ],
      salary: '7–11 triệu/tháng',
      salaryMin: 7,
      location: 'Đà Nẵng',
      mode: JobWorkMode.hybrid,
      type: JobType.parttime,
      postedHoursAgo: 169,
      description: 'Chuẩn bị tập dữ liệu cho các thử nghiệm học máy.\nChạy đánh giá mô hình và ghi nhận kết quả có thể lặp lại.\nTóm tắt tài liệu nghiên cứu cho nhóm dự án.',
    ),
    job(
      id: 'demo-21',
      title: 'Digital Product Coordinator',
      company: 'Sprout Product',
      fieldId: 'product-management',
      skills: [
        skill('skill-agile-scrum', 'Agile & Scrum', 4),
        skill('skill-stakeholder-communication', 'Giao tiếp liên phòng ban', 5),
        skill('skill-requirements', 'Phân tích yêu cầu', 4),
      ],
      salary: '12–17 triệu/tháng',
      salaryMin: 12,
      location: 'TP. Hồ Chí Minh',
      mode: JobWorkMode.onsite,
      type: JobType.fulltime,
      postedHoursAgo: 188,
      description: 'Điều phối kế hoạch phát triển giữa các nhóm chuyên môn.\nCập nhật backlog và theo dõi các mốc ưu tiên.\nTổng hợp phản hồi để hỗ trợ quyết định sản phẩm.',
    ),
    job(
      id: 'demo-22',
      title: 'Game Development Intern',
      company: 'Firefly Play',
      fieldId: 'game-development',
      skills: [
        skill('skill-python-data', 'Python', 3),
        skill('skill-figma-wireframe', 'Figma & Wireframe', 3),
        skill('skill-agile-scrum', 'Agile & Scrum', 2),
      ],
      salary: '4–7 triệu/tháng',
      salaryMin: 4,
      location: 'Hà Nội',
      mode: JobWorkMode.remote,
      type: JobType.internship,
      postedHoursAgo: 205,
      description: 'Xây dựng màn chơi và tương tác trong dự án game nhỏ.\nPhối hợp với họa sĩ để tích hợp tài nguyên hình ảnh.\nKiểm tra trải nghiệm trên nhiều kích thước màn hình.',
    ),
    job(
      id: 'demo-23',
      title: 'Product Testing Collaborator',
      company: 'Snail Testlab',
      fieldId: 'quality-assurance',
      skills: [
        skill('skill-jira-confluence', 'Jira & Confluence', 3),
        skill('skill-requirements', 'Phân tích yêu cầu', 3),
        skill('skill-stakeholder-communication', 'Giao tiếp liên phòng ban', 3),
      ],
      salary: '40–60 nghìn/giờ',
      salaryMin: 6,
      location: 'Đà Nẵng',
      mode: JobWorkMode.hybrid,
      type: JobType.parttime,
      postedHoursAgo: 229,
      description: 'Thực hiện kiểm thử thủ công theo hướng dẫn của nhóm.\nGhi lại bước tái hiện lỗi và ảnh hưởng quan sát được.\nXác minh các bản sửa trước khi phát hành.',
    ),
    job(
      id: 'demo-24',
      title: 'Web3 Application Intern',
      company: 'Lotus Chain',
      fieldId: 'blockchain-web3',
      skills: [
        skill('skill-python-data', 'Python', 4),
        skill('skill-english-jd', 'Tiếng Anh chuyên ngành', 4),
        skill('skill-sql', 'SQL', 3),
      ],
      salary: '5–9 triệu/tháng',
      salaryMin: 5,
      location: 'Hà Nội',
      mode: JobWorkMode.hybrid,
      type: JobType.internship,
      postedHoursAgo: 247,
      description: 'Hỗ trợ tạo nguyên mẫu ứng dụng trong mạng thử nghiệm.\nViết kiểm thử cho luồng dữ liệu và thao tác cơ bản.\nTổng hợp phản hồi nội bộ để cải thiện trải nghiệm.',
    ),
  ];
}
