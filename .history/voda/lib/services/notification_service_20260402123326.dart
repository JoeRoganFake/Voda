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

    // Explicitly create the Android notification channel.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'water_reminders',
            'Pripomienky piť vodu',
            description: 'Pravidelné pripomienky na pitný režim',
            importance: Importance.high,
          ),
        );
  }

  /// Returns true if permission was granted (or already had it).
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final plugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      // On Android < 13, POST_NOTIFICATIONS doesn't exist — always granted.
      final result = await plugin?.requestNotificationsPermission();
      if (result == false) return false;
      // Request exact-alarm permission so notifications fire on time.
      // On API 31-32 this opens the system "Alarms & reminders" settings page;
      // on API 33+ (USE_EXACT_ALARM declared) it is auto-granted.
      await plugin?.requestExactAlarmsPermission();
      return true;
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

  /// Cancels all reminders and schedules notifications for every
  /// [intervalMinutes] between [startHour] and [endHour] for the next 7 days.
  /// Each slot is an absolute one-shot alarm — reliable on all Android versions.
  static Future<void> scheduleReminders({
    required int intervalMinutes,
    int startHour = 8,
    int endHour = 22,
  }) async {
    await cancelAll();

    // Use exact alarms — USE_EXACT_ALARM (API 33+) is auto-granted via the manifest;
    // SCHEDULE_EXACT_ALARM (API 31-32) is requested during permission setup.
    const scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;

    final now = tz.TZDateTime.now(tz.local);
    int id = 0;
    final startMinutes = startHour * 60;
    final endMinutes = endHour * 60;

    for (int day = 0; day < 7; day++) {
      for (int offset = 0;
          startMinutes + offset <= endMinutes;
          offset += intervalMinutes) {
        final totalMinutes = startMinutes + offset;
        final hour = totalMinutes ~/ 60;
        final minute = totalMinutes % 60;
        final scheduledTime = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + day,
          hour,
          minute,
        );
        // Skip times already in the past.
        if (scheduledTime.isBefore(now)) continue;

        await _plugin.zonedSchedule(
          id++,
          'Čas piť vodu! 💧',
          'Nezabudnite sa zapiť a splniť denný pitný cieľ.',
          scheduledTime,
          _notificationDetails,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  /// Shows an immediate notification (used when reminders are first enabled).
  static Future<void> showNow() async {
    await _plugin.show(
      999999,
      'Čas piť vodu! 💧',
      'Pripomienky sú zapnuté. Nezabudnite sa zapiť!',
      _notificationDetails,
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
