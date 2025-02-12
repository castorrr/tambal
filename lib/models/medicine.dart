// File: models/medicine.dart

class Medicine {
  final String id; // Unique ID for the medicine
  final String name;
  final String purpose;
  final int stock;
  final int slot; // Quantity of the medicine

  Medicine({
    required this.id,
    required this.name,
    required this.purpose,
    required this.stock,
    required this.slot,
  });

  // Factory constructor to create a Medicine object from a map (for fetching from Firebase)
  factory Medicine.fromMap(Map<String, dynamic> data, String documentId) {
    return Medicine(
      id: documentId,
      name: data['name'] ?? '',
      purpose: data['purpose'] ?? '',
      stock: data['stock'] ?? 0,
      slot: data['slot'] ?? 0, // Default to 0 if stock is not provided
    );
  }

  // Method to convert a Medicine object to a map (for saving to Firebase)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'purpose': purpose,
      'stock': stock,
      'slot': slot,
    };
  }
}
