import 'package:flutter/material.dart';

import '../../models/flashcard.dart';
import '../../models/flashcard_deck.dart';
import 'deck_helpers.dart';

const processModelingDeckId = 'skill-process-modeling';

final processModelingDeck = createSeedDeck(
  id: processModelingDeckId,
  title: 'Mô hình hóa quy trình',
  icon: Icons.account_tree_rounded,
  color: const Color(0xFF7BD9C2),
  group: FlashcardGroup.analysis,
  level: FlashcardLevel.intermediate,
  description: 'Đọc BPMN, UML và ERD để diễn đạt quy trình, hệ thống, dữ liệu.',
  cards: [
    createSeedCard(
      id: 'mod-01',
      deckId: processModelingDeckId,
      type: FlashcardType.concept,
      front: 'BPMN pool và lane biểu thị điều gì?',
      back: 'Pool biểu thị một participant/quy trình; lane chia trách nhiệm theo vai trò hoặc đơn vị trong pool. Quy ước cụ thể phụ thuộc mô hình.',
      subTopic: 'BPMN',
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'mod-02',
      deckId: processModelingDeckId,
      type: FlashcardType.concept,
      front: 'Trong BPMN, gateway dùng để làm gì?',
      back: 'Gateway điều khiển phân nhánh hoặc đồng bộ luồng. Exclusive gateway chọn một nhánh; parallel gateway kích hoạt/đồng bộ các nhánh song song.',
      subTopic: 'BPMN',
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'mod-03',
      deckId: processModelingDeckId,
      type: FlashcardType.concept,
      front: 'Use case diagram UML cho thấy điều gì?',
      back: 'Cho thấy actor bên ngoài và các use case (mục tiêu/chức năng) họ tương tác, cùng ranh giới hệ thống; không diễn tả thứ tự chi tiết của luồng.',
      subTopic: 'UML',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'mod-04',
      deckId: processModelingDeckId,
      type: FlashcardType.concept,
      front: 'ERD mô tả các yếu tố nào?',
      back: 'Entity, thuộc tính, khóa và quan hệ/cardinality giữa các entity; dùng để trao đổi cấu trúc dữ liệu ở mức phù hợp.',
      subTopic: 'ERD',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'mod-05',
      deckId: processModelingDeckId,
      type: FlashcardType.tip,
      front: 'Tại sao phải ghi rõ giả định trên sơ đồ quy trình?',
      back: 'Giúp người đọc biết phạm vi, ngoại lệ hay trách nhiệm nào chưa được xác nhận và tránh nhầm mô hình hiện trạng với quy trình mục tiêu.',
      subTopic: 'Thực hành mô hình',
      difficulty: FlashcardDifficulty.medium,
    ),
  ],
);
