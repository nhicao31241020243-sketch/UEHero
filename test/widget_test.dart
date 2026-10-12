import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:uehero/main.dart';

void main() {
  testWidgets('Welcome routes through sign up, career goal, and mascot', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const UEHeroApp());
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Ready to explore?'), findsNothing);
    expect(find.byIcon(Icons.rocket_launch_rounded), findsNothing);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Sign up'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mục tiêu nghề nghiệp'), findsOneWidget);
    expect(find.text('Business Analyst'), findsWidgets);

    final businessAnalyst = find.text('Business Analyst').last;
    await tester.ensureVisible(businessAnalyst);
    await tester.tap(businessAnalyst);
    await tester.pump();
    final continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Tiếp tục'),
    );
    expect(continueButton.onPressed, isNotNull);
  });

  testWidgets('debug flag shows onboarding even when choices were saved', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'career_goal': 'Frontend Developer',
      'selected_mascot': 'space-astronaut-finn',
    });
    await tester.pumpWidget(const UEHeroApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Mục tiêu nghề nghiệp'), findsOneWidget);
    expect(find.text('Frontend Developer'), findsWidgets);
    expect(find.text('Tiếp tục'), findsOneWidget);
  });
}
