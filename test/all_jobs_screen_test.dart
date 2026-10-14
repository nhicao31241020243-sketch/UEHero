import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/data/job_demo_data.dart';
import 'package:uehero/models/student_job.dart';
import 'package:uehero/screens/all_jobs_screen.dart';
import 'package:uehero/services/job_repository.dart';
import 'package:uehero/services/points_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    JobRepository.instance.resetForTesting();
    PointsManager.instance.resetForTesting();
  });

  testWidgets('empty results can be cleared', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AllJobsScreen(
          initialState: JobFilterState(
            fieldId: 'unknown-field',
            location: 'Toàn quốc',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.text('Chưa có việc phù hợp, thử bỏ bớt bộ lọc'),
      findsOneWidget,
    );
    await tester.tap(find.text('Xóa lọc').first);
    await tester.pumpAndSettle();
    expect(find.text('24 việc phù hợp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pill switches between saved, applied and all jobs', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'student_job_statuses',
      '{"${jobDemoData.first.id}":"saved","${jobDemoData[1].id}":"applied"}',
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: AllJobsScreen(
          initialState: JobFilterState(location: 'Toàn quốc'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('24 việc phù hợp'), findsOneWidget);

    await tester.tap(find.text('Đã lưu'));
    await tester.pumpAndSettle();
    expect(find.text('1 việc phù hợp'), findsOneWidget);

    await tester.tap(find.text('Đã ứng tuyển'));
    await tester.pumpAndSettle();
    expect(find.text('1 việc phù hợp'), findsOneWidget);

    await tester.tap(find.text('Đã ứng tuyển'));
    await tester.pumpAndSettle();
    expect(find.text('24 việc phù hợp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
