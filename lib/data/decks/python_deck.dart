import 'package:flutter/material.dart';

import '../../models/flashcard.dart';
import '../../models/flashcard_deck.dart';
import 'deck_helpers.dart';

const pythonDeckId = 'skill-python-data';

final pythonDeck = createSeedDeck(
  id: pythonDeckId,
  title: 'Python cơ bản cho dữ liệu',
  icon: Icons.code_rounded,
  color: const Color(0xFF76D8C8),
  group: FlashcardGroup.data,
  level: FlashcardLevel.basic,
  description: 'Kiểu dữ liệu, pandas và quy trình phân tích tái lập.',
  cards: [
    createSeedCard(
      id: 'py-01',
      deckId: pythonDeckId,
      type: FlashcardType.concept,
      front: 'List và dictionary khác nhau thế nào?',
      back: 'List lưu các phần tử theo vị trí; dictionary ánh xạ khóa sang giá trị. Dùng dict khi cần tra cứu theo tên khóa có ý nghĩa.',
      subTopic: 'Cấu trúc dữ liệu',
      example: 'scores = [8, 9]\nprofile = {"name": "An", "year": 2}',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'py-02',
      deckId: pythonDeckId,
      type: FlashcardType.howto,
      front: 'Đọc file CSV bằng pandas?',
      back: 'read_csv trả về DataFrame. Hãy kiểm tra đường dẫn, encoding và kiểu dữ liệu sau khi đọc.',
      subTopic: 'pandas',
      example: 'import pandas as pd\n\ndf = pd.read_csv("sales.csv")\nprint(df.head())',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'py-03',
      deckId: pythonDeckId,
      type: FlashcardType.howto,
      front: 'Xem kiểu dữ liệu và giá trị thiếu của từng cột?',
      back: 'info() cho biết kiểu và số giá trị non-null; isna().sum() đếm giá trị thiếu ở từng cột.',
      subTopic: 'Khám phá dữ liệu',
      example: 'df.info()\ndf.isna().sum()',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'py-04',
      deckId: pythonDeckId,
      type: FlashcardType.query,
      front: 'Lọc đơn có doanh thu trên 1 triệu trong pandas.',
      back: 'Điều kiện boolean lọc các dòng thỏa mãn; dùng ngoặc quanh mỗi điều kiện khi kết hợp & hoặc |.',
      subTopic: 'pandas',
      example: 'high_value = df[df["revenue"] > 1_000_000]',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'py-05',
      deckId: pythonDeckId,
      type: FlashcardType.query,
      front: 'Tính doanh thu trung bình theo kênh bán?',
      back: 'groupby chọn nhóm, agg định nghĩa phép tổng hợp cho cột. reset_index đưa nhãn nhóm trở lại thành cột thông thường.',
      subTopic: 'Tổng hợp',
      example: 'summary = (\n    df.groupby("channel", as_index=False)\n      .agg(avg_revenue=("revenue", "mean"))\n)',
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'py-06',
      deckId: pythonDeckId,
      type: FlashcardType.concept,
      front: 'DataFrame là gì?',
      back: 'Cấu trúc dữ liệu dạng bảng hai chiều của pandas, gồm các cột có nhãn và chỉ mục dòng; các cột có thể có kiểu dữ liệu khác nhau.',
      subTopic: 'pandas',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'py-07',
      deckId: pythonDeckId,
      type: FlashcardType.tip,
      front: 'Vì sao nên dùng vectorized operation thay vòng lặp từng dòng trong pandas?',
      back: 'Phép toán vector hóa thường ngắn gọn và tận dụng xử lý tối ưu ở thư viện; vẫn cần chọn phương án rõ ràng, đúng ngữ nghĩa.',
      subTopic: 'Hiệu năng',
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'py-08',
      deckId: pythonDeckId,
      type: FlashcardType.scenario,
      front: 'Một báo cáo phân tích cần chạy lại hàng tuần. Điều gì giúp kết quả tái lập?',
      back: 'Lưu mã và phiên bản phụ thuộc, xác định rõ nguồn/ thời điểm dữ liệu, cố định bước biến đổi và kiểm tra đầu ra bằng quy tắc chất lượng dữ liệu.',
      subTopic: 'Quy trình',
      difficulty: FlashcardDifficulty.medium,
    ),
  ],
);
