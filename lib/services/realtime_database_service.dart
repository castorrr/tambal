import 'package:firebase_database/firebase_database.dart';
import 'package:logger/logger.dart';

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
        return null; // Return null if the slot does not exist
      }
    } catch (error) {
      _logger.e('Failed to get dispense slot: $error');
      return null; // Return null in case of an error
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

            // Reset the database fields to default values
            resetFingerprintCommand();
          }
        });
      }
    });
  }

  // Method to reset the fingerprint command fields
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
}
