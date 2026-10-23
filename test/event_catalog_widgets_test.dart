import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uehero/models/event_item.dart';
import 'package:uehero/widgets/event_catalog_widgets.dart';
import 'package:uehero/widgets/event_image_placeholder.dart';

void main() {
  testWidgets('event list and poster cards fit a 360px viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const event = EventItem(
      id: 'ui-ux-2026',
      title: 'Lollypop Designathon 2026 – Global Edition: thử thách thiết kế sản phẩm số',
      organizer: 'Lollypop Design Studio và các đối tác chương trình',
      type: 'Hackathon',
      registrationDeadline: null,
      eventStart: null,
      needsVerification: true,
      relatedCareers: ['UI/UX Designer'],
      skills: ['Thiết kế UI/UX'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              EventListTile(
                event: event,
                saved: false,
                matchPercent: 85,
                onTap: () {},
                onSave: () {},
              ),
              EventPosterCard(
                event: event,
                onTap: () {},
                onSave: () {},
                saved: true,
                matchPercent: 85,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Lollypop Designathon'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'hero fits a narrow viewport and missing art uses shared design',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const event = EventItem(
        id: 'hero-demo',
        title: 'Hackathon tiêu đề dài cần tự xuống dòng gọn gàng',
        organizer: 'Orbit Student Lab',
        type: 'Hackathon',
        registrationDeadline: null,
        eventStart: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 404,
              child: EventHero(
                event: event,
                saved: false,
                onOpen: () {},
                onShare: () {},
                onToggleSaved: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Xem chi tiết'), findsOneWidget);
      expect(find.byTooltip('Chia sẻ'), findsOneWidget);
      expect(find.byType(EventImagePlaceholder), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
