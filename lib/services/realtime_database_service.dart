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
  StreamSubscription<DatabaseEvent>? _stockListener;

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
      _logger.i("📢 New dispensing log detected: ${event.snapshot.value}");

      Map<dynamic, dynamic> logData =
          Map<dynamic, dynamic>.from(event.snapshot.value as Map);

      String logId = event.snapshot.key ?? "";
      bool isDispensed = logData['isDispensed'] ?? false;
      String day = logData['day'] ?? "Unknown";
      String patientId = logData['patientId'] ?? "Unknown";
      String time = logData['time'] ?? "Unknown";
      List<dynamic> medicinesList = logData['medicines'] ?? [];
      List<Map<String, dynamic>> updatedMedicines = [];

      // Fetch medicine names for all logs
      for (var med in medicinesList) {
        int slot = med['slot'] ?? 0;
        int quantity = med['quantity'] ?? 1;
        String medicineName = await _getMedicineNameFromSlot(slot);

        updatedMedicines.add({
          "slot": slot,
          "quantity": quantity,
          "medicineName": medicineName,
        });
      }

      // 🔹 Fetch patient name based on patientId
      String patientName = await _getPatientNameFromId(patientId);

      // Update stock only if dispensed
      //if (isDispensed) {
      //await firestoreService.updateStocksBySlot(updatedMedicines);
      //}

      // Determine target collection and store in Firestore with timestamp
      String collectionName = isDispensed ? "logging" : "alerts";
      await _firestore.collection(collectionName).doc(logId).set({
        "day": day,
        "patientId": patientId, // Keep original ID for reference
        "patientName": patientName, // Store resolved name
        "time": time,
        "medicines": updatedMedicines,
        "timestamp": FieldValue.serverTimestamp(), // 🔹 Add Firestore timestamp
      });

      // Remove processed log from Realtime Database
      await _databaseRef.child('dispensingLogs').child(logId).remove();
      _logger.i(
          "✅ Moved log to Firestore collection: $collectionName (ID: $logId)");
    }
  }

// 🔹 Fetch medicine name from Firestore based on slot
  Future<String> _getMedicineNameFromSlot(int slot) async {
    final querySnapshot = await _firestore
        .collection('medicine')
        .where('slot', isEqualTo: slot)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.get('name') ?? "Unknown";
    }
    return "Unknown"; // Default if medicine is not found
  }

// 🔹 Fetch patient name from Firestore based on patientId
  Future<String> _getPatientNameFromId(String patientId) async {
    try {
      DocumentSnapshot docSnapshot =
          await _firestore.collection('patients').doc(patientId).get();

      if (docSnapshot.exists) {
        return docSnapshot.get('name') ?? "Unknown Patient";
      }
      return "Unknown Patient"; // Default if patient is not found
    } catch (e) {
      _logger.i("Error fetching patient name for ID $patientId: $e");
      return "Unknown Patient"; // Return default in case of error
    }
  }

  // 🔹 Stop listening when needed (e.g., logout or app closes)
  void stopListening() {
    _dispensingLogSubscription?.cancel();
    _logger.i("Stopped listening to dispensingLogs");
  }

  Future<void> syncMedicineFromFirestore(String medicineId) async {
    try {
      _logger.i(
          'Fetching medicine $medicineId from Firestore to sync with RTDB...');

      // Fetch the medicine document from Firestore
      DocumentSnapshot docSnapshot =
          await _firestore.collection('medicine').doc(medicineId).get();

      if (docSnapshot.exists) {
        Map<String, dynamic> medicineData =
            docSnapshot.data() as Map<String, dynamic>;

        // ✅ Remove 'timestamp' & 'lastUpdated' if they exist
        medicineData.remove('timestamp');
        medicineData.remove('lastUpdated');

        // ✅ Store medicine data in RTDB under "medicines/{medicineId}"
        await _databaseRef.child('medicines/$medicineId').set(medicineData);

        _logger
            .i('Medicine $medicineId successfully synced to Realtime Database');
      } else {
        _logger.w(
            'Medicine $medicineId does not exist in Firestore. Skipping RTDB sync.');
      }
    } catch (e) {
      _logger.e(
          'Failed to sync medicine $medicineId from Firestore to Realtime Database: $e');
    }
  }

  Future<void> deleteMedicine(String medicineId) async {
    try {
      // Delete from Firestore first
      await _firestore.collection('medicine').doc(medicineId).delete();

      // Then delete from RTDB
      await _databaseRef.child('medicines').child(medicineId).remove();

      _logger.i(
          'Medicine $medicineId deleted from Firestore and Realtime Database');
    } catch (e) {
      _logger
          .e('Failed to delete medicine $medicineId from Firestore/RTDB: $e');
    }
  }

  void listenToStockChanges() {
    _logger.i("Listening to stock changes in Realtime Database...");

    // Listen to all medicines' stock updates inside "medicines" node
    _stockListener =
        _databaseRef.child('medicines').onChildChanged.listen((event) async {
      if (event.snapshot.exists) {
        String medicineId = event.snapshot.key ?? "";
        Map<dynamic, dynamic> updatedData =
            event.snapshot.value as Map<dynamic, dynamic>;

        // ✅ Check if "stock" exists in the update
        if (updatedData.containsKey("stock")) {
          int updatedStock = updatedData["stock"];
          _logger.i(
              "Stock updated in RTDB for $medicineId: New Stock = $updatedStock");

          // ✅ Sync stock update to Firestore
          await _syncStockToFirestore(medicineId, updatedStock);
        }
      }
    });
  }

  /// ✅ Sync Stock Changes from RTDB to Firestore
  Future<void> _syncStockToFirestore(String medicineId, int newStock) async {
    try {
      await _firestore.collection("medicine").doc(medicineId).update({
        "stock": newStock,
        "lastUpdated": FieldValue.serverTimestamp(), // Optional timestamp
      });

      _logger.i("Stock for $medicineId successfully updated in Firestore.");
    } catch (e) {
      _logger.e("Failed to update stock for $medicineId in Firestore: $e");
    }
  }

  /// ✅ Stop Listening When Not Needed
  void stopStockListener() {
    _stockListener?.cancel();
    _logger.i("Stopped listening to stock changes.");
  }
}
