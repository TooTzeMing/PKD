import 'package:eventmanagement_app/screen/additionaldata.dart';

import 'screen/homescreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screen/loginscreen.dart';
import 'screen/signupscreen.dart';
import 'screen/generateCode.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PKD Smart',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(), // Set LoginScreen as the home screen
      routes: {
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/generate': (context) => const Generatecode(),
        '/home': (context) => HomeScreen(),
      },
      debugShowCheckedModeBanner: false, // Hide the debug banner (optional)
    );
  }
}
