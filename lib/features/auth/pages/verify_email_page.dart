import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/auth_button.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isChecking = false;

  Future<void> _checkEmailVerified() async {
    setState(() => _isChecking = true);

    await FirebaseAuth.instance.currentUser?.reload();

    setState(() => _isChecking = false);

    if (FirebaseAuth.instance.currentUser?.emailVerified == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet. Please check your inbox.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.4)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Clean, simplified icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_unread_outlined,
                      size: 48,
                      color: isDarkMode
                          ? Colors.blueAccent
                          : const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Professional typography
                  const Text(
                    "Check your inbox",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "We sent a verification link to your email.\nTap the link to activate your account.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Subtle, integrated spam hint
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment
                        .center, // Keeps icon aligned if text wraps
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 24,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Tip: Check your spam folder if it doesn't arrive.",
                          style: TextStyle(
                            color: Colors.red.shade300,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Primary Action
                  AuthButton(
                    text: _isChecking
                        ? "Checking Status..."
                        : "I've clicked the link",
                    onPressed: _isChecking ? () {} : _checkEmailVerified,
                  ),
                  const SizedBox(height: 24),

                  // Stacked Secondary Actions for cleaner UX
                  Column(
                    children: [
                      TextButton(
                        onPressed: () async {
                          try {
                            await FirebaseAuth.instance.currentUser
                                ?.sendEmailVerification();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Verification email resent!'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please wait a moment before resending.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        style: TextButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text(
                          'Resend Email',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text(
                          "← Back to Login",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
