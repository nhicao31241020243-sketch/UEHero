import 'package:flutter/material.dart';

import '../../models/flashcard.dart';
import '../../models/flashcard_deck.dart';
import 'deck_helpers.dart';

const stakeholderDeckId = 'skill-stakeholder-communication';

final stakeholderDeck = createSeedDeck(
  id: stakeholderDeckId,
  title: 'Giao tiếp stakeholder',
  icon: Icons.forum_rounded,
  color: const Color(0xFF63D3B9),
  group: FlashcardGroup.communication,
  level: FlashcardLevel.basic,
  description: 'Lắng nghe, xác nhận kỳ vọng và trình bày quyết định rõ ràng.',
  cards: [
    createSeedCard(
      id: 'com-01',
      deckId: stakeholderDeckId,
      type: FlashcardType.howto,
      front: 'Cách xác nhận bạn hiểu đúng nhu cầu stakeholder?',
      back: 'Tóm tắt mục tiêu, người dùng, tình huống, tiêu chí thành công và điểm chưa rõ bằng lời của mình; xin họ xác nhận hoặc sửa.',
      subTopic: 'Lắng nghe',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'com-02',
      deckId: stakeholderDeckId,
      type: FlashcardType.tip,
      front: 'Làm gì khi hai stakeholder đưa ra yêu cầu mâu thuẫn?',
      back: 'Làm rõ mục tiêu và tác động của từng yêu cầu, đưa trade-off minh bạch, xác định người có quyền quyết định và ghi lại quyết định cùng lý do.',
      subTopic: 'Quản lý kỳ vọng',
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'com-03',
      deckId: stakeholderDeckId,
      type: FlashcardType.howto,
      front: 'Trình bày phát hiện dữ liệu cho người bận rộn theo thứ tự nào?',
      back: 'Bắt đầu bằng kết luận/khuyến nghị, sau đó nêu bằng chứng chính, phạm vi và giới hạn, cuối cùng là quyết định hoặc hành động cần thống nhất.',
      subTopic: 'Trình bày',
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'com-04',
      deckId: stakeholderDeckId,
      type: FlashcardType.scenario,
      front:
          'Stakeholder xin thêm phạm vi ngay trước deadline. Phản hồi ra sao?',
      back: 'Ghi nhận nhu cầu, hỏi mức ưu tiên và hạn cần; ước tính tác động lên thời gian/rủi ro, đưa lựa chọn đổi phạm vi hoặc mốc phát hành rồi xác nhận quyết định.',
      subTopic: 'Quản lý kỳ vọng',
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'com-05',
      deckId: stakeholderDeckId,
      type: FlashcardType.tip,
      front: 'Một biên bản họp quyết định nên ghi gì?',
      back: 'Quyết định, lý do/giả định quan trọng, người chịu trách nhiệm, hạn xử lý và câu hỏi còn mở; gửi lại để người tham gia xác nhận.',
      subTopic: 'Tài liệu',
      difficulty: FlashcardDifficulty.easy,
    ),
  ],
);
