import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart'; // [NEW] Added for memory storage

import 'features/auth/presentation/pages/auth_gate.dart';
import 'features/dashboard/services/user_service.dart';
import 'firebase_options.dart';

// Global state variables - these "broadcast" changes to the whole app
final ValueNotifier<String> currencyNotifier = ValueNotifier<String>('\$');
// [NEW] for the budget!
final ValueNotifier<double> budgetNotifier = ValueNotifier<double>(0.0);
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(
  ThemeMode.light,
);

// 1. App entry point
void main() async {
  // Required for Firebase and SharedPreferences to work properly
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Connect to Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. [NEW] Load saved settings from phone memory before the app starts
  await _loadSavedSettings();

  // 4. Start the app
  runApp(const SmartExpenseApp());

  //Update & Fetch selected currency on firestore.
  _listenToAuthChanges();
}

// Simple logic to read from storage
Future<void> _loadSavedSettings() async {
  final prefs = await SharedPreferences.getInstance();

  // Get saved theme: if nothing is saved, default to false (Light Mode)
  final bool isDark = prefs.getBool('isDarkMode') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  // Get saved currency: if nothing is saved, default to '$'
  currencyNotifier.value = prefs.getString('currencySymbol') ?? '\$';
}

// Simple logic to save Theme
Future<void> saveThemeToDisk(bool isDark) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isDarkMode', isDark);
}

// Simple logic to save Currency
Future<void> saveCurrencyToDisk(String symbol) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('currencySymbol', symbol);
}

//Update & Fetch selected Currency,Budget on firestore.
void _listenToAuthChanges() {
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user != null) {
      // Fetch both currency AND budget from the cloud
      final cloudCurrency = await UserService().getUserCurrency();
      final cloudBudget = await UserService().getUserBudget();

      if (cloudCurrency != null) {
        currencyNotifier.value = cloudCurrency;
      }
      // [NEW] Safely update the budget (default to 0.0 if they haven't set one yet)
      budgetNotifier.value = cloudBudget ?? 0.0;

    } else {
      // User logged out! Reset to safe defaults.
      currencyNotifier.value = '\$';
      budgetNotifier.value = 0.0;
    }
  });
}

class SmartExpenseApp extends StatelessWidget {
  const SmartExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder "listens" for theme changes and rebuilds the app UI
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Smart Expense',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E3A8A),
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData.dark(useMaterial3: true),
          home: const AuthGate(),
        );
      },
    );
  }
}
