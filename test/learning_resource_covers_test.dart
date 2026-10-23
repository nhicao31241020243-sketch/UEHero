import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<Map<String, dynamic>> resources;

  setUpAll(() {
    final raw = jsonDecode(
      File('assets/learning_resources.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    resources = [
      for (final list in raw.values)
        for (final item in list as List) item as Map<String, dynamic>,
    ];
  });

  // Sách chưa có bìa Open Library khớp cả tên lẫn tác giả: dùng placeholder.
  const placeholderBooks = {'pm-scrum-guide'};

  test('resource ids are unique', () {
    final ids = resources.map((item) => item['id']).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every real book has a pinned ISBN or Open Library cover', () {
    final books = resources.where((item) => item['type'] == 'book');
    final missing = [
      for (final book in books)
        if ((book['isbn'] as String? ?? '').isEmpty &&
            (book['coverUrl'] as String? ?? '').isEmpty)
          book['id'] as String,
    ];
    expect(missing.toSet(), placeholderBooks);
  });

  test('pinned cover urls are https Open Library ids without blank images', () {
    for (final item in resources) {
      final url = item['coverUrl'] as String?;
      if (url == null) continue;
      expect(
        url,
        matches(
          RegExp(
            r'^https://covers\.openlibrary\.org/b/id/\d+-L\.jpg\?default=false$',
          ),
        ),
        reason: item['id'] as String,
      );
    }
  });

  test('courses and tools never pin a book cover', () {
    for (final item in resources.where((item) => item['type'] != 'book')) {
      expect(item['coverUrl'], isNull, reason: item['id'] as String);
      expect((item['isbn'] as String? ?? ''), isEmpty);
    }
  });
}
