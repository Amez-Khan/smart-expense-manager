import 'package:flutter/material.dart';
import 'package:smart_expense_manager/features/auth/presentation/pages/register_page.dart';
import '../../services/auth_service.dart';
import '../widget/auth_button.dart';
import '../widget/auth_text_field.dart';
import 'forgot_password_page.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // 1. Add the service and a simple loading state
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
  // 2. Add the login logic
  void _handleLogin() async {
    // Basic validation to ensure fields aren't empty
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailPassword(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      // Notice we don't need Navigator.push here!
      // The AuthGate will automatically detect the login and send us to the Dashboard.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Detect if the system is currently in Dark Mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration:  BoxDecoration(
          gradient: LinearGradient(
            // 2. Swap the gradient based on the theme
            colors: isDarkMode
                ? [const Color(0xFF020617), const Color(0xFF0F172A)]
                : [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
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
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Login to continue managing expenses",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  AuthTextField(
                    hint: "Email",
                    icon: Icons.email_outlined,
                    controller: emailController,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    hint: "Password",
                    icon: Icons.lock_outline,
                    controller: passwordController,
                    obscure: true,
                  ),
                  // ADD THIS BLOCK RIGHT HERE
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AuthButton(
                    text: _isLoading ? "Logging in..." : "Login",
                    onPressed: _isLoading ? () {} : _handleLogin,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // ARCHITECT FIX: Clear text fields before leaving the screen
                      emailController.clear();
                      passwordController.clear();

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterPage()),
                      );
                    },
                    child: const Text("Create an account"),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
