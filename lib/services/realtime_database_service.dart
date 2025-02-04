import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tambal/services/firestore_service.dart'; // Import FirestoreService
import 'package:firebase_database/firebase_database.dart';
import 'package:logger/logger.dart';
import 'package:tambal/models/schedule.dart';
import 'package:tambal/models/dispensing_log.dart';
import 'dart:async';

class RealtimeDatabaseService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  final Logger _logger = Logger();
  StreamSubscription? _fingerprintListener;

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
    StreamSubscription? subscription;
    Timer? timeoutTimer;

    // Start listening to Firebase database changes
    subscription =
        _databaseRef.child('fingerprintCommand/status').onValue.listen((event) {
      if (event.snapshot.value == 'done') {
        _databaseRef.child('fingerprintCommand/id').once().then((snapshot) {
          final String? fingerprintID = snapshot.snapshot.value as String?;
          if (fingerprintID != null) {
            onResult(fingerprintID);
            _logger
                .i('Fingerprint enrolled successfully with ID: $fingerprintID');
            resetFingerprintCommand();

            // Cancel the subscription and timer as the result is found
            subscription?.cancel();
            timeoutTimer?.cancel();
          }
        });
      }
    });

    // Set up a timer to cancel the subscription after 15 seconds
    timeoutTimer = Timer(const Duration(seconds: 15), () {
      subscription?.cancel();
      _logger.w('Fingerprint enrollment timeout.');
      onResult('timeout'); // Callback to indicate a timeout
    });
  }

  // Method to reset the fingerprint command fields
  Future<void> resetFingerprintCommand() async {
    try {
      await _databaseRef.child('fingerprintCommand').set({
        'command': 'none',
        'id': '0',
        'status': 'idle',
      });
      _logger.i('Fingerprint command reset to default values');
    } catch (error) {
      _logger.e('Failed to reset fingerprint command: $error');
    }
  }

  void dispose() {
    _fingerprintListener?.cancel();
    _logger.i('Fingerprint listener canceled');
  }

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
    DatabaseReference logRef = FirebaseDatabase.instance.ref('dispensingLogs');

    return logRef.onValue.asyncMap((event) async {
      final data = event.snapshot.value;

      if (data != null && data is Map) {
        List<DispensingLog> dispensingLogs = [];
        final firestoreService = FirestoreService();

        for (var entry in data.entries) {
          final logData = Map<String, dynamic>.from(entry.value);

          final day = logData['day'] ?? 'Unknown';
          final time = logData['time'] ?? 'Unknown';
          final patientName = logData['patientId'] ?? 'Unknown';
          final isDispensed = logData['isDispensed'] == 'true' ||
              logData['isDispensed'] == true;

          // Fetch the medicines array
          final medicines = logData['medicines'];

          // Convert medicines to a list of maps, handle unexpected formats
          List<Map<String, dynamic>> medicineList = [];
          if (medicines is List) {
            try {
              // Ensure all items in the list are valid maps
              medicineList = medicines
                  .whereType<Map>()
                  .map((medicine) => Map<String, dynamic>.from(medicine))
                  .toList();
            } catch (e) {
              _logger.e('Invalid medicine data format: $medicines');
            }
          } else {
            _logger.e('Medicines field is not a List: $medicines');
          }

          // Add the log data to the dispensingLogs list
          dispensingLogs.add(
            DispensingLog(
              day: day,
              time: time,
              patientName: patientName,
              medicineList: medicineList
                  .map((medicine) => medicine['name']?.toString() ?? 'Unknown')
                  .toList(),
            ),
          );

          // If isDispensed is true, process the medicines asynchronously
          if (isDispensed) {
            Future(() async {
              List<Map<String, dynamic>> medicineData = [];

              // Fetch stock details for each medicine
              for (var medicine in medicineList) {
                final medicineName = medicine['name']?.toString() ?? 'Unknown';
                final quantity = medicine['quantity'] ?? 0;

                final medicineQuery = await FirebaseFirestore.instance
                    .collection('medicine')
                    .where('name', isEqualTo: medicineName)
                    .get();

                if (medicineQuery.docs.isNotEmpty) {
                  final doc = medicineQuery.docs.first;
                  final currentStock = doc['stock'] ?? 0;

                  if (currentStock >= quantity) {
                    medicineData.add({
                      'name': medicineName,
                      'quantity': quantity, // Decrement by this quantity
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

  // Add this method to your RealtimeDatabaseService
  Future<List<DispensingLog>> getDispensingLogsByPatient(
      String patientName) async {
    DatabaseReference logRef = _databaseRef.child('dispensingLogs');

    try {
      final DataSnapshot snapshot = await logRef.get();

      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        List<DispensingLog> dispensingLogs = [];

        for (var entry in data.entries) {
          final logData = Map<String, dynamic>.from(entry.value);

          final logPatientName = logData['patientId'] ?? 'Unknown';

          // Match only logs for the specified patient
          if (logPatientName == patientName) {
            final day = logData['day'] ?? 'Unknown';
            final time = logData['time'] ?? 'Unknown';

            // Fetch the medicines array
            final medicines = logData['medicines'] ?? [];
            List<String> medicineList = [];

            if (medicines is List) {
              try {
                medicineList = medicines
                    .whereType<Map>()
                    .map(
                        (medicine) => medicine['name']?.toString() ?? 'Unknown')
                    .toList();
              } catch (e) {
                _logger.e('Invalid medicine data format: $medicines');
              }
            }

            dispensingLogs.add(
              DispensingLog(
                day: day,
                time: time,
                patientName: logPatientName,
                medicineList: medicineList,
              ),
            );
          }
        }

        _logger.i(
            'Fetched ${dispensingLogs.length} logs for patient: $patientName');
        return dispensingLogs;
      } else {
        _logger.w('No logs found for patient: $patientName');
        return [];
      }
    } catch (e) {
      _logger.e('Failed to fetch dispensing logs for patient $patientName: $e');
      return [];
    }
  }
}
