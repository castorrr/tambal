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

class PatientInformationModal extends StatelessWidget {
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String patientId;

  const PatientInformationModal({
    super.key,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.patientId,
  });

  // Function to get gender-based image
  String getGenderImage(String gender) {
    if (gender.toLowerCase() == 'male') {
      return 'assets/images/Male.png';
    } else {
      return 'assets/images/Female.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return DefaultTabController(
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
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // 🔹 Centering the CircleAvatar properly
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 90, // Ensures it's a circle
                          height: 90,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white, // Background color
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26, // Soft shadow
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: -3, // Move up slightly for the pop-out effect
                          left: 0,
                          right: 0,
                          child: ClipOval(
                            child: Image.asset(
                              getGenderImage(
                                  patientGender), // Load the correct gender image
                              width:
                                  85, // Must match height to keep it a perfect circle
                              height: 92,
                              fit: BoxFit
                                  .cover, // Ensures it fills without distortion
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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

  Future<void> _dispenseMedicines(
      BuildContext context, List<Map<String, dynamic>> medicines) async {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final realtimeDatabaseService =
        Provider.of<RealtimeDatabaseService>(context, listen: false);
    final Logger logger = Logger();

    // Show the loading dialog
    _showLoadingDialog(context, "Checking Medicines and Dispensing");

    try {
      // Validate medicines data
      for (final medicine in medicines) {
        if (medicine['name'] == null) {
          logger.e('Medicine with missing name found: $medicine');
          if (context.mounted) {
            Navigator.of(context).pop();
            _showResultDialog(
                context, false, 'One or more medicines have invalid data.');
          }
          return;
        }
      }

      // Check if all stocks are sufficient
      final allStocksAvailable =
          await firestoreService.checkStocksByName(medicines);

      if (!allStocksAvailable) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Dismiss loading dialog
          _showResultDialog(
              context, false, 'Insufficient stock for one or more medicines.');
        }
        logger.e(
            'Dispense aborted: Insufficient stock for one or more medicines.');
        return;
      }

      // Proceed to dispense medicines
      bool allDispensedSuccessfully = true;

      for (final medicine in medicines) {
        final int slot = (medicine['slot'] is int)
            ? medicine['slot']
            : int.parse(medicine['slot']);
        final int quantity = (medicine['quantity'] is int)
            ? medicine['quantity']
            : int.parse(medicine['quantity']);

        for (int i = 0; i < quantity; i++) {
          bool isDispensed = false;

          logger.i(
              'Setting slot $slot to dispense medicine ${medicine['name']} (Attempt ${i + 1})');
          await realtimeDatabaseService.setDispenseSlot(slot);

          // Wait for the ESP32 to confirm dispensing
          await Future.delayed(const Duration(milliseconds: 500));
          final Stopwatch timer = Stopwatch()..start();

          while (timer.elapsed < const Duration(seconds: 10)) {
            final int? currentSlot =
                await realtimeDatabaseService.getDispenseSlot();
            if (currentSlot == 0) {
              isDispensed = true;
              logger.i(
                  'Medicine ${medicine['name']} dispensed successfully from slot $slot.');
              break;
            }
            await Future.delayed(const Duration(milliseconds: 500));
          }

          timer.stop();

          if (!isDispensed) {
            allDispensedSuccessfully = false;
            logger.e(
                'Failed to dispense medicine ${medicine['name']} from slot $slot within the timeout period.');
            await realtimeDatabaseService
                .setDispenseSlot(0); // Reset the dispense slot
            if (context.mounted) {
              Navigator.of(context).pop(); // Dismiss the loading dialog
              _showResultDialog(context, false,
                  'Failed to dispense medicine ${medicine['name']} from slot $slot.');
            }
            return; // Stop the process on failure
          }
        }
      }

      // Update stocks after successful dispensing
      if (allDispensedSuccessfully) {
        logger.i('Updating stocks...');
        await firestoreService.updateStocksBySlot(medicines);
        logger.i('Stocks updated successfully after dispensing.');
      } else {
        logger.w('Dispensing failed. Stocks will not be updated.');
      }

      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss the loading dialog
        _showResultDialog(
            context,
            allDispensedSuccessfully,
            allDispensedSuccessfully
                ? 'All medicines dispensed successfully!'
                : 'Failed to dispense some medicines. Please try again.');
      }

      logger.i(allDispensedSuccessfully
          ? 'All medicines dispensed successfully.'
          : 'Some medicines failed to dispense.');
    } catch (e) {
      logger.e('An error occurred during dispensing: $e');
      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss the loading dialog
        _showResultDialog(
            context, false, 'An error occurred. Please try again.');
      }
    }
  }

  void _confirmDispense(BuildContext context, Schedule schedule) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Dispense'),
          content: Text(
            'Do you want to dispense the medicines in this schedule?\n\n${schedule.medicines.map((m) => "${m['name']} (x${m['quantity']})").join("\n")} ',
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
                _dispenseMedicines(context, schedule.medicines);
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
        final schedules = snapshot.data!;
        return ListView.builder(
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              child: CustomScheduleCard(
                schedule: schedule,
                onTap: () => _confirmDispense(context, schedule),
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
              child: RecentPatientCard(
                patientName: log.patientName,
                day: log.day,
                time: log.time,
                medicineList:
                    log.medicineList.map((item) => item.toString()).toList(),
              ),
            );
          },
        );
      },
    );
  }
}
