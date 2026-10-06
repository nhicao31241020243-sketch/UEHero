import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uehero/screens/campus_map_3d_screen.dart';

void main() {
  testWidgets('campus map filters booths and opens spot details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CampusMap3DScreen()));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Bản đồ 3D UEH'), findsOneWidget);
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.byTooltip('Cổng chính Nguyễn Tri Phương'), findsOneWidget);
    expect(find.byTooltip('Cây đàn piano'), findsOneWidget);
    expect(find.byTooltip('Căn tin'), findsOneWidget);
    expect(find.byTooltip('Khối phòng B1'), findsOneWidget);
    expect(find.byTooltip('Khối phòng B2'), findsOneWidget);

    await tester.tap(find.text('Tuyển dụng & Job Fair'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byTooltip('Job Fair & Tuyển dụng Data/AI'), findsOneWidget);
    expect(find.byTooltip('Check-in CLB & Đội Nhóm UEH'), findsNothing);

    await tester.tap(find.byTooltip('Job Fair & Tuyển dụng Data/AI'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Minigame'), findsOneWidget);
    expect(find.text('Quà tặng'), findsOneWidget);
    expect(
      find.text('Bổ trợ Lộ trình Nghề nghiệp (Career Map)'),
      findsOneWidget,
    );
  });
}
