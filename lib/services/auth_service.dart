import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
      return userCredential.user;
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
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'username': username,
          'email': email,
          'createdAt': Timestamp.now(),
        });
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
