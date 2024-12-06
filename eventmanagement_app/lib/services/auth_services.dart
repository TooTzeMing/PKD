import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:eventmanagement_app/main.dart';
import 'package:eventmanagement_app/services/global.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("User signed up: ${userCredential.user?.uid}");
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred. Please try again.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists with that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      }

      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );

      return null;
    } catch (e) {
      print("Unexpected error: $e");
      Fluttertoast.showToast(
        msg: 'An unexpected error occurred. Please try again later.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );

      return null;
    }
  }

  // Sign In
  Future<void> signin(
      {required String email,
      required String password,
      required BuildContext context}) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await _getUserRole(user); // Store the user role globally
      }

      await Future.delayed(const Duration(seconds: 1));
      Navigator.popAndPushNamed(context, "/home");
    } on FirebaseAuthException catch (e) {
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


  Future<void> _getUserRole(User user) async {
    try {
      // Fetch the role from the Firestore database
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final int? numericRole = doc.data()?['role'];

      // Store the role globally
      if (numericRole == 1) {
        userRole = 'admin'; // Set role to admin
      } else if (numericRole == 2) {
        userRole = 'user'; // Set role to user
      } else {
        userRole = null; // If no valid role is found
      }
    } catch (e) {
      print("Error fetching user role: $e");
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
