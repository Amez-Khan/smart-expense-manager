import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'features/auth/presentation/pages/auth_gate.dart';
import 'features/dashboard/services/notification_service.dart';
import 'features/dashboard/services/user_service.dart';
import 'firebase_options.dart';

// Helper to compare version numbers (returns true if an update is needed)
bool _isVersionLower(String current, String required) {
  if (required.isEmpty) return false;
  try {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> requiredParts = required.split('.').map(int.parse).toList();
    for (int i = 0; i < requiredParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (currentParts[i] < requiredParts[i]) return true;
      if (currentParts[i] > requiredParts[i]) return false;
    }
  } catch (e) {
    debugPrint("Version parsing error: $e");
  }
  return false;
}

// Global state variables - these "broadcast" changes to the whole app
final ValueNotifier<String> currencyNotifier = ValueNotifier<String>('\$');
final ValueNotifier<double> budgetNotifier = ValueNotifier<double>(0.0);
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

// 1. App entry point
void main() async {
  // [CRITICAL FIX 1] This MUST be the very first line! It binds Flutter to the native engine.
  WidgetsFlutterBinding.ensureInitialized();

  // [CRITICAL FIX 2] Now Firebase can safely boot up (removed duplicate calls).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Load saved settings from phone memory before the app starts
  await _loadSavedSettings();

  // ==========================================
  // FIREBASE REMOTE CONFIG CHECK
  // ==========================================
  bool requiresUpdate = false;
  String storeUrl = '';

  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      // In production, set this to 1 hour (Duration(hours: 1)).
      // For testing, we use 0 so it fetches instantly!
      minimumFetchInterval: const Duration(seconds: 0),
    ));
    await remoteConfig.fetchAndActivate();

    final requiredVersion = remoteConfig.getString('minimum_required_version');
    storeUrl = remoteConfig.getString('update_store_url');

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    requiresUpdate = _isVersionLower(currentVersion, requiredVersion);
    debugPrint("Current Version: $currentVersion | Required: $requiredVersion | Needs Update: $requiresUpdate");
  } catch (e) {
    debugPrint("Failed to fetch remote config: $e");
  }
  // ==========================================

  // Initialize the notification service
  await NotificationService().init();
  await NotificationService().requestPermission();
  await NotificationService().scheduleDailyReminder();

  // [CRITICAL FIX 3] Start listening to auth/data changes BEFORE drawing the UI
  _listenToAuthChanges();

  // Start the app
  runApp(SmartExpenseApp(requiresUpdate: requiresUpdate, storeUrl: storeUrl));
}

// Simple logic to read from storage
Future<void> _loadSavedSettings() async {
  final prefs = await SharedPreferences.getInstance();

  // Get saved theme:
  // If null (first time), we now use ThemeMode.system!
  final bool? isDark = prefs.getBool('isDarkMode');

  if (isDark == null) {
    themeNotifier.value = ThemeMode.system; // [NEW] Follows device settings
  } else {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

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

// Update & Fetch selected Currency, Budget on firestore.
void _listenToAuthChanges() {
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user != null) {
      final cloudCurrency = await UserService().getUserCurrency();
      final cloudBudget = await UserService().getUserBudget();

      if (cloudCurrency != null) {
        currencyNotifier.value = cloudCurrency;
      }
      budgetNotifier.value = cloudBudget ?? 0.0;
    } else {
      // User logged out! Reset to safe defaults.
      currencyNotifier.value = '\$';
      budgetNotifier.value = 0.0;
    }
  });
}

class SmartExpenseApp extends StatelessWidget {
  final bool requiresUpdate;
  final String storeUrl;

  const SmartExpenseApp({
    super.key,
    required this.requiresUpdate,
    required this.storeUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Smart Expense',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
            useMaterial3: true,
          ),
          darkTheme: ThemeData.dark(useMaterial3: true),
          // [THE GATEKEEPER] If update is required, trap them on the update page.
          home: requiresUpdate
              ? UpdateRequiredPage(storeUrl: storeUrl)
              : const AuthGate(),
        );
      },
    );
  }
}

// The Branded, Un-dismissible Update Screen
class UpdateRequiredPage extends StatelessWidget {
  final String storeUrl;
  const UpdateRequiredPage({super.key, required this.storeUrl});

  Future<void> _launchStore() async {
    final Uri url = Uri.parse(storeUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF2563EB);

    return Scaffold(
      // 1. Softer background colors for a more polished feel
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // 2. The "Glowing" Premium Icon Wrapper
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? primaryColor.withOpacity(0.05) : primaryColor.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withOpacity(0.1),
                    width: 2,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.rocket_launch_rounded, // Feels more like an upgrade than a system alert
                    size: 64,
                    color: isDark ? Colors.blue[400] : primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 3. Refined Typography (Tighter letter spacing, bolder weights)
              Text(
                "Time to Upgrade",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "Your money management just got better. Update now to access improved performance and smarter tools.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6, // Taller line height for better readability
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),

              const Spacer(flex: 3),

              // 4. Elevated Action Button
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(isDark ? 0.15 : 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0, // We handle elevation with the custom BoxShadow above
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _launchStore,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Update Smart Expense",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}