// File: services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:tambal/models/medicine.dart';
import 'package:tambal/models/patient.dart';
import 'package:tambal/models/schedule.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // ----------------- Medicine Methods -----------------

  // Method to add a new medicine to Firestore
  Future<void> addMedicine({
    required String name,
    required String purpose,
    required String description,
    required int stock,
    required int slot,
    required String userId,
  }) async {
    try {
      await _firestore.collection('medicine').add({
        'name': name,
        'purpose': purpose,
        'description': description,
        'stock': stock,
        'slot': slot,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _logger.i('Medicine added successfully to Firestore.');
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
    required String description,
    required int stock,
    required int slot,
    required String userId,
  }) async {
    try {
      await _firestore.collection('medicine').doc(id).update({
        'name': name,
        'purpose': purpose,
        'description': description,
        'stock': stock,
        'slot': slot,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _logger.i('Medicine with ID $id updated successfully in Firestore.');
    } catch (e) {
      _logger.e('Failed to update medicine with ID $id: $e');
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
            description: doc['description'] ?? 'No description available',
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

  Future<void> updateStocksByName(List<Map<String, dynamic>> medicines) async {
    final batch = _firestore.batch();

    for (final medicine in medicines) {
      final medicineName = medicine['name'];
      final requiredQuantity = medicine['quantity'];

      final querySnapshot = await _firestore
          .collection('medicine')
          .where('name', isEqualTo: medicineName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final currentStock = doc.get('stock') ?? 0;
        final newStock = currentStock - requiredQuantity;

        batch.update(doc.reference, {'stock': newStock});
      }
    }

    await batch.commit(); // Commit all updates as a single batch
  }
}
