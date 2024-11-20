import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:eventmanagement_app/main.dart';


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
 Future<void> signin({
    required String email,
    required String password,
    required BuildContext context
  }) async {
    
    try {

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password
      );

      await Future.delayed(const Duration(seconds: 1));
      Navigator.popAndPushNamed(context, "/home");
      
    } on FirebaseAuthException catch(e) {
      String message = '';
      if (e.code == 'invalid-email') {
        message = 'No user found for that email.';
      } else if (e.code == 'invalid-credential') {
        message = 'Wrong password provided for that user.';
      }
       Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
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