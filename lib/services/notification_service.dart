import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int completionNotificationId = 101;

  // Notification channel for completion alerts
  // Note: We use _v2 to recreate the channel so Android accepts new sound/vibration settings
  static const String alertChannelId = 'timfoc_alerts_v5';
  static const String alertChannelName = 'Timer Alerts';
  static const String alertChannelDesc = 'Alerts when sessions complete';

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );
  }

  /// Show a completion notification (high priority, with sound and heavy vibration)
  static Future<void> showCompletionNotification({
    required String title,
    required String body,
    required bool playSound,
  }) async {
    final Int64List vibrationPattern = Int64List.fromList([0, 1000, 500, 1000, 500, 1000]); // 3 strong vibrations

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      alertChannelId,
      alertChannelName,
      channelDescription: alertChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'Timer Complete',
      playSound: playSound,
      sound: playSound ? const RawResourceAndroidNotificationSound('beep') : null,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      id: completionNotificationId,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
