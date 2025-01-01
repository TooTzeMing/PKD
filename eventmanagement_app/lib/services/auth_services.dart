import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:eventmanagement_app/services/global.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up
Future<UserCredential?> signUp({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    if (!isValidPassword(password)) {
      Fluttertoast.showToast(
        msg:
            'Password must be 8-12 characters long and include an uppercase letter, a number, and a special character.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
      return null;
    }

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

  bool isValidPassword(String password) {
    // Password must be at least 8 characters, max 12 characters,
    // contain at least one uppercase letter, one lowercase letter,
    // one digit, and one special character.
    final passwordRegex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,12}$');
    return passwordRegex.hasMatch(password);
  }


Future<Map<String, String?>> signin({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await _getUserRole(user); // Store the user role globally
      }

      return {"emailError": null, "passwordError": null};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return {
          "emailError": "No user found for this email",
          "passwordError": null
        };
      } else if (e.code == 'wrong-password') {
        return {"emailError": null, "passwordError": "Incorrect password"};
      } else {
        return {
          "emailError": null,
          "passwordError": "Something went wrong. Please try again."
        };
      }
    }
  }

Future<Map<String, String>?> googleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user != null) {
        // Check if user data is complete
        final bool isDataComplete = await _isUserDataComplete(user.uid);

        if (!isDataComplete) {
          // If data is not complete, return userId and username
          return {
            'userId': user.uid,
            'username': user.displayName ?? 'Anonymous',
          };
        }

        // If data is complete, return null
        return null;
      }
    } catch (e) {
      throw Exception('Error during Google Sign-In: ${e.toString()}');
    }

    throw Exception('Something went wrong.');
  }

  Future<bool> _isUserDataComplete(String uid) async {
      final userData =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userData.exists) {
        final data = userData.data();
        return data != null ; // Add other required fields here
      }
      return false;
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
  Future<void> signout({required BuildContext context}) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(
          context, '/login'); // Ensure '/login' is defined in routes
    } catch (e) {
      // Show an error message if signout fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during signout: ${e.toString()}')),
      );
    }
  }

Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      print("Password reset email sent");
    } catch (e) {
      print("Error: $e");
    }
  }


  // Reset Password
// Future<void> resetPassword(String password, BuildContext context) async {
//     try {
//       // Validate the password
//       if (!isValidPassword(password)) {
//         Fluttertoast.showToast(
//           msg:
//               "Password must be 8-12 characters, include uppercase, lowercase, a number, and a special character.",
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.SNACKBAR,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//           fontSize: 14.0,
//         );
//         return;
//       }

//       User? user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         await user.updatePassword(password);
//         Fluttertoast.showToast(
//           msg: "Password successfully reset.",
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.SNACKBAR,
//           backgroundColor: Colors.green,
//           textColor: Colors.white,
//           fontSize: 14.0,
//         );
//         Navigator.pop(context); // Navigate back on success
//       } else {
//         Fluttertoast.showToast(
//           msg: "No user is currently signed in.",
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.SNACKBAR,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//           fontSize: 14.0,
//         );
//       }
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: "Failed to reset password. Please try again.",
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.SNACKBAR,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//         fontSize: 14.0,
//       );
//     }
//   }

  // Listen to Authentication State
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
