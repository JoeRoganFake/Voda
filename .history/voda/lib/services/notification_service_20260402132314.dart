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

    // Initialize alarm manager
    if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();
    }

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
    debugPrint('[NotificationService] 🔔 Immediate notification shown');
  }

  /// Background callback - fires when alarm triggers
  @pragma('vm:entry-point')
  static Future<void> _fireNotification() async {
    debugPrint('[NotificationService] 🔥 Alarm triggered! Showing notification...');
    
    final plugin = FlutterLocalNotificationsPlugin();
    
    // Initialize plugin for background execution
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await plugin.initialize(settings);
    
    await plugin.show(
      1,
      'Čas piť vodu! 💧',
      'Nezabudnite sa zapiť a splniť denný pitný cieľ.',
      _notificationDetails,
    );
    
    debugPrint('[NotificationService] ✅ Notification shown successfully');
  }

  /// Schedules a single notification [intervalMinutes] from now.
  /// Returns the scheduled time.
  static Future<DateTime?> scheduleNext(int intervalMinutes) async {
    await cancelAll();

    final now = DateTime.now();
    final scheduledTime = now.add(Duration(minutes: intervalMinutes));

    debugPrint('[NotificationService] 📅 Current time: ${now.toString()}');
    debugPrint('[NotificationService] ⏰ Scheduling alarm in $intervalMinutes minutes');
    debugPrint('[NotificationService] 🔔 Will fire at: ${scheduledTime.toString()}');

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
      await AndroidAlarmManager.cancel(1);
      debugPrint('[NotificationService] 🗑️ Alarm cancelled');
    }
  }
}
