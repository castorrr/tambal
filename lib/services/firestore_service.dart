// File: services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:tambal/models/medicine.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // Method to add medicine to Firestore
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

  // Method to fetch medicines as a stream from Firestore
  Stream<List<Medicine>> getMedicines() {
    return _firestore.collection('medicine').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          // Fetch only the fields that are added in addMedicine
          return Medicine(
            id: doc.id,
            name: doc['name'] ?? 'Unknown',
            // Default to 'Unknown' if name is missing
            purpose: doc['purpose'] ?? 'Unknown',
            // Use 'purpose' as 'type' if 'type' is not a separate field
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
}
