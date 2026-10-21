import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class EventNotificationService {
  EventNotificationService._();

  static final instance = EventNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _initialized = true;
  }

  Future<int> scheduleRegistrationReminders({
    required String eventId,
    required String title,
    required DateTime deadline,
    required bool requestPermission,
  }) async {
    await initialize();
    if (requestPermission) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final iosGranted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if ((android != null && granted != true) ||
          (ios != null && iosGranted != true)) {
        return -1;
      }
    }

    var scheduled = 0;
    for (final leadDays in const [3, 1]) {
      final at = tz.TZDateTime(
        tz.local,
        deadline.year,
        deadline.month,
        deadline.day,
        9,
      ).subtract(Duration(days: leadDays));
      if (!at.isAfter(tz.TZDateTime.now(tz.local))) continue;
      await _plugin.zonedSchedule(
        id: _notificationId(eventId, leadDays),
        title: 'Sắp hết hạn đăng ký',
        body: '$title · còn $leadDays ngày để đăng ký',
        scheduledDate: at,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'event_registration_deadline',
            'Hạn đăng ký sự kiện',
            channelDescription: 'Nhắc trước hạn đăng ký sự kiện',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: eventId,
      );
      scheduled++;
    }
    return scheduled;
  }

  Future<void> cancelRegistrationReminders(String eventId) async {
    await initialize();
    await _plugin.cancel(id: _notificationId(eventId, 3));
    await _plugin.cancel(id: _notificationId(eventId, 1));
  }

  int _notificationId(String eventId, int leadDays) {
    var hash = 0x811c9dc5;
    for (final unit in eventId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return (hash * 2 + (leadDays == 1 ? 1 : 0)) & 0x7fffffff;
  }
}
