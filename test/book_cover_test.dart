import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/screens/second_hand_market_screen.dart';
import 'package:uehero/widgets/book_cover.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LearningResource reads optional coverUrl', () {
    final base = {
      'id': 'a',
      'title': 'T',
      'type': 'book',
      'skill': 'SQL',
      'level': 'basic',
      'why': 'w',
      'lang': 'en',
    };
    expect(LearningResource.fromJson('BA', base).coverUrl, isNull);
    expect(
      LearningResource.fromJson('BA', {
        ...base,
        'coverUrl': 'https://x/y.jpg',
      }).coverUrl,
      'https://x/y.jpg',
    );
  });

  testWidgets('BookCover keeps 2:3 ratio and shows placeholder title', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 120,
            child: BookCover(id: 'x', title: 'Sách thử', author: ''),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 6));
    expect(tester.getSize(find.byType(BookCover)), const Size(120, 180));
    expect(tester.takeException(), isNull);
  });
}
