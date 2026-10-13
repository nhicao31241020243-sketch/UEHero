import 'package:flutter/material.dart';

import '../../models/flashcard.dart';
import '../../models/flashcard_deck.dart';
import 'deck_helpers.dart';

const englishJdDeckId = 'skill-english-jd';

final englishJdDeck = createSeedDeck(
  id: englishJdDeckId,
  title: 'Tiếng Anh công sở & đọc JD',
  icon: Icons.translate_rounded,
  color: const Color(0xFF6FD7BF),
  group: FlashcardGroup.english,
  level: FlashcardLevel.basic,
  description: 'Thuật ngữ tuyển dụng và cách trao đổi chuyên nghiệp.',
  cards: [
    createSeedCard(
      id: 'en-01',
      deckId: englishJdDeckId,
      type: FlashcardType.concept,
      front: '“Responsibilities” trong job description là gì?',
      back: 'Các nhiệm vụ/trách nhiệm chính của vị trí. Hãy đối chiếu với phần “Requirements” (yêu cầu năng lực/điều kiện).',
      subTopic: 'Đọc JD',
      tags: ['tuyển dụng'],
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'en-02',
      deckId: englishJdDeckId,
      type: FlashcardType.concept,
      front: '“Nice to have” có nghĩa là gì khi đọc JD?',
      back: 'Kỹ năng có lợi thế nhưng thường không phải điều kiện bắt buộc như “must-have”. Tuy nhiên cần xác nhận ưu tiên với nhà tuyển dụng nếu chưa rõ.',
      subTopic: 'Đọc JD',
      tags: ['tuyển dụng'],
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'en-03',
      deckId: englishJdDeckId,
      type: FlashcardType.howto,
      front: 'Viết email chuyên nghiệp để xin lịch phỏng vấn khác?',
      back: 'Cảm ơn lời mời, nêu ngắn gọn lý do không thể tham dự khung giờ đó, đề xuất vài khung giờ thay thế kèm múi giờ và bày tỏ mong muốn tham gia.',
      subTopic: 'Email',
      tags: ['lịch sự'],
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'en-04',
      deckId: englishJdDeckId,
      type: FlashcardType.concept,
      front: '“I am responsible for” khác “I contributed to” thế nào?',
      back: 'Responsible for thể hiện trách nhiệm trực tiếp; contributed to nhấn mạnh phần đóng góp trong công việc chung. Dùng đúng mức độ tham gia thực tế.',
      subTopic: 'CV English',
      tags: ['trung thực'],
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'en-05',
      deckId: englishJdDeckId,
      type: FlashcardType.tip,
      front: '“Entry-level” và “internship” thường chỉ gì?',
      back: 'Entry-level là vị trí đầu sự nghiệp; internship là chương trình/vị trí thực tập. Điều kiện cụ thể khác nhau theo công ty và JD.',
      subTopic: 'Đọc JD',
      tags: ['tuyển dụng'],
      difficulty: FlashcardDifficulty.easy,
    ),
  ],
);
