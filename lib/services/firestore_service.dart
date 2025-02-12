// File: services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:tambal/models/medicine.dart';
import 'package:tambal/models/patient.dart';
import 'package:tambal/models/schedule.dart';
import 'package:tambal/models/dispensing_log.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // ----------------- Medicine Methods -----------------

  // Method to add a new medicine to Firestore
  Future<String> addMedicine({
    required String name,
    required String purpose,
    required int stock,
    required int slot,
    required String userId, // ✅ Make sure userId is required
  }) async {
    try {
      DocumentReference docRef = await _firestore.collection('medicine').add({
        'name': name,
        'purpose': purpose,
        'stock': stock,
        'slot': slot,
        'userId': userId, // ✅ Ensure it's stored
        'timestamp': FieldValue.serverTimestamp(),
      });

      String newId = docRef.id;
      _logger.i('Medicine added successfully with ID: $newId');

      return newId; // Return document ID
    } catch (e) {
      _logger.e('Failed to add medicine: $e');
      rethrow;
    }
  }

  // Method to update an existing medicine in Firestore
  Future<void> updateMedicine({
    required String id,
    required String name,
    required String purpose,
    required int stock,
    required int slot,
    required String userId,
  }) async {
    try {
      await _firestore.collection('medicine').doc(id).update({
        'name': name,
        'purpose': purpose,
        'stock': stock,
        'slot': slot,
        'userId': userId,
        // ❌ Removed 'timestamp' or 'lastUpdated' field
      });

      _logger.i('Medicine $id successfully updated in Firestore.');
    } catch (e) {
      _logger.e('Failed to update medicine $id in Firestore: $e');
      rethrow;
    }
  }

  // Method to fetch medicines as a stream from Firestore
  Stream<List<Medicine>> getMedicines() {
    return _firestore.collection('medicine').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return Medicine(
            id: doc.id,
            name: doc['name'] ?? 'Unknown',
            purpose: doc['purpose'] ?? 'Unknown',
            stock: doc['stock'] ?? 0,
            slot: doc['slot'] ?? 0,
          );
        } catch (e) {
          _logger.e('Error parsing medicine document: $e');
          throw Exception('Invalid data format in Firestore');
        }
      }).toList();
    });
  }

  // Method to delete a medicine from Firestore
  Future<void> deleteMedicine(String id) async {
    try {
      await _firestore.collection('medicine').doc(id).delete();
      _logger.i('Medicine with ID $id deleted successfully from Firestore.');
    } catch (e) {
      _logger.e('Failed to delete medicine with ID $id: $e');
      rethrow;
    }
  }

  // Method to get available medicines with slot, name, and stock
  Future<List<Map<String, dynamic>>> getAvailableMedicinesWithSlots() async {
    try {
      final snapshot = await _firestore.collection('medicine').get();
      final medicines = snapshot.docs.map((doc) {
        return {
          'slot': doc['slot'].toString(),
          'name': doc['name'] ?? 'Unknown',
        };
      }).toList();
      return medicines;
    } catch (e) {
      _logger.e('Failed to fetch available medicines: $e');
      rethrow;
    }
  }

  // Method to get specific medicine details by slot and name
  Future<Map<String, dynamic>?> getMedicineDetails(
      int slot, String name) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('medicine')
          .where('slot', isEqualTo: slot)
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        return {
          'id': doc.id,
          'slot': doc['slot'],
          'name': doc['name'],
          'stock': doc['stock'],
        };
      } else {
        _logger.w('No medicine found with slot $slot and name $name.');
        return null;
      }
    } catch (e) {
      _logger.e('Failed to fetch medicine details: $e');
      return null;
    }
  }

  // ----------------- Patient Methods -----------------

  // Method to generate a unique ID for a given collection
  String generateUniqueId(String collection) {
    return _firestore.collection(collection).doc().id;
  }

  // Method to add a new patient to Firestore
  Future<void> addPatient(Patient patient) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patient.id)
          .set(patient.toMap());
      _logger.i('Patient ${patient.name} added successfully to Firestore.');
    } catch (e) {
      _logger.e('Failed to add patient: $e');
      rethrow;
    }
  }

  // Method to get a stream of patients from Firestore
  Stream<List<Patient>> getPatientsStream() {
    return _firestore.collection('patients').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Patient.fromMap(data, doc.id);
      }).toList();
    });
  }

  // Method to delete a patient and all associated schedules
  Future<void> deletePatientAndSchedules(String patientId) async {
    try {
      // Start a batch write
      WriteBatch batch = _firestore.batch();

      // Delete the patient
      DocumentReference patientRef =
          _firestore.collection('patients').doc(patientId);
      batch.delete(patientRef);

      // Fetch all schedules associated with the patient
      QuerySnapshot scheduleSnapshot = await _firestore
          .collection('schedules')
          .where('patientId', isEqualTo: patientId)
          .get();

      // Add each schedule deletion to the batch
      for (var doc in scheduleSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Commit the batch
      await batch.commit();
      _logger.i(
          'Patient with ID $patientId and all associated schedules deleted successfully.');
    } catch (e) {
      _logger.e(
          'Failed to delete patient with ID $patientId and associated schedules: $e');
      rethrow;
    }
  }

  // Method to update a patient's details in Firestore
  Future<void> updatePatient(
      String patientId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('patients').doc(patientId).update(data);
      _logger.i('Patient with ID $patientId updated successfully.');
    } catch (e) {
      _logger.e('Failed to update patient with ID $patientId: $e');
      rethrow;
    }
  }

  // ----------------- Schedule Methods -----------------

  // Method to add a new schedule to Firestore
  Future<void> addSchedule(Schedule schedule) async {
    try {
      await _firestore.collection('schedules').add(schedule.toMap());
      _logger.i(
          'Schedule for ${schedule.patientName} added successfully to Firestore.');
    } catch (e) {
      _logger.e('Failed to add schedule: $e');
      rethrow;
    }
  }

  // Method to fetch schedules for a specific patient
  Future<List<Schedule>> getSchedulesForPatient(String patientId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('schedules')
          .where('patientId', isEqualTo: patientId)
          .get();

      return snapshot.docs.map((doc) {
        return Schedule.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      _logger.e('Failed to fetch schedules for patient ID $patientId: $e');
      rethrow;
    }
  }

  // Method to delete a schedule from Firestore
  Future<void> deleteSchedule(String fieldId) async {
    try {
      // Query the document based on the 'id' field
      QuerySnapshot snapshot = await _firestore
          .collection('schedules')
          .where('id', isEqualTo: fieldId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // If a document is found, delete it using its document ID
        await _firestore
            .collection('schedules')
            .doc(snapshot.docs.first.id)
            .delete();
        _logger.i('Schedule with field ID $fieldId deleted successfully.');
      } else {
        _logger.w('No schedule found with field ID $fieldId.');
      }
    } catch (e) {
      _logger.e('Failed to delete schedule with field ID $fieldId: $e');
      throw Exception('Failed to delete schedule with field ID $fieldId: $e');
    }
  }

  DocumentReference getScheduleDocument(String id) {
    return _firestore.collection('schedules').doc(id);
  }

  Future<bool> documentExists(String path) async {
    final doc = await _firestore.doc(path).get();
    return doc.exists;
  }

  Future<void> updateSchedule(Schedule schedule) async {
    try {
      await _firestore
          .collection('schedules')
          .doc(schedule.id)
          .update(schedule.toMap());
    } catch (e) {
      _logger.e('Failed to update schedule: $e');
      rethrow;
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getScheduleById(
      String scheduleId) {
    return _firestore.collection('schedules').doc(scheduleId).get();
  }

  //check medicine stock
  Future<int> checkStock(String medicineId) async {
    final medicineDoc = _firestore.collection('medicine').doc(medicineId);

    try {
      final snapshot = await medicineDoc.get();

      if (snapshot.exists) {
        final stock = snapshot.get('stock') ?? 0;
        return stock;
      } else {
        throw Exception('Medicine document not found: $medicineId');
      }
    } catch (e) {
      throw Exception('Failed to check stock for medicine $medicineId: $e');
    }
  }

  //decrement of stocks
  Future<void> decrementStock(String medicineId, int quantity) async {
    final medicineDoc = _firestore.collection('medicine').doc(medicineId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(medicineDoc);
      if (snapshot.exists) {
        final currentStock = snapshot.get('stock') ?? 0;
        if (currentStock >= quantity) {
          transaction.update(medicineDoc, {'stock': currentStock - quantity});
        } else {
          throw Exception(
              'Insufficient stock for medicine with ID $medicineId.');
        }
      } else {
        throw Exception('Medicine document not found: $medicineId.');
      }
    });
  }

  //schedule dispensing
  Future<bool> checkStocksByName(List<Map<String, dynamic>> medicines) async {
    for (final medicine in medicines) {
      final medicineName = medicine['name'];
      final requiredQuantity = medicine['quantity'];

      final querySnapshot = await _firestore
          .collection('medicine')
          .where('name', isEqualTo: medicineName)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return false; // Medicine not found
      }

      final doc = querySnapshot.docs.first;
      final currentStock = doc.get('stock') ?? 0;

      if (currentStock < requiredQuantity) {
        return false; // Insufficient stock
      }
    }
    return true; // All stocks are sufficient
  }

  Future<void> updateStocksBySlot(List<Map<String, dynamic>> medicines) async {
    try {
      Map<int, int> slotDecrements = {}; // Track total decrement per slot

      // Step 1: Accumulate decrements per slot
      for (final medicine in medicines) {
        final int slotNumber = (medicine['slot'] is int)
            ? medicine['slot']
            : int.tryParse(medicine['slot'].toString()) ?? 0;

        final int requiredQuantity = (medicine['quantity'] is int)
            ? medicine['quantity']
            : int.tryParse(medicine['quantity'].toString()) ?? 0;

        if (slotNumber == 0 || requiredQuantity == 0) {
          _logger.w('Skipping invalid medicine entry: $medicine');
          continue; // Skip invalid data
        }

        slotDecrements[slotNumber] =
            (slotDecrements[slotNumber] ?? 0) + requiredQuantity;
        _logger.i(
            'Slot $slotNumber: Adding quantity $requiredQuantity to decrement');
      }

      _logger.i('Final slot decrements: $slotDecrements');

      // Step 2: Apply total decrements for each slot
      for (final entry in slotDecrements.entries) {
        final int slotNumber = entry.key;
        final int totalQuantityToDeduct = entry.value;

        _logger.i(
            'Processing slot $slotNumber - Deducting $totalQuantityToDeduct units');

        final querySnapshot = await _firestore
            .collection('medicine')
            .where('slot', isEqualTo: slotNumber)
            .get();

        if (querySnapshot.docs.isEmpty) {
          _logger.e('No medicine found for slot $slotNumber');
          continue;
        }

        for (final doc in querySnapshot.docs) {
          final int currentStock = (doc.get('stock') is int)
              ? doc.get('stock')
              : int.tryParse(doc.get('stock').toString()) ?? 0;

          final String medicineName = doc.get('name') ?? 'Unknown Medicine';

          final int newStock = (currentStock - totalQuantityToDeduct)
              .clamp(0, currentStock); // Prevent negative stock

          _logger.i('Updating $medicineName (Slot $slotNumber):');
          _logger.i('Current stock: $currentStock');
          _logger.i('Deducting: $totalQuantityToDeduct');
          _logger.i('New stock will be: $newStock');

          // Use transaction for atomic update
          await _firestore.runTransaction((transaction) async {
            final docRef = doc.reference;
            final snapshot = await transaction.get(docRef);

            if (!snapshot.exists) {
              throw Exception('Document does not exist!');
            }

            final int currentStockInTransaction = (snapshot.get('stock') is int)
                ? snapshot.get('stock')
                : int.tryParse(snapshot.get('stock').toString()) ?? 0;

            final int newStockInTransaction =
                (currentStockInTransaction - totalQuantityToDeduct)
                    .clamp(0, currentStockInTransaction);

            transaction.update(docRef, {'stock': newStockInTransaction});
          });

          _logger.i('✅ Successfully updated stock for $medicineName');
        }
      }
    } catch (e, stackTrace) {
      _logger.e('⛔ Error updating stock: $e');
      _logger.e('Stack trace: $stackTrace');
      throw Exception('Failed to update stock: $e');
    }
  }

  //Analytics
  Stream<int> getTotalPatients() {
    return _firestore.collection('patients').snapshots().map((snapshot) {
      return snapshot.docs.length; // Count total patients
    });
  }

  Stream<int> getMedicineTypes() {
    return _firestore.collection('medicine').snapshots().map((snapshot) {
      return snapshot.docs.length; // Total medicines
    });
  }

  Stream<String> getLowestStockMedicine() {
    return _firestore
        .collection('medicine')
        .orderBy('stock') // Sort by lowest stock first
        .limit(1) // Only fetch one document
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return "No Medicines";
      return snapshot.docs.first.get('name') ?? "Unknown"; // Fetch only 'name'
    });
  }

  Stream<Map<String, String>?> getUpcomingSchedule() {
    String today = DateFormat('EEEE').format(DateTime.now()); // e.g., "Tuesday"

    return _firestore
        .collection('schedules')
        .where('days',
            arrayContains: today) // ✅ Filter schedules only for today
        .orderBy('time') // ✅ Order by time
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }

      DateTime now = DateTime.now();
      int currentTimeInt = _convertTimeToInt(DateFormat('h:mm a').format(now));

      for (var doc in snapshot.docs) {
        var data = doc.data();
        String scheduleTimeStr = data['time'] ?? "--";
        int scheduleTimeInt = _convertTimeToInt(scheduleTimeStr);

        if (scheduleTimeInt > currentTimeInt) {
          // ✅ Only return schedules that are in the future
          return {
            'patientName': data['patientName'] ?? "Unknown",
            'time': scheduleTimeStr,
          };
        }
      }

      // ✅ If no future schedules exist, return null
      return null;
    });
  }

  // 🔹 Convert "10:11 PM" to an int (e.g., 2211) for easier comparison
  int _convertTimeToInt(String timeStr) {
    try {
      DateTime parsedTime = DateFormat("h:mm a").parse(timeStr);
      return int.parse(DateFormat('HHmm').format(parsedTime)); // "2211"
    } catch (e) {
      return 0; // Return 0 if parsing fails
    }
  }

  Stream<List<DispensingLog>> streamDispensingLogs(
      {required String collectionName}) {
    return _firestore
        .collection(collectionName)
        .orderBy('timestamp', descending: true) // 🔹 Order by newest first
        .snapshots()
        .map((snapshot) {
      List<DispensingLog> dispensingLogs = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final day = data['day'] ?? 'Unknown';
        final time = data['time'] ?? 'Unknown';
        final patientName = data['patientName'] ?? 'Unknown';

        // Fetch the medicines array
        final medicines = data['medicines'] ?? [];
        List<Map<String, dynamic>> medicineList = [];

        if (medicines is List) {
          try {
            medicineList = medicines
                .whereType<Map<String, dynamic>>() // Ensure type safety
                .toList();
          } catch (e) {
            _logger.i('❌ Invalid medicine data format: $medicines');
          }
        } else {
          _logger.i('❌ Medicines field is not a List: $medicines');
        }

        // Add the log data to the list
        dispensingLogs.add(
          DispensingLog(
            day: day,
            time: time,
            patientName: patientName,
            medicineList: medicineList
                .map((medicine) =>
                    medicine['medicineName']?.toString() ?? 'Unknown')
                .toList(),
            source: '',
          ),
        );
      }

      return dispensingLogs;
    });
  }

  Future<List<DispensingLog>> getDispensingLogsByPatient(
      String patientId) async {
    try {
      List<Map<String, dynamic>> rawLogs = [];

      // Fetch from `logging` collection
      QuerySnapshot loggingSnapshot = await _firestore
          .collection('logging')
          .where('patientId', isEqualTo: patientId)
          .orderBy('timestamp',
              descending: true) // 🔹 Firestore sorts within `logging`
          .get();

      // Fetch from `alerts` collection
      QuerySnapshot alertsSnapshot = await _firestore
          .collection('alerts')
          .where('patientId', isEqualTo: patientId)
          .orderBy('timestamp',
              descending: true) // 🔹 Firestore sorts within `alerts`
          .get();

      // Store `logging` logs with extracted timestamp
      for (var doc in loggingSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        rawLogs.add({
          ...data,
          'source': 'logging',
          'timestamp': (data['timestamp'] as Timestamp).toDate()
        });
      }

      // Store `alerts` logs with extracted timestamp
      for (var doc in alertsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        rawLogs.add({
          ...data,
          'source': 'alerts',
          'timestamp': (data['timestamp'] as Timestamp).toDate()
        });
      }

      // 🔹 Sort by `timestamp` before mapping to `DispensingLog`
      rawLogs.sort((a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      // Convert raw logs to `DispensingLog` instances (without timestamp field)
      List<DispensingLog> dispensingLogs = rawLogs
          .map((data) => DispensingLog(
                day: data['day'] ?? 'Unknown',
                time: data['time'] ?? 'Unknown',
                patientName: data['patientName'] ?? 'Unknown',
                medicineList: (data['medicines'] as List<dynamic>?)
                        ?.whereType<Map<String, dynamic>>()
                        .map((medicine) =>
                            medicine['medicineName']?.toString() ?? 'Unknown')
                        .toList() ??
                    [],
                source: data['source'],
              ))
          .toList();

      return dispensingLogs;
    } catch (e) {
      _logger.i("Error fetching logs: $e");
      return [];
    }
  }

  Stream<DispensingLog?> getMostRecentPatientAlert() {
    return _firestore
        .collection('alerts')
        .orderBy('timestamp', descending: true) // 🔹 Get the latest first
        .limit(1) // 🔹 Only get the most recent alert
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null; // 🔹 Handle empty case

      final data =
          snapshot.docs.first.data(); // 🔹 Get the first (most recent) doc

      return DispensingLog(
          day: data['day'] ?? 'Unknown',
          time: data['time'] ?? 'Unknown',
          patientName: data['patientName'] ?? 'Unknown',
          medicineList: (data['medicines'] as List<dynamic>)
              .map((m) =>
                  (m as Map<String, dynamic>)['medicineName']?.toString() ??
                  'Unknown')
              .toList(),
          source: 'alerts');
    });
  }
}
