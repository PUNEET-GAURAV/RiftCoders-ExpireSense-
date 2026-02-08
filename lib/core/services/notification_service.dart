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
      
      // CRITICAL: Request Exact Alarm Permission for Android 12+
      // 'zonedSchedule' with 'exactAllowWhileIdle' requires this.
      await androidImplementation.requestExactAlarmsPermission();

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
    
    print("Scheduling daily countdown for $productName (ID: $id). Expiry: $expiryDate");

    // Base ID structure: product_key * 100 + offset
    // Offsets: 1-7 for daily countdowns, 99 for custom reminder
    
    // 1. Schedule Daily Countdowns (7, 6, 5, 4, 3, 2, 1 days before)
    for (int i = 7; i >= 1; i--) {
        final reminderDate = expiryDate.subtract(Duration(days: i));
        if (reminderDate.isAfter(DateTime.now())) {
            
            String title = (i == 1) ? "Urgent Expiry!" : "Expiry Warning";
            String body = (i == 1) 
                ? "$productName expires tomorrow!" 
                : "$productName expires in $i days.";

            await _schedule(id * 100 + i, title, body, reminderDate);
        }
    }
    
    // 2. Schedule Expiry Day Notification (0 days before)
    // Optional: User might want to know ON the day too.
    if (expiryDate.isAfter(DateTime.now())) {
       await _schedule(id * 100 + 0, "Expired!", "$productName expires today!", expiryDate);
    }

    // 3. Schedule Specific Custom Reminder (from Product)
    if (customReminderDate != null) {
        if (customReminderDate.isAfter(DateTime.now())) {
             final daysDiff = expiryDate.difference(customReminderDate).inDays;
             String body = (daysDiff > 0) 
                ? "$productName expires in $daysDiff days." 
                : "$productName expires today!";
             
             print("Scheduling Custom Reminder for $productName at $customReminderDate with ID ${id * 100 + 99}");
             await _schedule(id * 100 + 99, "Custom Reminder", body, customReminderDate);
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
            playSound: true,
            styleInformation: BigTextStyleInformation(''),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: body,
      );
      print("Successfully scheduled ID $id");
     } catch (e) {
       print("Error scheduling notification (ID $id): $e");
       
       // Fallback: Try scheduling without 'precise' if exact alarm permission is missing
       if (e.toString().contains("exact_alarms_not_permitted")) {
           print("Falling back to inexact scheduling for ID $id");
           try {
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
                    playSound: true,
                    styleInformation: BigTextStyleInformation(''),
                  ),
                ),
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // Fallback
                uiLocalNotificationDateInterpretation:
                    UILocalNotificationDateInterpretation.absoluteTime,
                payload: body,
              );
              print("Successfully scheduled ID $id (Inexact)");
           } catch (e2) {
               print("Fallback failed: $e2");
           }
       }
     }
  }
  
  Future<void> cancelNotifications(dynamic productId) async {
      int id = productId is int ? productId : productId.hashCode;
      
      // Cancel all potential daily countdowns (0-7) and custom reminder (99)
      for (int i = 0; i <= 7; i++) {
          await flutterLocalNotificationsPlugin.cancel(id * 100 + i);
      }
      await flutterLocalNotificationsPlugin.cancel(id * 100 + 99);
  }
}
