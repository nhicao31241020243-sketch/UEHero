import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/event_item.dart';

abstract class EventRepository {
  Future<List<EventItem>> fetchEvents();
}

class LocalEventRepository implements EventRepository {
  // TODO: Cập nhật hằng tuần từ BrandsVietnam mục Hội thảo & Sự kiện,
  // fanpage CLB và Phòng Quan hệ doanh nghiệp UEH; luôn ghi sourceUrl và verifiedAt.
  @override
  Future<List<EventItem>> fetchEvents() async {
    final source = await rootBundle.loadString('assets/data/events.json');
    final decoded = jsonDecode(source);
    if (decoded is! List) {
      throw const FormatException('events.json phải là một mảng sự kiện');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(EventItem.fromJson)
        .toList(growable: false);
  }
}
