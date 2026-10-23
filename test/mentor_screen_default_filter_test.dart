import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/data/mentor_demo_data.dart';
import 'package:uehero/screens/mentor_screen.dart';

void main() {
  testWidgets('mentor list shows every mentor by default even with a goal', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'career_goal': 'Data Analyst'});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MentorScreen()));
    await tester.pumpAndSettle();

    final total = MentorRepository.getMentors().length;
    expect(total, greaterThanOrEqualTo(60));
    expect(find.text('$total mentor'), findsOneWidget);
  });
}
