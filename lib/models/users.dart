// File: users.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid; // User ID
  final String name;
  final String email;
  final String? profilePicture; // Optional field for profile picture URL
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profilePicture,
    required this.createdAt,
  });

  // Factory constructor to create a UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      name: data['name'] as String,
      email: data['email'] as String,
      profilePicture: data['profilePicture'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Method to convert UserModel to a map for saving in Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
      'createdAt': createdAt,
    };
  }
}
