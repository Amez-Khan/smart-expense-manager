import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For formatting the date beautifully

import '../../../dashboard/models/expense_model.dart';
import '../../../dashboard/services/expense_service.dart';
import '../widget/add_expense_bottom_sheet.dart'; // Your exact path


// Changed from StatelessWidget to StatefulWidget to handle dynamic data
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Instantiate our Cloud Service
  final ExpenseService _expenseService = ExpenseService();

  // Helper method to pick a specific icon based on the user's selected category
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food': return Icons.restaurant;
      case 'Transport': return Icons.directions_car;
      case 'Entertainment': return Icons.movie;
      case 'Bills': return Icons.receipt;
      default: return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Smart Expense',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
            ),
            // Kept your exact Welcome User formatting
            Text(
              "Welcome ${user?.displayName ?? "User"}",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),

      // Floating Action Button to add expenses
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Opens our beautiful sliding bottom sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
            ),
            builder: (context) => const AddExpenseBottomSheet(),
          );
        },
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Expense", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      // The main list area
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ARCHITECT FIX: Replaced simple text with a Row that includes a swipe hint!
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  "Recent Expenses",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                // The sleek visual affordance hint
                Row(
                  children: [
                    Icon(Icons.swipe_left, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      "Swipe to delete",
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ARCHITECT FIX: The StreamBuilder listens to Firestore in real-time
            Expanded(
              child: StreamBuilder<List<ExpenseModel>>(
                stream: _expenseService.getUserExpenses(),
                builder: (context, snapshot) {
                  // State 1: Waiting for Firestore to respond
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // State 2: An error occurred (e.g., security rules blocked it)
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }

                  // State 3: Successfully loaded, but the list is completely empty
                  final expenses = snapshot.data ?? [];
                  if (expenses.isEmpty) {
                    // This is your exact empty state UI that you already built!
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            "No expenses yet.",
                            style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Click the + button below to get started.",
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    );
                  }

                  // State 4: We have expenses! Display them in a beautiful list.
                  return ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];

                      // ARCHITECT FIX: We return the Dismissible HERE,
                      // which wraps around your beautiful Card!
                      return Dismissible(
                        key: Key(expense.id),
                        direction: DismissDirection.endToStart,

                        // The red background that shows when swiping
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
                        ),

                        // Pause the swipe and ask for confirmation
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Delete Expense"),
                                content: Text("Are you sure you want to delete '${expense.title}'? This cannot be undone."),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              );
                            },
                          );
                        },

                        // If they clicked "Delete", actually remove it from Firestore
                        onDismissed: (direction) async {
                          await _expenseService.deleteExpense(expense.id);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${expense.title} deleted'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },

                        // This is your original Card UI
                        child: Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              child: Icon(_getCategoryIcon(expense.category), color: const Color(0xFF2563EB)),
                            ),
                            title: Text(
                              expense.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text(
                              DateFormat('MMM dd, yyyy').format(expense.date),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                            trailing: Text(
                              '\$${expense.amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A)),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}