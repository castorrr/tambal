class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final int slot; // Patient slot number (1-5)

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.slot,
  });

  /// Convert Firestore data into a Patient object
  factory Patient.fromMap(Map<String, dynamic> data) {
    return Patient(
      id: data['id'] ?? '', // If Firestore doc ID is stored in 'id' field
      name: data['name'] ?? '',
      age: (data['age'] ?? 0).toInt(),
      gender: data['gender'] ?? '',
      slot: (data['slot'] ?? 0).toInt(), // Ensure slot is an integer
    );
  }

  /// Convert Patient object to a Firestore-friendly Map
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Ensure Firestore stores the patient ID
      'name': name,
      'age': age,
      'gender': gender,
      'slot': slot,
    };
  }
}
