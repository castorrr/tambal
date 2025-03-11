import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();

class NotificationService {
  /// Initialize notifications and schedule fixed reminders
  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      'resource://drawable/ic_notification', // Notification icon
      [
        NotificationChannel(
          channelKey: 'scheduled_channel',
          channelName: 'Scheduled Notifications',
          channelDescription: 'Notifications for scheduled medications',
          defaultColor: const Color(0xFF003FFF),
          importance: NotificationImportance.High,
          locked: true,
          ledColor: Colors.white,
          criticalAlerts: true,
        ),
      ],
    );

    if (!(await AwesomeNotifications().isNotificationAllowed())) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    // Clear and reschedule notifications every time the app starts
    await _clearAndRescheduleNotifications();
  }

  /// Clear all existing scheduled notifications and reschedule fixed ones
  Future<void> _clearAndRescheduleNotifications() async {
    logger.i("Clearing old notifications...");
    await AwesomeNotifications()
        .cancelAllSchedules(); // Clears all scheduled notifications

    logger.i("Scheduling new notifications...");
    await _scheduleFixedNotifications();
  }

  /// Schedule fixed notifications at predefined times
  Future<void> _scheduleFixedNotifications() async {
    try {
      final localTimeZone =
          await AwesomeNotifications().getLocalTimeZoneIdentifier();

      final now = DateTime.now();

      // Fixed medication times with corresponding messages
      final List<Map<String, dynamic>> notifications = [
        {
          "time": DateTime(
              now.year, now.month, now.day, 7, 30), // Breakfast - 8:00 AM
          "title": "Breakfast Medication Reminder",
          "body": "Time to eat breakfast and take your medicine!"
        },
        {
          "time":
              DateTime(now.year, now.month, now.day, 12, 0), // Lunch - 12:00 PM
          "title": "Lunch Medication Reminder",
          "body": "Time for lunch! Don't forget to take your medicine."
        },
        {
          "time":
              DateTime(now.year, now.month, now.day, 19, 0), // Dinner - 7:00 PM
          "title": "Dinner Medication Reminder",
          "body": "Dinner time! Take your medicine after eating."
        },
      ];

      for (final notification in notifications) {
        await _createNotification(
          notification["time"],
          notification["title"],
          notification["body"],
          localTimeZone,
        );
      }

      logger.i("Fixed notifications scheduled.");
    } catch (e, stackTrace) {
      logger.e("Error scheduling notifications: $e\n$stackTrace");
    }
  }

  /// Create a notification for a specific meal time
  Future<void> _createNotification(DateTime scheduledTime, String title,
      String body, String timeZone) async {
    try {
      if (scheduledTime.isBefore(DateTime.now())) {
        logger.w("Skipping past notification: $scheduledTime");
        return;
      }

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: scheduledTime.hour, // Unique ID based on hour
          channelKey: 'scheduled_channel',
          title: title,
          body: body,
          notificationLayout: NotificationLayout.BigText,
        ),
        schedule: NotificationCalendar(
          hour: scheduledTime.hour,
          minute: scheduledTime.minute,
          second: 0,
          timeZone: timeZone,
          repeats: true, // Daily repetition
        ),
      );

      logger.i("Notification scheduled at $scheduledTime: $title");
    } catch (e, stackTrace) {
      logger.e("Error creating notification: $e\n$stackTrace");
    }
  }
}
