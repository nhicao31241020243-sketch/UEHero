import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mentor_booking.dart';
import '../models/xp_entry.dart';
import 'points_manager.dart';

typedef MentorMeetingXpAwarder = Future<int> Function(String bookingId);

class MentorBookingService extends ChangeNotifier {
  MentorBookingService({MentorMeetingXpAwarder? awardMeetingXp})
    : _awardMeetingXp = awardMeetingXp ?? _awardMeetingXpByPointsManager;

  static final instance = MentorBookingService();
  static const _storageKey = 'mentor_bookings_v1';
  static const _purposes = {'cv', 'interview', 'career_direction'};

  final MentorMeetingXpAwarder _awardMeetingXp;
  final List<MentorBooking> _bookings = [];
  SharedPreferences? _preferences;
  bool _initialized = false;
  Future<void>? _initializing;
  Future<void> _mutationTail = Future<void>.value();
  int _nextId = 0;

  bool get isInitialized => _initialized;
  List<MentorBooking> get bookings => List.unmodifiable(_bookings);
  int get completedCount => _bookings
      .where((item) => item.status == MentorBookingStatus.completed)
      .length;
  int get activeCount => _bookings
      .where(
        (item) =>
            item.status == MentorBookingStatus.pending ||
            item.status == MentorBookingStatus.confirmed,
      )
      .length;

  Future<void> initialize({SharedPreferences? preferences}) async {
    if (_initialized) return;
    final pending = _initializing;
    if (pending != null) {
      await pending;
      return;
    }
    final task = _load(preferences);
    _initializing = task;
    try {
      await task;
    } finally {
      _initializing = null;
    }
  }

  Future<MentorBooking> create({
    required String mentorId,
    required DateTime? slot,
    required String purpose,
    required String question,
    DateTime? createdAt,
  }) async {
    await initialize();
    if (mentorId.trim().isEmpty) {
      throw ArgumentError.value(mentorId, 'mentorId', 'Cần chọn mentor.');
    }
    if (!_purposes.contains(purpose)) {
      throw ArgumentError.value(purpose, 'purpose', 'Mục đích không hợp lệ.');
    }
    if (question.runes.length > 200) {
      throw ArgumentError.value(
        question,
        'question',
        'Câu hỏi tối đa 200 ký tự.',
      );
    }

    return _serialize(() async {
      final duplicate =
          slot != null &&
          _bookings.any(
            (booking) =>
                booking.mentorId == mentorId &&
                booking.slot?.isAtSameMomentAs(slot) == true &&
                booking.status != MentorBookingStatus.cancelled,
          );
      if (duplicate) {
        throw StateError('Bạn đã có lịch với mentor này vào khung giờ đó.');
      }
      if (activeCount >= 2) {
        throw StateError(
          'Bạn chỉ có thể có tối đa 2 lịch đang chờ hoặc đã hẹn.',
        );
      }
      final created = createdAt ?? DateTime.now();
      final booking = MentorBooking(
        id: 'mentor-booking-${created.microsecondsSinceEpoch}-${_nextId++}',
        mentorId: mentorId,
        slot: slot,
        purpose: purpose,
        question: question.trim(),
        status: MentorBookingStatus.pending,
        actionItems: const [],
        createdAt: created,
      );
      _bookings.add(booking);
      await _save();
      notifyListeners();
      return booking;
    });
  }

  Future<void> cancel(String bookingId) async {
    await initialize();
    await _serialize(() async {
      final booking = _requireBooking(bookingId);
      if (booking.status != MentorBookingStatus.pending &&
          booking.status != MentorBookingStatus.confirmed) {
        throw StateError('Chỉ lịch đang chờ hoặc đã hẹn mới được hủy.');
      }
      _replace(booking.copyWith(status: MentorBookingStatus.cancelled));
      await _save();
      notifyListeners();
    });
  }

  Future<void> markConfirmed(String bookingId) async {
    await initialize();
    await _serialize(() async {
      final booking = _requireBooking(bookingId);
      if (booking.status != MentorBookingStatus.pending) {
        throw StateError('Chỉ lịch đang chờ mới được xác nhận.');
      }
      _replace(booking.copyWith(status: MentorBookingStatus.confirmed));
      await _save();
      notifyListeners();
    });
  }

  Future<void> markCompleted(String bookingId, {DateTime? completedAt}) async {
    await initialize();
    await _serialize(() async {
      final booking = _requireBooking(bookingId);
      if (booking.status != MentorBookingStatus.confirmed) {
        throw StateError('Chỉ lịch đã hẹn mới được đánh dấu đã gặp.');
      }
      await _awardMeetingXp(booking.id);
      _replace(
        booking.copyWith(
          status: MentorBookingStatus.completed,
          completedAt: completedAt ?? DateTime.now(),
        ),
      );
      await _save();
      notifyListeners();
    });
  }

  Future<void> addActionItems(
    String bookingId,
    List<String> actionItems,
  ) async {
    await initialize();
    final cleaned = actionItems
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (cleaned.length > 3) {
      throw ArgumentError.value(actionItems, 'actionItems', 'Tối đa 3 việc.');
    }
    await _serialize(() async {
      final booking = _requireBooking(bookingId);
      if (booking.status != MentorBookingStatus.completed) {
        throw StateError('Chỉ lịch đã gặp mới lưu được việc cần làm.');
      }
      _replace(booking.copyWith(actionItems: List.unmodifiable(cleaned)));
      await _save();
      notifyListeners();
    });
  }

  List<MentorBooking> listByStatus(String status) {
    if (!MentorBookingStatus.values.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Trạng thái không hợp lệ.');
    }
    return List.unmodifiable(
      _bookings.where((booking) => booking.status == status).toList()
        ..sort(_compareBookings),
    );
  }

  MentorBooking? upcomingConfirmedWithin24Hours({DateTime? now}) {
    final current = now ?? DateTime.now();
    final latest = current.add(const Duration(hours: 24));
    final upcoming =
        _bookings
            .where(
              (booking) =>
                  booking.status == MentorBookingStatus.confirmed &&
                  booking.slot != null &&
                  booking.slot!.isAfter(current) &&
                  !booking.slot!.isAfter(latest),
            )
            .toList()
          ..sort(_compareBookings);
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Future<void> _load(SharedPreferences? preferences) async {
    _preferences = preferences ?? await SharedPreferences.getInstance();
    final raw = _preferences!.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _bookings
        ..clear()
        ..addAll(
          decoded.map(
            (item) => MentorBooking.fromJson(item as Map<String, dynamic>),
          ),
        );
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    _preferences = preferences;
    await preferences.setString(
      _storageKey,
      jsonEncode(_bookings.map((booking) => booking.toJson()).toList()),
    );
  }

  MentorBooking _requireBooking(String id) {
    for (final booking in _bookings) {
      if (booking.id == id) return booking;
    }
    throw StateError('Không tìm thấy lịch mentor.');
  }

  void _replace(MentorBooking replacement) {
    final index = _bookings.indexWhere((item) => item.id == replacement.id);
    if (index < 0) throw StateError('Không tìm thấy lịch mentor.');
    _bookings[index] = replacement;
  }

  Future<T> _serialize<T>(Future<T> Function() operation) async {
    final previous = _mutationTail;
    final completer = Completer<void>();
    _mutationTail = completer.future;
    await previous;
    try {
      return await operation();
    } finally {
      completer.complete();
    }
  }

  int _compareBookings(MentorBooking first, MentorBooking second) =>
      (first.slot ?? first.createdAt).compareTo(
        second.slot ?? second.createdAt,
      );

  static Future<int> _awardMeetingXpByPointsManager(String bookingId) =>
      PointsManager.instance.addXP(
        thanh: XpBar.thucChien,
        skill: null,
        luong: 40,
        nguon: 'mentor_meeting',
        sourceRef: bookingId,
      );
}
