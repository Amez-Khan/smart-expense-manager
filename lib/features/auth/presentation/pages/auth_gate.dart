import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_page.dart';
import 'login_page.dart';
import 'verify_email_page.dart'; // Import the new page

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // ARCHITECT FIX: Changed from authStateChanges() to userChanges()
      // Now it will instantly rebuild the UI when reload() is called!
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // ARCHITECT FIX: Check if the email is actually verified
          final user = snapshot.data!;
          if (!user.emailVerified) {
            // Block them from the Dashboard and show the verification screen
            return const VerifyEmailPage();
          }

          return const DashboardPage();
        }

        return const LoginPage();
      },
    );
  }
}