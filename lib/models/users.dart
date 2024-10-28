// File: users.dart

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? profilePicture;
  final String username; // Add username here
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profilePicture,
    required this.username, // Include username in constructor
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
      'username': username, // Map username
      'createdAt': createdAt.toIso8601String(),
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
    );
  }
}
