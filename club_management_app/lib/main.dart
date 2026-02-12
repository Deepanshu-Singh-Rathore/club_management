import 'package:flutter/material.dart';

void main() {
  runApp(const ClubApp());
}

class ClubApp extends StatelessWidget {
  const ClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Club Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Club Management"),
      ),
      body: const Center(
        child: Text(
          "Project Setup Successful 🚀",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
