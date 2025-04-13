import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:tambal/models/schedule.dart';
import 'package:tambal/models/dispensing_log.dart';
import 'package:tambal/services/firestore_service.dart';
import 'package:tambal/services/realtime_database_service.dart';
import 'package:tambal/widgets/custom_schedule_card.dart';
import 'package:tambal/widgets/custom_recent_patient.dart';
import 'package:tambal/widgets/custom_alert_card.dart';

class PatientInformationModal extends StatelessWidget {
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String patientId;
  final int patientSlot;
  final VoidCallback onEdit;

  const PatientInformationModal({
    super.key,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.patientId,
    required this.patientSlot,
    required this.onEdit,
  });

  // Function to get gender-based image
  String getGenderImage(String gender) {
    if (gender.toLowerCase() == 'male') {
      return 'assets/images/Male.png';
    } else {
      return 'assets/images/Female.png';
    }
  }

  Future<void> _dispenseMedicines(BuildContext context, int patientSlot) async {
    final realtimeDatabaseService =
        Provider.of<RealtimeDatabaseService>(context, listen: false);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final Logger logger = Logger();

    // ✅ Capture time before async calls to avoid using BuildContext later
    final DateTime now = DateTime.now();
    final String formattedDate = "${now.month}/${now.day}/${now.year}";

    // ✅ Use MaterialLocalizations to format time without needing BuildContext later
    final String formattedTime = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(now));

    // Show the loading dialog
    if (context.mounted) {
      _showLoadingDialog(context, "Dispensing Medicines...");
    }

    try {
      bool isDispensed = false;

      logger.i('Setting patient slot $patientSlot to dispense medicines.');
      await realtimeDatabaseService.setDispenseSlot(patientSlot);

      // Wait for the ESP32 to confirm dispensing
      await Future.delayed(const Duration(milliseconds: 500));
      final Stopwatch timer = Stopwatch()..start();

      while (timer.elapsed < const Duration(seconds: 10)) {
        final int? currentSlot =
            await realtimeDatabaseService.getDispenseSlot();
        if (currentSlot == 0) {
          isDispensed = true;
          logger.i(
              'Medicines dispensed successfully from patient slot $patientSlot.');
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }

      timer.stop();

      if (!isDispensed) {
        logger.e(
            'Failed to dispense medicines from patient slot $patientSlot within the timeout period.');
        await realtimeDatabaseService.setDispenseSlot(0); // Reset dispense slot

        if (context.mounted) {
          Navigator.of(context).pop(); // Dismiss the loading dialog
          _showResultDialog(context, false,
              'Failed to dispense medicines from patient slot $patientSlot.');
        }
        return;
      }

      final scheduleData =
          await firestoreService.getLatestDispenseWithMedicine(patientId);

      logger.i("🔹 Raw Schedule Type: ${scheduleData?["scheduleType"]}");

      if (scheduleData != null) {
        String scheduleType = scheduleData["scheduleType"]?.toString() ??
            "Unknown"; // ✅ Explicitly convert to String
        logger.i("✅ Assigned Schedule Type: $scheduleType");

        DispensingLog logEntry = DispensingLog(
          date: formattedDate,
          time: formattedTime,
          patientId: patientId,
          patientName: patientName,
          scheduleType: scheduleType, // ✅ Direct assignment
          medicine: scheduleData["medicine"]
              .toString(), // ✅ Ensure medicine is String
          source: "",
        );

        logger.i("🚀 Final LogEntry Before Saving: ${logEntry.scheduleType}");

        await firestoreService.addDispensingLog(logEntry);
      } else {
        logger.e("⛔ No schedule found for patient.");
      }

      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss the loading dialog
        _showResultDialog(context, true, 'Medicines dispensed successfully!');
      }
    } catch (e) {
      logger.e('An error occurred during dispensing: $e');

      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss the loading dialog
        _showResultDialog(
            context, false, 'An error occurred. Please try again.');
      }
    }
  }

  void _confirmDispense(BuildContext context, int patientSlot) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Dispense'),
          content: const Text(
            'Do you want to dispense the medicines of this patient?', // ✅ Display as string
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _dispenseMedicines(context, patientSlot); // ✅ Pass slot only
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        );
      },
    );
  }

  void _showResultDialog(BuildContext context, bool success, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(success ? 'Success' : 'Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        DefaultTabController(
          length: 2, // Number of tabs: Schedule and Activity
          child: Container(
            height: screenHeight * 0.9, // Modal height set to 90% of the screen
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30), // Rounded top corners
              ),
            ),
            child: Column(
              children: [
                // Upper Section with Avatar and Patient Info
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade300,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🔹 Top Handle Bar (for dragging the modal)
                      Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      // 🔹 Avatar & Edit Button (Stacked together)
                      Stack(
                        clipBehavior: Clip.none, // ✅ Ensures nothing is clipped
                        children: [
                          // 🔹 Centered Circle Avatar
                          Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: -3,
                                  left: 0,
                                  right: 0,
                                  child: ClipOval(
                                    child: Image.asset(
                                      getGenderImage(patientGender),
                                      width: 85,
                                      height: 92,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 🔹 Edit Button (Upper-right, clickable)
                          Positioned(
                            top: -15, // ✅ Moves button slightly down
                            right: -5, // ✅ Aligns it to the right
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              // ✅ Ensures it remains tappable
                              child: Material(
                                color: Colors.transparent,
                                // ✅ Fixes tap issues on Android
                                child: IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.white, size: 26),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    onEdit(); // ✅ Call edit function
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 🔹 Name, Age & Gender (Placed below the Avatar)
                      const SizedBox(height: 12),
                      // ✅ Space between Avatar & Name
                      Text(
                        patientName,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Age: $patientAge',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            'Gender: $patientGender',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tab Bar
                const TabBar(
                  labelColor: Colors.black,
                  indicatorColor: Colors.blue,
                  tabs: [
                    Tab(text: 'Schedule'),
                    Tab(text: 'Activity'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ScheduleTab(
                        patientId: patientId,
                        patientName: patientName,
                      ),
                      ActivityTab(patientId: patientId),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 🔹 Floating Action Button (FAB) - Positioned Above Modal Bottom
        Positioned(
          bottom: 30, // ✅ Adjusted to float above the bottom
          right: 20, // ✅ Positioned to the right
          child: FloatingActionButton(
            onPressed: () {
              _confirmDispense(context, patientSlot);
            },
            backgroundColor: Colors.blue, // Customize button color
            child: const Icon(Icons.medical_services_rounded,
                size: 28, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // Helper function to get initials from name
  String getInitials(String name) {
    return name.split(' ').map((word) => word[0]).join().toUpperCase();
  }
}

class ScheduleTab extends StatelessWidget {
  final String patientId;
  final String patientName;

  const ScheduleTab({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    return FutureBuilder<List<Schedule>>(
      future: firestoreService.getSchedulesForPatient(patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No schedules found.'));
        }

        // ✅ Sort the schedules based on scheduleType (Breakfast -> Lunch -> Dinner)
        final schedules = snapshot.data!;
        schedules.sort((a, b) => a.scheduleType.compareTo(b.scheduleType));

        return ListView.builder(
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              child: CustomScheduleCard(
                schedule: schedule,
                onTap: () => {},
              ),
            );
          },
        );
      },
    );
  }
}

class ActivityTab extends StatelessWidget {
  final String patientId;

  const ActivityTab({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    return FutureBuilder<List<DispensingLog>>(
      future: firestoreService.getDispensingLogsByPatient(patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No activity logs found.'));
        }

        final logs = snapshot.data!;

        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              child: log.source == "logging"
                  ? RecentPatientCard(
                      patientName: log.patientName,
                      day: log.date,
                      time: log.time,
                      medicineList: log.scheduleType,
                    )
                  : CustomAlertCard(
                      patientName: log.patientName,
                      missedMedicine: log.scheduleType,
                      dateMissed: log.date,
                      timeMissed: log.time,
                    ),
            );
          },
        );
      },
    );
  }
}
