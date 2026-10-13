import 'package:flutter/material.dart';

import '../../models/flashcard.dart';
import '../../models/flashcard_deck.dart';
import 'deck_helpers.dart';

const jiraDeckId = 'skill-jira-confluence';

final jiraDeck = createSeedDeck(
  id: jiraDeckId,
  title: 'Jira & Confluence',
  icon: Icons.view_kanban_rounded,
  color: const Color(0xFF67CDB8),
  group: FlashcardGroup.tools,
  level: FlashcardLevel.basic,
  description: 'Quản lý backlog, sprint và tài liệu nhóm.',
  cards: [
    createSeedCard(
      id: 'jira-01',
      deckId: jiraDeckId,
      type: FlashcardType.concept,
      front: 'Epic, Story và Task thường biểu thị điều gì trong Jira?',
      back: 'Epic nhóm công việc lớn; Story mô tả giá trị hoặc nhu cầu người dùng; Task là việc cần thực hiện. Cách cấu hình loại issue có thể tùy dự án.',
      subTopic: 'Backlog',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'jira-02',
      deckId: jiraDeckId,
      type: FlashcardType.howto,
      front: 'Một user story tốt nên có những phần nào?',
      back: 'Mẫu phổ biến: “Là [vai trò], tôi muốn [mục tiêu], để [giá trị]”, kèm tiêu chí chấp nhận có thể kiểm tra.',
      subTopic: 'User story',
      example:
          'Là khách hàng, tôi muốn lưu địa chỉ giao hàng để đặt đơn nhanh hơn.',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'jira-03',
      deckId: jiraDeckId,
      type: FlashcardType.tip,
      front: 'Definition of Done giúp ích gì?',
      back: 'Thống nhất tiêu chuẩn tối thiểu để coi công việc hoàn tất, ví dụ review, kiểm thử và cập nhật tài liệu. Tiêu chí cần phù hợp nhóm và sản phẩm.',
      subTopic: 'Quy trình',
      difficulty: FlashcardDifficulty.medium,
    ),
    createSeedCard(
      id: 'jira-04',
      deckId: jiraDeckId,
      type: FlashcardType.concept,
      front: 'Confluence page khác space thế nào?',
      back: 'Page chứa nội dung cụ thể; space là vùng tổ chức các page theo nhóm, dự án hoặc chủ đề trong Confluence.',
      subTopic: 'Confluence',
      difficulty: FlashcardDifficulty.easy,
    ),
    createSeedCard(
      id: 'jira-05',
      deckId: jiraDeckId,
      type: FlashcardType.scenario,
      front: 'Yêu cầu thay đổi giữa sprint. Nhóm nên làm gì?',
      back: 'Trao đổi tác động và mức ưu tiên với Product Owner/nhóm, điều chỉnh phạm vi nếu cần theo thỏa thuận; không âm thầm thêm việc làm mất tính minh bạch.',
      subTopic: 'Sprint',
      difficulty: FlashcardDifficulty.medium,
    ),
  ],
);
