import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/screens/job_screen.dart';
import 'package:uehero/services/job_repository.dart';
import 'package:uehero/services/points_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'career_goal': 'Business Analyst',
    });
    JobRepository.instance.resetForTesting();
    PointsManager.instance.resetForTesting();
  });

  testWidgets('Job Match layout and details fit a 320px viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: JobScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Khám phá việc làm'), findsOneWidget);
    expect(find.text('Gợi ý cho bạn'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Business Analyst Intern').first);
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết công việc'), findsOneWidget);
    expect(find.text('Độ khớp với kỹ năng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
