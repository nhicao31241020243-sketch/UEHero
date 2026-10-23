import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/config/it_fields.dart';
import 'package:uehero/data/mentor_demo_data.dart';
import 'package:uehero/data/mentor_seed_data.dart';
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

    test('provides 63 demo mentors covering every IT field', () {
      expect(mentors, hasLength(63));
      expect(mentors.map((mentor) => mentor.id).toSet(), hasLength(63));
      expect(mentors.every((mentor) => mentor.isDemo), isTrue);
      final covered = mentors.expand((mentor) => mentor.fieldIds).toSet();
      expect(covered, containsAll(itFields.map((field) => field.id)));
      for (final fieldId in ['frontend', 'backend', 'mobile', 'data_analyst']) {
        expect(
          mentors.where((mentor) => mentor.fieldIds.contains(fieldId)).length,
          greaterThanOrEqualTo(2),
        );
      }
      expect(
        mentors.every((mentor) => mentor.bio.split('. ').length >= 2),
        isTrue,
      );
      expect(mentors.map((mentor) => mentor.bio).toSet(), hasLength(63));
      expect(
        mentors.every(
          (mentor) =>
              mentor.topics.length >= 2 &&
              mentor.yearsExperience >= 1 &&
              mentor.yearsExperience <= 12,
        ),
        isTrue,
      );
    });

    test('uses local portrait assets whose gender matches the name', () {
      final seedFemale = {
        for (final row in mentorSeedRows) row.id: row.female,
      };
      final pattern = RegExp(
        r'^assets/mentors/mentor_([fm])(0[1-9]|1[0-5])\.jpg$',
      );
      for (final mentor in mentors) {
        final match = pattern.firstMatch(mentor.avatarAsset ?? '');
        expect(match, isNotNull, reason: mentor.id);
        final female =
            seedFemale[mentor.id] ?? originalMentorFemale[mentor.id] ?? false;
        expect(match![1], female ? 'f' : 'm', reason: mentor.id);
        expect(mentor.avatarUrl, isNull, reason: mentor.id);
      }
      for (var i = 1; i < mentors.length; i++) {
        expect(
          mentors[i].avatarAsset,
          isNot(mentors[i - 1].avatarAsset),
          reason: 'adjacent mentors share a portrait at index $i',
        );
      }
      expect(
        mentors
            .map((mentor) => mentor.rating)
            .every((rating) => rating! >= 4.0 && rating <= 5.0),
        isTrue,
      );
      expect(mentors.every((mentor) => mentor.sessionsCount > 0), isTrue);
      expect(mentors.every((mentor) => mentor.reviews.isNotEmpty), isTrue);
    });

    test('mentor names are unique full Vietnamese names', () {
      expect(mentors.map((mentor) => mentor.name).toSet(), hasLength(63));
      for (final mentor in mentors) {
        expect(mentor.name.trim().split(' ').length, greaterThanOrEqualTo(3));
      }
    });

    test('experience matches the title level and session count', () {
      final mismatches = <String>[];
      for (final mentor in mentors) {
        final title = mentor.title.toLowerCase();
        final years = mentor.yearsExperience;
        final String level;
        final (int, int) range;
        if (RegExp(r'intern|junior|associate').hasMatch(title)) {
          level = 'junior';
          range = (1, 2);
        } else if (RegExp(r'lead|manager|head|director').hasMatch(title)) {
          level = 'lead';
          range = (8, 14);
        } else if (title.contains('senior')) {
          level = 'senior';
          range = (6, 9);
        } else {
          level = 'mid';
          range = (3, 5);
        }
        if (years < range.$1 || years > range.$2) {
          mismatches.add('${mentor.id}: "${mentor.title}" ($level) $years y');
        }
        if (years <= 2) {
          final sessions = mentor.sessionsCount;
          if (sessions < 10 || sessions > 60) {
            mismatches.add('${mentor.id}: $sessions sessions at $years y');
          }
        } else if (years >= 6) {
          final sessions = mentor.sessionsCount;
          if (sessions < 50 || sessions > 300) {
            mismatches.add('${mentor.id}: $sessions sessions at $years y');
          }
        }
      }
      if (mismatches.isNotEmpty) fail(mismatches.join('\n'));
    });


    test('some mentors have no free slots', () {
      expect(mentors.any((mentor) => mentor.availableSlots.isEmpty), isTrue);
      expect(mentors.any((mentor) => mentor.availableSlots.isNotEmpty), isTrue);
    });

    test('sorts by rating and earliest slot', () {
      final byRating = filterAndSortMentors(
        mentors: mentors,
        sort: MentorSort.rating,
      );
      for (var i = 1; i < byRating.length; i++) {
        expect(
          byRating[i - 1].rating,
          greaterThanOrEqualTo(byRating[i].rating!),
        );
      }
      final soonest = filterAndSortMentors(
        mentors: mentors,
        sort: MentorSort.soonest,
      );
      expect(soonest.first.availableSlots, isNotEmpty);
      expect(soonest.last.availableSlots, isEmpty);
      final favorites = filterAndSortMentors(
        mentors: mentors,
        onlyIds: {mentors[3].id},
      );
      expect(favorites.single.id, mentors[3].id);
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
      expect(result, isNotEmpty);
      expect(
        result.every((mentor) => mentor.fieldIds.contains('data_analyst')),
        isTrue,
      );
      expect(
        result.every((mentor) => mentor.availableSlots.isNotEmpty),
        isTrue,
      );
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
      expect(
        withSlots.every((mentor) => mentor.availableSlots.isNotEmpty),
        isTrue,
      );
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
          find.text('Đặng Mai Chi'),
          250,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.text('Đặng Mai Chi'));
        await tester.pumpAndSettle();
        expect(find.text('Hồ sơ mentor'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
