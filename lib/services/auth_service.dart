// File: auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tambal/models/users.dart'; // Import the UserModel

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserModel?> getCurrentUser() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // If the user is anonymous, skip Firestore fetch
        if (user.isAnonymous) {
          return null;
        }

        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        } else {
          throw Exception('Firestore document not found for user ${user.uid}');
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get current user: ${e.toString()}');
    }
  }

  Stream<UserModel?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((User? user) async {
      if (user != null) {
        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        }
      }
      return null;
    });
  }

  String getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already in use. Please use a different email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      default:
        return 'An unexpected error occurred. Please try again later.';
    }
  }

  // Sign in with email and password, return UserModel
  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      // Attempt to sign in with email and password
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      // Fetch user data from Firestore if user exists
      if (user != null) {
        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        } else {
          throw Exception('User data not found in Firestore');
        }
      }

      throw Exception('User authentication failed');
    } on FirebaseAuthException catch (e) {
      // Map FirebaseAuth errors to user-friendly messages
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found for that email');
        case 'wrong-password':
          throw Exception('Incorrect password');
        case 'invalid-email':
          throw Exception('The email address is not valid');
        default:
          throw Exception('An unexpected error occurred: ${e.message}');
      }
    } catch (e) {
      // Catch any other exceptions
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Google Sign-In, return UserModel
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          final UserModel newUser = UserModel(
            uid: user.uid,
            name: user.displayName ?? 'No Name',
            email: user.email!,
            profilePicture: user.photoURL,
            username: user.displayName ?? 'No Username',
            createdAt: DateTime.now(),
          );

          await _firestore
              .collection('users')
              .doc(newUser.uid)
              .set(newUser.toMap());
          return newUser;
        } else {
          return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        }
      }

      return null;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Sign up a user and return UserModel
  Future<UserModel?> signUpUser({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = userCredential.user;

      if (user != null) {
        final UserModel newUser = UserModel(
          uid: user.uid,
          name: name,
          email: email,
          profilePicture: null,
          username: username,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(newUser.uid)
            .set(newUser.toMap());
        return newUser;
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Firebase Authentication
      await _auth.signOut();

      // Sign out from Google Sign-In
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }
}
