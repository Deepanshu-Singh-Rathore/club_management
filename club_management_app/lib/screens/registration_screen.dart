import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  String selectedClub = 'Coding Club';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Deepanshu ka Brilliant White Background
      backgroundColor: const Color(0xFFEDF1FE),
      appBar: AppBar(
        title: const Text(
          "Club Registration",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Join Your Favorite Club ✨",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7B61FF),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Fill in your details to get started.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Form Fields using Custom Widgets
            const CustomTextField(
              hintText: "Full Name",
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 20),
            const CustomTextField(
              hintText: "Roll Number",
              icon: Icons.numbers_outlined,
            ),
            const SizedBox(height: 20),

            // Club Selection Dropdown (Deepanshu's Metallic White Style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFCF6), // Metallic White
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.black12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedClub,
                  isExpanded: true,
                  items:
                      <String>[
                        'Coding Club',
                        'Dance Club',
                        'Music Club',
                        'Sports Club',
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedClub = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Register Button
            CustomButton(
              text: "Register Now",
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Registration Successful!")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
