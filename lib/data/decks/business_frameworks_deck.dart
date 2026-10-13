import 'package:flutter/material.dart';

import '../../models/flashcard.dart';
import '../../models/flashcard_deck.dart';
import 'deck_helpers.dart';

const businessFrameworksDeckId = 'skill-business-frameworks';

final businessFrameworksDeck = createSeedDeck(
  id: businessFrameworksDeckId,
  title: 'Framework kinh doanh',
  icon: Icons.lightbulb_outline_rounded,
  color: const Color(0xFF70D6B3),
  group: FlashcardGroup.analysis,
  level: FlashcardLevel.basic,
  description: 'SWOT, 5 Whys, KPI, OKR và đánh giá ROI.',
  cards: [
    createSeedCard(
      id: 'biz-01',
      deckId: businessFrameworksDeckId,
      type: FlashcardType.concept,
      front: 'SWOT gồm những nhóm yếu tố nào?',
      back: 'Strengths và Weaknesses thường là yếu tố nội bộ; Opportunities và Threats thường là yếu tố bên ngoài. SWOT là khung thảo luận, không tự thay thế bằng chứng.',
      subTopic: 'SWOT',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'biz-02',
      deckId: businessFrameworksDeckId,
      type: FlashcardType.howto,
      front: 'Dùng 5 Whys thế nào cho hiệu quả?',
      back: 'Lặp lại câu hỏi “vì sao” để lần theo nguyên nhân, nhưng kiểm tra mỗi bước bằng dữ kiện. Có thể có nhiều nhánh nguyên nhân; không ép đủ đúng năm lần.',
      subTopic: '5 Whys',
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'biz-03',
      deckId: businessFrameworksDeckId,
      type: FlashcardType.concept,
      front: 'KPI tốt cần được định nghĩa ra sao?',
      back: 'Nêu tên chỉ số, công thức, phạm vi, nguồn dữ liệu, kỳ đo, chủ sở hữu và cách diễn giải. Chỉ số cần hỗ trợ quyết định thay vì chỉ dễ đo.',
      subTopic: 'KPI',
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'biz-04',
      deckId: businessFrameworksDeckId,
      type: FlashcardType.concept,
      front: 'Objective và Key Result trong OKR khác nhau thế nào?',
      back: 'Objective mô tả hướng đi/mục tiêu định tính có ý nghĩa; Key Results là kết quả đo lường cho biết mức đạt mục tiêu. Initiative là việc làm để tác động kết quả.',
      subTopic: 'OKR',
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'biz-05',
      deckId: businessFrameworksDeckId,
      type: FlashcardType.query,
      front: 'ROI đơn giản được tính thế nào?',
      back: 'Một dạng phổ biến là (lợi ích ròng − chi phí đầu tư) / chi phí đầu tư. Phải thống nhất kỳ đo, cách quy đổi lợi ích và chi phí; không nhầm với doanh thu.',
      subTopic: 'ROI',
      example: 'ROI = (Net benefit - Investment cost) / Investment cost',
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'biz-06',
      deckId: businessFrameworksDeckId,
      type: FlashcardType.tip,
      front: 'Tại sao không nên dùng một chỉ số duy nhất để kết luận hiệu quả?',
      back: 'Chỉ số có thể bị ảnh hưởng bởi yếu tố ngoài kiểm soát hoặc tạo hành vi tối ưu sai mục tiêu. Kết hợp chỉ số kết quả và chỉ số bảo vệ/chất lượng khi phù hợp.',
      subTopic: 'KPI',
      difficulty: FlashcardDifficulty.hard,
    ),
  ],
);
