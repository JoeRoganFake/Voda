import 'dart:io';
import 'package:flutter/foundation.dart';
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
      debugPrint('[NotificationService] Notification permission: $result');
      // Exact alarm permissions (SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM) are
      // declared in AndroidManifest and granted automatically on Android 12+.
      // On some devices, user must manually enable in Settings → Special app access.
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

  /// Schedules notifications starting [intervalMinutes] from now,
  /// repeating at that interval within [startHour]-[endHour] daily for 7 days.
  /// Returns the time of the first scheduled notification.
  static Future<tz.TZDateTime?> scheduleReminders({
    required int intervalMinutes,
    int startHour = 8,
    int endHour = 22,
  }) async {
    await cancelAll();

    // Use alarmClock mode for reliable delivery without requiring exact-alarm permission.
    // This mode treats notifications as user-facing alarms (like an alarm clock app)
    // and is exempt from Doze restrictions — perfect for scheduled reminders.
    const scheduleMode = AndroidScheduleMode.alarmClock;

    final now = tz.TZDateTime.now(tz.local);
    int id = 0;
    tz.TZDateTime? firstNotification;
    
    // Start countdown from now + interval
    var nextTime = now.add(Duration(minutes: intervalMinutes));
    
    debugPrint('[NotificationService] Scheduling reminders from ${now.toString()}');
    debugPrint('[NotificationService] Interval: $intervalMinutes min, Active: $startHour:00-$endHour:00');
    debugPrint('[NotificationService] Using AndroidScheduleMode.alarmClock for reliable delivery');
    
    // If first notification falls outside active hours, jump to next valid start time
    if (nextTime.hour >= endHour || nextTime.hour < startHour) {
      if (nextTime.hour >= endHour) {
        // Past end time today → start time tomorrow
        nextTime = tz.TZDateTime(
          tz.local,
          nextTime.year,
          nextTime.month,
          nextTime.day + 1,
          startHour,
          0,
        );
      } else {
        // Before start time today → start time today
        nextTime = tz.TZDateTime(
          tz.local,
          nextTime.year,
          nextTime.month,
          nextTime.day,
          startHour,
          0,
        );
      }
    }
    
    final endDate = now.add(const Duration(days: 7));
    
    while (nextTime.isBefore(endDate)) {
      firstNotification ??= nextTime;
      
      debugPrint('[NotificationService] Scheduled #$id at ${nextTime.toString()}');
      
      await _plugin.zonedSchedule(
        id++,
        'Čas piť vodu! 💧',
        'Nezabudnite sa zapiť a splniť denný pitný cieľ.',
        nextTime,
        _notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      // Add interval for next notification
      nextTime = nextTime.add(Duration(minutes: intervalMinutes));
      
      // If we've crossed into restricted hours, jump to next valid start time
      if (nextTime.hour >= endHour || nextTime.hour < startHour) {
        if (nextTime.hour >= endHour) {
          // Past end time → start time next day
          nextTime = tz.TZDateTime(
            tz.local,
            nextTime.year,
            nextTime.month,
            nextTime.day + 1,
            startHour,
            0,
          );
        } else {
          // Before start time (crossed midnight) → start time same day
          nextTime = tz.TZDateTime(
            tz.local,
            nextTime.year,
            nextTime.month,
            nextTime.day,
            startHour,
            0,
          );
        }
      }
    }
    
    debugPrint('[NotificationService] Total scheduled: $id notifications');
    return firstNotification;
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
