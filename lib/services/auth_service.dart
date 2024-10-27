// File: auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tambal/models/users.dart'; // Import the UserModel

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance for storing user data
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException {
      rethrow; // Throw exceptions for UI to handle
    }
  }

  // Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // Return null if sign-in was canceled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

        // If the user document doesn't exist, store the user's details in Firestore
        if (!userDoc.exists) {
          final UserModel newUser = UserModel(
            uid: user.uid,
            name: user.displayName ?? 'No Name',
            email: user.email!,
            profilePicture: user.photoURL,
            createdAt: DateTime.now(),
          );

          await _firestore.collection('users').doc(newUser.uid).set(newUser.toMap());
        }
      }

      return user;
    } on FirebaseAuthException {
      rethrow; // Pass exceptions to UI to handle
    }
  }

  // Sign up a user with email, password and store additional info in Firestore
  Future<User?> signUpUser({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Create user in Firebase Authentication
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = userCredential.user;

      // If the user is created successfully, store user data in Firestore
      if (user != null) {
        final UserModel newUser = UserModel(
          uid: user.uid,
          name: name,
          email: email,
          profilePicture: null, // No profile picture for email sign-up
          createdAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(newUser.uid).set(newUser.toMap());
      }

      return user;
    } on FirebaseAuthException {
      rethrow; // Throw exceptions for UI to handle
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
