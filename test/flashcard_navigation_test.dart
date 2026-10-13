import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/data/decks/sql_deck.dart';
import 'package:uehero/screens/flashcard_home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('study route returns to the intact library at 320px', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: FlashcardHomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Thẻ kỹ năng nghề'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('flashcard-deck-$sqlDeckId')),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('flashcard-deck-$sqlDeckId')));
    await tester.pumpAndSettle();
    expect(find.text('1/18'), findsOneWidget);
    expect(find.text('SELECT dùng để làm gì?'), findsOneWidget);

    await tester.tap(find.byTooltip('Hiện đáp án'));
    await tester.pumpAndSettle();
    expect(find.text('GIẢI THÍCH'), findsOneWidget);

    await tester.tap(find.byTooltip('Về bộ thẻ'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('flashcard-deck-$sqlDeckId')),
      findsOneWidget,
    );
    expect(find.text('SELECT dùng để làm gì?'), findsNothing);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('Thẻ kỹ năng nghề'), findsOneWidget);
    expect(find.text('SQL cho phân tích dữ liệu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
