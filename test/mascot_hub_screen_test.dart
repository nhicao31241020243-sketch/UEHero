import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uehero/screens/mascot_hub_screen.dart';
import 'package:uehero/services/mascot_selection_store.dart';

void main() {
  for (final width in [320.0, 600.0]) {
    testWidgets('mascot hub fits ${width.toInt()}px viewport', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MascotHubScreen(initialSelection: MascotSelection()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Linh vật của bạn'), findsOneWidget);
      expect(find.text('Mascot chính'), findsOneWidget);
      expect(find.text('Bạn đồng hành AI'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
