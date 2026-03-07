import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For formatting the date beautifully
import 'package:smart_expense_manager/features/auth/presentation/pages/profile_page.dart';

import '../../../../main.dart';
import '../../../dashboard/models/expense_model.dart';
import '../../../dashboard/services/expense_service.dart';
import '../../../dashboard/services/notification_service.dart';
import '../../../dashboard/services/user_service.dart';
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

  // --- NEW: Budget Dialog ---
  void _showEditBudgetDialog(BuildContext context) {
    // Pre-fill the text field with the current budget if it's greater than 0
    final currentBudget = budgetNotifier.value;
    final TextEditingController budgetController = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // [FIX] Let Flutter handle the default text color based on the theme!
        title: const Text(
          "Set Monthly Budget",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: budgetController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: "Budget Amount",
            // Dynamically show the correct currency symbol!
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                currencyNotifier.value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final newBudget = double.tryParse(budgetController.text) ?? 0.0;

              // 1. Instantly update UI
              budgetNotifier.value = newBudget;

              // 2. Save to Firebase in the background
              try {
                await UserService().updateBudget(newBudget);
              } catch (e) {
                print("Error saving budget: $e");
              }

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text(
              "Save Goal",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // [NEW] 1. Check if we are in Dark Mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      // [FIX] 2. Dynamic background color
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
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
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                final displayName = snapshot.data?.displayName ?? "User";
                return Text(
                  "Welcome $displayName",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Colors.white,
            ),
            tooltip: 'Profile',
            onPressed: () {
              // Navigate to our new Profile Page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
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
            // backgroundColor: Colors.white,
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

          // --- NEW: Calculate Today's Total ---
          final now = DateTime.now();
          final double todaysTotal = allExpenses
              .where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day)
              .fold(0.0, (sum, item) => sum + item.amount);
          // ---------------------------------------------------------

          // [NEW] 2. Trigger the Budget Warning logic (push notification local_notification)
          // We use a microtask to ensure the UI finishes rendering before the notification pops
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final budget = budgetNotifier.value;
            if (budget > 0) {
              double usagePercentage = totalSpent / budget;

              // Check if usage is 90% or more
              if (usagePercentage >= 0.9) {
                NotificationService().showBudgetWarning(
                  percentageUsed: usagePercentage,
                );
              }
            }
          });

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
                // --- UPGRADED: MONTH SELECTOR UI ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1E3A8A), // [FIX]
                      ),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedMonth),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1E3A8A), // [FIX]
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1E3A8A), // [FIX]
                      ),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // --- UPGRADED TOTAL SPENT CARD WITH BUDGET ---
                Container(
                  width: double.infinity,
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
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ValueListenableBuilder<double>(
                    valueListenable: budgetNotifier,
                    builder: (context, budget, child) {
                      // Calculate progress (cap at 1.0 or 100%)
                      double progress = budget > 0
                          ? (totalSpent / budget)
                          : 0.0;
                      if (progress > 1.0) progress = 1.0;

                      // Smart Colors: Green (<75%), Orange (75-90%), Red (>90%)
                      Color progressColor = Colors.greenAccent;
                      if (progress > 0.9)
                        progressColor = Colors.redAccent;
                      else if (progress > 0.75)
                        progressColor = Colors.orangeAccent;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Spent",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              // Small edit button to set the budget
                              InkWell(
                                onTap: () => _showEditBudgetDialog(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        budget > 0 ? Icons.edit : Icons.add,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        budget > 0 ? "Edit Goal" : "Set Budget",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),

                          // --- MAIN ROW: TOTAL SPENT (LEFT) & TODAY'S SPEND (RIGHT) ---
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left Side: Total Monthly Spent
                              Expanded(
                                child: ValueListenableBuilder<String>(
                                  valueListenable: currencyNotifier,
                                  builder: (context, symbol, child) {
                                    return Text(
                                      "$symbol${totalSpent.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis, // Prevents errors if the number gets huge!
                                    );
                                  },
                                ),
                              ),

                              // Right Side: Today's Spend Pill
                              if (_selectedMonth.month == now.month && _selectedMonth.year == now.year) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20), // Made it a perfectly rounded pill
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.today_rounded, color: Colors.white, size: 14),
                                      const SizedBox(width: 6),
                                      ValueListenableBuilder<String>(
                                        valueListenable: currencyNotifier,
                                        builder: (context, symbol, child) {
                                          return Text(
                                            "Today's: $symbol${todaysTotal.toStringAsFixed(2)}",
                                            style:  TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Only show the progress bar if a budget is actually set
                          if (budget > 0) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Budget: ${currencyNotifier.value}${budget.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "${(progress * 100).toStringAsFixed(0)}%",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                color: progressColor,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
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
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        // [FIX] This ensures text is black in light mode and white in dark mode
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),

                                    //ValueListenableBuilder change the moment the user picks a new symbol
                                    ValueListenableBuilder<String>(
                                      valueListenable: currencyNotifier,
                                      builder: (context, symbol, child) {
                                        return Text(
                                          "$symbol${categoryAmount.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: percentage,
                                  // [FIX] Darker track color for Dark Mode
                                  backgroundColor: isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
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

                // ARCHITECT FIX: Only show headers and hints if there is data to interact with
                if (expenses.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Recent Expenses",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E3A8A), // [FIX]
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 13,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            "Tap to edit  •  ",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          Icon(
                            Icons.swipe_left,
                            size: 13,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            "Swipe to delete",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ], // Tighter gap
                // --- EXPENSE LIST ---
                // ARCHITECT FIX: Removed 'Expanded' and added shrinkWrap so it works inside SingleChildScrollView
                expenses.isEmpty
                    ? SizedBox(
                        // ARCHITECT FIX: Dynamically fill the remaining vertical space
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No expenses yet.",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Click the + button below to get started.",
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap:
                            true, // MUST HAVE THIS inside SingleChildScrollView
                        physics:
                            const NeverScrollableScrollPhysics(), // Disables inner scrolling so the whole page scrolls together
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
                                          style: TextStyle(color: Colors.grey),
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
                              // [FIX] Explicitly set dark mode card color to stand out from background
                              color: isDark ? Colors.grey[900] : Colors.white,
                              margin: const EdgeInsets.only(
                                bottom: 8,
                              ), // Reduced card margin from 12 to 8
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // Slightly smaller radius
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: ListTile(
                                // --- NEW: Tap to Edit ---
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    // backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(25.0),
                                      ),
                                    ),
                                    // Pass the clicked expense into the sheet!
                                    builder: (context) => AddExpenseBottomSheet(
                                      existingExpense: expense,
                                    ),
                                  );
                                },
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ), // Tighter inner padding
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.withOpacity(0.1),
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
                                trailing: ValueListenableBuilder<String>(
                                  valueListenable: currencyNotifier,
                                  builder: (context, symbol, child) {
                                    return Text(
                                      '$symbol${expense.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        // [FIX] Lighter blue in Dark Mode so it is readable
                                        color: isDark
                                            ? Colors.blue[300]
                                            : const Color(0xFF1E3A8A),
                                      ),
                                    );
                                  },
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
