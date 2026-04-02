import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'water_reminders',
      'Pripomienky piť vodu',
      channelDescription: 'Pripomienky na pitný režim',
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

    // Initialize timezones for scheduling
    tz_data.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

    // Create Android notification channel
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'water_reminders',
            'Pripomienky piť vodu',
            description: 'Pripomienky na pitný režim',
            importance: Importance.high,
          ),
        );
  }

  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final plugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
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

  static Future<void> showNow() async {
    await _plugin.show(
      0,
      'Čas piť vodu! 💧',
      'Pripomienky sú zapnuté. Nezabudnite sa zapiť!',
      _notificationDetails,
    );
  }

  /// Schedules a single notification [intervalMinutes] from now.
  /// Returns the scheduled time.
  static Future<tz.TZDateTime?> scheduleNext(int intervalMinutes) async {
    await cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = now.add(Duration(minutes: intervalMinutes));

    debugPrint('[NotificationService] 📅 Current time: ${now.toString()}');
    debugPrint('[NotificationService] ⏰ Scheduling notification in $intervalMinutes minutes');
    debugPrint('[NotificationService] 🔔 Will fire at: ${scheduledTime.toString()}');

    await _plugin.zonedSchedule(
      1,
      'Čas piť vodu! 💧',
      'Nezabudnite sa zapiť a splniť denný pitný cieľ.',
      scheduledTime,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('[NotificationService] ✅ Notification scheduled successfully');
    return scheduledTime;
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('[NotificationService] 🗑️ All notifications cancelled');
  }
}
