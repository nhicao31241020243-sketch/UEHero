import 'package:flutter/material.dart';

import '../../models/flashcard.dart';
import '../../models/flashcard_deck.dart';
import 'deck_helpers.dart';

const excelDeckId = 'skill-excel';

final excelDeck = createSeedDeck(
  id: excelDeckId,
  title: 'Excel cho công việc',
  icon: Icons.table_chart_rounded,
  color: const Color(0xFF98DB82),
  group: FlashcardGroup.data,
  level: FlashcardLevel.basic,
  description: 'Hàm tra cứu, tổng hợp và PivotTable cho bài toán nghiệp vụ.',
  cards: [
    createSeedCard(
      id: 'xl-01',
      deckId: excelDeckId,
      type: FlashcardType.concept,
      front: 'PivotTable giúp giải quyết việc gì?',
      back: 'Tóm tắt và phân tích nhiều dòng dữ liệu theo các trường hàng, cột, giá trị và bộ lọc mà không cần tự viết nhiều công thức.',
      subTopic: 'PivotTable',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'xl-02',
      deckId: excelDeckId,
      type: FlashcardType.howto,
      front: 'XLOOKUP tìm kiếm và trả kết quả thế nào?',
      back: 'Cú pháp cơ bản: XLOOKUP(giá_trị_tìm, cột_tìm, cột_trả_về). Mặc định tìm khớp chính xác và có thể trả kết quả ở bất kỳ phía nào.',
      subTopic: 'XLOOKUP',
      example: '=XLOOKUP(E2, A:A, C:C, "Không tìm thấy")',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'xl-03',
      deckId: excelDeckId,
      type: FlashcardType.query,
      front: 'Tính tổng doanh số của vùng “South” trong tháng 1 bằng SUMIFS.',
      back: 'SUMIFS nhận vùng cần cộng trước, sau đó là các cặp vùng điều kiện và giá trị điều kiện. Với ngày nên dùng cận đầu và cận cuối tháng.',
      subTopic: 'SUMIFS',
      example: '=SUMIFS(D:D, B:B, "South", A:A, ">="&DATE(2025,1,1), A:A, "<"&DATE(2025,2,1))',
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'xl-04',
      deckId: excelDeckId,
      type: FlashcardType.concept,
      front: 'Vì sao nên dùng bảng Excel (Format as Table)?',
      back: 'Bảng tự mở rộng, có structured references dễ đọc, tự lan công thức và tích hợp thuận tiện với lọc, PivotTable và Power Query.',
      subTopic: 'Bảng dữ liệu',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'xl-05',
      deckId: excelDeckId,
      type: FlashcardType.tip,
      front: 'Một công thức có thể lỗi khi kéo xuống do tham chiếu đổi. Cách xử lý?',
      back: 'Dùng tham chiếu tuyệt đối cho ô cố định bằng ký hiệu đô la, ví dụ khóa cả cột và hàng; tham chiếu hỗn hợp chỉ khóa một chiều.',
      subTopic: 'Công thức',
      example: r'=$B$2*C5',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'xl-06',
      deckId: excelDeckId,
      type: FlashcardType.howto,
      front: 'Khi nào nên dùng IFERROR?',
      back: 'Dùng để xử lý lỗi dự kiến và hiển thị thông báo/giá trị dễ hiểu; không nên bọc mọi công thức để che lỗi dữ liệu cần điều tra.',
      subTopic: 'Làm sạch',
      example: '=IFERROR(XLOOKUP(E2,A:A,B:B), "Chưa có mã")',
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'xl-07',
      deckId: excelDeckId,
      type: FlashcardType.scenario,
      front: 'PivotTable không nhận các dòng mới vừa thêm. Kiểm tra gì?',
      back: 'Nếu dùng vùng dữ liệu tĩnh, hãy đổi nguồn hoặc chuyển vùng nguồn thành Excel Table. Sau đó refresh PivotTable.',
      subTopic: 'PivotTable',
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'xl-08',
      deckId: excelDeckId,
      type: FlashcardType.concept,
      front: 'COUNT, COUNTA và COUNTBLANK khác nhau thế nào?',
      back: 'COUNT đếm ô số; COUNTA đếm ô không rỗng; COUNTBLANK đếm ô trống (cách xử lý công thức trả chuỗi rỗng có thể phụ thuộc hàm).',
      subTopic: 'Hàm đếm',
      difficulty: FlashcardDifficulty.easy,
    ),
  ],
);
