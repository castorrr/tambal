// File: services/dispense_service.dart
import 'dart:async';
import 'package:logger/logger.dart';
import 'package:tambal/services/realtime_database_service.dart';

class DispenseService {
  final RealtimeDatabaseService realtimeDatabaseService;
  final Logger logger = Logger();

  // Constructor to initialize the RealtimeDatabaseService
  DispenseService(this.realtimeDatabaseService);

  Future<bool> dispenseMedicine(int slot) async {
    try {
      // Set the dispense slot in the database
      await realtimeDatabaseService.setDispenseSlot(slot);
      logger.i('Slot $slot set for dispensing');

      // Wait for 5 seconds
      await Future.delayed(const Duration(seconds: 5));

      // Check if the dispense slot is still set
      int? currentSlot = await realtimeDatabaseService.getDispenseSlot();

      if (currentSlot == slot) {
        // If still set, reset to 0 and indicate unsuccessful dispensing
        await realtimeDatabaseService.setDispenseSlot(0);
        logger.e('Unsuccessful dispensing. Slot $slot reset to 0.');
        return false; // Indicate failure
      } else {
        // If slot was reset, dispensing was successful
        logger.i('Medicine dispensed successfully from slot $slot.');
        return true; // Indicate success
      }
    } catch (error) {
      logger.e('Failed to set dispense: $error');
      return false; // Indicate failure
    }
  }
}
