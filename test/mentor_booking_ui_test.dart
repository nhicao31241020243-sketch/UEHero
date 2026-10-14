import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/data/mentor_demo_data.dart';
import 'package:uehero/screens/mentor_bookings_screen.dart';
import 'package:uehero/screens/mentor_profile_screen.dart';

void main() {
  testWidgets('question-only request can be confirmed and completed in demo', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final mentor = MentorRepository.getMentors().firstWhere(
      (item) => item.availableSlots.isEmpty,
    );
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MentorProfileScreen(mentor: mentor),
                      ),
                    ),
                    child: const Text('Mở hồ sơ'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MentorBookingsScreen(),
                      ),
                    ),
                    child: const Text('Lịch hẹn'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở hồ sơ'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Gửi câu hỏi'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Gửi câu hỏi'), findsOneWidget);
    await tester.tap(find.text('Gửi câu hỏi'));
    await tester.pumpAndSettle();
    expect(
      find.text('Mentor mẫu, yêu cầu chỉ lưu trên máy này'),
      findsOneWidget,
    );
    await tester.tap(find.text('Gửi câu hỏi').last);
    await tester.pumpAndSettle();
    expect(find.text('Hãy nhập câu hỏi để gửi cho mentor.'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField),
      'Em muốn hỏi về hướng phát triển portfolio.',
    );
    await tester.ensureVisible(find.text('Gửi câu hỏi').last);
    await tester.tap(find.text('Gửi câu hỏi').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Đã gửi yêu cầu, trạng thái: Chờ xác nhận'),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lịch hẹn'));
    await tester.pumpAndSettle();
    expect(find.text('Chờ xác nhận · 1'), findsOneWidget);
    await tester.tap(find.text('Demo · Giả lập mentor xác nhận'));
    await tester.pumpAndSettle();
    expect(find.text('Đã hẹn · 1'), findsOneWidget);
    await tester.tap(find.text('Demo · Giả lập đã gặp'));
    await tester.pumpAndSettle();
    expect(find.text('Ghi 1-3 việc cần làm sau buổi gặp'), findsOneWidget);
    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();
    expect(find.text('Đã gặp · 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
