import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uehero/models/event_item.dart';
import 'package:uehero/widgets/event_catalog_widgets.dart';
import 'package:uehero/widgets/event_image_placeholder.dart';
import 'package:uehero/widgets/event_streaming_widgets.dart';

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

  testWidgets('hero carousel is widescreen and supports swipe navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const first = EventItem(
      id: 'hero-first',
      title: 'First event',
      organizer: 'UEH',
      type: 'Hackathon',
    );
    const second = EventItem(
      id: 'hero-second',
      title: 'Second event',
      organizer: 'UEH',
      type: 'Workshop',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 328,
              child: EventHeroCarousel(
                events: const [first, second],
                savedIds: const {},
                onOpen: (_) {},
                onShare: (_) {},
                onToggleSaved: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final heroSize = tester.getSize(find.byType(EventHero).first);
    expect(heroSize.width / heroSize.height, closeTo(16 / 9, 0.01));

    await tester.drag(find.byType(PageView), const Offset(-280, 0));
    await tester.pumpAndSettle();
    expect(find.text('Second event'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('streaming event cards only show genre and title', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const event = EventItem(
      id: 'evt_001',
      title: 'UEH Code Challenge',
      organizer: 'UEH Student Hub',
      type: 'Technology',
      timeline: 'Tháng 9 - Tháng 12 hàng năm',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventStreamCard(event: event, onTap: () {}),
        ),
      ),
    );

    expect(find.text('Cuộc thi'), findsOneWidget);
    expect(find.text('UEH Code Challenge'), findsOneWidget);
    expect(find.text('UEH Student Hub'), findsNothing);
    expect(find.textContaining('Tháng 9'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('streaming hero presents the requested four details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const event = EventItem(
      id: 'evt_002',
      title: 'UEH Game Jam',
      organizer: 'UEH Innovation Center',
      type: 'Open Event',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventStreamHeroCarousel(events: const [event], onOpen: (_) {}),
        ),
      ),
    );

    expect(find.text('Hackathon'), findsOneWidget);
    expect(find.text('UEH Game Jam'), findsOneWidget);
    expect(find.text('UEH Innovation Center'), findsOneWidget);
    expect(find.text('Xem chi tiết'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
