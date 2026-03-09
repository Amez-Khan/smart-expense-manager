import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../main.dart';
import '../../../../core/services/user_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Header Section with Avatar
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? "User",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  user?.email ?? "",
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Settings List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfileItem(
                  Icons.edit,
                  "Edit Display Name",
                  () => _showEditNameDialog(context),
                ),
                // ARCHITECT FIX: Added a Switch to toggle Dark Mode
                ListTile(
                  leading: const Icon(
                    Icons.dark_mode,
                    color: Color(0xFF1E3A8A), // Your preferred brand blue
                  ),
                  title: const Text(
                    "App Theme",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  // [NEW] Trailing text shows the current mode instead of a limited switch
                  trailing: ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (context, mode, _) {
                      String modeText = "System";
                      if (mode == ThemeMode.light) modeText = "Light";
                      if (mode == ThemeMode.dark) modeText = "Dark";

                      return Text(
                        modeText,
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  onTap: () => _showThemeDialog(context),
                ),
                _buildProfileItem(
                  Icons.help_outline,
                  "Help & Support",
                  () => _showHelpSupportBottomSheet(
                    context,
                  ), // [NEW] Calls your new function!
                ),
                // Wrap the item in a listener so it updates instantly!
                ValueListenableBuilder<String>(
                  valueListenable: currencyNotifier,
                  builder: (context, currency, child) {
                    return _buildProfileItem(
                      Icons.payments_outlined,
                      "Change Currency ($currency)",
                      () => _showCurrencyPicker(context),
                    );
                  },
                ),
                const Divider(),
                _buildProfileItem(
                  Icons.logout_rounded,
                  "Logout",
                  () => _showLogoutDialog(context),
                  textColor: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? const Color(0xFF1E3A8A)),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) Navigator.pop(context); // Go back to Auth screen
    }
  }

  void _showEditNameDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.displayName ?? "",
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Display Name"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: "Enter your name",
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                // Update Firebase User Profile
                await FirebaseAuth.instance.currentUser?.updateDisplayName(
                  newName,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  // Quick snackbar to confirm
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Name updated! Restart app to sync."),
                    ),
                  );
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    final List<String> currencies = ['\$', '₹', '€', '£', '¥', '₩'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 1. [FIX] Allows sheet to resize dynamically
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => SafeArea(
        // 2. [FIX] Prevents clipping into landscape screen notches
        child: SingleChildScrollView(
          // 3. [FIX] Makes the content scrollable if it overflows
          child: Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              // 4. [FIX] Adds padding at the bottom for navigation bars
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar for better UX
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Select Currency",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight
                        .bold, // 4. [FIX] White text in dark mode, blue in light mode
                    color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 24),

                // ARCHITECT FIX: Using a GridView instead of Wrap for perfect alignment
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 columns looks best on mobile
                    childAspectRatio: 2.0, // Makes the buttons slightly wide
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: currencies.length,
                  itemBuilder: (context, index) {
                    final symbol = currencies[index];
                    final isSelected = currencyNotifier.value == symbol;

                    return InkWell(
                      onTap: () async {
                        // 2. Update the UI symbol instantly (Optimistic UI)
                        currencyNotifier.value = symbol;

                        // 3. Save the symbol to phone memory (Local backup)
                        saveCurrencyToDisk(symbol);

                        // 4. [NEW] Save to Firestore silently in the background!
                        try {
                          await UserService().updateCurrency(symbol);
                        } catch (e) {
                          print("Failed to sync currency to cloud: $e");
                        }

                        // 5. Close the bottom sheet safely
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          // 5. [FIX] Dynamic background colors for the grid buttons
                          color: isSelected
                              ? (isDark
                                    ? const Color(0xFF2563EB).withOpacity(0.2)
                                    : const Color(0xFF2563EB).withOpacity(0.1))
                              : (isDark ? Colors.grey[800] : Colors.grey[50]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            // 6. [FIX] Dynamic border colors
                            color: isSelected
                                ? (isDark
                                      ? Colors.blue[300]!
                                      : const Color(0xFF2563EB))
                                : (isDark
                                      ? Colors.grey[700]!
                                      : Colors.grey[200]!),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            symbol,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              // 7. [FIX] Dynamic text colors for the symbols
                              color: isSelected
                                  ? (isDark
                                        ? Colors.blue[300]
                                        : const Color(0xFF2563EB))
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- NEW: Help & Support Bottom Sheet (Dark Mode Ready) ---
// --- UPDATED: Functional Help & Support ---
  void _showHelpSupportBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        // Use wrap to make it take only as much space as needed
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 24
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 🔥 CRITICAL: Wraps content tightly
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Help & Support",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 24),

            _buildSupportAction(
              context,
              icon: Icons.email_outlined,
              color: Colors.blue,
              title: "Email Support",
              subtitle: "amez8409khan@gmail.com",
              onTap: _launchEmail,
            ),
            const SizedBox(height: 8),
            _buildSupportAction(
              context,
              icon: Icons.privacy_tip_outlined,
              color: Colors.green,
              title: "Privacy Policy",
              subtitle: "How we protect your data",
              onTap: _launchPrivacyUrl,
            ),
            const SizedBox(height: 8),
            _buildSupportAction(
              context,
              icon: Icons.share_outlined,
              color: Colors.orange,
              title: "Share App",
              subtitle: "Invite your friends",
              onTap: _shareApp,
            ),

            const SizedBox(height: 24),
            const Divider(),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.code_rounded, color: Colors.grey),
              title: const Text('About the Developer', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Designed & built by Amez Khan', style: TextStyle(fontSize: 12)),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Smart Expense',
                  applicationVersion: '1.0.4',
                  applicationIcon: const Icon(Icons.account_balance_wallet, size: 40, color: Colors.blue),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widget for Actions ---
  Widget _buildSupportAction(BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Theme"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, currentMode, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThemeOption(
                  context,
                  "Light",
                  ThemeMode.light,
                  currentMode,
                ),
                _buildThemeOption(context, "Dark", ThemeMode.dark, currentMode),
                _buildThemeOption(
                  context,
                  "System Default",
                  ThemeMode.system,
                  currentMode,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    ThemeMode mode,
    ThemeMode currentMode,
  ) {
    return RadioListTile<ThemeMode>(
      title: Text(title),
      value: mode,
      groupValue: currentMode,
      activeColor: const Color(0xFF2563EB), // Matches your switch's activeColor
      onChanged: (newMode) {
        if (newMode != null) {
          themeNotifier.value = newMode;
          // Save to disk: true for dark, false for light, null for system
          if (newMode == ThemeMode.system) {
            SharedPreferences.getInstance().then((p) => p.remove('isDarkMode'));
          } else {
            saveThemeToDisk(newMode == ThemeMode.dark);
          }
        }
        Navigator.pop(context);
      },
    );
  }

  // Helper to open your actual email app
  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'amez.developer@gmail.com', // Your contact from the profile
      query: 'subject=Smart Expense Support Request',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

// Helper to open your future Privacy Policy website
  Future<void> _launchPrivacyUrl() async {
    final Uri url = Uri.parse('https://www.termsfeed.com/live/8f3e0738-d012-4d85-abf3-481f78e0ff31');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  void _shareApp() {
    // Use the dynamic URL from main.dart, fallback to GitHub only if Remote Config fails
    final String liveUrl = appStoreUrlNotifier.value.isNotEmpty
        ? appStoreUrlNotifier.value
        : "https://github.com/Amez-Khan/smart-expense-manager/releases";

    Share.share(
      "Check out Smart Expense Manager! Download it here: $liveUrl",
      subject: "Manage your expenses easily!",
    );
  }
}
