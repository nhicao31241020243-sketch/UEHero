import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/screens/career_notebook_screen.dart';

void main() {
  testWidgets('notebook has a single page and period range selector', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CareerNotebookScreen())),
    );

    expect(find.text('Sổ tay'), findsOneWidget);
    expect(find.text('ASTRONAUT ACADEMY'), findsOneWidget);
    expect(find.text('Tổng quan'), findsNothing);
    expect(find.text('Mục tiêu'), findsNothing);
    await tester.tap(find.text('Tất cả'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tuần này'), findsOneWidget);
    expect(find.text('Tháng này'), findsOneWidget);
  });
}
