// File: models/patient.dart

class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String? fingerprintData; // Base64-encoded or another format

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.fingerprintData,
  });

  // Method to convert a Patient object to a map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'fingerprintData': fingerprintData,
    };
  }

  // Method to create a Patient object from a map (from Firestore)
  factory Patient.fromMap(Map<String, dynamic> map, String documentId) {
    return Patient(
      id: documentId,
      name: map['name'],
      age: map['age'],
      gender: map['gender'],
      fingerprintData: map['fingerprintData'],
    );
  }
}
