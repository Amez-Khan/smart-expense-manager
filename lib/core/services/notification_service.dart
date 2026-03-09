import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Added for Auth
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

// --- BACKGROUND HANDLER ---
// Must be a top-level function to handle notifications when the app is completely closed.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  // 1. Singleton Setup
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // 2. Initialize the Service
  Future<void> init() async {
    if (kIsWeb) return;

    // --- TIMEZONE SETUP ---
    tz.initializeTimeZones();
    final dynamic tzData = await FlutterTimezone.getLocalTimezone();
    final String timeZoneName = tzData is String ? tzData : tzData.identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    debugPrint("🌍 TIMEZONE SUCCESSFULLY SET TO: $timeZoneName");

    // --- LOCAL NOTIFICATION SETUP ---
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("Notification tapped: ${details.payload}");
      },
    );

    // --- FIREBASE CLOUD MESSAGING SETUP ---

    // 1. Listen for background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Handle messages while the app is OPEN (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Cloud message received in foreground!");
      if (message.notification != null) {
        _showFcmLocalNotification(
          message.notification!.title ?? "App Update",
          message.notification!.body ?? "Check out the new features!",
        );
      }
    });

    // 3. Handle when the user taps a notification to open the app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("App opened from a cloud notification!");
    });

    // 4. Get FCM Token and save to Firestore
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint("🚀 YOUR DEVICE FCM TOKEN: $token");
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint("Failed to get FCM token: $e");
    }

    // 5. Listen for token refreshes (e.g., user clears app data)
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint("🔄 FCM Token Refreshed!");
      _saveTokenToFirestore(newToken);
    });
  }

  // 3. Request Permissions
  Future<void> requestPermission() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM Permission Status: ${settings.authorizationStatus}');

    if (kIsWeb) {
      await html.Notification.requestPermission();
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImplementation?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // --- SECURE TOKEN STORAGE ---
  /*  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // SetOptions(merge: true) is critical so we don't erase user preferences
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint("✅ FCM Token securely saved to Firestore for user: ${user.uid}");
      } else {
        debugPrint("⏳ No user logged in. Skipping token save.");
      }
    } catch (e) {
      debugPrint("❌ Failed to save FCM token: $e");
    }
  }*/
  // --- SECURE TOKEN STORAGE ---
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // 🔥 ADDED: user.email and user.displayName
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email ?? 'Unknown Email', // Makes them identifiable!
          'displayName':
              user.displayName ??
              'Smart Expense User', // Makes them identifiable!
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint("✅ FCM Token and Info saved for: ${user.email}");
      } else {
        debugPrint("⏳ No user logged in. Skipping token save.");
      }
    } catch (e) {
      debugPrint("❌ Failed to save FCM token: $e");
    }
  }

  // --- HELPER: Show Cloud messages while app is active ---
  Future<void> _showFcmLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'cloud_updates',
          'App Updates',
          channelDescription: 'Notifications for news and version updates',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFF2563EB),
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: 10,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  // 4. The Actionable Budget Warning
  Future<void> showBudgetWarning({required double percentageUsed}) async {
    final formattedPercentage = (percentageUsed * 100).toStringAsFixed(0);
    final String title = 'Budget Alert';
    final String body =
        'You have utilized $formattedPercentage% of your monthly budget. Spend carefully.';

    if (kIsWeb) {
      if (html.Notification.permission == 'granted') {
        html.Notification(title, body: body);
      }
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
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
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20, // 8:00 PM
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    debugPrint("⏰ NEXT DAILY REMINDER AT: $scheduledDate");

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
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
