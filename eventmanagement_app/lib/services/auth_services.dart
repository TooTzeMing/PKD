import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up
Future<void> signUp({required String email, required String password}) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("User signed up: ${userCredential.user?.uid}");
    } on FirebaseAuthException catch (e) {
      print("Error: $e");
    }
  }


  // Sign In
  Future<void> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("User signed in: ${userCredential.user?.uid}");
    } on FirebaseAuthException catch (e) {
      print("Error: $e");
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print("User signed out");
    } catch (e) {
      print("Error: $e");
    }
  }

  // Listen to Authentication State
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
