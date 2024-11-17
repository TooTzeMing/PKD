import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screen/loginscreen.dart';
import 'screen/signupscreen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(), // Set LoginScreen as the home screen
      routes: {
        '/signup': (context) => const SignupScreen(),
      },
      debugShowCheckedModeBanner: false, // Hide the debug banner (optional)
    );
  }
}

