import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'detox_main';
  static const String _channelName = 'Detox Notifications';
  static const String _channelDescription =
      'Notifications for detox goals and lock mode';

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);

    // Create notification channel for Android
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showMinutesLowNotification(int minutesLeft) async {
    await _notifications.show(
      1,
      'Low on Phone Time',
      'Only $minutesLeft minutes left today. Complete tasks to earn more!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> showLockModeNotification() async {
    await _notifications.show(
      2,
      'Lock Mode Activated',
      'You\'ve reached your daily limit. Complete tasks to unlock more time.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.max,
          ongoing: true,
        ),
      ),
    );
  }

  Future<void> showTaskCompletedNotification(String taskTitle, int minutesEarned) async {
    await _notifications.show(
      3,
      'Task Completed!',
      'You earned $minutesEarned minutes from "$taskTitle"',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> showMotivationalNotification(String message) async {
    await _notifications.show(
      4,
      'Detox Reminder',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
        ),
      ),
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}
