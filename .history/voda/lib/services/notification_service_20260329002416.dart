import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'water_reminders',
      'Pripomienky piť vodu',
      channelDescription: 'Pravidelné pripomienky na pitný režim',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    ),
  );

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
  }

  /// Returns true if permission was granted (or already had it).
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final plugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      // On Android < 13, POST_NOTIFICATIONS doesn't exist — always granted.
      final result = await plugin?.requestNotificationsPermission();
      return result ?? true;
    } else if (Platform.isIOS) {
      final plugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await plugin?.requestPermissions(
            alert: true,
            badge: false,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  /// Cancels all reminders and schedules new daily recurring notifications
  /// for every [intervalMinutes] minutes between [startHour] and [endHour].
  /// When [debugMode] is true, fires every minute instead.
  static Future<void> scheduleReminders({
    required int intervalMinutes,
    int startHour = 8,
    int endHour = 22,
  }) async {
    await cancelAll();

    if (debugMode) {
      // Fire one immediately so we can confirm the channel/permission works.
      await _plugin.show(
        99,
        'Čas piť vodu! 💧',
        'Testovacia notifikácia – funguje!',
        _notificationDetails,
      );
      // Then repeat every minute.
      await _plugin.periodicallyShow(
        0,
        'Čas piť vodu! 💧',
        'Nezabudnite sa zapiť a splniť denný pitný cieľ.',
        RepeatInterval.everyMinute,
        _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    int id = 0;
    final startMinutes = startHour * 60;
    final endMinutes = endHour * 60;

    for (int offset = 0; startMinutes + offset <= endMinutes; offset += intervalMinutes) {
      final totalMinutes = startMinutes + offset;
      final hour = totalMinutes ~/ 60;
      final minute = totalMinutes % 60;
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id++,
        'Čas piť vodu! 💧',
        'Nezabudnite sa zapiť a splniť denný pitný cieľ.',
        scheduledTime,
        _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
