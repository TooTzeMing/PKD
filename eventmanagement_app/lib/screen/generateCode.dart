import 'package:flutter/material.dart';

class Generatecode extends StatefulWidget {
  const Generatecode({super.key});

  @override
  State<Generatecode> createState() => _GeneratecodeState();
}

class _GeneratecodeState extends State<Generatecode> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: Text('Generate Code'),
      ),
    );
  }
}