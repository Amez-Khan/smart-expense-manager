import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Create a private instance of FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Future function to handle registration
  Future<User?> signUpWithEmailPassword(String email, String password) async {
    try {
      // This is the actual call to Firebase
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ARCHITECT FIX: Send verification email immediately after creation
      await credential.user?.sendEmailVerification();

      return credential.user;

      // Catch specific Firebase exceptions to give the user helpful feedback
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('This email is already registered. Please login.');
      } else if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else {
        throw Exception(e.message ?? 'An unknown error occurred.');
      }
    } catch (e) {
      // Catch any other general app errors
      throw Exception(e.toString());
    }
  }

  // Future function to handle login
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      // Keep error handling simple and direct
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Invalid email or password.');
      }
      throw Exception(e.message ?? 'Login failed.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}