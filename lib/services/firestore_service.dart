// File: services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:tambal/models/patient.dart';
import 'package:tambal/models/schedule.dart';
import 'package:tambal/models/dispensing_log.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // ----------------- Patient Methods -----------------

  // Method to generate a unique ID for a given collection
  String generateUniqueId(String collection) {
    return _firestore.collection(collection).doc().id;
  }

  // Method to add a new patient to Firestore
  Future<void> addPatient(Patient patient) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      await _firestore
          .collection('patients')
          .doc(patient.id)
          .set(patient.toMap());

      await _firestore.collection('users').doc(uid).update({
        'patients': FieldValue.arrayUnion([patient.id]),
      });
      _logger.i('Patient ${patient.name} added successfully to Firestore.');
    } catch (e) {
      _logger.e('Failed to add patient: $e');
      rethrow;
    }
  }

  // Method to get a stream of patients from Firestore
  Stream<List<Patient>> getPatientsStream() {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      // If no user is logged in, return an empty stream
      return Stream.value([]);
    }

    return _firestore
        .collection('patients')
        .where('userId', isEqualTo: userId) // ✅ Filter by userId
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add Firestore document ID manually
        return Patient.fromMap(data);
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
      await _firestore
          .collection('schedules')
          .doc(schedule.id)
          .set(schedule.toMap());
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

  Future<void> updateSchedule(String scheduleId, Schedule schedule) async {
    final docRef = _firestore.collection('schedules').doc(scheduleId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      _logger.e(
          '⛔ Schedule not found in Firestore: $scheduleId. Skipping update.');
      return;
    }

    _logger.i(
        '✅ Updating Firestore schedule: $scheduleId with ${schedule.toMap()}');
    await docRef.update(schedule.toMap());
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getScheduleById(
      String scheduleId) {
    return _firestore.collection('schedules').doc(scheduleId).get();
  }

  //Analytics
  Stream<int> getTotalPatients() {
    return Stream.fromFuture(_computeTotalPatients());
  }

  Future<int> _computeTotalPatients() async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return 0;

    // 🔹 Step 1: Get the user document
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userData = userDoc.data();

    if (userData == null || userData['patients'] == null) return 0;

    final List<String> userPatientIds = List<String>.from(userData['patients']);

    // 🔹 Step 2: Get all existing patient documents from the 'patients' collection
    final patientSnapshot =
        await FirebaseFirestore.instance.collection('patients').get();

    // 🔹 Step 3: Count only those that match the IDs in the user's patient list
    final total = patientSnapshot.docs
        .where((doc) => userPatientIds.contains(doc.id))
        .length;

    return total;
  }

  Stream<Map<String, String>?> getUpcomingSchedule() {
    return _firestore
        .collection('schedules')
        .orderBy('time') // Order schedules by time (ascending)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null; // No schedules available
      }

      DateTime now = DateTime.now();
      int currentTimeInt = _convertTimeToInt(DateFormat('h:mm a').format(now));

      Map<String, String>? upcomingSchedule;
      int? lastScheduleTime; // Track the last schedule time of the day

      for (var doc in snapshot.docs) {
        var data = doc.data();
        String scheduleTimeStr = data['time'] ?? "--";
        int scheduleTimeInt = _convertTimeToInt(scheduleTimeStr);

        // Track the last schedule time of the day
        if (lastScheduleTime == null || scheduleTimeInt > lastScheduleTime) {
          lastScheduleTime = scheduleTimeInt;
        }

        // If the schedule is upcoming (after the current time), set it as the upcoming schedule
        if (scheduleTimeInt > currentTimeInt) {
          upcomingSchedule = {
            'patientName': data['patientName'] ?? "Unknown",
            'time': scheduleTimeStr,
          };
          break; // Stop after finding the first upcoming schedule
        }
      }

      // If the current time is past the last schedule of the day, return null
      if (lastScheduleTime != null && currentTimeInt > lastScheduleTime) {
        return null;
      }

      return upcomingSchedule;
    });
  }

  /// Converts "7:30 PM" to an integer for easier comparison (e.g., 1930)
  int _convertTimeToInt(String timeStr) {
    try {
      DateTime dateTime = DateFormat('h:mm a').parse(timeStr);
      return dateTime.hour * 100 + dateTime.minute;
    } catch (e) {
      return -1; // Invalid time
    }
  }

  Stream<List<DispensingLog>> streamDispensingLogs(
      {required String collectionName}) async* {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      yield []; // No user logged in
      return;
    }

    // 🔹 Step 1: Get the list of patient IDs from the user document
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userData = userDoc.data();

    if (userData == null || userData['patients'] == null) {
      yield []; // No patients listed
      return;
    }

    final List<String> patientIds = List<String>.from(userData['patients']);

    // 🔹 Step 2: Listen to the log collection and filter only user's patients
    yield* FirebaseFirestore.instance
        .collection(collectionName)
        .snapshots()
        .map((snapshot) {
      List<DispensingLog> dispensingLogs = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final patientId = data['patientId'];

        // ✅ Only include if patientId is in current user's patients list
        if (patientIds.contains(patientId)) {
          final dateStr = data['date'] ?? '01/01/1970';
          final timeStr = data['time'] ?? '12:00 AM';
          final patientName = data['patientName'] ?? 'Unknown';
          final medicine = data['medicine'] ?? 'Unknown';

          dispensingLogs.add(
            DispensingLog(
              date: dateStr,
              time: timeStr,
              patientId: patientId,
              patientName: patientName,
              scheduleType: data['scheduleType'] ?? 'Unknown',
              medicine: medicine,
              source: '',
            ),
          );
        }
      }

      // 🔹 Sort logs by datetime (latest first)
      dispensingLogs.sort((a, b) {
        DateTime dateTimeA = _parseDateTime(a.date, a.time);
        DateTime dateTimeB = _parseDateTime(b.date, b.time);
        return dateTimeB.compareTo(dateTimeA);
      });

      return dispensingLogs;
    });
  }

  /// 🔹 Helper function to parse `MM/DD/YYYY` and `hh:mm AM/PM` into a DateTime object
  DateTime _parseDateTime(String dateStr, String timeStr) {
    try {
      // Combine date and time into a single DateTime object
      return DateTime.parse(
          "${_convertToISOFormat(dateStr)} ${_convertTo24HourFormat(timeStr)}");
    } catch (e) {
      _logger.e("⛔ Error parsing date/time: $dateStr $timeStr");
      return DateTime(1970, 1, 1, 0, 0); // Default fallback
    }
  }

  /// 🔹 Convert `MM/DD/YYYY` to `YYYY-MM-DD` for DateTime parsing
  String _convertToISOFormat(String dateStr) {
    try {
      List<String> parts = dateStr.split('/');
      if (parts.length == 3) {
        String month = parts[0].padLeft(2, '0');
        String day = parts[1].padLeft(2, '0');
        String year = parts[2];
        return "$year-$month-$day"; // Convert to `YYYY-MM-DD`
      }
    } catch (e) {
      _logger.e("⛔ Error converting date: $dateStr");
    }
    return "1970-01-01"; // Default fallback
  }

  /// 🔹 Convert `hh:mm AM/PM` to `HH:mm:ss` (24-hour format) for DateTime parsing
  String _convertTo24HourFormat(String timeStr) {
    try {
      DateTime time =
          DateTime.parse("1970-01-01 ${_convertToISOTime(timeStr)}");
      return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00";
    } catch (e) {
      _logger.e("⛔ Error converting time: $timeStr");
      return "00:00:00"; // Default fallback
    }
  }

  /// 🔹 Helper function to format `hh:mm AM/PM` into `hh:mm a` for DateTime parsing
  String _convertToISOTime(String timeStr) {
    try {
      DateFormat inputFormat = DateFormat("h:mm a"); // `hh:mm AM/PM` format
      DateFormat outputFormat = DateFormat("HH:mm"); // `HH:mm` 24-hour format
      return outputFormat.format(inputFormat.parse(timeStr));
    } catch (e) {
      _logger.e("⛔ Error parsing time: $timeStr");
      return "00:00"; // Default fallback
    }
  }

  Future<List<DispensingLog>> getDispensingLogsByPatient(
      String patientId) async {
    try {
      List<Map<String, dynamic>> rawLogs = [];

      // Fetch from `logging` collection
      QuerySnapshot loggingSnapshot = await _firestore
          .collection('logging')
          .where('patientId', isEqualTo: patientId)
          .get();

      // Fetch from `alerts` collection
      QuerySnapshot alertsSnapshot = await _firestore
          .collection('alerts')
          .where('patientId', isEqualTo: patientId)
          .get();

      // Store `logging` logs
      for (var doc in loggingSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        rawLogs.add({
          ...data,
          'source': 'logging',
        });
      }

      // Store `alerts` logs
      for (var doc in alertsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        rawLogs.add({
          ...data,
          'source': 'alerts',
        });
      }

      // 🔹 Sort logs by `date` first, then `time` (newest to oldest)
      rawLogs.sort((a, b) {
        DateTime dateTimeA =
            _parseDateTime(a['date'] ?? '01/01/1970', a['time'] ?? '12:00 AM');
        DateTime dateTimeB =
            _parseDateTime(b['date'] ?? '01/01/1970', b['time'] ?? '12:00 AM');
        return dateTimeB.compareTo(dateTimeA); // 🔹 Newest first
      });

      // Convert raw logs to `DispensingLog` instances
      List<DispensingLog> dispensingLogs = rawLogs
          .map((data) => DispensingLog(
                date: data['date'] ?? 'Unknown',
                time: data['time'] ?? 'Unknown',
                patientId: data['patientId'] ?? 'Unknown',
                patientName: data['patientName'] ?? 'Unknown',
                scheduleType: data['scheduleType'] ?? 'Unknown',
                medicine: data['medicine'] ?? 'Unknown',
                source: data['source'],
              ))
          .toList();

      return dispensingLogs;
    } catch (e) {
      _logger.e("Error fetching logs: $e");
      return [];
    }
  }

  Stream<DispensingLog?> getMostRecentPatientAlert() async* {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      yield null;
      return;
    }

    // Step 1: Get the patient's ID list from the user document
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userData = userDoc.data();

    if (userData == null || userData['patients'] == null) {
      yield null;
      return;
    }

    final List<String> patientIds = List<String>.from(userData['patients']);

    // Step 2: Listen to the alerts collection and filter matching patientId
    yield* FirebaseFirestore.instance
        .collection('alerts')
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.where((doc) {
        final patientId = doc.data()['patientId'];
        return patientIds.contains(patientId);
      }).toList();

      if (docs.isEmpty) return null;

      // Step 3: Sort and get most recent
      docs.sort((a, b) {
        final dateTimeA = _parseDateTime(
          a.data()['date'] ?? '01/01/1970',
          a.data()['time'] ?? '12:00 AM',
        );
        final dateTimeB = _parseDateTime(
          b.data()['date'] ?? '01/01/1970',
          b.data()['time'] ?? '12:00 AM',
        );
        return dateTimeB.compareTo(dateTimeA); // Newest first
      });

      final mostRecent = docs.first.data();

      return DispensingLog(
        date: mostRecent['date'] ?? 'Unknown',
        time: mostRecent['time'] ?? 'Unknown',
        patientName: mostRecent['patientName'] ?? 'Unknown',
        patientId: mostRecent['patientId'] ?? 'Unknown',
        scheduleType: mostRecent['scheduleType'] ?? 'Unknown',
        medicine: mostRecent['medicine'] ?? 'Unknown',
        source: 'alerts',
      );
    });
  }

  Future<List<Patient>> getAllPatients() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('patients').get();
      return snapshot.docs.map((doc) {
        return Patient.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      _logger.e("Error fetching patients: $e");
      return [];
    }
  }

  Future<String> getLatestDispense(String patientId) async {
    try {
      var snapshot = await _firestore
          .collection('logging')
          .where('patientId', isEqualTo: patientId)
          .get();

      if (snapshot.docs.isEmpty) {
        // 🔹 No logs found, fetch earliest schedule from `schedules`
        return await _getEarliestSchedule(patientId);
      }

      List<Map<String, dynamic>> logs = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "scheduleType": data['scheduleType'] ?? "Unknown",
          "date": data['date'] ?? "01/01/1970",
          "time": data['time'] ?? "12:00 AM",
        };
      }).toList();

      // 🔹 Sort logs by DateTime (newest first)
      logs.sort((a, b) {
        DateTime dateTimeA = _parseDateTime(a["date"], a["time"]);
        DateTime dateTimeB = _parseDateTime(b["date"], b["time"]);
        return dateTimeB.compareTo(dateTimeA);
      });

      // 🔹 Get latest dispensed schedule type
      String latestDispensed = logs.first["scheduleType"];

      // 🔹 Determine the next valid schedule type
      return await _getNextValidScheduleType(patientId, latestDispensed);
    } catch (e) {
      return "Error";
    }
  }

  /// 🔹 Fetch all available schedule types for the patient and find the next valid one
  Future<String> _getNextValidScheduleType(
      String patientId, String latest) async {
    const order = ["Breakfast", "Lunch", "Dinner"];

    try {
      var snapshot = await _firestore
          .collection('schedules')
          .where('patientId', isEqualTo: patientId)
          .get();

      if (snapshot.docs.isEmpty) {
        return "No Schedule"; // No schedules exist
      }

      // 🔹 Extract existing schedule types
      List<String> availableSchedules = snapshot.docs
          .map((doc) =>
              _mapScheduleType(doc.data()['scheduleType'] as int? ?? 999))
          .toList();

      if (availableSchedules.isEmpty) {
        return "No Schedule";
      }

      // 🔹 Ensure schedules are in the correct order
      availableSchedules
          .sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));

      // 🔹 Find the next available schedule type in order
      int index = order.indexOf(latest);

      if (index == -1 || availableSchedules.length == 1) {
        // 🔹 If the last dispensed type is not in order OR only one schedule exists
        return availableSchedules.first;
      }

      // 🔹 Loop through to find the next available schedule
      for (int i = 1; i < order.length; i++) {
        int nextIndex = (index + i) % order.length;
        if (availableSchedules.contains(order[nextIndex])) {
          return order[nextIndex];
        }
      }

      // 🔹 If no valid next schedule is found, default to the first available one
      return availableSchedules.first;
    } catch (e) {
      return "Error";
    }
  }

  /// 🔹 Fetch the earliest schedule type if no logs exist
  Future<String> _getEarliestSchedule(String patientId) async {
    try {
      var snapshot = await _firestore
          .collection('schedules')
          .where('patientId', isEqualTo: patientId)
          .get();

      if (snapshot.docs.isEmpty) {
        return "No Schedule"; // No schedules exist
      }

      // 🔹 Extract schedule types as integers and find the lowest one
      List<int> scheduleTypes = snapshot.docs
          .map((doc) =>
              doc.data()['scheduleType'] as int? ??
              999) // Default high value for sorting
          .toList();

      int earliestType = scheduleTypes.reduce((a, b) => a < b ? a : b);

      // 🔹 Map scheduleType to string
      return _mapScheduleType(earliestType);
    } catch (e) {
      return "Error";
    }
  }

  /// 🔹 Convert scheduleType (int) to its corresponding name
  String _mapScheduleType(int type) {
    const scheduleMap = {1: "Breakfast", 2: "Lunch", 3: "Dinner"};
    return scheduleMap[type] ?? "Unknown";
  }

  // Fetch the latest schedule for a given patient
  Future<Map<String, dynamic>?> getLatestDispenseWithMedicine(
      String patientId) async {
    try {
      // Step 1: Get the latest schedule type using getLatestDispense
      String latestScheduleType = await getLatestDispense(patientId);
      _logger.i(latestScheduleType);
      _logger.i(patientId);

      if (latestScheduleType == "Error") {
        return null; // Return null if no valid schedule is found
      }

      int scheduleTypeNumber;
      switch (latestScheduleType) {
        case "Breakfast":
          scheduleTypeNumber = 1;
        case "Lunch":
          scheduleTypeNumber = 2;
        case "Dinner":
          scheduleTypeNumber = 3;
        default:
          return null; // Return 0 if it's an unknown type
      }

      // Step 2: Query the schedules collection using the retrieved schedule type
      var snapshot = await _firestore
          .collection('schedules')
          .where('patientId', isEqualTo: patientId)
          .where('scheduleType',
              isEqualTo: scheduleTypeNumber) // ✅ Use the exact value returned
          .get();

      if (snapshot.docs.isEmpty) {
        return null; // No matching schedule found
      }

      // Step 3: Extract medicine data from the first matching document
      var scheduleData = snapshot.docs.first.data();
      return {
        "scheduleType":
            latestScheduleType, // ✅ Ensure conversion using your mapping method
        "medicine": scheduleData['medicine'] ?? [],
      };
    } catch (e) {
      return null;
    }
  }

// Add a dispensing log to Firestore
  Future<void> addDispensingLog(DispensingLog log) async {
    await FirebaseFirestore.instance.collection('logging').add({
      'date': log.date,
      'time': log.time,
      'patientId': log.patientId,
      'patientName': log.patientName,
      'scheduleType': log.scheduleType, // ✅ Convert here
      'medicine': log.medicine,
    });
  }

  /// Deletes all documents inside the specified Firestore collections
  Future<void> resetFirestoreCollections() async {
    try {
      // List of collections to delete
      List<String> collections = ['alerts', 'logging', 'patients', 'schedules'];

      for (String collection in collections) {
        QuerySnapshot snapshot = await _firestore.collection(collection).get();
        for (DocumentSnapshot doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }

      _logger.i("Firestore collections cleared.");
    } catch (e) {
      _logger.e("Error resetting Firestore collections: $e");
    }
  }
}
