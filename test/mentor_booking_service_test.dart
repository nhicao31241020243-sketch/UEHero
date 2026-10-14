import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/config/career_goal_config.dart';
import 'package:uehero/models/mentor_booking.dart';
import 'package:uehero/services/goal_progress_service.dart';
import 'package:uehero/services/mentor_booking_service.dart';
import 'package:uehero/services/points_manager.dart';

void main() {
  Future<MentorBooking> createBooking(
    MentorBookingService service, {
    required String mentorId,
    required DateTime? slot,
  }) => service.create(
    mentorId: mentorId,
    slot: slot,
    purpose: 'cv',
    question: 'Xin góp ý CV của tôi.',
    createdAt: DateTime(2026, 10, 14, 10),
  );

  group('MentorBookingService', () {
    test(
      'prevents duplicate active requests for one mentor and slot',
      () async {
        SharedPreferences.setMockInitialValues({});
        final service = MentorBookingService(awardMeetingXp: (_) async => 0);
        addTearDown(service.dispose);
        await service.initialize();
        final slot = DateTime(2026, 10, 15, 19);
        await createBooking(service, mentorId: 'mentor-a', slot: slot);

        await expectLater(
          createBooking(service, mentorId: 'mentor-a', slot: slot),
          throwsStateError,
        );
        expect(service.bookings, hasLength(1));
      },
    );

    test('allows at most two active bookings at the same time', () async {
      SharedPreferences.setMockInitialValues({});
      final service = MentorBookingService(awardMeetingXp: (_) async => 0);
      addTearDown(service.dispose);
      await service.initialize();
      await createBooking(
        service,
        mentorId: 'mentor-a',
        slot: DateTime(2026, 10, 15, 19),
      );
      await createBooking(
        service,
        mentorId: 'mentor-b',
        slot: DateTime(2026, 10, 16, 19),
      );

      await expectLater(
        createBooking(
          service,
          mentorId: 'mentor-c',
          slot: DateTime(2026, 10, 17, 19),
        ),
        throwsStateError,
      );
      expect(service.activeCount, 2);
    });

    test('enforces pending to confirmed to completed transitions', () async {
      SharedPreferences.setMockInitialValues({});
      final service = MentorBookingService(awardMeetingXp: (_) async => 40);
      addTearDown(service.dispose);
      await service.initialize();
      final booking = await createBooking(
        service,
        mentorId: 'mentor-a',
        slot: DateTime(2026, 10, 15, 19),
      );

      await expectLater(service.markCompleted(booking.id), throwsStateError);
      expect(service.bookings.single.status, MentorBookingStatus.pending);
      await service.markConfirmed(booking.id);
      await expectLater(service.markConfirmed(booking.id), throwsStateError);
      await service.markCompleted(booking.id);
      expect(service.bookings.single.status, MentorBookingStatus.completed);
      expect(service.bookings.single.completedAt, isNotNull);
    });

    test('awards meeting XP at most once and persists action items', () async {
      SharedPreferences.setMockInitialValues({});
      var awardCount = 0;
      final service = MentorBookingService(
        awardMeetingXp: (_) async {
          awardCount++;
          return 40;
        },
      );
      addTearDown(service.dispose);
      await service.initialize();
      final booking = await createBooking(
        service,
        mentorId: 'mentor-a',
        slot: DateTime(2026, 10, 15, 19),
      );
      await service.markConfirmed(booking.id);
      await service.markCompleted(booking.id);
      await expectLater(service.markCompleted(booking.id), throwsStateError);
      await service.addActionItems(booking.id, [
        'Rà soát CV',
        'Luyện giới thiệu',
      ]);

      expect(awardCount, 1);
      expect(service.bookings.single.actionItems, [
        'Rà soát CV',
        'Luyện giới thiệu',
      ]);
      await expectLater(
        service.addActionItems(booking.id, ['1', '2', '3', '4']),
        throwsArgumentError,
      );
    });

    test(
      'persists bookings and enforces the 200 character question limit',
      () async {
        SharedPreferences.setMockInitialValues({});
        final service = MentorBookingService(awardMeetingXp: (_) async => 0);
        addTearDown(service.dispose);
        await service.initialize();
        final booking = await createBooking(
          service,
          mentorId: 'mentor-a',
          slot: null,
        );
        final restored = MentorBookingService(awardMeetingXp: (_) async => 0);
        addTearDown(restored.dispose);
        await restored.initialize();
        expect(restored.bookings.single.id, booking.id);
        expect(restored.bookings.single.slot, isNull);
        await expectLater(
          restored.create(
            mentorId: 'mentor-b',
            slot: null,
            purpose: 'interview',
            question: List.filled(201, 'x').join(),
          ),
          throwsArgumentError,
        );
      },
    );

    test('cancellation frees an active slot', () async {
      SharedPreferences.setMockInitialValues({});
      final service = MentorBookingService(awardMeetingXp: (_) async => 0);
      addTearDown(service.dispose);
      await service.initialize();
      final booking = await createBooking(
        service,
        mentorId: 'mentor-a',
        slot: DateTime(2026, 10, 15, 19),
      );
      await service.cancel(booking.id);
      expect(service.activeCount, 0);
      expect(service.listByStatus(MentorBookingStatus.cancelled), hasLength(1));
    });

    test('returns the nearest confirmed booking within 24 hours', () async {
      SharedPreferences.setMockInitialValues({});
      final service = MentorBookingService(awardMeetingXp: (_) async => 0);
      addTearDown(service.dispose);
      await service.initialize();
      final now = DateTime(2026, 10, 14, 12);
      final near = await service.create(
        mentorId: 'mentor-near',
        slot: now.add(const Duration(hours: 4)),
        purpose: 'cv',
        question: '',
        createdAt: now,
      );
      final far = await service.create(
        mentorId: 'mentor-far',
        slot: now.add(const Duration(days: 2)),
        purpose: 'interview',
        question: '',
        createdAt: now,
      );
      await service.markConfirmed(near.id);
      await service.markConfirmed(far.id);

      expect(service.upcomingConfirmedWithin24Hours(now: now)?.id, near.id);
    });
  });

  test(
    'completed mentor meeting fills the Career Map criterion and awards 40 XP',
    () async {
      SharedPreferences.setMockInitialValues({});
      final service = MentorBookingService.instance;
      final progress = GoalProgressService.instance;
      await progress.initialize();
      final booking = await service.create(
        mentorId: 'mentor-progress-test',
        slot: DateTime.now().add(const Duration(days: 1)),
        purpose: 'career_direction',
        question: 'Trao đổi lộ trình.',
      );

      await service.markConfirmed(booking.id);
      await service.markCompleted(booking.id);
      await expectLater(service.markCompleted(booking.id), throwsStateError);

      final mentorCriterion = careerGoals.first.criteria.firstWhere(
        (criterion) => criterion.id == 'mentor',
      );
      expect(mentorCriterion.enabled, isTrue);
      expect(progress.criterionProgress(careerGoals.first, 'mentor'), 1);
      final xpAwards = PointsManager.instance.entries
          .where(
            (entry) =>
                entry.nguon == 'mentor_meeting' &&
                entry.sourceRef == booking.id,
          )
          .toList();
      expect(xpAwards, hasLength(1));
      expect(xpAwards.single.luong, 40);
      expect(PointsManager.dailyCaps['mentor_meeting'], 100);
    },
  );
}
