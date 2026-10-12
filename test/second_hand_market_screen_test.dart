import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/screens/second_hand_market_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('library list and details fit a 320px viewport', (tester) async {
    final data = jsonDecode(
      await rootBundle.loadString('assets/learning_resources.json'),
    ) as Map<String, dynamic>;
    final cachedCovers = <String, String>{
      for (final items in data.values)
        for (final item in items as List)
          (item as Map<String, dynamic>)['id'] as String:
              'https://example.invalid/${item['id']}.jpg',
    };
    SharedPreferences.setMockInitialValues({
      'resource_cover_cache': jsonEncode(cachedCovers),
    });
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SecondHandMarketScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Thư viện học liệu'), findsOneWidget);
    expect(find.text('Khám phá học liệu'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -560));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('resource-card-ba-sql-mere-mortals')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vì sao nên học/đọc'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
