import 'package:flutter/material.dart';

import '../../models/flashcard.dart';
import '../../models/flashcard_deck.dart';
import 'deck_helpers.dart';

const figmaDeckId = 'skill-figma-wireframe';

final figmaDeck = createSeedDeck(
  id: figmaDeckId,
  title: 'Figma & Wireframe',
  icon: Icons.design_services_rounded,
  color: const Color(0xFF78D8BA),
  group: FlashcardGroup.tools,
  level: FlashcardLevel.basic,
  description: 'Từ bố cục khung đến prototype và cộng tác thiết kế.',
  cards: [
    createSeedCard(
      id: 'fig-01',
      deckId: figmaDeckId,
      type: FlashcardType.concept,
      front: 'Wireframe dùng để truyền đạt điều gì?',
      back: 'Wireframe thể hiện cấu trúc, thứ bậc thông tin và luồng cơ bản; thường chưa tập trung màu sắc/chi tiết thị giác cuối cùng.',
      subTopic: 'Wireframe',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'fig-02',
      deckId: figmaDeckId,
      type: FlashcardType.howto,
      front: 'Auto Layout trong Figma hữu ích khi nào?',
      back: 'Dùng cho thành phần cần tự co giãn theo nội dung, có khoảng cách nhất quán hoặc lặp lại như nút, card, hàng danh sách.',
      subTopic: 'Auto Layout',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'fig-03',
      deckId: figmaDeckId,
      type: FlashcardType.concept,
      front: 'Component và instance khác nhau thế nào?',
      back: 'Component là nguồn định nghĩa; instance là bản sử dụng có thể kế thừa và tùy chỉnh một số thuộc tính theo component.',
      subTopic: 'Component',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'fig-04',
      deckId: figmaDeckId,
      type: FlashcardType.howto,
      front: 'Prototype giúp kiểm tra điều gì trước khi phát triển?',
      back: 'Kiểm tra luồng, điều hướng, cách hiểu thao tác và giả thuyết trải nghiệm với người dùng; prototype không chứng minh tính khả thi kỹ thuật.',
      subTopic: 'Prototype',
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'fig-05',
      deckId: figmaDeckId,
      type: FlashcardType.tip,
      front: 'Chuẩn bị gì trước buổi handoff thiết kế?',
      back: 'Đặt tên layer rõ, tổ chức component, ghi trạng thái và hành vi, kiểm tra kích thước/spacing, cung cấp tài nguyên và nêu các trường hợp responsive.',
      subTopic: 'Handoff',
      difficulty: FlashcardDifficulty.medium,
    ),
  ],
);
