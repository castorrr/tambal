// File: helpers/medicine_helper.dart
import 'package:tambal/services/firestore_service.dart';

class MedicineHelper {
  final FirestoreService _firestoreService = FirestoreService();

  Future<Map<String, dynamic>?> fetchMedicineDetails(
      int slot, String name) async {
    return await _firestoreService.getMedicineDetails(slot, name);
  }
}
