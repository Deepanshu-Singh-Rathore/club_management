import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String role;
  const RegistrationScreen({super.key, this.role = 'student'});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  String selectedClub = 'Coding Club';
  bool _isLoading = false;

  final _nameCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // Maps club display name â†’ backend club id (populated from API)
  final List<String> _clubNames = [
    'Coding Club',
    'Dance Club',
    'Music Club',
    'Sports Club'
  ];
  final Map<String, String> _clubIds = {};

  @override
  void initState() {
    super.initState();
    _fetchClubs();
  }

  Future<void> _fetchClubs() async {
    try {
      final clubs = await ApiService.getClubs();
      if (clubs.isNotEmpty) {
        setState(() {
          _clubNames.clear();
          _clubIds.clear();
          for (final c in clubs) {
            _clubNames.add(c['name'] as String);
            _clubIds[c['name'] as String] = c['id'] as String;
          }
          if (_clubNames.isNotEmpty) selectedClub = _clubNames.first;
        });
      }
    } catch (_) {
      // keep static fallback list
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rollCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final roll = _rollCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = await ApiService.register(
        fullName: name,
        email: email,
        password: pass,
        rollNumber: roll,
      );

      if (data.containsKey('access')) {
        await ApiService.saveTokens(data['access'] as String, data['refresh'] as String);

        // Auto-join the selected club if we have its id
        final clubId = _clubIds[selectedClub];
        if (clubId != null) {
          await ApiService.joinClub(clubId);
        }

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      } else {
        final errors =
            data.entries.map((e) => '${e.key}: ${e.value}').join('\n');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errors)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF1FE),
      appBar: AppBar(
        title: const Text(
          "Club Registration",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Join Your Favorite Club âœ¨",
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
            CustomTextField(
              hintText: "Full Name",
              icon: Icons.person_outline,
              controller: _nameCtrl,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              hintText: "Roll Number",
              icon: Icons.numbers_outlined,
              controller: _rollCtrl,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              hintText: "Email",
              icon: Icons.email_outlined,
              controller: _emailCtrl,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              hintText: "Password",
              icon: Icons.lock_outline,
              isPassword: true,
              controller: _passCtrl,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFCF6),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.black12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedClub,
                  isExpanded: true,
                  items: _clubNames.map((name) {
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => selectedClub = v!),
                ),
              ),
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4A6CF7)))
                : CustomButton(text: "Register Now", onPressed: _register),
          ],
        ),
      ),
    );
  }
}
