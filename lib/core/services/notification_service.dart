import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    // CRITICAL FIX: Set the local location to the device's timezone
    try {
        final String timeZoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
        // Fallback to UTC if timezone cannot be determined
        print("Could not get local timezone: $e");
        tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
            // Handle notification tap
        },
    );
    
    // Explicitly create the channel for Android 8.0+
    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'expiry_channel', // id
      'Expiry Notifications', // title
      description: 'Notifications for expiring products', // description
      importance: Importance.max,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }
  
  // New Feature: Test Notification
  Future<void> showTestNotification() async {
      await flutterLocalNotificationsPlugin.show(
          0,
          'Test Notification',
          'This is a test notification from ExpiryGuard.',
          const NotificationDetails(
              android: AndroidNotificationDetails(
                  'expiry_channel',
                  'Expiry Notifications',
                  channelDescription: 'Notifications for expiring products',
                  importance: Importance.max,
                  priority: Priority.high,
                  showWhen: true,
              ),
          ),
      );
  }

  Future<void> scheduleExpiryNotification(
      int id, String productName, DateTime expiryDate, {int daysBefore = 7, DateTime? customReminderDate}) async {
    
    print("Scheduling for $productName (ID: $id). Expiry: $expiryDate, Custom: $customReminderDate");

    // 1. Schedule custom days before (from Settings)
    final customDate = expiryDate.subtract(Duration(days: daysBefore));
    if (customDate.isAfter(DateTime.now())) {
        await _schedule(id * 10 + 1, "Expiry Warning", "$productName expires in $daysBefore days!", customDate);
    }

    // 2. Schedule 10 days before (Fixed logic)
    if (daysBefore != 10) {
      final tenDaysBefore = expiryDate.subtract(const Duration(days: 10));
      if (tenDaysBefore.isAfter(DateTime.now())) {
          await _schedule(id * 10 + 3, "Upcoming Expiry", "$productName expires in 10 days.", tenDaysBefore);
      }
    }

    // 3. Schedule 1 day before (Urgent)
    if (daysBefore != 1) { 
      final oneDayBefore = expiryDate.subtract(const Duration(days: 1));
      if (oneDayBefore.isAfter(DateTime.now())) {
          await _schedule(id * 10 + 2, "Urgent Expiry", "$productName expires tomorrow!", oneDayBefore);
      }
    }

    // 4. Schedule Specific Custom Reminder (from Product)
    if (customReminderDate != null) {
        if (customReminderDate.isAfter(DateTime.now())) {
             final daysDiff = expiryDate.difference(customReminderDate).inDays;
             String body = (daysDiff > 0) 
                ? "$productName expires in $daysDiff days." 
                : "$productName expires today!";
             
             print("Scheduling Custom Reminder for $productName at $customReminderDate");
             await _schedule(id * 10 + 4, "Custom Reminder", body, customReminderDate);
        } else {
             print("Custom reminder date $customReminderDate is in the past! Now: ${DateTime.now()}");
        }
    }
  }

  Future<void> _schedule(int id, String title, String body, DateTime scheduledDate) async {
     try {
       print("Attempting to schedule ID $id at $scheduledDate (Local: ${tz.TZDateTime.from(scheduledDate, tz.local)})");
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
      print("Successfully scheduled ID $id");
     } catch (e) {
       print("Error scheduling notification: $e");
       // Ignore errors for past dates or scheduling limits
     }
  }
  
  Future<void> cancelNotifications(dynamic productId) async {
      // Handle both String UUIDs (hash them) or int IDs. 
      // Product.key is usually int in Hive, but check usage.
      // If productId is int, use it directly.
      int id = productId is int ? productId : productId.hashCode;
      
      await flutterLocalNotificationsPlugin.cancel(id * 10 + 1);
      await flutterLocalNotificationsPlugin.cancel(id * 10 + 2);
      await flutterLocalNotificationsPlugin.cancel(id * 10 + 3);
      await flutterLocalNotificationsPlugin.cancel(id * 10 + 4);
  }
}
