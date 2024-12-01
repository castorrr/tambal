import 'package:flutter/material.dart';
import 'package:tambal/models/users.dart'; // Import your UserModel
import 'package:tambal/services/auth_service.dart'; // Your AuthService

class AuthProvider with ChangeNotifier {
  final AuthService _authService =
      AuthService(); // Instance of your AuthService
  UserModel? _user; // Private UserModel to hold the current user information
  String? _errorMessage; // Error message for handling authentication errors
  bool _isLoading = false; // Boolean to track the loading state

  // Getter to access user info
  UserModel? get user => _user;

  // Getter to access error message
  String? get errorMessage => _errorMessage;

  // Getter to check if authentication is in progress
  bool get isLoading => _isLoading;

  // Initialize the current user on app startup
  Future<void> initializeCurrentUser() async {
    try {
      _isLoading = true; // Start loading
      notifyListeners();

      // Fetch current user from AuthService
      _user = await _authService.getCurrentUser();

      if (_user == null) {
        _errorMessage = 'No user is logged in.';
      }
    } catch (e) {
      _errorMessage = 'Error initializing user: ${e.toString()}';
    } finally {
      _isLoading = false; // Stop loading
      notifyListeners();
    }
  }

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true; // Start loading
      _errorMessage = null; // Clear any previous error messages
      notifyListeners();

      // Fetch user data from AuthService
      _user = await _authService.signInWithEmailAndPassword(email, password);

      if (_user == null) {
        _errorMessage = 'Login failed. Please check your credentials.';
      }
    } catch (e) {
      _errorMessage =
          'Error: ${e.toString()}'; // Capture and set the error message
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

      if (_user == null) {
        _errorMessage = 'Google sign-in failed. Please try again.';
      }
    } catch (e) {
      _errorMessage =
          'Error: ${e.toString()}'; // Capture and set the error message
    } finally {
      _isLoading = false; // Stop loading
      notifyListeners(); // Notify UI to reflect changes
    }
  }

  // Sign up a new user
  Future<void> signUp(
      String name, String username, String email, String password) async {
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

      if (_user == null) {
        _errorMessage = 'Sign up failed. Please try again.';
      }
    } catch (e) {
      _errorMessage =
          'Error: ${e.toString()}'; // Capture and set the error message
    } finally {
      _isLoading = false; // Stop loading
      notifyListeners(); // Notify UI to reflect changes
    }
  }

  // Sign out the current user
  Future<void> signOut() async {
    try {
      await _authService.signOut(); // Sign out from both Firebase and Google
      _user = null; // Clear user information in the provider
      notifyListeners(); // Notify UI of changes
    } catch (e) {
      _errorMessage = 'Error signing out: ${e.toString()}';
      notifyListeners();
    }
  }

  // Check if the user is authenticated
  bool isAuthenticated() {
    return _user != null;
  }
}
