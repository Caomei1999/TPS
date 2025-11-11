import 'package:flutter/material.dart';
import 'package:officer_interface/SCREENS/login_screen.dart';


void main() {
  runApp(OfficerApp());
}

class OfficerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controller Interface',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
    );
  }
}
