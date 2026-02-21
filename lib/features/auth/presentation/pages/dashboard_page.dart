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

  // --- NEW: Month Filter State ---
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _changeMonth(int monthsToAdd) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + monthsToAdd,
      );
    });
  }

  // Helper method to pick a specific icon based on the user's selected category
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Entertainment':
        return Icons.movie;
      case 'Bills':
        return Icons.receipt;
      default:
        return Icons.category;
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
              ),
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
        label: const Text(
          "Add Expense",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      // The main list area
      // ARCHITECT FIX: Moved the StreamBuilder to the very top of the body
      body: StreamBuilder<List<ExpenseModel>>(
        stream: _expenseService.getUserExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // 1. Get ALL expenses from the database
          final allExpenses = snapshot.data ?? [];

          // --- NEW: Filter by selected month ---
          final expenses = allExpenses.where((expense) {
            return expense.date.month == _selectedMonth.month &&
                expense.date.year == _selectedMonth.year;
          }).toList();

          // 2. Calculate totals using ONLY the filtered expenses
          final double totalSpent = expenses.fold(
            0.0,
            (sum, item) => sum + item.amount,
          );

          final Map<String, double> categoryTotals = {};
          for (var expense in expenses) {
            categoryTotals[expense.category] =
                (categoryTotals[expense.category] ?? 0) + expense.amount;
          }

          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          // --------------------------------------------

          return SingleChildScrollView(
            // Reduced outer padding slightly from 16 to 12 to give more horizontal room
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- NEW: MONTH SELECTOR UI ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Color(0xFF1E3A8A),
                      ),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Text(
                      // Uses the intl package to format beautifully (e.g. "February 2026")
                      DateFormat('MMMM yyyy').format(_selectedMonth),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF1E3A8A),
                      ),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // --- SLIMMED DOWN TOTAL SPENT CARD ---
                Container(
                  width: double.infinity,
                  // Reduced padding from 24 to 16
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(
                      20,
                    ), // Slightly smaller radius
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Spent",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ), // Smaller font
                      ),
                      const SizedBox(height: 2), // Tighter gap
                      Text(
                        "\$${totalSpent.toStringAsFixed(2)}",
                        // Reduced font size from 36 to 28
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16), // Reduced gap from 24 to 16
                // --- TIGHTER CATEGORY BREAKDOWN ---
                if (expenses.isNotEmpty) ...[
                  const Text(
                    "Spending Breakdown",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8), // Reduced gap
                  // Wrap the breakdown in a limited-size box if there are too many categories
                  ...sortedCategories.map((entry) {
                    final categoryName = entry.key;
                    final categoryAmount = entry.value;
                    final percentage = totalSpent > 0
                        ? (categoryAmount / totalSpent)
                        : 0.0;

                    return Padding(
                      // Reduced bottom padding from 12 to 8
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(categoryName),
                            size: 18,
                            color: const Color(0xFF2563EB),
                          ), // Slightly smaller icon
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      categoryName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      "\$${categoryAmount.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: percentage,
                                  backgroundColor: Colors.grey[200],
                                  color: const Color(0xFF2563EB),
                                  minHeight: 4, // Thinner progress bar
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12), // Tighter gap
                ],

                // --- RECENT EXPENSES HEADER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Recent Expenses",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),

                    // ARCHITECT FIX: Both icons side-by-side with their respective text!
                    Row(
                      children: [
                        Icon(Icons.touch_app, size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 2),
                        Text("Tap to edit  •  ", style: TextStyle(fontSize: 11, color: Colors.grey[500])),

                        Icon(Icons.swipe_left, size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 2),
                        Text("Swipe to delete", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),

                  ],
                ),
                const SizedBox(height: 8), // Tighter gap
                // --- EXPENSE LIST ---
                // ARCHITECT FIX: Removed 'Expanded' and added shrinkWrap so it works inside SingleChildScrollView
                expenses.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32), // Extra padding since Expanded is gone
                      Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text("No expenses yet.", style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text("Click the + button below to get started.", style: TextStyle(color: Colors.grey[400])),
                    ],
                  ),
                )
                    :ListView.builder(
                  shrinkWrap: true, // MUST HAVE THIS inside SingleChildScrollView
                  physics: const NeverScrollableScrollPhysics(), // Disables inner scrolling so the whole page scrolls together
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return Dismissible(
                      key: Key(expense.id),
                      direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Delete Expense"),
                                    content: Text(
                                      "Are you sure you want to delete '${expense.title}'?",
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text(
                                          "Cancel",
                                          style: TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text(
                                          "Delete",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
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
                            child: Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(
                                bottom: 8,
                              ), // Reduced card margin from 12 to 8
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // Slightly smaller radius
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                // --- NEW: Tap to Edit ---
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
                                    ),
                                    // Pass the clicked expense into the sheet!
                                    builder: (context) => AddExpenseBottomSheet(existingExpense: expense),
                                  );
                                },
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ), // Tighter inner padding
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.withOpacity(
                                    0.1,
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(expense.category),
                                    size: 20,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                                title: Text(
                                  expense.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(expense.date),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                                trailing: Text(
                                  '\$${expense.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                              ),
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
