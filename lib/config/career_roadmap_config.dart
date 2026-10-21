class Milestone {
  const Milestone({
    required this.title,
    required this.shortLabel,
    required this.tasks,
    this.xp = 50,
  });

  final String title;
  final String shortLabel;
  final List<String> tasks;
  final int xp;
}

const defaultRoadmapRole = 'Business Analyst';

const _ba = <Milestone>[
  Milestone(
    title: 'Business Fundamentals & SDLC',
    shortLabel: 'Business Fund',
    tasks: [
      'Nắm vai trò BA trong doanh nghiệp và các mô hình kinh doanh cơ bản',
      'Học các pha của SDLC: Waterfall, Agile, Scrum',
      'Vẽ sơ đồ quy trình SDLC cho một dự án giả định',
    ],
  ),
  Milestone(
    title: 'Requirements Elicitation, BPMN & Flowchart',
    shortLabel: 'BPMN & Flow',
    tasks: [
      'Thực hành phỏng vấn stakeholder để thu thập yêu cầu',
      'Học ký hiệu BPMN 2.0 cơ bản',
      'Vẽ một flowchart quy trình As-Is và To-Be',
    ],
  ),
  Milestone(
    title: 'BRD, SRS & User Stories',
    shortLabel: 'BRD & SRS',
    tasks: [
      'Viết một BRD mẫu cho tính năng mới',
      'Viết SRS với use case và tiêu chí chấp nhận',
      'Viết 10 user story theo chuẩn INVEST',
    ],
  ),
  Milestone(
    title: 'SQL & Data Querying',
    shortLabel: 'SQL',
    tasks: [
      'Thành thạo SELECT, WHERE, GROUP BY, HAVING',
      'Luyện JOIN nhiều bảng',
      'Giải 15 bài SQL từ dễ đến trung bình',
    ],
  ),
  Milestone(
    title: 'Power BI / Tableau Dashboarding',
    shortLabel: 'Dashboard',
    tasks: [
      'Kết nối dữ liệu và làm sạch trong Power BI hoặc Tableau',
      'Dựng dashboard 1 trang với 4 KPI',
      'Thêm bộ lọc và tương tác drill-down',
    ],
  ),
  Milestone(
    title: 'BA Portfolio & Mock Interview',
    shortLabel: 'Portfolio',
    tasks: [
      'Đóng gói 2 case study BA vào portfolio',
      'Luyện 5 câu hỏi phỏng vấn BA phổ biến',
      'Làm một buổi mock interview',
    ],
    xp: 80,
  ),
];

const _da = <Milestone>[
  Milestone(
    title: 'Excel Advanced & Statistics Basics',
    shortLabel: 'Excel & Stats',
    tasks: [
      'Thành thạo PivotTable, XLOOKUP, hàm điều kiện',
      'Ôn trung bình, trung vị, độ lệch chuẩn, phân phối',
      'Làm một bài phân tích số liệu bán hàng bằng Excel',
    ],
  ),
  Milestone(
    title: 'SQL Advanced (JOIN, Subquery, Window Functions)',
    shortLabel: 'SQL Advanced',
    tasks: [
      'Luyện JOIN và subquery lồng nhau',
      'Học ROW_NUMBER, RANK, LAG/LEAD',
      'Giải 10 bài window function',
    ],
  ),
  Milestone(
    title: 'Data Visualization (Power BI / Tableau)',
    shortLabel: 'Visualization',
    tasks: [
      'Chọn đúng loại biểu đồ cho từng câu hỏi',
      'Dựng dashboard có tương tác',
      'Viết 3 insight rút ra từ dashboard',
    ],
  ),
  Milestone(
    title: 'Python for Data Analysis (Pandas, NumPy)',
    shortLabel: 'Python',
    tasks: [
      'Đọc, làm sạch và biến đổi dữ liệu bằng Pandas',
      'Dùng NumPy cho tính toán mảng',
      'Làm một notebook phân tích dữ liệu nhỏ',
    ],
  ),
  Milestone(
    title: 'Exploratory Data Analysis (EDA) & Metrics',
    shortLabel: 'EDA & Metrics',
    tasks: [
      'Kiểm tra dữ liệu thiếu, ngoại lai, phân phối',
      'Định nghĩa bộ metric cho một bài toán kinh doanh',
      'Viết báo cáo EDA ngắn',
    ],
  ),
  Milestone(
    title: 'End-to-End Data Project & Storytelling',
    shortLabel: 'Data Project',
    tasks: [
      'Chọn bộ dữ liệu và đặt câu hỏi kinh doanh',
      'Làm trọn quy trình: làm sạch, phân tích, trực quan',
      'Trình bày kết quả theo cấu trúc kể chuyện',
    ],
    xp: 80,
  ),
];

const _frontend = <Milestone>[
  Milestone(
    title: 'HTML5, CSS3 & Responsive Design',
    shortLabel: 'HTML & CSS',
    tasks: [
      'Dựng trang với thẻ ngữ nghĩa HTML5',
      'Dùng Flexbox và Grid',
      'Làm một landing page responsive',
    ],
  ),
  Milestone(
    title: 'JavaScript ES6+ & DOM Manipulation',
    shortLabel: 'JavaScript',
    tasks: [
      'Học let/const, arrow function, destructuring, module',
      'Thao tác DOM và xử lý sự kiện',
      'Làm một ứng dụng to-do nhỏ',
    ],
  ),
  Milestone(
    title: 'Git, GitHub & Web Build Tools',
    shortLabel: 'Git & Build',
    tasks: [
      'Dùng branch, merge, pull request',
      'Đẩy một project lên GitHub',
      'Làm quen Vite hoặc Webpack',
    ],
  ),
  Milestone(
    title: 'React.js / Next.js Framework & Tailwind CSS',
    shortLabel: 'React & Tailwind',
    tasks: [
      'Học component, props, hooks cơ bản',
      'Dựng giao diện bằng Tailwind CSS',
      'Làm một app React nhiều trang',
    ],
  ),
  Milestone(
    title: 'State Management & RESTful API Integration',
    shortLabel: 'State & API',
    tasks: [
      'Quản lý state toàn cục (Context, Redux hoặc Zustand)',
      'Gọi REST API, xử lý loading và lỗi',
      'Thêm cache dữ liệu phía client',
    ],
  ),
  Milestone(
    title: 'Performance Optimization & Deployment',
    shortLabel: 'Perf & Deploy',
    tasks: [
      'Đo bằng Lighthouse và cải thiện điểm',
      'Lazy loading và tối ưu ảnh',
      'Triển khai lên Vercel hoặc Netlify',
    ],
    xp: 80,
  ),
];

const _mobile = <Milestone>[
  Milestone(
    title: 'Dart / JavaScript Basics & OOP',
    shortLabel: 'Dart & OOP',
    tasks: [
      'Nắm kiểu dữ liệu, hàm, collection',
      'Học lớp, kế thừa, mixin, interface',
      'Giải 10 bài tập OOP nhỏ',
    ],
  ),
  Milestone(
    title: 'Widget Tree, Layouts & UI Components',
    shortLabel: 'Widgets & UI',
    tasks: [
      'Hiểu widget tree và vòng đời',
      'Dùng Row, Column, Stack, ListView',
      'Dựng một màn hình từ mẫu thiết kế',
    ],
  ),
  Milestone(
    title: 'State Management (Provider / Bloc / Riverpod)',
    shortLabel: 'State Mgmt',
    tasks: [
      'Chọn một giải pháp state và hiểu luồng dữ liệu',
      'Tách logic khỏi giao diện',
      'Làm một app có nhiều màn dùng chung state',
    ],
  ),
  Milestone(
    title: 'API Integration, Firebase & Local Storage',
    shortLabel: 'API & Firebase',
    tasks: [
      'Gọi REST API và parse JSON',
      'Dùng Firebase Auth và Firestore',
      'Lưu dữ liệu cục bộ bằng SharedPreferences hoặc SQLite',
    ],
  ),
  Milestone(
    title: 'App Performance & Native Device Features',
    shortLabel: 'Performance',
    tasks: [
      'Đo hiệu năng bằng DevTools',
      'Dùng camera, vị trí hoặc thông báo',
      'Xin quyền thiết bị đúng cách',
    ],
  ),
  Milestone(
    title: 'CI/CD, Testing & Publishing App',
    shortLabel: 'CI/CD & Publish',
    tasks: [
      'Viết unit test và widget test',
      'Thiết lập CI chạy test và build',
      'Chuẩn bị hồ sơ và đẩy bản beta lên cửa hàng ứng dụng',
    ],
    xp: 80,
  ),
];

const _pm = <Milestone>[
  Milestone(
    title: 'Product Mindset, Market Research & Persona',
    shortLabel: 'Product Mindset',
    tasks: [
      'Phân biệt vấn đề, giải pháp và giá trị',
      'Làm nghiên cứu thị trường và đối thủ',
      'Xây dựng 2 persona người dùng',
    ],
  ),
  Milestone(
    title: 'UI/UX Wireframing & Product Backlog',
    shortLabel: 'Wireframe',
    tasks: [
      'Vẽ wireframe cho một luồng chính',
      'Lập product backlog và sắp ưu tiên',
      'Dùng khung RICE hoặc MoSCoW',
    ],
  ),
  Milestone(
    title: 'Data-Driven Decision (A/B Testing, Funnel Analytics)',
    shortLabel: 'A/B & Funnel',
    tasks: [
      'Thiết kế một thí nghiệm A/B với giả thuyết rõ',
      'Phân tích funnel chuyển đổi',
      'Chọn metric chính và metric bảo vệ',
    ],
  ),
  Milestone(
    title: 'E-Commerce Operations & Growth Hacking',
    shortLabel: 'Ecom & Growth',
    tasks: [
      'Tìm hiểu vận hành đơn hàng, kho, chăm sóc khách hàng',
      'Lập một kế hoạch tăng trưởng nhỏ',
      'Đề xuất 3 thử nghiệm tăng trưởng',
    ],
  ),
  Milestone(
    title: 'Agile/Scrum Product Execution',
    shortLabel: 'Agile & Scrum',
    tasks: [
      'Chạy một sprint planning giả lập',
      'Viết user story và tiêu chí chấp nhận',
      'Chạy một buổi retrospective',
    ],
  ),
  Milestone(
    title: 'Product Launch Strategy & Case Study',
    shortLabel: 'Launch & Case',
    tasks: [
      'Lập kế hoạch go-to-market',
      'Định nghĩa chỉ số thành công sau ra mắt',
      'Viết một case study sản phẩm hoàn chỉnh',
    ],
    xp: 80,
  ),
];

const careerRoadmaps = <String, List<Milestone>>{
  'Business Analyst': _ba,
  'Data Analyst': _da,
  'Frontend Developer': _frontend,
  'Mobile Developer': _mobile,
  'Product Manager': _pm,
  'E-commerce Specialist': _pm,
};

/// Falls back to Business Analyst when the role has no dedicated roadmap.
String resolveRoadmapRole(String? targetRole) {
  if (targetRole != null && careerRoadmaps.containsKey(targetRole)) {
    return targetRole;
  }
  return defaultRoadmapRole;
}

List<Milestone> roadmapFor(String? targetRole) =>
    careerRoadmaps[resolveRoadmapRole(targetRole)]!;
