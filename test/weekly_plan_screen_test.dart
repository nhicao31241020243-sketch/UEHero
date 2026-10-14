import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/screens/calendar_screen.dart';
import 'package:uehero/services/points_manager.dart';
import 'package:uehero/services/task_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PointsManager.instance.resetForTesting();
    TaskRepository.instance.resetForTesting();
  });

  for (final size in const [Size(320, 640), Size(600, 900)]) {
    testWidgets('Weekly Plan lays out at ${size.width}px', (tester) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(find.text('Weekly Plan'), findsOneWidget);
      expect(find.textContaining('Tuần này:'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Mở cả tháng'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'saving a manual task closes its sheet without lifecycle errors',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      await tester.tap(find.byTooltip('Thêm công việc'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Việc kiểm tra lifecycle');
      await tester.tap(find.text('LƯU CÔNG VIỆC'));
      await tester.pumpAndSettle();

      expect(
        (await TaskRepository.instance.list()).any(
          (task) => task.noiDung == 'Việc kiểm tra lifecycle',
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
