import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../main.dart';

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
                  leading: const Icon(Icons.dark_mode, color: Color(0xFF1E3A8A)),
                  title: const Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (context, mode, child) {
                      return Switch(
                        value: mode == ThemeMode.dark,
                        onChanged: (bool value) {
                          // Update the UI immediately
                          themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;

                          // [NEW] Save the choice to phone memory
                          saveThemeToDisk(value);
                        },
                        activeColor: const Color(0xFF2563EB),
                      );
                    },
                  ),
                ),
                _buildProfileItem(Icons.help_outline, "Help & Support", () {}),
                _buildProfileItem(
                    Icons.payments_outlined,
                    "Change Currency (${currencyNotifier.value})",
                        () => _showCurrencyPicker(context)
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
                "Select Currency",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))
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
                  onTap: () {
                    // 1. Update the UI symbol
                    currencyNotifier.value = symbol;

                    // 2. [NEW] Save the symbol to phone memory
                    saveCurrencyToDisk(symbol);

                    // 3. Close the bottom sheet
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2563EB).withOpacity(0.1) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2563EB) : Colors.grey[200]!,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        symbol,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF2563EB) : Colors.black87,
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
}
