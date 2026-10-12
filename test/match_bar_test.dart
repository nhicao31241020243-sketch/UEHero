import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uehero/widgets/match_bar.dart';

void main() {
  for (final percent in [0, 50, 100]) {
    testWidgets('renders $percent% without overflow at 320px', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: MatchBar(percent: percent),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MatchBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
