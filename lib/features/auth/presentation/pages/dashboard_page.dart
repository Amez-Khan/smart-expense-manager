import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Grab the details of the user who is currently logged in
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      // A very light grey background so future white expense cards will pop out
      backgroundColor: Colors.grey[50],

      // The top navigation bar
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        // We use a flexibleSpace to give the AppBar our signature blue gradient
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Smart Expense',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          // The logout button
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              // This instantly signs the user out and the AuthGate takes them to the Login screen
              await FirebaseAuth.instance.signOut();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      // The main content of the dashboard
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // A simple wallet icon placeholder for now
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, size: 60, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 24),

            const Text(
              'Welcome Back!',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 8),

            // A small badge displaying the user's logged-in email address
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              // We use user?.email to show the email, or "Unknown User" if it's somehow missing
              child: Text(
                user?.email ?? "Unknown User",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}