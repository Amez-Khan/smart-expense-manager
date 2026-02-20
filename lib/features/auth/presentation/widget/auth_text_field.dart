import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextEditingController controller;
  // NEW: Added validator and keyboardType for production readiness
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const AuthTextField({
    super.key,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscure = false,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    // CHANGED: TextField to TextFormField
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator, // Hooking up the validator
      autovalidateMode: AutovalidateMode.onUserInteraction, // Shows errors as they type
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        // Changed to a very light grey so it stands out against the white card
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}