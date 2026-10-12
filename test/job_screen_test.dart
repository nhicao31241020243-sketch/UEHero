import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/screens/job_screen.dart';

void main() {
  testWidgets('job list and details fit a 320px viewport', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: JobScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Xem job sinh viên'), findsOneWidget);
    await tester.tap(find.text('Business Analyst Intern').first);
    await tester.pumpAndSettle();

    expect(find.text('Phân tích độ khớp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
