import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tambal/services/firestore_service.dart'; // Import FirestoreService
import 'package:firebase_database/firebase_database.dart';
import 'package:logger/logger.dart';
import 'package:tambal/models/schedule.dart';
import 'dart:async';
import 'dart:collection';

class RealtimeDatabaseService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firestoreService = FirestoreService(); // ✅ Create instance
  final Logger _logger = Logger();
  StreamSubscription? _fingerprintListener;
  StreamSubscription? _dispensingLogSubscription;

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

  void listenToDispensingLogs() {
    final Queue<DatabaseEvent> eventQueue = Queue<DatabaseEvent>();
    bool isProcessing = false;

    _dispensingLogSubscription = _databaseRef
        .child('dispensingLogs')
        .onChildAdded
        .listen((DatabaseEvent event) async {
      // Add the event to the queue
      eventQueue.add(event);

      // Process the queue if not already processing
      if (!isProcessing) {
        isProcessing = true;
        try {
          while (eventQueue.isNotEmpty) {
            var currentEvent = eventQueue.removeFirst();
            await _processDispensingLog(currentEvent);
          }
        } finally {
          isProcessing = false;
        }
      }
    });
  }

  Future<void> _processDispensingLog(DatabaseEvent event) async {
    if (event.snapshot.value != null) {
      Map<dynamic, dynamic> logData =
          Map<dynamic, dynamic>.from(event.snapshot.value as Map);

      String logId = event.snapshot.key ?? "";
      String patientId = logData['patientId'] ?? "Unknown";
      int scheduleType = logData['scheduleType'] ?? 0;
      String medicine = logData['medicine'] ?? "Unknown";
      String time = logData['time'] ?? "Unknown";
      String date = logData['date'] ?? "Unknown";
      bool isDispensed = logData['isDispensed'] ?? "Unknown";

      // 🔹 Fetch patient name from Firestore using patientId
      String patientName = await _getPatientNameFromId(patientId);

      // 🔹 Convert scheduleType into readable format
      String scheduleTypeName = _convertScheduleType(scheduleType);

      // Determine target collection in Firestore
      String collectionName = isDispensed ? "logging" : "alerts";

      // 🔹 Store data in Firestore with timestamp
      await _firestore.collection(collectionName).doc(logId).set({
        "patientId": patientId, // Keep patient ID
        "patientName": patientName, // Store resolved name from Firestore
        "scheduleType":
            scheduleTypeName, // Convert scheduleType to readable string
        "medicine": medicine,
        "time": time,
        "date": date,
      });

      // 🔹 Remove processed log from Realtime Database
      await _databaseRef.child('dispensingLogs').child(logId).remove();
      _logger.i(
          "✅ Moved log to Firestore collection: $collectionName (ID: $logId)");
    }
  }

  /// 🔹 Fetch patient name using patientId from Firestore
  Future<String> _getPatientNameFromId(String patientId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('patients').doc(patientId).get();
      if (doc.exists) {
        return doc['name'] ?? "Unknown"; // Return patient name if available
      } else {
        return "Unknown"; // Return default if no patient found
      }
    } catch (e) {
      _logger.e("Error fetching patient name: $e");
      return "Unknown"; // Return default on error
    }
  }

  /// 🔹 Convert `scheduleType` (int) to readable format
  String _convertScheduleType(int scheduleType) {
    switch (scheduleType) {
      case 1:
        return "Breakfast";
      case 2:
        return "Lunch";
      case 3:
        return "Dinner";
      default:
        return "Unknown";
    }
  }

  // 🔹 Stop listening when needed (e.g., logout or app closes)
  void stopListening() {
    _dispensingLogSubscription?.cancel();
    _logger.i("Stopped listening to dispensingLogs");
  }

  /// 🔹 Hardcoded method to add a dispensing log to Realtime Database
  Future<void> addTestDispensingLog() async {
    try {
      // Generate a unique key for the new log
      String logId = _databaseRef.child("dispensingLogs").push().key ??
          DateTime.now().millisecondsSinceEpoch.toString();

      // Hardcoded dispensing log data
      Map<String, dynamic> logData = {
        "patientId": "Iyj9SpJnTJbgnIpGQ813",
        "scheduleType": 1, // 1 = Breakfast
        "medicine": "Naproxen 550 MG 1×, Folanerve N/A 1×, Bewell-C N/A 1×",
        "time": "08:00 AM",
        "date": "2/25/2025",
        "isDispensed": "No",
      };

      // Save the log data to the Realtime Database under 'dispensingLogs'
      await _databaseRef.child("dispensingLogs/$logId").set(logData);
    } catch (e) {
      _logger.i("Hotdog");
    }
  }

  Future<void> resetRealtimeDatabaseSchedules() async {
    try {
      await _databaseRef.child('schedules').remove();
      _logger.i("Realtime Database schedules node cleared.");
    } catch (e) {
      _logger.e("Error resetting Realtime Database schedules: $e");
    }
  }

  Future<void> resetScheduleUpdateStatus() async {
    try {
      await _databaseRef.child('latestUpdate/isUpdated').set(false);
      _logger.i('isUpdated set to false successfully.');
    } catch (e) {
      _logger.e('Error updating isUpdated: $e');
    }
  }
}
