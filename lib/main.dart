import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'features/auth/presentation/pages/login_page.dart';

// App entry point
void main() async {

  // Required before using async code in main()
  WidgetsFlutterBinding.ensureInitialized();

  // Connects app to Firebase project
  await Firebase.initializeApp();

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
      home: const LoginPage(),
    );
  }
}
