import 'package:flutter/material.dart';

// Sari screens ke liye ek common profile header + small logo
class BrandedHeader extends StatelessWidget {
  const BrandedHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Profile Icon (AM)
        const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.amber,
          child: Text(
            "AM",
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(height: 5), // Chhota space
        // Small ClubSphere Logo (Aapki requirement ke hisab se chhota)
        Container(
          width: 25,
          height: 25,
          padding: const EdgeInsets.all(4), // Logo ko thoda padding
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)
            ],
          ),
          child: Image.asset(
            "assets/images/logo.png", // Aapka logo file path
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
