import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../main.dart';
import '../../../dashboard/services/user_service.dart';

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
                    color: Color(0xFF1E3A8A),
                  ),
                  title: const Text(
                    "Dark Mode",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (context, mode, child) {
                      return Switch(
                        value: mode == ThemeMode.dark,
                        onChanged: (bool value) {
                          // Update the UI immediately
                          themeNotifier.value = value
                              ? ThemeMode.dark
                              : ThemeMode.light;

                          // [NEW] Save the choice to phone memory
                          saveThemeToDisk(value);
                        },
                        activeColor: const Color(0xFF2563EB),
                      );
                    },
                  ),
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
    // 1. [NEW] Check the current theme brightness
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      // 2. [FIX] Swap background color based on theme
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar for better UX
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                // 3. [FIX] Darker handle bar in dark mode
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
                            : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
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
    );
  }

  // --- NEW: Help & Support Bottom Sheet (Dark Mode Ready) ---
  void _showHelpSupportBottomSheet(BuildContext context) {
    // 1. Check the current theme brightness
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // 2. Swap background color based on theme
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView(
              controller: scrollController,
              children: [
                // Handle bar
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
                    // Swap the dark blue for pure white in Dark Mode
                    color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "How can we help you manage your expenses today?",
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  "Frequently Asked Questions",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // FAQ 1
                ExpansionTile(
                  iconColor: isDark
                      ? Colors.blue[300]
                      : const Color(0xFF2563EB),
                  textColor: isDark
                      ? Colors.blue[300]
                      : const Color(0xFF2563EB),
                  collapsedIconColor: isDark ? Colors.white70 : Colors.black54,
                  collapsedTextColor: isDark ? Colors.white : Colors.black87,
                  title: const Text(
                    "How do I edit or delete an expense?",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "On the Dashboard, tap any expense to edit it. To delete an expense, simply swipe the expense card to the left.",
                        style: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),

                // FAQ 2
                ExpansionTile(
                  iconColor: isDark
                      ? Colors.blue[300]
                      : const Color(0xFF2563EB),
                  textColor: isDark
                      ? Colors.blue[300]
                      : const Color(0xFF2563EB),
                  collapsedIconColor: isDark ? Colors.white70 : Colors.black54,
                  collapsedTextColor: isDark ? Colors.white : Colors.black87,
                  title: const Text(
                    "Will my data sync if I get a new phone?",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Yes! All your expenses, your monthly budget, and your currency preferences are securely backed up to your account. Just log in with your email on any device.",
                        style: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Divider(color: isDark ? Colors.grey[800] : Colors.grey[300]),
                const SizedBox(height: 16),

                // Contact Section
                Text(
                  "Still need help?",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isDark
                        ? const Color(0xFF2563EB).withOpacity(0.2)
                        : Colors.blue.withOpacity(0.1),
                    child: Icon(
                      Icons.email_outlined,
                      color: isDark
                          ? Colors.blue[300]
                          : const Color(0xFF2563EB),
                    ),
                  ),
                  title: Text(
                    "Email Support",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    "support@smartexpense.com",
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Email client integration coming soon!"),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
