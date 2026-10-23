import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/data/decks/sql_deck.dart';
import 'package:uehero/screens/flashcard_home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in [320.0, 360.0, 600.0]) {
    testWidgets(
      'study route returns to the intact library at ${width.toInt()}px',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MaterialApp(home: FlashcardHomeScreen()));
        await tester.pumpAndSettle();
        expect(find.text('Thẻ kỹ năng nghề'), findsOneWidget);

        final deckFinder = find.byKey(
          const ValueKey('flashcard-deck-$sqlDeckId'),
        );
        await tester.scrollUntilVisible(
          deckFinder,
          280,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(deckFinder);
        await tester.pumpAndSettle();
        expect(find.text('1/18'), findsOneWidget);
        expect(find.text('SELECT dùng để làm gì?'), findsOneWidget);

        await tester.tap(find.byTooltip('Hiện đáp án'));
        await tester.pumpAndSettle();
        expect(find.text('GIẢI THÍCH'), findsOneWidget);

        await tester.tap(find.byTooltip('Về bộ thẻ'));
        await tester.pumpAndSettle();
        expect(deckFinder, findsOneWidget);
        expect(find.text('SELECT dùng để làm gì?'), findsNothing);
        final viewport = tester.getRect(find.byType(Scrollable).first);
        final deckRect = tester.getRect(deckFinder);
        expect(deckRect.top, greaterThanOrEqualTo(viewport.top));
        expect(deckRect.bottom, lessThanOrEqualTo(viewport.bottom));
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
        await tester.pumpAndSettle();
        expect(find.text('Thẻ kỹ năng nghề'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('SQL cho phân tích dữ liệu'),
          280,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.text('SQL cho phân tích dữ liệu'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
