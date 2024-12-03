import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tambal/services/firestore_service.dart'; // Import FirestoreService
import 'package:firebase_database/firebase_database.dart';
import 'package:logger/logger.dart';
import 'package:tambal/models/schedule.dart';
import 'package:tambal/models/dispensing_log.dart';

class RealtimeDatabaseService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  final Logger _logger = Logger();

  // Method to set the dispense slot
  Future<void> setDispenseSlot(int slot) async {
    try {
      await _databaseRef.child('dispense').set(slot);
      _logger.i('Slot $slot set to dispense');
    } catch (error) {
      _logger.e('Failed to set dispense: $error');
      rethrow; // Rethrow the error to be caught by the caller
    }
  }

  // Method to get the current dispense slot
  Future<int?> getDispenseSlot() async {
    try {
      final DataSnapshot snapshot = await _databaseRef.child('dispense').get();
      if (snapshot.exists) {
        final int? slot = snapshot.value as int?;
        _logger.i('Current dispense slot: $slot');
        return slot;
      } else {
        _logger.w('Dispense slot does not exist in the database');
        return null;
      }
    } catch (error) {
      _logger.e('Failed to get dispense slot: $error');
      return null;
    }
  }

  // Method to trigger fingerprint enrollment
  Future<void> triggerFingerprintEnrollment() async {
    try {
      await _databaseRef.child('fingerprintCommand').set({
        'command': 'enroll',
        'status': 'processing',
        'id': '0',
      });
      _logger.i('Fingerprint enrollment command sent');
    } catch (error) {
      _logger.e('Failed to send fingerprint enrollment command: $error');
      rethrow;
    }
  }

  // Method to listen for the fingerprint ID result
  void listenForFingerprintID(Function(String id) onResult) {
    _databaseRef.child('fingerprintCommand/status').onValue.listen((event) {
      if (event.snapshot.value == 'done') {
        _databaseRef.child('fingerprintCommand/id').once().then((snapshot) {
          final String? fingerprintID = snapshot.snapshot.value as String?;
          if (fingerprintID != null) {
            onResult(fingerprintID);
            _logger
                .i('Fingerprint enrolled successfully with ID: $fingerprintID');
            resetFingerprintCommand();
          }
        });
      }
    });
  }

  // Method to reset the fingerprint command fields
  Future<void> resetFingerprintCommand() async {
    try {
      await _databaseRef.child('fingerprintCommand').set({
        'command': 'none',
        'id': 0,
        'status': 'idle',
      });
      _logger.i('Fingerprint command reset to default values');
    } catch (error) {
      _logger.e('Failed to reset fingerprint command: $error');
    }
  }

  // Method to sync a single schedule to the Realtime Database
  // Function to sync a schedule to the Realtime Database
  Future<void> syncSchedule(Schedule schedule) async {
    try {
      await _databaseRef
          .child('schedules/${schedule.id}')
          .set(schedule.toMap());
      _logger.i('Schedule ${schedule.id} synced to Realtime Database');
    } catch (e) {
      _logger.e('Failed to sync schedule to Realtime Database: $e');
    }
  }

  // Function to delete a schedule from the Realtime Database
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _databaseRef.child('schedules/$scheduleId').remove();
      _logger.i('Schedule $scheduleId deleted from Realtime Database');
    } catch (e) {
      _logger.e('Failed to delete schedule $scheduleId: $e');
    }
  }

  // Function to delete all schedules for a specific patient
  Future<void> deleteSchedulesByPatient(String patientId) async {
    try {
      final schedulesSnapshot = await _databaseRef
          .child('schedules')
          .orderByChild('patientId')
          .equalTo(patientId)
          .get();

      if (schedulesSnapshot.exists) {
        for (final child in schedulesSnapshot.children) {
          await child.ref.remove();
        }
      }
      _logger.i(
          'All schedules for patient $patientId deleted from Realtime Database');
    } catch (e) {
      _logger.e('Failed to delete schedules for patient $patientId: $e');
    }
  }

  // Function to sync multiple schedules for a patient
  Future<void> syncSchedulesForPatient(
      String patientId, List<Schedule> schedules) async {
    try {
      for (final schedule in schedules) {
        await syncSchedule(schedule);
      }
      _logger.i(
          'All schedules for patient $patientId synced to Realtime Database');
    } catch (e) {
      _logger.e('Failed to sync schedules for patient $patientId: $e');
    }
  }

  //dispensing listener
  Stream<List<DispensingLog>> streamDispensingLogs() {
    // Reference to the dispensingLogs node
    DatabaseReference logRef = FirebaseDatabase.instance.ref('dispensingLogs');

    // Listen to the entire dispensingLogs node
    return logRef.onValue.asyncMap((event) async {
      final data = event.snapshot.value;

      if (data != null && data is Map) {
        // List to store the dispensing logs
        List<DispensingLog> dispensingLogs = [];

        // Create an instance of FirestoreService
        final firestoreService = FirestoreService();

        // Iterate through each entry in the dispensingLogs node
        for (var entry in data.entries) {
          final logData = Map<String, dynamic>.from(entry.value);

          // Extract log data
          final day = logData['day'] ?? 'Unknown';
          final time = logData['time'] ?? 'Unknown';
          final patientName = logData['patientId'] ?? 'Unknown';

          // Safely parse `isDispensed` as a bool
          final isDispensed = logData['isDispensed'] == 'true' ||
              logData['isDispensed'] == true;

          // Fetch the medicines array
          final medicines = logData['medicines'] ?? [];

          // Add the log data to the dispensingLogs list
          dispensingLogs.add(
            DispensingLog(
              day: day,
              time: time,
              patientName: patientName,
              medicineList: medicines.isEmpty
                  ? null
                  : List<String>.from(
                      medicines), // Convert to List<String> if necessary
            ),
          );

          // If isDispensed is true, process the medicines asynchronously
          if (isDispensed) {
            Future(() async {
              List<Map<String, dynamic>> medicineData = [];

              // Fetch stock details for each medicine
              for (String medicineName in List<String>.from(medicines)) {
                // Use FirestoreService to query Firestore by name
                final medicineQuery = await FirebaseFirestore.instance
                    .collection('medicine')
                    .where('name', isEqualTo: medicineName)
                    .get();

                if (medicineQuery.docs.isNotEmpty) {
                  final doc = medicineQuery.docs.first;
                  final currentStock = doc['stock'] ?? 0;

                  if (currentStock > 0) {
                    medicineData.add({
                      'name': medicineName,
                      'quantity': 1, // Decrement by 1 for each dispense
                      'currentStock': currentStock,
                      'docRef': doc.reference, // Store reference for updating
                    });
                  }
                }
              }

              // Use FirestoreService to update stocks
              await firestoreService.updateStocksByName(medicineData);

              // Set isDispensed to false in the Realtime Database
              await logRef.child(entry.key).update({'isDispensed': false});
            });
          }
        }

        return dispensingLogs;
      } else {
        // Return an empty list if there's no data
        return [];
      }
    });
  }
}
