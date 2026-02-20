import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'features/auth/presentation/pages/auth_gate.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'firebase_options.dart';

// App entry point
void main() async {

  // Required before using async code in main()
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Connects app to Firebase project
  await Firebase.initializeApp(
  // 2. Initialize Firebase using the generated firebase_options.dart
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Starts the main app widget
  runApp(const SmartExpenseApp());
}


class SmartExpenseApp extends StatelessWidget {
  const SmartExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Expense Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      // Point to AuthGate instead of LoginPage
      home: const AuthGate(),
    );
  }
}
