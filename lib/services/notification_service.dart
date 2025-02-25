import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/schedule.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

final Logger logger = Logger();

class NotificationService {
  final CollectionReference _scheduleCollection =
      FirebaseFirestore.instance.collection('schedules');

  final Set<int> _activeNotificationIds = {};

  /// Initialize notifications
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
  }

  /// Start listening for schedule updates in Firestore
  void startListeningForScheduleUpdates() async {
    final localTimeZone =
        await AwesomeNotifications().getLocalTimeZoneIdentifier();
    logger.i("Starting to listen for Firestore updates...");

    // Clear existing schedules
    await AwesomeNotifications().cancelAllSchedules();
    _activeNotificationIds.clear();

    _scheduleCollection.snapshots().listen(
      (snapshot) {
        for (final change in snapshot.docChanges) {
          final Map<String, dynamic>? data =
              change.doc.data() as Map<String, dynamic>?;

          if (data == null) {
            logger.w("Received null data for document: ${change.doc.id}");
            continue;
          }

          final schedule = Schedule.fromMap(data);

          switch (change.type) {
            case DocumentChangeType.added:
              _scheduleNotification(schedule, localTimeZone);
              break;
            case DocumentChangeType.modified:
              _updateNotification(schedule, localTimeZone);
              break;
            case DocumentChangeType.removed:
              _cancelNotificationsForSchedule(schedule);
              break;
          }
        }
      },
      onError: (error) {
        logger.e("Error in Firestore listener: $error");
        Future.delayed(
            const Duration(minutes: 1), startListeningForScheduleUpdates);
      },
    );
  }

  /// Schedule notifications
  Future<void> _scheduleNotification(Schedule schedule, String timeZone) async {
    try {
      final medicationTime = _parseTime(schedule.time);
      if (medicationTime == null) {
        logger.e("Invalid time format for schedule: ${schedule.time}");
        return;
      }

      final notificationTimes = [
        medicationTime.subtract(const Duration(minutes: 15)), // Reminder
        medicationTime, // Actual notification
      ];

      for (final time in notificationTimes) {
        await _createNotification(schedule, time, timeZone, repeats: true);
      }
    } catch (e, stackTrace) {
      logger.e("Error scheduling notification: $e\n$stackTrace");
    }
  }

  /// Create a notification
  Future<void> _createNotification(
      Schedule schedule, DateTime scheduledTime, String timeZone,
      {bool repeats = false}) async {
    try {
      if (scheduledTime.isBefore(DateTime.now())) {
        logger.w("Skipping past notification: $scheduledTime");
        return;
      }

      // ✅ Use schedule.medicine directly (it's already formatted as a string)
      final String medicineList = schedule.medicine;

      final notificationId =
          _generateNotificationId(schedule.id, scheduledTime);

      const title = "Medication Reminder";
      final body =
          "Hello ${schedule.patientName}, it's almost time to take your medication.\n$medicineList";

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'scheduled_channel',
          title: title,
          body: body,
          notificationLayout: NotificationLayout.BigText,
        ),
        schedule: NotificationCalendar(
          year: scheduledTime.year,
          month: scheduledTime.month,
          day: scheduledTime.day,
          hour: scheduledTime.hour,
          minute: scheduledTime.minute,
          second: 0,
          timeZone: timeZone,
          repeats: repeats,
        ),
      );

      logger.i(
          "Notification scheduled for ${schedule.patientName} at $scheduledTime");
    } catch (e, stackTrace) {
      logger.e("Error creating notification: $e\n$stackTrace");
    }
  }

  /// Update notifications
  Future<void> _updateNotification(Schedule schedule, String timeZone) async {
    await _cancelNotificationsForSchedule(schedule);
    await _scheduleNotification(schedule, timeZone);
  }

  /// Cancel notifications for a schedule
  Future<void> _cancelNotificationsForSchedule(Schedule schedule) async {
    final scheduleIdHash = schedule.id.hashCode.toString();
    final toCancel = _activeNotificationIds
        .where((id) => id.toString().startsWith(scheduleIdHash))
        .toList();

    for (final id in toCancel) {
      await AwesomeNotifications().cancel(id);
      _activeNotificationIds.remove(id);
    }

    logger.i("Cancelled notifications for schedule: ${schedule.id}");
  }

  /// Parse time string
  DateTime? _parseTime(String time) {
    try {
      final cleanedTime = time.replaceAll(RegExp(r'\s+'), ' ').trim();
      final now = DateTime.now();
      final formats = [
        DateFormat.jm(),
        DateFormat('h:mm a'),
        DateFormat('HH:mm')
      ];

      for (final format in formats) {
        try {
          final parsedTime = format.parse(cleanedTime);
          return DateTime(
              now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
        } catch (_) {
          continue;
        }
      }
      logger.e("Failed to parse time: $cleanedTime");
      return null;
    } catch (e) {
      logger.e("Error parsing time: $time\n$e");
      return null;
    }
  }

  /// Generate unique notification ID
  int _generateNotificationId(String id, DateTime time) {
    return id.hashCode ^ time.hashCode;
  }
}
