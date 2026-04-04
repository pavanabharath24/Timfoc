import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Notification IDs
  static const int timerNotificationId = 100;
  static const int completionNotificationId = 101;

  // Notification channel for live timer
  static const String timerChannelId = 'timfoc_live_timer';
  static const String timerChannelName = 'Live Timer';
  static const String timerChannelDesc = 'Shows live countdown while timer is running';

  // Notification channel for completion alerts
  static const String alertChannelId = 'timfoc_alerts';
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

  /// Show/update the live timer notification with countdown
  static Future<void> showTimerNotification({
    required String title,
    required String timeText,
    required bool isPaused,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      timerChannelId,
      timerChannelName,
      channelDescription: timerChannelDesc,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      usesChronometer: false,
      visibility: NotificationVisibility.public,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.progress,
      silent: true,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      id: timerNotificationId,
      title: title,
      body: timeText,
      notificationDetails: details,
    );
  }

  /// Cancel the live timer notification
  static Future<void> cancelTimerNotification() async {
    await flutterLocalNotificationsPlugin.cancel(id: timerNotificationId);
  }

  /// Show a completion notification (high priority, with sound)
  static Future<void> showCompletionNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      alertChannelId,
      alertChannelName,
      channelDescription: alertChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Timer Complete',
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

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
