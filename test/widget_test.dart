import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uehero/main.dart';

void main() {
  testWidgets('Welcome shows only its background and Start action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UEHeroApp());
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Ready to explore?'), findsNothing);
    expect(find.byIcon(Icons.rocket_launch_rounded), findsNothing);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Sign up'), findsOneWidget);
  });
}
