import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uehero/features/gpa_studio_v3/controller.dart';
import 'package:uehero/features/gpa_studio_v3/screen.dart';

void main() {
  testWidgets('dashboard loads at phone width without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const GpaStudioV3App());
    await tester.pumpAndSettle();
    expect(find.text('GPA Journey'), findsOneWidget);
    expect(find.byKey(const ValueKey('grade-chart')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grade buttons and undo edit the same scenario', (tester) async {
    tester.view.physicalSize = const Size(412, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = StudioController();
    await tester.pumpWidget(
      MaterialApp(home: StudioScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
    final a = find.byKey(const ValueKey('grade-A'));
    await tester.ensureVisible(a);
    await tester.tap(a);
    await tester.pumpAndSettle();
    expect(controller.committed.grades['ai_project'], 400);
    final undo = find.byKey(const ValueKey('undo'));
    await tester.ensureVisible(undo);
    await tester.tap(undo);
    await tester.pumpAndSettle();
    expect(controller.committed.grades['ai_project'], 350);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('narrow screen and enlarged text remain scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(1.5)),
          child: child!,
        ),
        home: const StudioScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('studio-scroll')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'vertical chart drag commits a grade rather than changing the target',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = StudioController();
      await tester.pumpWidget(
        MaterialApp(home: StudioScreen(controller: controller)),
      );
      await tester.pumpAndSettle();
      final chart = find.byKey(const ValueKey('grade-chart'));
      final origin = tester.getTopLeft(chart);
      final gesture = await tester.startGesture(origin + const Offset(30, 100));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -35));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.committed.grades['ai_project'], 400);
      expect(controller.committed.targetUnits, 350);
      expect(controller.canUndo, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );
}
