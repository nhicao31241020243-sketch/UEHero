import 'package:flutter/material.dart';

import '../../models/flashcard.dart';
import '../../models/flashcard_deck.dart';
import 'deck_helpers.dart';

const requirementsDeckId = 'skill-requirements';

final requirementsDeck = createSeedDeck(
  id: requirementsDeckId,
  title: 'Phân tích yêu cầu',
  icon: Icons.fact_check_rounded,
  color: const Color(0xFF78D9C1),
  group: FlashcardGroup.analysis,
  level: FlashcardLevel.basic,
  description: 'User story, use case, acceptance criteria và MoSCoW.',
  cards: [
    createSeedCard(
      id: 'req-01',
      deckId: requirementsDeckId,
      type: FlashcardType.concept,
      front: 'Functional requirement mô tả điều gì?',
      back: 'Mô tả hành vi hoặc chức năng hệ thống cần cung cấp, thường gắn với tác nhân và điều kiện sử dụng.',
      subTopic: 'Yêu cầu',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'req-02',
      deckId: requirementsDeckId,
      type: FlashcardType.concept,
      front: 'Non-functional requirement có ví dụ nào?',
      back: 'Yêu cầu về chất lượng/ràng buộc như hiệu năng, bảo mật, tính sẵn sàng hoặc khả năng tiếp cận. Nên diễn đạt đo lường được khi có thể.',
      subTopic: 'Yêu cầu',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'req-03',
      deckId: requirementsDeckId,
      type: FlashcardType.howto,
      front: 'Viết acceptance criteria tốt thế nào?',
      back: 'Viết điều kiện quan sát/kiểm tra được cho các luồng chính và trường hợp biên. Given–When–Then là một định dạng thường dùng.',
      subTopic: 'Acceptance criteria',
      example: 'Given giỏ hàng có sản phẩm\nWhen người dùng xác nhận đơn\nThen hệ thống tạo đơn và hiển thị mã đơn',
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'req-04',
      deckId: requirementsDeckId,
      type: FlashcardType.concept,
      front: 'MoSCoW gồm các mức nào?',
      back: 'Must have, Should have, Could have, Won’t have (for now). Đây là cách ưu tiên phạm vi theo giá trị và giới hạn hiện tại, không phải nhãn độ quan trọng vĩnh viễn.',
      subTopic: 'MoSCoW',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'req-05',
      deckId: requirementsDeckId,
      type: FlashcardType.tip,
      front: 'Làm sao xử lý yêu cầu mơ hồ?',
      back: 'Hỏi ai gặp vấn đề, mục tiêu và tiêu chí thành công; đưa ví dụ/luồng mẫu, xác nhận giả định và ghi lại quyết định với stakeholder.',
      subTopic: 'Khai thác yêu cầu',
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'req-06',
      deckId: requirementsDeckId,
      type: FlashcardType.concept,
      front: 'User story khác use case ở đâu?',
      back: 'User story ngắn gọn tập trung vai trò, mục tiêu và giá trị; use case mô tả tương tác, luồng chính và luồng thay thế chi tiết hơn. Hai cách có thể bổ trợ nhau.',
      subTopic: 'User story',
      difficulty: FlashcardDifficulty.medium,
    ),
  ],
);
