import '../models/mentor_model.dart';

/// Sample-only mentor seed. Every mentor here is fictional demo data.
class MentorSeedRow {
  const MentorSeedRow(
    this.id,
    this.name,
    this.title,
    this.years,
    this.org,
    this.fields,
    this.topics,
    this.bio, {
    this.female = false,
  });

  final String id;
  final String name;
  final String title;
  final int years;
  final String org;
  final List<String> fields;
  final List<MentorTopic> topics;
  final String bio;
  final bool female;
}

const _cv = MentorTopic.cv;
const _iv = MentorTopic.interview;
const _cd = MentorTopic.careerDirection;
const _pf = MentorTopic.portfolio;
const _te = MentorTopic.technical;

const mentorSeedRows = <MentorSeedRow>[
  MentorSeedRow(
    'mentor-ngoc-linh',
    'Hoàng Ngọc Linh',
    'Junior Frontend Developer',
    2,
    'Startup thương mại điện tử',
    ['frontend'],
    [_cv, _pf],
    'Mới đi làm hai năm nên còn nhớ rõ nỗi lo của người vào nghề. '
        'Chị hay giúp bạn dọn lại portfolio để nhà tuyển dụng đọc trong một phút.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-duy-khang',
    'Huỳnh Duy Khang',
    'React Engineer',
    4,
    'Công ty phần mềm xuất khẩu',
    ['frontend', 'fullstack'],
    [_iv, _te, _cv],
    'Chuyên làm hệ thống thiết kế dùng chung cho nhiều đội. '
        'Anh luyện bạn cách giải thích quyết định kỹ thuật khi phỏng vấn.',
  ),
  MentorSeedRow(
    'mentor-yen-nhi',
    'Cao Yến Nhi',
    'Senior Web Performance Specialist',
    7,
    'Nền tảng nội dung số',
    ['frontend'],
    [_te, _pf, _cd],
    'Từng rút ngắn thời gian tải trang của một trang tin lớn. '
        'Chị chỉ cách đo, đọc báo cáo hiệu năng và kể lại thành tích đó trong CV.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-van-toan',
    'Mai Văn Toàn',
    'Backend Developer',
    3,
    'Công ty công nghệ tài chính',
    ['backend'],
    [_cv, _te],
    'Làm việc với hệ thống thanh toán nên rất kỹ chuyện kiểm tra dữ liệu đầu vào. '
        'Anh sẵn sàng cùng bạn xem lại bài tập lớn môn cơ sở dữ liệu.',
  ),
  MentorSeedRow(
    'mentor-bich-tram',
    'Lương Bích Trâm',
    'Senior Java Backend Engineer',
    8,
    'Ngân hàng số',
    ['backend'],
    [_iv, _te, _cd],
    'Đã phỏng vấn nhiều ứng viên Java cho các vị trí junior. '
        'Chị chia sẻ những câu hỏi hay gặp và cách trả lời không học thuộc lòng.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-anh-tuan',
    'Trịnh Anh Tuấn',
    'Node.js Engineer',
    5,
    'Công ty dịch vụ giao hàng',
    ['backend', 'fullstack'],
    [_pf, _te],
    'Từng xử lý hàng nghìn yêu cầu mỗi giây trong giờ cao điểm giao hàng. '
        'Anh gợi ý các dự án nhỏ có tải thật để bạn học hệ thống phân tán.',
  ),
  MentorSeedRow(
    'mentor-kim-ngan',
    'Phan Kim Ngân',
    'Senior Fullstack Developer',
    6,
    'Công ty giải pháp bán lẻ',
    ['fullstack', 'frontend'],
    [_cv, _pf, _cd],
    'Làm cả giao diện lẫn máy chủ cho một sản phẩm quản lý cửa hàng. '
        'Chị giúp bạn chọn hướng đi khi chưa biết nên nghiêng về mặt nào.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-tien-dat',
    'Vương Tiến Đạt',
    'Senior Android Developer',
    9,
    'Công ty ứng dụng gọi xe',
    ['mobile'],
    [_iv, _te, _cd],
    'Đã duy trì một ứng dụng di động có hàng triệu người dùng hằng ngày. '
        'Anh nói rõ mức kiến thức nền cần có để vượt vòng phỏng vấn mobile.',
  ),
  MentorSeedRow(
    'mentor-hong-diem',
    'Châu Hồng Diễm',
    'Flutter Developer',
    3,
    'Studio ứng dụng giáo dục',
    ['mobile'],
    [_cv, _pf, _te],
    'Đã phát hành ba ứng dụng Flutter cho học sinh và sinh viên. '
        'Chị hướng dẫn cách ghi lại quá trình làm app để portfolio có sức thuyết phục.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-minh-triet',
    'Dương Minh Triết',
    'Lead iOS Engineer',
    11,
    'Công ty sản phẩm toàn cầu',
    ['mobile'],
    [_cd, _te],
    'Làm việc nhiều năm với đội ngũ phân tán ở nhiều múi giờ. '
        'Anh chia sẻ cách giao tiếp bằng tiếng Anh trong họp kỹ thuật.',
  ),
  MentorSeedRow(
    'mentor-thuy-kieu',
    'Tô Thúy Kiều',
    'Junior Data Analyst',
    2,
    'Công ty bán lẻ đa kênh',
    ['data_analyst'],
    [_cv, _iv],
    'Chuyển từ ngành kế toán sang phân tích dữ liệu sau một khóa học ngắn. '
        'Chị hiểu rõ người học trái ngành cần chứng minh điều gì trong hồ sơ.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-nhat-minh',
    'Ngô Nhật Minh',
    'Lead Data Analyst',
    10,
    'Tập đoàn tiêu dùng nhanh',
    ['data_analyst', 'business_analyst'],
    [_cd, _pf, _iv],
    'Quản lý nhóm báo cáo cho các chiến dịch bán hàng toàn quốc. '
        'Anh góp ý cách trình bày dashboard để lãnh đạo ra quyết định nhanh hơn.',
  ),
  MentorSeedRow(
    'mentor-thao-vy',
    'Lại Thảo Vy',
    'BI Developer',
    5,
    'Công ty bảo hiểm',
    ['data_analyst'],
    [_te, _pf],
    'Chuyên xây mô hình dữ liệu và báo cáo Power BI cho khối vận hành. '
        'Chị có thể xem bài dashboard của bạn và chỉ ra chỗ gây hiểu nhầm.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-quang-vinh',
    'Hồ Quang Vinh',
    'Senior Data Engineer',
    6,
    'Công ty thương mại điện tử lớn',
    ['data_engineer'],
    [_te, _iv, _cd],
    'Thiết kế các đường ống dữ liệu chạy hằng đêm cho nhiều phòng ban. '
        'Anh giúp bạn hiểu khác biệt giữa batch và streaming bằng ví dụ gần gũi.',
  ),
  MentorSeedRow(
    'mentor-lan-huong',
    'Đào Lan Hương',
    'Analytics Engineer',
    4,
    'Công ty công nghệ giáo dục',
    ['data_engineer', 'data_analyst'],
    [_cv, _te],
    'Làm cầu nối giữa đội phân tích và đội hạ tầng dữ liệu. '
        'Chị hướng dẫn bạn dựng một kho dữ liệu nhỏ làm dự án cuối khóa.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-hoai-nam',
    'Tăng Hoài Nam',
    'Lead Big Data Engineer',
    12,
    'Công ty viễn thông',
    ['data_engineer'],
    [_cd, _te, _iv],
    'Có hơn mười năm làm với dữ liệu lớn từ thời Hadoop đến nền tảng đám mây. '
        'Anh nhìn lại xu hướng nghề để bạn chọn công cụ đáng học trước.',
  ),
  MentorSeedRow(
    'mentor-diep-chi',
    'Âu Diệp Chi',
    'Data Scientist',
    5,
    'Công ty công nghệ y tế',
    ['data_science_ai'],
    [_pf, _te, _cv],
    'Áp dụng mô hình dự đoán vào dữ liệu khám chữa bệnh đã ẩn danh. '
        'Chị khuyên cách chọn đề tài vừa sức và kể rõ giới hạn của mô hình.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-bao-long',
    'Kiều Bảo Long',
    'NLP Engineer',
    4,
    'Phòng thí nghiệm ngôn ngữ',
    ['data_science_ai'],
    [_te, _cd],
    'Xây hệ thống xử lý tiếng Việt cho chatbot chăm sóc khách hàng. '
        'Anh sẵn lòng chỉ nguồn dữ liệu mở và cách đánh giá mô hình công bằng.',
  ),
  MentorSeedRow(
    'mentor-cam-tu',
    'Quách Cẩm Tú',
    'AI Product Engineer',
    3,
    'Startup trí tuệ nhân tạo',
    ['data_science_ai', 'product_manager'],
    [_iv, _pf],
    'Đưa các mô hình có sẵn vào sản phẩm thật cho người dùng cuối. '
        'Chị luyện bạn kể dự án AI theo hướng giải quyết vấn đề, không chỉ khoe thuật toán.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-gia-bao',
    'Thái Gia Bảo',
    'DevOps Engineer',
    5,
    'Công ty trò chơi trực tuyến',
    ['devops_cloud'],
    [_te, _cv],
    'Vận hành hạ tầng phải chịu những đợt tăng người chơi đột biến. '
        'Anh chỉ cách luyện CI/CD ở nhà bằng máy tính cá nhân.',
  ),
  MentorSeedRow(
    'mentor-uyen-phuong',
    'Giang Uyên Phương',
    'Senior Site Reliability Engineer',
    9,
    'Nền tảng thanh toán',
    ['devops_cloud', 'backend'],
    [_iv, _cd],
    'Làm công việc trực hệ thống và rút kinh nghiệm sau mỗi sự cố. '
        'Chị chia sẻ cách tập tư duy giám sát và viết báo cáo sự cố ngắn gọn.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-hung-cuong',
    'Mạc Hùng Cường',
    'Senior Penetration Tester',
    7,
    'Công ty tư vấn an ninh mạng',
    ['cybersecurity'],
    [_te, _cd, _pf],
    'Thực hiện kiểm thử xâm nhập cho các hệ thống nội bộ của doanh nghiệp. '
        'Anh hướng dẫn cách xây lab hợp pháp và viết báo cáo lỗ hổng chuyên nghiệp.',
  ),
  MentorSeedRow(
    'mentor-thu-trang',
    'Cù Thu Trang',
    'SOC Analyst',
    3,
    'Trung tâm giám sát an ninh',
    ['cybersecurity'],
    [_cv, _iv],
    'Theo dõi cảnh báo an ninh theo ca và phân loại sự cố. '
        'Chị giải thích một ngày làm việc thật để bạn biết nghề này có hợp không.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-viet-anh',
    'Chu Việt Anh',
    'Junior QA Engineer',
    2,
    'Công ty phần mềm ngân hàng',
    ['qa_testing'],
    [_cv, _cd],
    'Bắt đầu từ kiểm thử thủ công rồi chuyển dần sang tự động. '
        'Anh gợi ý lộ trình học theo từng tháng cho người mới.',
  ),
  MentorSeedRow(
    'mentor-hanh-nguyen',
    'Tạ Hạnh Nguyên',
    'Test Lead',
    10,
    'Công ty gia công phần mềm',
    ['qa_testing', 'project_manager'],
    [_iv, _cd, _te],
    'Dẫn dắt nhóm kiểm thử mười người cho các dự án nước ngoài. '
        'Chị chỉ cách viết test case rõ ràng và trao đổi lỗi mà không gây căng thẳng.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-khoi-nguyen',
    'Sơn Khôi Nguyên',
    'UI/UX Designer',
    3,
    'Studio thiết kế độc lập',
    ['ui_ux'],
    [_pf, _cv],
    'Làm nhiều dự án thiết kế ứng dụng cho cửa hàng nhỏ. '
        'Anh góp ý case study để người xem thấy được lý do đằng sau từng quyết định.',
  ),
  MentorSeedRow(
    'mentor-my-duyen',
    'Thi Mỹ Duyên',
    'Senior UX Researcher',
    6,
    'Công ty ứng dụng tài chính cá nhân',
    ['ui_ux', 'product_manager'],
    [_cd, _iv, _pf],
    'Tổ chức các buổi phỏng vấn người dùng và tổng hợp thành khuyến nghị cho sản phẩm. '
        'Chị hướng dẫn cách đặt câu hỏi không dẫn dắt khi nghiên cứu.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-phat-loc',
    'Vũ Phát Lộc',
    'Design System Lead',
    8,
    'Công ty thương mại điện tử',
    ['ui_ux', 'frontend'],
    [_te, _pf, _cd],
    'Xây bộ thành phần giao diện dùng chung cho hơn chục đội sản phẩm. '
        'Anh chỉ cách phối hợp giữa thiết kế và lập trình để bàn giao đỡ sai sót.',
  ),
  MentorSeedRow(
    'mentor-tuong-vi',
    'Lục Tường Vi',
    'Product Analyst',
    3,
    'Ứng dụng xem phim trực tuyến',
    ['product_manager'],
    [_cv, _iv],
    'Bắt đầu từ vai trò phân tích rồi chuyển sang quản lý sản phẩm. '
        'Chị chia sẻ cách kể thành tích dưới dạng tác động đo được.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-dinh-phong',
    'Bành Đình Phong',
    'Group Product Manager',
    12,
    'Tập đoàn công nghệ',
    ['product_manager', 'project_manager'],
    [_cd, _iv],
    'Đã ra mắt nhiều sản phẩm và cũng đóng cửa một vài sản phẩm không hiệu quả. '
        'Anh nói thẳng về những quyết định khó và cách học từ thất bại.',
  ),
  MentorSeedRow(
    'mentor-ngoc-han',
    'Quan Ngọc Hân',
    'Business Analyst',
    4,
    'Công ty phần mềm bảo hiểm',
    ['business_analyst'],
    [_cv, _iv, _te],
    'Làm yêu cầu cho hệ thống quản lý hợp đồng với nhiều bên liên quan. '
        'Chị luyện bạn vẽ quy trình nghiệp vụ và đặt câu hỏi làm rõ yêu cầu.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-tan-phat',
    'Lê Tấn Phát',
    'Senior Business Analyst',
    9,
    'Công ty tư vấn chuyển đổi số',
    ['business_analyst', 'erp_sap'],
    [_cd, _pf],
    'Tham gia chuyển đổi số cho nhiều doanh nghiệp vừa và nhỏ. '
        'Anh chia sẻ cách xây portfolio BA khi chưa có kinh nghiệm đi làm.',
  ),
  MentorSeedRow(
    'mentor-hoang-yen',
    'Mạnh Hoàng Yến',
    'Project Manager',
    8,
    'Công ty gia công phần mềm',
    ['project_manager'],
    [_iv, _cd, _cv],
    'Quản lý tiến độ và rủi ro cho các dự án có khách hàng nước ngoài. '
        'Chị giúp bạn thấy trước các câu hỏi tình huống trong phỏng vấn quản lý dự án.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-son-tung',
    'Hà Sơn Tùng',
    'Scrum Master',
    5,
    'Ngân hàng điện tử',
    ['project_manager', 'product_manager'],
    [_te, _cd],
    'Huấn luyện các đội áp dụng Scrum trong môi trường nhiều quy định. '
        'Anh giải thích Agile bằng những tình huống thật, không sa vào thuật ngữ.',
  ),
  MentorSeedRow(
    'mentor-minh-chau',
    'Phùng Minh Châu',
    'Unity Developer',
    4,
    'Studio game di động',
    ['game_dev'],
    [_pf, _te, _cv],
    'Làm game giải đố cho điện thoại từ ý tưởng đến phát hành. '
        'Chị khuyên bạn nên hoàn thiện một game nhỏ thay vì bỏ dở nhiều game lớn.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-dat-thinh',
    'Cung Đạt Thịnh',
    'Senior Gameplay Programmer',
    7,
    'Studio game nhập vai',
    ['game_dev'],
    [_iv, _te],
    'Chuyên về cơ chế chiến đấu và hiệu năng trong game. '
        'Anh biết rõ bài kiểm tra lập trình mà các studio hay dùng khi tuyển.',
  ),
  MentorSeedRow(
    'mentor-quynh-anh',
    'Từ Quỳnh Anh',
    'Senior Embedded Engineer',
    6,
    'Công ty thiết bị điện tử',
    ['embedded_iot'],
    [_te, _cv, _cd],
    'Lập trình vi điều khiển cho thiết bị đo dùng trong nhà máy. '
        'Chị gợi ý bộ linh kiện giá rẻ để bạn làm dự án cá nhân đáng giá.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-hieu-nghia',
    'Lưu Hiếu Nghĩa',
    'Lead IoT Solution Architect',
    11,
    'Công ty giải pháp nhà thông minh',
    ['embedded_iot', 'devops_cloud'],
    [_cd, _pf],
    'Thiết kế kiến trúc kết nối thiết bị với đám mây cho nhiều tòa nhà. '
        'Anh nói về con đường từ lập trình nhúng lên vai trò kiến trúc.',
  ),
  MentorSeedRow(
    'mentor-thanh-mai',
    'Ung Thanh Mai',
    'Senior SAP Consultant',
    8,
    'Công ty tư vấn ERP',
    ['erp_sap', 'business_analyst'],
    [_cv, _cd, _iv],
    'Triển khai phân hệ tài chính SAP cho doanh nghiệp sản xuất. '
        'Chị giải thích vì sao nghề tư vấn ERP vẫn cần người trẻ và nên bắt đầu từ đâu.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-khai-hoan',
    'Doãn Khải Hoàn',
    'ERP Functional Consultant',
    5,
    'Công ty giải pháp doanh nghiệp',
    ['erp_sap'],
    [_te, _iv],
    'Làm việc sát với kế toán và kho vận để cấu hình quy trình trên ERP. '
        'Anh giúp bạn hiểu luồng nghiệp vụ mua hàng, bán hàng trước khi học công cụ.',
  ),
  MentorSeedRow(
    'mentor-phuc-hau',
    'Triệu Phúc Hậu',
    'Frontend Team Lead',
    10,
    'Công ty phần mềm tài chính',
    ['frontend', 'fullstack'],
    [_cd, _iv],
    'Dẫn dắt nhóm sáu người và duyệt mã nguồn mỗi ngày. '
        'Anh chỉ ra những lỗi thường gặp trong bài thi viết mã của ứng viên junior.',
  ),
  MentorSeedRow(
    'mentor-nhu-quynh',
    'Ân Như Quỳnh',
    'Junior Data Analyst',
    1,
    'Công ty khởi nghiệp thực phẩm',
    ['data_analyst'],
    [_cv, _cd],
    'Vừa tốt nghiệp được một năm nên nhớ rõ cách xin việc đầu tiên. '
        'Chị chia sẻ cách chọn dự án cá nhân từ dữ liệu mở của Việt Nam.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-trung-hieu',
    'Bạch Trung Hiếu',
    'Senior Backend & Data Engineer',
    6,
    'Công ty công nghệ logistics',
    ['backend', 'data_engineer'],
    [_pf, _te, _iv],
    'Làm cả dịch vụ máy chủ lẫn đường ống dữ liệu cho hệ thống vận đơn. '
        'Anh gợi ý cách chọn dự án có đủ độ sâu để kể trong phỏng vấn.',
  ),
  MentorSeedRow(
    'mentor-lien-huong',
    'Khúc Liên Hương',
    'Senior Product Designer',
    9,
    'Công ty công nghệ giáo dục',
    ['ui_ux'],
    [_cd, _pf],
    'Dẫn dắt thiết kế cho một nền tảng học trực tuyến nhiều năm. '
        'Chị nói về cách giữ phong cách riêng khi làm việc với nhiều bên.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-bach-duong',
    'Tiêu Bách Dương',
    'Senior Machine Learning Researcher',
    7,
    'Viện nghiên cứu ứng dụng',
    ['data_science_ai'],
    [_cd, _te],
    'Vừa nghiên cứu vừa đưa kết quả vào thử nghiệm thực tế. '
        'Anh tư vấn cho bạn đang cân nhắc giữa đi làm và học tiếp sau đại học.',
  ),
  MentorSeedRow(
    'mentor-ha-giang',
    'Lỗ Hà Giang',
    'Cloud Solutions Engineer',
    4,
    'Nhà cung cấp dịch vụ đám mây',
    ['devops_cloud'],
    [_cv, _iv, _cd],
    'Hỗ trợ khách hàng chuyển hệ thống lên đám mây an toàn. '
        'Chị giải thích các chứng chỉ nào đáng đầu tư và cái nào có thể bỏ qua.',
    female: true,
  ),
  MentorSeedRow(
    'mentor-manh-dung',
    'Ông Mạnh Dũng',
    'Mobile Tech Lead',
    12,
    'Công ty thương mại di động',
    ['mobile', 'backend'],
    [_cd, _iv, _te],
    'Từ lập trình viên trở thành người dẫn dắt kỹ thuật cho cả đội mobile. '
        'Anh nói về cách chuẩn bị để nhận trách nhiệm lớn hơn mà không kiệt sức.',
  ),
];

const _reviewPool = <MentorReview>[
  MentorReview(
    author: 'Bạn Minh Thư',
    rating: 5,
    comment: 'Buổi trao đổi rất cụ thể, mình sửa lại CV ngay trong tối đó.',
  ),
  MentorReview(
    author: 'Bạn Quốc Việt',
    rating: 5,
    comment: 'Mentor lắng nghe kỹ và đưa ví dụ dễ hiểu.',
  ),
  MentorReview(
    author: 'Bạn Hải Yến',
    rating: 4,
    comment: 'Góp ý thẳng thắn, hơi nhanh nhưng mình ghi chú được nhiều.',
  ),
  MentorReview(
    author: 'Bạn Đức Thịnh',
    rating: 5,
    comment: 'Giúp mình thấy rõ nên học gì trước trong ba tháng tới.',
  ),
  MentorReview(
    author: 'Bạn Thùy Dương',
    rating: 4,
    comment: 'Nhiệt tình, phản hồi tin nhắn sau buổi hẹn rất nhanh.',
  ),
  MentorReview(
    author: 'Bạn Anh Khoa',
    rating: 5,
    comment: 'Buổi luyện phỏng vấn thử giúp mình bớt run hẳn.',
  ),
  MentorReview(
    author: 'Bạn Phương Linh',
    rating: 5,
    comment: 'Đưa ra lộ trình rõ ràng, không làm mình thấy bị quá tải.',
  ),
  MentorReview(
    author: 'Bạn Tuấn Anh',
    rating: 4,
    comment: 'Chỉ ra được điểm yếu trong portfolio mà mình không nhận ra.',
  ),
  MentorReview(
    author: 'Bạn Gia Hân',
    rating: 5,
    comment: 'Rất thân thiện, câu hỏi nào cũng được giải thích đến nơi.',
  ),
  MentorReview(
    author: 'Bạn Nhật Nam',
    rating: 4,
    comment: 'Nội dung hữu ích, mong có thêm khung giờ vào cuối tuần.',
  ),
];

const _responseTimes = ['~2h', '~6h', '~12h', '~24h', '~48h'];

/// Slot offsets as (days from now, hour). Index 5 mod 11 gets no slots.
const _slotPatterns = <List<(int, int)>>[
  [(1, 19)],
  [(2, 20), (4, 19)],
  [(1, 20), (3, 19), (6, 20)],
  [(3, 21)],
  [(2, 19), (5, 19), (7, 20), (9, 19)],
  [(4, 20), (8, 19)],
  [(1, 21), (2, 20)],
];

/// Fixed id -> gender for the original hand-written mentors.
const originalMentorFemale = <String, bool>{
  'mentor-lan-anh': true,
  'mentor-minh-quan': false,
  'mentor-hoang-nam': false,
  'mentor-thanh-tung': false,
  'mentor-thu-ha': true,
  'mentor-duc-long': false,
  'mentor-mai-chi': true,
  'mentor-quoc-bao': false,
  'mentor-gia-huy': false,
  'mentor-thanh-ha': true,
  'mentor-tuan-kiet': false,
  'mentor-phuong-thao': true,
  'mentor-khanh-vy': true,
  'mentor-bao-ngoc': true,
  'mentor-trong-nghia': false,
  'mentor-hai-dang': false,
};

/// Portrait files cycle per gender; files live in assets/mentors/.
const mentorPortraitPoolSize = 15;

String portraitAsset({required bool female, required int genderIndex}) =>
    'assets/mentors/mentor_${female ? 'f' : 'm'}'
    '${(genderIndex % mentorPortraitPoolSize + 1).toString().padLeft(2, '0')}.jpg';

/// Builds the 44 seed mentors; slots are added later by [decorateMentors].
List<Mentor> buildSeedMentors() => [
  for (final row in mentorSeedRows)
    Mentor(
      id: row.id,
      name: row.name,
      title: row.title,
      yearsExperience: row.years,
      organizationLabel: row.org,
      bio: row.bio,
      topics: row.topics,
      fieldIds: row.fields,
      availableSlots: const [],
      isDemo: true,
    ),
];

/// Session counts grow with experience: juniors 10–60, mid 30–120, senior and lead 50–300.
int _sessionsFor(int years, int i) {
  if (years <= 2) return 10 + (i * 53) % 51;
  if (years <= 5) return 30 + (i * 53) % 91;
  return 50 + (i * 53) % 251;
}

/// Adds portrait, rating, sessions, reviews and slots to every mentor.
/// Index `i` is the mentor's position in the combined list, so the result is
/// stable between runs. Original mentors keep the slots they already have.
List<Mentor> decorateMentors(List<Mentor> mentors, DateTime current) {
  DateTime slot(int days, int hour) =>
      DateTime(current.year, current.month, current.day + days, hour);
  var men = 0;
  var women = 0;
  final seedFemale = {for (final row in mentorSeedRows) row.id: row.female};
  final result = <Mentor>[];
  for (var i = 0; i < mentors.length; i++) {
    final mentor = mentors[i];
    final isSeed = seedFemale.containsKey(mentor.id);
    final female =
        seedFemale[mentor.id] ?? originalMentorFemale[mentor.id] ?? false;
    final genderIndex = female ? women++ : men++;
    final rating = 4.0 + ((i * 37) % 11) / 10;
    final reviewCount = 2 + i % 2;
    result.add(
      mentor.copyWith(
        avatarAsset: portraitAsset(female: female, genderIndex: genderIndex),
        rating: double.parse(rating.toStringAsFixed(1)),
        sessionsCount: _sessionsFor(mentor.yearsExperience, i),
        responseTime: _responseTimes[i % _responseTimes.length],
        reviews: [
          for (var r = 0; r < reviewCount; r++)
            _reviewPool[(i * 3 + r * 4) % _reviewPool.length],
        ],
        availableSlots: isSeed
            ? (i % 11 == 5
                  ? const []
                  : [
                      for (final (days, hour)
                          in _slotPatterns[i % _slotPatterns.length])
                        slot(days, hour),
                    ])
            : null,
      ),
    );
  }
  return result;
}
