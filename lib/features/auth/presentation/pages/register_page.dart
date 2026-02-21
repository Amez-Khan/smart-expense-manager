import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../widget/auth_button.dart';
import '../widget/auth_text_field.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // GlobalKey is required to trigger the validators inside the Form
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 1. Instantiate the service and add a loading boolean
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    // Architect Rule: ALWAYS dispose controllers to prevent memory leaks
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 2. Make the handler asynchronous
  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      // Start the loading spinner
      setState(() => _isLoading = true);

      try {
        // Call the service with the text from the controllers
        final user = await _authService.signUpWithEmailPassword(
          _nameController.text.trim(), // Pass the name here!
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (user != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully!')),
          );
          // Go back to the Login screen upon success
          Navigator.pop(context);
        }
      } catch (e) {
        // If the service throws an exception (like email already in use), show it here
        if (mounted) {
          // Remove the "Exception: " prefix from the error message
          final errorMessage = e.toString().replaceAll('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        // Stop the loading spinner whether it succeeded or failed
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity, // Ensures gradient fills the whole screen
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Form( // Wrapping the column in a Form
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Start tracking your expenses today",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 30),

                    AuthTextField(
                      hint: "Full Name",
                      icon: Icons.person_outline,
                      controller: _nameController,
                      validator: (value) =>
                      value!.isEmpty ? "Please enter your name" : null,
                    ),
                    const SizedBox(height: 16),

                    AuthTextField(
                      hint: "Email",
                      icon: Icons.email_outlined,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Please enter an email";
                        if (!value.contains('@')) return "Please enter a valid email";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    AuthTextField(
                      hint: "Password",
                      icon: Icons.lock_outline,
                      controller: _passwordController,
                      obscure: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Please enter a password";
                        if (value.length < 8) return "Must be at least 8 characters";
                        if (!RegExp(r'(?=.*?[A-Z])').hasMatch(value)) return "Need at least one uppercase letter";
                        if (!RegExp(r'(?=.*?[0-9])').hasMatch(value)) return "Need at least one number";
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    AuthButton(
                      text: _isLoading ? "Loading..." : "Sign Up",
                      onPressed: _isLoading ? () {} : _handleRegister,
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () => Navigator.pop(context), // Goes back to Login
                      child: const Text("Already have an account? Login"),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}