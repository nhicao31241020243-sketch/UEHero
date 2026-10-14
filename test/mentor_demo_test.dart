import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/config/it_fields.dart';
import 'package:uehero/data/mentor_demo_data.dart';
import 'package:uehero/models/mentor_model.dart';
import 'package:uehero/screens/mentor_screen.dart';
import 'package:uehero/services/mentor_filter.dart';
import 'package:uehero/widgets/mentor_avatar.dart';

void main() {
  group('fieldIdForGoal', () {
    test('maps saved career goal names and configured goal ids', () {
      expect(fieldIdForGoal('Frontend Developer'), 'frontend');
      expect(fieldIdForGoal('Data Analyst'), 'data_analyst');
      expect(fieldIdForGoal('Business Analyst'), 'business_analyst');
      expect(fieldIdForGoal('Product Manager'), 'product_manager');
      expect(fieldIdForGoal('data-business-analyst'), isNull);
      expect(fieldIdForGoal('frontend_developer'), 'frontend');
    });

    test('returns null for unknown and non-IT goals', () {
      expect(fieldIdForGoal('Digital Marketing'), isNull);
      expect(fieldIdForGoal('E-commerce Specialist'), isNull);
      expect(fieldIdForGoal(null), isNull);
    });

    test('defines all requested IT fields once', () {
      expect(itFields, hasLength(17));
      expect(itFields.map((field) => field.id).toSet(), hasLength(17));
    });
  });

  group('MentorRepository and filtering', () {
    final mentors = MentorRepository.getMentors(
      now: DateTime(2026, 10, 14, 12),
    );

    test('provides 16 demo mentors covering every IT field', () {
      expect(mentors, hasLength(16));
      expect(mentors.every((mentor) => mentor.isDemo), isTrue);
      final covered = mentors.expand((mentor) => mentor.fieldIds).toSet();
      expect(covered, containsAll(itFields.map((field) => field.id)));
      for (final fieldId in [
        'frontend',
        'backend',
        'mobile',
        'data_analyst',
      ]) {
        expect(
          mentors.where((mentor) => mentor.fieldIds.contains(fieldId)).length,
          greaterThanOrEqualTo(2),
        );
      }
      expect(
        mentors.every((mentor) => mentor.bio.split('. ').length >= 2),
        isTrue,
      );
      expect(
        mentors.every((mentor) => mentor.topics.length == 3),
        isTrue,
      );
    });

    test('filters by goal and ranks goal matches first', () {
      final result = filterAndSortMentors(
        mentors: mentors,
        targetFieldId: 'frontend',
      );
      expect(result.first.fieldIds, contains('frontend'));
      expect(
        result.takeWhile((mentor) => mentor.fieldIds.contains('frontend')),
        isNotEmpty,
      );
    });

    test('goal selection filters to matching mentors and available slots', () {
      final result = filterAndSortMentors(
        mentors: mentors,
        fieldId: '__goal__',
        targetFieldId: 'data_analyst',
        onlyAvailable: true,
      );
      expect(result, hasLength(1));
      expect(result.single.fieldIds, contains('data_analyst'));
      expect(result.single.availableSlots, isNotEmpty);
    });

    test('filters by industry and text in topic/title/industry', () {
      final backendMentors = filterAndSortMentors(
        mentors: mentors,
        fieldId: 'backend',
      );
      expect(
        backendMentors.every((mentor) => mentor.fieldIds.contains('backend')),
        isTrue,
      );
      final searched = filterAndSortMentors(
        mentors: mentors,
        query: 'Phỏng vấn',
      );
      expect(
        searched.every(
          (mentor) => mentor.topics.contains(MentorTopic.interview),
        ),
        isTrue,
      );
      expect(
        filterAndSortMentors(mentors: mentors, query: 'không tồn tại'),
        isEmpty,
      );
    });

    test('availability filter works independently', () {
      final withSlots = filterAndSortMentors(
        mentors: mentors,
        onlyAvailable: true,
      );
      expect(withSlots.every((mentor) => mentor.availableSlots.isNotEmpty), isTrue);
      expect(withSlots.length, lessThan(mentors.length));
    });
  });

  group('Mentor avatar identity', () {
    test('uses the first uppercase character and stable id palette', () {
      expect(mentorInitial('  ngọc Linh'), 'N');
      expect(mentorInitial(''), '?');
      expect(mentorPaletteIndex('mentor-lan-anh'), inInclusiveRange(0, 7));
      expect(
        mentorPaletteIndex('mentor-lan-anh'),
        mentorPaletteIndex('mentor-lan-anh'),
      );
      expect(mentorAvatarPalettes, hasLength(8));
    });
  });

  testWidgets('list and profile fit narrow and tablet-width viewports', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'career_goal': 'Data Analyst'});
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in [const Size(320, 800), const Size(600, 900)]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(key: ValueKey(size.width), home: const MentorScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mentor đồng hành'), findsOneWidget);
      expect(tester.takeException(), isNull);

      if (size.width == 320) {
        await tester.scrollUntilVisible(
          find.text('Mai Chi Đặng'),
          250,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.text('Mai Chi Đặng'));
        await tester.pumpAndSettle();
        expect(find.text('Hồ sơ mentor'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
