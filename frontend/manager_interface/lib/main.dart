import 'package:flutter/material.dart';
import 'package:manager_interface/SCREENS/login_screen.dart';


void main() {
  runApp(ManagerApp());
}

class ManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manager Interface',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
    );
  }
}
