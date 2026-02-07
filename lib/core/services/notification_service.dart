import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleExpiryNotification(
      int id, String productName, DateTime expiryDate) async {
    
    // Schedule 7 days before
    final sevenDaysBefore = expiryDate.subtract(const Duration(days: 7));
    if (sevenDaysBefore.isAfter(DateTime.now())) {
        await _schedule(id * 10 + 1, "Expiry Warning", "$productName expires in 7 days!", sevenDaysBefore);
    }

    // Schedule 1 day before
    final oneDayBefore = expiryDate.subtract(const Duration(days: 1));
     if (oneDayBefore.isAfter(DateTime.now())) {
        await _schedule(id * 10 + 2, "Urgent Expiry", "$productName expires tomorrow!", oneDayBefore);
     }
  }

  Future<void> _schedule(int id, String title, String body, DateTime scheduledDate) async {
     await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiry_channel',
          'Expiry Notifications',
          channelDescription: 'Notifications for expiring products',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  
  Future<void> cancelNotifications(int productId) async {
      await flutterLocalNotificationsPlugin.cancel(productId * 10 + 1);
      await flutterLocalNotificationsPlugin.cancel(productId * 10 + 2);
  }
}
