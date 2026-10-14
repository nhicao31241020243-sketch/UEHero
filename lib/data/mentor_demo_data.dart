import '../models/mentor_model.dart';

class MentorRepository {
  const MentorRepository._();

  static List<Mentor> getMentors({DateTime? now}) {
    final current = now ?? DateTime.now();

    DateTime slot(int days, int hour) =>
        DateTime(current.year, current.month, current.day + days, hour);

    return [
      Mentor(
        id: 'mentor-lan-anh',
        name: 'Lan Anh Nguyễn',
        title: 'Frontend Engineer',
        yearsExperience: 6,
        organizationLabel: 'Công ty công nghệ lớn',
        bio: 'Đã xây dựng giao diện web cho sản phẩm phục vụ hàng triệu lượt dùng. '
            'Có thể cùng bạn luyện nền tảng UI và chuẩn bị phỏng vấn frontend.',
        topics: const [MentorTopic.cv, MentorTopic.interview, MentorTopic.technical],
        fieldIds: const ['frontend'],
        availableSlots: [slot(1, 19), slot(3, 20)],
        isDemo: true,
      ),
      Mentor(
        id: 'mentor-minh-quan',
        name: 'Minh Quân Trần',
        title: 'Senior Frontend Developer',
        yearsExperience: 8,
        organizationLabel: 'Đội ngũ sản phẩm số',
        bio: 'Từng dẫn dắt việc cải thiện hiệu năng và khả năng truy cập cho ứng dụng web. '
            'Anh thường góp ý portfolio bằng ví dụ thực tế và dễ áp dụng.',
        topics: const [
          MentorTopic.portfolio,
          MentorTopic.technical,
          MentorTopic.careerDirection,
        ],
        fieldIds: const ['frontend', 'fullstack'],
        availableSlots: [slot(2, 19)],
        isDemo: true,
      ),
      Mentor(
        id: 'mentor-hoang-nam',
        name: 'Hoàng Nam Lê',
        title: 'Backend Engineer',
        yearsExperience: 7,
        organizationLabel: 'Công ty nền tảng số',
        bio: 'Có kinh nghiệm thiết kế API và hệ thống xử lý dữ liệu giao dịch. '
            'Anh có thể giúp bạn luyện tư duy backend và trình bày dự án kỹ thuật.',
        topics: const [
          MentorTopic.interview,
          MentorTopic.technical,
          MentorTopic.portfolio,
        ],
        fieldIds: const ['backend'],
        availableSlots: [slot(1, 20), slot(4, 19)],
        isDemo: true,
      ),
      Mentor(
        id: 'mentor-thanh-tung',
        name: 'Thanh Tùng Phạm',
        title: 'Backend & Cloud Engineer',
        yearsExperience: 9,
        organizationLabel: 'Công ty giải pháp đám mây',
        bio: 'Từng vận hành dịch vụ backend có yêu cầu cao về độ ổn định. '
            'Anh chia sẻ cách đọc log, thiết kế API và chuẩn bị hồ sơ kỹ thuật.',
        topics: const [MentorTopic.cv, MentorTopic.technical, MentorTopic.interview],
        fieldIds: const ['backend', 'devops_cloud'],
        availableSlots: const [],
        isDemo: true,
      ),
      Mentor(
        id: 'mentor-thu-ha',
        name: 'Thu Hà Võ',
        title: 'Mobile Application Engineer',
        yearsExperience: 5,
        organizationLabel: 'Studio ứng dụng di động',
        bio: 'Đã phát triển ứng dụng di động đa nền tảng từ bản thử nghiệm đến phát hành. '
            'Chị có thể cùng bạn rà soát luồng trải nghiệm và cách mô tả dự án.',
        topics: const [
          MentorTopic.portfolio,
          MentorTopic.technical,
          MentorTopic.careerDirection,
        ],
        fieldIds: const ['mobile'],
        availableSlots: [slot(1, 19), slot(5, 20)],
        isDemo: true,
      ),
      Mentor(
        id: 'mentor-duc-long',
        name: 'Đức Long Bùi',
        title: 'Mobile & IoT Developer',
        yearsExperience: 6,
        organizationLabel: 'Nhóm thiết bị thông minh',
        bio: 'Từng kết nối ứng dụng di động với thiết bị cảm biến và dịch vụ đám mây. '
            'Anh hướng dẫn cách biến bài tập cá nhân thành portfolio rõ ràng.',
        topics: const [MentorTopic.cv, MentorTopic.portfolio, MentorTopic.technical],
        fieldIds: const ['mobile', 'embedded_iot'],
        availableSlots: [slot(2, 20)],
        isDemo: true,
      ),
      Mentor(
        id: 'mentor-mai-chi',
        name: 'Mai Chi Đặng',
        title: 'Data Analyst',
        yearsExperience: 6,
        organizationLabel: 'Đơn vị phân tích sản phẩm',
        bio: 'Đã xây dựng báo cáo giúp các nhóm sản phẩm hiểu hành vi người dùng. '
            'Chị có thể cùng bạn luyện SQL, trực quan hóa và kể chuyện bằng dữ liệu.',
        topics: const [MentorTopic.cv, MentorTopic.interview, MentorTopic.technical],
        fieldIds: const ['data_analyst'],
        availableSlots: [slot(1, 19), slot(3, 19)],
        isDemo: true,
      ),
      Mentor(
        id: 'mentor-quoc-bao',
        name: 'Quốc Bảo Đỗ',
        title: 'Data & Analytics Engineer',
        yearsExperience: 8,
        organizationLabel: 'Công ty dữ liệu số',
        bio: 'Từng xây dựng quy trình dữ liệu phục vụ báo cáo và ra quyết định. '
            'Anh giúp bạn phân biệt vai trò phân tích với kỹ thuật dữ liệu qua dự án mẫu.',
        topics: const [
          MentorTopic.technical,
          MentorTopic.careerDirection,
          MentorTopic.portfolio,
        ],
        fieldIds: const ['data_analyst', 'data_engineer'],
        availableSlots: const [],
        isDemo: true,
      ),
      Mentor(
        id: 'mentor-gia-huy',
        name: 'Gia Huy Nguyễn',
        title: 'Machine Learning Engineer',
        yearsExperience: 5,
        organizationLabel: 'Phòng nghiên cứu ứng dụng',
        bio: 'Đã đưa mô hình học máy vào các bài toán phân loại và gợi ý. '
            'Anh tập trung giải thích cách chọn dự án vừa sức và trình bày kết quả.',
        topics: const [MentorTopic.portfolio, MentorTopic.technical, MentorTopic.cv],
        fieldIds: const ['data_science_ai'],
        availableSlots: [slot(1, 20)],
        isDemo: true,
      ),
      Mentor(
        id: 'mentor-thanh-ha',
        name: 'Thanh Hà Lâm',
        title: 'Cloud & DevOps Engineer',
        yearsExperience: 7,
        organizationLabel: 'Công ty hạ tầng số',
        bio: 'Từng tự động hóa triển khai và theo dõi dịch vụ trên nền tảng đám mây. '
            'Chị chia sẻ cách xây lab cá nhân để chứng minh kỹ năng DevOps.',
        topics: const [
          MentorTopic.cv,
          MentorTopic.careerDirection,
          MentorTopic.technical,
        ],
        fieldIds: const ['devops_cloud'],
        availableSlots: [slot(3, 20)],
        isDemo: true,
      ),
      Mentor(
        id: 'mentor-tuan-kiet',
        name: 'Tuấn Kiệt Võ',
        title: 'Security Analyst',
        yearsExperience: 6,
        organizationLabel: 'Nhóm an toàn hệ thống',
        bio: 'Có kinh nghiệm rà soát rủi ro và cải thiện quy trình bảo mật nội bộ. '
            'Anh hướng dẫn người mới chọn bài lab phù hợp và viết báo cáo rõ ràng.',
        topics: const [
          MentorTopic.interview,
          MentorTopic.technical,
          MentorTopic.careerDirection,
        ],
        fieldIds: const ['cybersecurity'],
        availableSlots: [slot(2, 20)],
        isDemo: true,
      ),
      Mentor(
        id: 'mentor-phuong-thao',
        name: 'Phương Thảo Đinh',
        title: 'QA Automation Engineer',
        yearsExperience: 5,
        organizationLabel: 'Đội chất lượng sản phẩm',
        bio: 'Từng xây bộ kiểm thử tự động cho web và ứng dụng di động. '
            'Chị giúp bạn chọn case tiêu biểu để đưa vào CV và portfolio.',
        topics: const [MentorTopic.cv, MentorTopic.interview, MentorTopic.technical],
        fieldIds: const ['qa_testing'],
        availableSlots: [slot(1, 19)],
        isDemo: true,
      ),
      Mentor(
        id: 'mentor-khanh-vy',
        name: 'Khánh Vy Trương',
        title: 'Product Designer',
        yearsExperience: 6,
        organizationLabel: 'Nhóm thiết kế sản phẩm số',
        bio: 'Đã nghiên cứu nhu cầu người dùng và thiết kế luồng cho sản phẩm mới. '
            'Chị có thể góp ý case study để portfolio thể hiện rõ quá trình tư duy.',
        topics: const [
          MentorTopic.portfolio,
          MentorTopic.careerDirection,
          MentorTopic.interview,
        ],
        fieldIds: const ['ui_ux'],
        availableSlots: [slot(4, 19)],
        isDemo: true,
      ),
      Mentor(
        id: 'mentor-bao-ngoc',
        name: 'Bảo Ngọc Nguyễn',
        title: 'Product Manager',
        yearsExperience: 8,
        organizationLabel: 'Đội phát triển sản phẩm',
        bio: 'Từng phối hợp với thiết kế và kỹ thuật để đưa tính năng từ ý tưởng đến thử nghiệm. '
            'Chị chia sẻ cách ưu tiên công việc và chuẩn bị câu chuyện phỏng vấn.',
        topics: const [
          MentorTopic.interview,
          MentorTopic.careerDirection,
          MentorTopic.cv,
        ],
        fieldIds: const ['product_manager', 'project_manager'],
        availableSlots: [slot(2, 19), slot(5, 19)],
        isDemo: true,
      ),
      Mentor(
        id: 'mentor-trong-nghia',
        name: 'Trọng Nghĩa Lý',
        title: 'Business Analyst',
        yearsExperience: 7,
        organizationLabel: 'Đơn vị tư vấn giải pháp số',
        bio: 'Có kinh nghiệm làm rõ yêu cầu và kết nối nhóm nghiệp vụ với đội kỹ thuật. '
            'Anh cùng bạn luyện tài liệu phân tích và tình huống phỏng vấn BA.',
        topics: const [MentorTopic.cv, MentorTopic.interview, MentorTopic.technical],
        fieldIds: const ['business_analyst'],
        availableSlots: [slot(1, 20)],
        isDemo: true,
      ),
      Mentor(
        id: 'mentor-hai-dang',
        name: 'Hải Đăng Phạm',
        title: 'Game & ERP Solution Developer',
        yearsExperience: 6,
        organizationLabel: 'Studio giải pháp tương tác',
        bio: 'Từng tham gia phát triển trải nghiệm game và tích hợp quy trình doanh nghiệp. '
            'Anh giúp bạn chọn một hướng dự án cụ thể để thể hiện kỹ năng thực hành.',
        topics: const [
          MentorTopic.portfolio,
          MentorTopic.technical,
          MentorTopic.careerDirection,
        ],
        fieldIds: const ['game_dev', 'erp_sap'],
        availableSlots: [slot(3, 19)],
        isDemo: true,
      ),
    ];
  }
}
