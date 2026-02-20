import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widget/auth_button.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  // This variable controls what the button says (e.g., "Checking Status..." vs "I've Verified My Email")
  bool _isChecking = false;

  // This function runs when the user clicks the verification button
  Future<void> _checkEmailVerified() async {
    // 1. Show the loading state on the button
    setState(() => _isChecking = true);

    // 2. Force Firebase to fetch the absolute latest user data from the server.
    // Without this, the app won't know the user clicked the link in their email!
    await FirebaseAuth.instance.currentUser?.reload();

    // 3. Stop the loading state
    setState(() => _isChecking = false);

    // 4. Check if the email is STILL not verified after reloading.
    // If it's true, the AuthGate will automatically take them to the Dashboard.
    // If it's false, we stay on this screen and show them a helpful warning.
    if (FirebaseAuth.instance.currentUser?.emailVerified == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet. Please check your inbox.'),
            backgroundColor: Colors.orange, // Orange stands out as a warning
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        // Match the background gradient from the Login and Register screens
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
            // The white floating card that holds our content
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A nice big email icon at the top
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_rounded,
                      size: 64,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Verify Your Email",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "We've sent a secure link to your inbox. Please click it to activate your account.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  // Our custom button. It changes text based on the _isChecking variable.
                  AuthButton(
                    text: _isChecking ? "Checking Status..." : "I've Verified My Email",
                    onPressed: _isChecking ? () {} : _checkEmailVerified,
                  ),
                  const SizedBox(height: 16),

                  // Bottom row for extra options (Logout or Resend Email)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // If they want to log in with a different account instead
                      TextButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        child: const Text("Back to Login", style: TextStyle(color: Colors.grey)),
                      ),
                      // If they didn't get the email, let them request a new one
                      TextButton(
                        onPressed: () async {
                          try {
                            // 1. Ask Firebase to send the email
                            await FirebaseAuth.instance.currentUser?.sendEmailVerification();

                            // 2. If it works, show a success message
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Verification email resent!')),
                              );
                            }
                          } catch (e) {
                            // 3. If Firebase blocks it (spam protection), catch the error
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please wait a moment before resending.')),
                              );
                            }
                          }
                        },
                        child: const Text('Resend Link'),
                      ),
                    ],
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