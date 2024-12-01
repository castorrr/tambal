import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart'; // Import Logger
import 'package:tambal/models/schedule.dart';
import 'package:tambal/services/firestore_service.dart';
import 'package:tambal/services/realtime_database_service.dart';
import 'package:tambal/widgets/custom_schedule_card.dart';

class PatientSchedulesModal extends StatelessWidget {
  final String patientId;
  final String patientName;

  const PatientSchedulesModal({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  Future<void> _dispenseMedicines(
      BuildContext context, List<Map<String, dynamic>> medicines) async {
    final realtimeDatabaseService =
        Provider.of<RealtimeDatabaseService>(context, listen: false);
    final Logger logger = Logger();

    // Show the loading dialog
    _showLoadingDialog(context, "Dispensing medicine");

    bool allDispensedSuccessfully = true;

    for (final medicine in medicines) {
      // Safely parse 'slot' and 'quantity' as integers
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
        // Set the dispense slot
        await realtimeDatabaseService.setDispenseSlot(slot);

        // Wait for the ESP32 to confirm dispensing
        await Future.delayed(
            const Duration(milliseconds: 500)); // Give ESP32 time to respond
        final Stopwatch timer = Stopwatch()..start();

        while (timer.elapsed < const Duration(seconds: 10)) {
          final int? currentSlot =
              await realtimeDatabaseService.getDispenseSlot();
          if (currentSlot == 0) {
            // Dispense successful
            isDispensed = true;
            logger.i(
                'Medicine ${medicine['name']} dispensed successfully from slot $slot.');
            break;
          }
          await Future.delayed(
              const Duration(milliseconds: 500)); // Poll every 500ms
        }

        timer.stop();

        if (!isDispensed) {
          // Dispense failed
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
  }

  void _confirmDispense(BuildContext context, Schedule schedule) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing dialog by tapping outside
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Dispense'),
          content: Text(
            'Do you want to dispense the medicines in this schedule?\n\n${schedule.medicines.map((m) => "${m['name']} (x${m['quantity']})").join("\n")}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
                _dispenseMedicines(
                    context, schedule.medicines); // Start dispensing medicines
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
      barrierDismissible: false, // Prevent dismissing dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
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
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(success ? 'Success' : 'Failure'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
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

    return AlertDialog(
      title: Text('$patientName\'s Schedules'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: FutureBuilder<List<Schedule>>(
          future: firestoreService.getSchedulesForPatient(patientId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text(
                'No schedules found for this patient.',
                style: TextStyle(color: Colors.grey),
              );
            }

            final schedules = snapshot.data!;
            return ListView.builder(
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = schedules[index];
                return CustomScheduleCard(
                  schedule: schedule,
                  onTap: () => _confirmDispense(
                      context, schedule), // Show confirmation dialog
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
