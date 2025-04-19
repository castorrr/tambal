// File: users.dart

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? profilePicture;
  final String username; // Add username here
  final DateTime createdAt;
  final List<String>? patients;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profilePicture,
    required this.username, // Include username in constructor
    required this.createdAt,
    this.patients,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
      'username': username, // Map username
      'createdAt': createdAt.toIso8601String(),
      'patients': patients,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      profilePicture: map['profilePicture'],
      username: map['username'], // Map username
      createdAt: DateTime.parse(map['createdAt']),
      patients: map['patients'] != null
          ? List<String>.from(map['patients'])
          : null, // ✅ convert to List<String>
    );
  }
}
