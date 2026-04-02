import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
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

    // Initialize alarm manager
    if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
                AndroidFlutterLocalNotificationsPlugin
              >();
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
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('currentIntake') ?? 0;
    final goal = prefs.getInt('dailyGoal') ?? 2000;
    final remaining = goal - current;
    
    debugPrint('[NotificationService] 💧 Current: ${current}ml / Goal: ${goal}ml');
    
    String body;
    if (remaining > 0) {
      body = 'Zostáva: ${remaining}ml do cieľa (${current}ml / ${goal}ml)';
    } else {
      body = 'Cieľ splnený! Vynikajúce! (${current}ml / ${goal}ml)';
    }
    
    await _plugin.show(
      0,
      'Čas piť vodu',
      body,
      _notificationDetails,
    );
    debugPrint('[NotificationService] 🔔 Immediate notification shown');
  }

  /// Background callback - fires when alarm triggers
  @pragma('vm:entry-point')
  static Future<void> _fireNotification() async {
    debugPrint(
      '[NotificationService] 🔥 Alarm triggered! Showing notification...',
    );

    final plugin = FlutterLocalNotificationsPlugin();

    // Initialize plugin for background execution
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await plugin.initialize(settings);

    // Get current progress
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('currentIntake') ?? 0;
    final goal = prefs.getInt('dailyGoal') ?? 2000;
    final remaining = goal - current;
    
    debugPrint('[NotificationService] 💧 Current: ${current}ml / Goal: ${goal}ml');
    
    String body;
    if (remaining > 0) {
      body = 'Zostáva: ${remaining}ml do cieľa (${current}ml / ${goal}ml)';
    } else {
      body = 'Cieľ splnený! Vynikajúce! (${current}ml / ${goal}ml)';
    }

    await plugin.show(
      1,
      'Čas piť vodu',
      body,
      _notificationDetails,
    );

    debugPrint('[NotificationService] ✅ Notification shown successfully');
  }

  /// Background callback - fires at midnight to reschedule next day's reminders
  @pragma('vm:entry-point')
  static Future<void> _midnightReschedule() async {
    debugPrint('[NotificationService] 🌙 Midnight reschedule triggered');

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('remindersEnabled') ?? false;

    if (!enabled) {
      debugPrint(
        '[NotificationService] ⏸️ Reminders disabled, skipping reschedule',
      );
      return;
    }

    final interval = prefs.getInt('reminderIntervalMinutes') ?? 60;
    final startHour = prefs.getInt('reminderStartHour') ?? 8;
    final endHour = prefs.getInt('reminderEndHour') ?? 22;

    debugPrint('[NotificationService] 🔄 Rescheduling for new day...');
    await scheduleForDay(interval, startHour: startHour, endHour: endHour);
  }

  /// Schedules notifications for the entire day based on interval and active hours.
  /// Also schedules a midnight alarm to reschedule for the next day.
  /// Returns the time of the first scheduled notification.
  static Future<DateTime?> scheduleForDay(
    int intervalMinutes, {
    int startHour = 8,
    int endHour = 22,
  }) async {
    await cancelAll();

    final now = DateTime.now();
    DateTime? firstNotification;
    int alarmId = 1;

    debugPrint('[NotificationService] 📅 Current time: ${now.toString()}');
    debugPrint(
      '[NotificationService] ⏰ Interval: $intervalMinutes min, Active: $startHour:00-$endHour:00',
    );
    debugPrint('[NotificationService] 📋 Scheduling reminders for today...');

    // Calculate all notification times for today
    var currentTime = now.add(Duration(minutes: intervalMinutes));

    // If first notification is before start hour today, move to start hour
    if (currentTime.hour < startHour) {
      currentTime = DateTime(now.year, now.month, now.day, startHour, 0);
    }

    if (Platform.isAndroid) {
      // Schedule notifications for today
      while (currentTime.day == now.day && currentTime.hour < endHour) {
        firstNotification ??= currentTime;

        debugPrint(
          '[NotificationService] 🔔 Alarm #$alarmId at ${currentTime.toString()}',
        );

        await AndroidAlarmManager.oneShotAt(
          currentTime,
          alarmId++,
          _fireNotification,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: false,
        );

        currentTime = currentTime.add(Duration(minutes: intervalMinutes));
      }

      // Schedule midnight reschedule for next day
      final midnight = DateTime(now.year, now.month, now.day + 1, 0, 0);
      await AndroidAlarmManager.oneShotAt(
        midnight,
        999, // special ID for midnight reschedule
        _midnightReschedule,
        exact: true,
        wakeup: false,
        rescheduleOnReboot: false,
      );

      debugPrint(
        '[NotificationService] 🌙 Midnight reschedule set for ${midnight.toString()}',
      );
      debugPrint(
        '[NotificationService] ✅ Total scheduled: ${alarmId - 1} notifications',
      );
      
      // Store the count for efficient cancellation
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastAlarmId', alarmId - 1);
    }

    return firstNotification;
  }

  /// Schedules a single notification [intervalMinutes] from now.
  /// Respects [startHour] and [endHour] - if scheduled time is outside active hours,
  /// moves to next day's start time.
  /// Returns the scheduled time.
   static Future<DateTime?> scheduleNext(
    int intervalMinutes, {
    int startHour = 8,
    int endHour = 22,
  }) async {
    await cancelAll();

    final now = DateTime.now();
    var scheduledTime = now.add(Duration(minutes: intervalMinutes));

    // Check if scheduled time is outside active hours
    if (scheduledTime.hour >= endHour || scheduledTime.hour < startHour) {
      // Move to next valid start time
      if (scheduledTime.hour >= endHour) {
        // Past end time today → start time tomorrow
        scheduledTime = DateTime(
          scheduledTime.year,
          scheduledTime.month,
          scheduledTime.day + 1,
          startHour,
          0,
        );
        debugPrint(
          '[NotificationService] ⏰ Scheduled time is past active hours (${endHour}:00)',
        );
        debugPrint(
          '[NotificationService] 🌙 Moving to tomorrow at $startHour:00',
        );
      } else {
        // Before start time today → start time today
        scheduledTime = DateTime(
          scheduledTime.year,
          scheduledTime.month,
          scheduledTime.day,
          startHour,
          0,
        );
        debugPrint(
          '[NotificationService] ⏰ Scheduled time is before active hours ($startHour:00)',
        );
        debugPrint('[NotificationService] 🌅 Moving to today at $startHour:00');
      }
    }

    debugPrint('[NotificationService] 📅 Current time: ${now.toString()}');
    debugPrint(
      '[NotificationService] ⏰ Alarm interval: $intervalMinutes minutes',
    );
    debugPrint(
      '[NotificationService] 🔔 Will fire at: ${scheduledTime.toString()}',
    );
    debugPrint(
      '[NotificationService] 🕐 Active hours: $startHour:00 - $endHour:00',
    );

    if (Platform.isAndroid) {
      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        1, // alarm ID
        _fireNotification,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: false,
      );
      debugPrint('[NotificationService] ✅ Alarm scheduled successfully');
    }

    return scheduledTime;
  }

   static Future<void> cancelAll() async {
    if (Platform.isAndroid) {
      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getInt('lastAlarmId') ?? 30;
      
      // Cancel only the alarms that were actually scheduled
      for (int id = 1; id <= lastId; id++) {
        await AndroidAlarmManager.cancel(id);
      }
      // Cancel midnight reschedule alarm
      await AndroidAlarmManager.cancel(999);
      debugPrint('[NotificationService] 🗑️ Cancelled $lastId alarms + midnight');
    }
  }

