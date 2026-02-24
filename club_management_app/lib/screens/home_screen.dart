import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String role;

  HomeScreen({required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: Center(
        child: Text("Welcome $role", style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
