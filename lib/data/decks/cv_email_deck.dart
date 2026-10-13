import 'package:flutter/material.dart';

import '../../models/flashcard.dart';
import '../../models/flashcard_deck.dart';
import 'deck_helpers.dart';

const cvEmailDeckId = 'skill-cv-email';

final cvEmailDeck = createSeedDeck(
  id: cvEmailDeckId,
  title: 'Viết CV & email chuyên nghiệp',
  icon: Icons.description_rounded,
  color: const Color(0xFF78D9BC),
  group: FlashcardGroup.communication,
  level: FlashcardLevel.basic,
  description: 'Diễn đạt kinh nghiệm có bằng chứng và email rõ mục đích.',
  cards: [
    createSeedCard(
      id: 'cv-01',
      deckId: cvEmailDeckId,
      type: FlashcardType.howto,
      front: 'Một bullet kinh nghiệm CV nên nêu những gì?',
      back: 'Hành động bạn thực hiện, phạm vi/công cụ liên quan và kết quả hoặc sản phẩm đầu ra có thể kiểm chứng. Chỉ dùng số liệu khi có cơ sở.',
      subTopic: 'Kinh nghiệm',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'cv-02',
      deckId: cvEmailDeckId,
      type: FlashcardType.tip,
      front: 'Làm sao điều chỉnh CV theo mô tả công việc mà không nói quá?',
      back: 'Ưu tiên bằng chứng thật liên quan, dùng thuật ngữ chính xác khi phù hợp và phân biệt rõ kỹ năng đã dùng với kỹ năng mới học.',
      subTopic: 'Tùy chỉnh CV',
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'cv-03',
      deckId: cvEmailDeckId,
      type: FlashcardType.concept,
      front: 'Email ứng tuyển cần những phần nào?',
      back: 'Tiêu đề dễ nhận diện, lời chào, vị trí ứng tuyển, giới thiệu ngắn phù hợp, tệp đính kèm được nêu rõ, lời cảm ơn và chữ ký/liên hệ.',
      subTopic: 'Email',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'cv-04',
      deckId: cvEmailDeckId,
      type: FlashcardType.howto,
      front: 'Nên đặt tên file CV thế nào?',
      back: 'Dùng tên rõ và chuyên nghiệp, ví dụ NguyenVanA_CV_DataAnalyst.pdf; kiểm tra quyền mở, định dạng và không gửi nhầm bản cũ.',
      subTopic: 'Hồ sơ',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'cv-05',
      deckId: cvEmailDeckId,
      type: FlashcardType.tip,
      front: 'Trước khi gửi email ứng tuyển, kiểm tra nhanh điều gì?',
      back: 'Đúng người nhận/vị trí, tiêu đề, lời xưng hô, chính tả, tệp đính kèm mở được, tên file chuyên nghiệp và thông tin liên hệ.',
      subTopic: 'Email',
      difficulty: FlashcardDifficulty.easy,
    ),
  ],
);
