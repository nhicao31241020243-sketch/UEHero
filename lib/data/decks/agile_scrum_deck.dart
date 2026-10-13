import 'package:flutter/material.dart';

import '../../models/flashcard.dart';
import '../../models/flashcard_deck.dart';
import 'deck_helpers.dart';

const agileScrumDeckId = 'skill-agile-scrum';

final agileScrumDeck = createSeedDeck(
  id: agileScrumDeckId,
  title: 'Agile & Scrum',
  icon: Icons.groups_rounded,
  color: const Color(0xFF69D8BA),
  group: FlashcardGroup.project,
  level: FlashcardLevel.basic,
  description: 'Vai trò, sự kiện, tạo tác và cải tiến theo vòng lặp.',
  cards: [
    createSeedCard(
      id: 'ag-01',
      deckId: agileScrumDeckId,
      type: FlashcardType.concept,
      front: 'Ba accountabilities trong Scrum là gì?',
      back: 'Developers, Product Owner và Scrum Master. Đây là các accountability được định nghĩa trong Scrum Guide; tên chức danh tại công ty có thể khác.',
      subTopic: 'Vai trò',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'ag-02',
      deckId: agileScrumDeckId,
      type: FlashcardType.concept,
      front: 'Sprint Planning trả lời những câu hỏi nào?',
      back: 'Vì sao sprint có giá trị (Why), có thể hoàn thành gì (What), và công việc sẽ được thực hiện thế nào (How) theo Scrum Guide.',
      subTopic: 'Sự kiện',
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'ag-03',
      deckId: agileScrumDeckId,
      type: FlashcardType.concept,
      front: 'Daily Scrum là buổi báo cáo cho quản lý?',
      back: 'Không. Đây là sự kiện cho Developers kiểm tra tiến độ hướng tới Sprint Goal và điều chỉnh kế hoạch; cách tổ chức nên giữ trọng tâm này.',
      subTopic: 'Sự kiện',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'ag-04',
      deckId: agileScrumDeckId,
      type: FlashcardType.howto,
      front: 'Sprint Review khác Sprint Retrospective thế nào?',
      back: 'Review cùng stakeholder kiểm tra kết quả và thích ứng Product Backlog; Retrospective xem xét cách làm việc, chất lượng và cải tiến của nhóm.',
      subTopic: 'Sự kiện',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'ag-05',
      deckId: agileScrumDeckId,
      type: FlashcardType.tip,
      front: 'Agile có nghĩa là không cần lập kế hoạch hay tài liệu?',
      back: 'Không. Agile ưu tiên phản hồi và thích ứng, nhưng vẫn lập kế hoạch, tài liệu khi đem lại giá trị và duy trì trao đổi phù hợp.',
      subTopic: 'Agile mindset',
      difficulty: FlashcardDifficulty.medium,
    ),
  ],
);
