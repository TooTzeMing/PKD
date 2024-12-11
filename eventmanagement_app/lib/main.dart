import 'package:eventmanagement_app/screen/viewAccount.dart';
import 'screen/homescreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screen/loginscreen.dart';
import 'screen/signupscreen.dart';
import 'screen/generateCode.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PKD Smart',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(), // Set LoginScreen as the home screen
      routes: {
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/generate': (context) => const Generatecode(),
        '/home': (context) => HomeScreen(),
        '/viewAccount': (context) => const ViewAccount(),
      },
      debugShowCheckedModeBanner: false, // Hide the debug banner (optional)
    );
  }
}
