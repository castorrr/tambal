// File: auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tambal/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Login with email and password
  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _authService.signInWithEmailAndPassword(email, password);
      _errorMessage = null;  // Clear error message on success
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
    notifyListeners();  // Notify listeners to rebuild UI
  }

  // Signup
  Future<void> signUp(String name, String username, String email, String password) async {
    _setLoading(true);
    try {
      _user = await _authService.signUpUser(
        name: name,
        username: username,
        email: email,
        password: password,
      );
      _errorMessage = null;  // Clear error message on success
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  // Google Sign-In
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      _user = await _authService.signInWithGoogle();
      _errorMessage = null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();  // Notify listeners to update UI
  }
}
