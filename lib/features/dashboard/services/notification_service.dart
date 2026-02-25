import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  // 1. Singleton Setup
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // 2. Initialize the Service
  Future<void> init() async {
    // If Web, skip mobile-only configuration
    if (kIsWeb) return;

    tz.initializeTimeZones();

    // [PRODUCTION FIX] Safely extract the timezone identifier
    final dynamic tzData = await FlutterTimezone.getLocalTimezone();
    final String timeZoneName = tzData is String ? tzData : tzData.identifier;

    tz.setLocalLocation(tz.getLocation(timeZoneName));
    debugPrint("🌍 TIMEZONE SUCCESSFULLY SET TO: $timeZoneName");

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings: initSettings);
  }

  // 3. Request Permissions for the current platform
  Future<void> requestPermission() async {
    if (kIsWeb) {
      await html.Notification.requestPermission();
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      await iosImplementation?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // 4. The Actionable, Professional Budget Warning
  Future<void> showBudgetWarning({required double percentageUsed}) async {
    final formattedPercentage = (percentageUsed * 100).toStringAsFixed(0);
    final String title = 'Budget Alert';
    final String body = 'You have utilized $formattedPercentage% of your monthly budget. Spend carefully.';

    // --- WEB EXECUTION ---
    if (kIsWeb) {
      if (html.Notification.permission == 'granted') {
        html.Notification(title, body: body);
      } else if (html.Notification.permission != 'denied') {
        final permission = await html.Notification.requestPermission();
        if (permission == 'granted') {
          html.Notification(title, body: body);
        }
      }
      return;
    }

    // --- MOBILE EXECUTION ---
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'budget_alerts',
      'Budget Alerts',
      channelDescription: 'Notifications for monthly budget limits',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF2563EB),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  // 5. The 8:00 PM Daily Reminder
  Future<void> scheduleDailyReminder() async {
    if (kIsWeb) return;

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Set for 8:00 PM (20:00) today
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);

    // If it's already past 8:00 PM, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    debugPrint("⏰ ALARM SET FOR: $scheduledDate");

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminders',
      'Daily Reminders',
      channelDescription: 'Evening reminder to log your daily expenses',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: Color(0xFF2563EB),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id: 1,
      title: 'Don’t Break the Streak 🔥',
      body: 'Keep your daily tracking streak alive!',
      scheduledDate: scheduledDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}