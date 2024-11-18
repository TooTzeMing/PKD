import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screen/loginscreen.dart';
import 'screen/signupscreen.dart';
import 'screen/homescreen.dart';
import 'screen/generateCode.dart';

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
      routes: {
        "/generate": (context) => const Generatecode(),
      },
      home: HomeScreen(),
      debugShowCheckedModeBanner: false, // Hide the debug banner (optional)
    );
  }
}

