import 'package:flutter/material.dart';
import 'package:tambal/models/users.dart'; // Import your UserModel
import 'package:tambal/services/auth_service.dart'; // Your AuthService

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService(); // Instance of your AuthService
  UserModel? _user; // Private UserModel to hold the current user information
  String? _errorMessage; // Error message for handling authentication errors
  bool _isLoading = false; // Boolean to track the loading state

  // Getter to access user info
  UserModel? get user => _user;

  // Getter to access error message
  String? get errorMessage => _errorMessage;

  // Getter to check if authentication is in progress
  bool get isLoading => _isLoading;

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true; // Start loading
      _errorMessage = null; // Clear any previous error messages
      notifyListeners();

      // Fetch user data from AuthService
      _user = await _authService.signInWithEmailAndPassword(email, password);

      // Handle case where sign-in fails
      if (_user == null) {
        _errorMessage = 'Login failed. Please check your credentials.';
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}'; // Capture and set the error message
    } finally {
      _isLoading = false; // Stop loading
      notifyListeners(); // Notify UI to reflect changes
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true; // Start loading
      _errorMessage = null; // Clear any previous error messages
      notifyListeners();

      // Fetch user data from AuthService
      _user = await _authService.signInWithGoogle();

      // Handle case where Google sign-in fails
      if (_user == null) {
        _errorMessage = 'Google sign-in failed. Please try again.';
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}'; // Capture and set the error message
    } finally {
      _isLoading = false; // Stop loading
      notifyListeners(); // Notify UI to reflect changes
    }
  }

  // Sign up a new user
  Future<void> signUp(String name, String username, String email, String password) async {
    try {
      _isLoading = true; // Start loading
      _errorMessage = null; // Clear any previous error messages
      notifyListeners();

      // Create a new user using the AuthService
      _user = await _authService.signUpUser(
        name: name,
        username: username,
        email: email,
        password: password,
      );

      // Handle case where sign-up fails
      if (_user == null) {
        _errorMessage = 'Sign up failed. Please try again.';
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}'; // Capture and set the error message
    } finally {
      _isLoading = false; // Stop loading
      notifyListeners(); // Notify UI to reflect changes
    }
  }

  // Sign out the current user
  Future<void> signOut() async {
    try {
      await _authService.signOut(); // Sign out via AuthService
      _user = null; // Clear user information
      notifyListeners(); // Notify UI to reflect changes
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}'; // Capture and set the error message
    }
  }
}
