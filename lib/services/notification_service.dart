import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();

class NotificationService {
  /// Initialize notifications and schedule reminders & "meal almost over" alerts
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

  /// Clear all existing scheduled notifications and reschedule
  Future<void> _clearAndRescheduleNotifications() async {
    logger.i("Clearing old notifications...");
    await AwesomeNotifications()
        .cancelAllSchedules(); // Clears all scheduled notifications

    logger.i("Scheduling new notifications...");
    await _scheduleFixedNotifications();
  }

  /// Schedule meal reminders and "meal almost over" notifications
  Future<void> _scheduleFixedNotifications() async {
    try {
      final localTimeZone =
          await AwesomeNotifications().getLocalTimeZoneIdentifier();
      final now = DateTime.now();

      // Meal times & "almost over" alerts (30 min before end)
      final List<Map<String, dynamic>> notifications = [
        {
          "reminderTime": DateTime(now.year, now.month, now.day, 5,
              0), // Breakfast Reminder - 5:00 AM
          "almostOverTime": DateTime(now.year, now.month, now.day, 7,
              30), // Breakfast Almost Over - 7:30 AM
          "title": "Breakfast Medication Reminder",
          "body": "It's time for breakfast! Take your medication now.",
          "almostOverTitle": "Breakfast Almost Over",
          "almostOverBody":
              "Breakfast is almost over! Don't forget to take your medicine."
        },
        {
          "reminderTime": DateTime(
              now.year, now.month, now.day, 10, 0), // Lunch Reminder - 10:00 AM
          "almostOverTime": DateTime(now.year, now.month, now.day, 12,
              30), // Lunch Almost Over - 12:30 PM
          "title": "Lunch Medication Reminder",
          "body": "Time for lunch! Don't forget to take your medicine.",
          "almostOverTitle": "Lunch Almost Over",
          "almostOverBody":
              "Lunch is almost over! Don't forget to take your medicine."
        },
        {
          "reminderTime": DateTime(
              now.year, now.month, now.day, 17, 0), // Dinner Reminder - 5:00 PM
          "almostOverTime": DateTime(now.year, now.month, now.day, 19,
              30), // Dinner Almost Over - 7:30 PM
          "title": "Dinner Medication Reminder",
          "body": "Dinner time! Take your medication after eating.",
          "almost OverTitle": "Dinner Almost Over",
          "almostOverBody":
              "Dinner is almost over! Don't forget to take your medicine."
        },
      ];

      for (final notification in notifications) {
        // Schedule the reminder notification
        await _createNotification(
          notification["reminderTime"],
          notification["title"],
          notification["body"],
          localTimeZone,
        );

        // Schedule the "meal almost over" notification
        await _createNotification(
          notification["almostOverTime"],
          notification["almostOverTitle"],
          notification["almostOverBody"],
          localTimeZone,
        );
      }

      logger.i("Meal reminders and 'meal almost over' alerts scheduled.");
    } catch (e, stackTrace) {
      logger.e("Error scheduling notifications: $e\n$stackTrace");
    }
  }

  /// Create a notification for a meal reminder or "meal almost over" alert
  Future<void> _createNotification(
    DateTime scheduledTime,
    String title,
    String body,
    String timeZone,
  ) async {
    try {
      if (scheduledTime.isBefore(DateTime.now())) {
        logger.w("Skipping past notification: $scheduledTime");
        return;
      }

      int uniqueId = scheduledTime.hour * 100 +
          scheduledTime.minute; // Unique ID based on time

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: uniqueId,
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
          repeats: true, // Repeat daily
        ),
      );

      logger.i("Notification scheduled at $scheduledTime: $title");
    } catch (e, stackTrace) {
      logger.e("Error creating notification: $e\n$stackTrace");
    }
  }
}
