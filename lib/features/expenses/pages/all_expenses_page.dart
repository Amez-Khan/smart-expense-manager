import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/expense_model.dart';
import '../../../../core/services/expense_service.dart';
import '../../../../main.dart';
import '../../dashboard/widgets/add_expense_bottom_sheet.dart';

class AllExpensesPage extends StatefulWidget {
  const AllExpensesPage({super.key});

  @override
  State<AllExpensesPage> createState() => _AllExpensesPageState();
}

class _AllExpensesPageState extends State<AllExpensesPage> {
  final ExpenseService _expenseService = ExpenseService();

  // --- STATE FOR SEARCH & FILTER ---
  String _searchQuery = '';
  String _selectedCategory = 'All'; // 'All' means no category filter is applied

  final List<String> _categories = [
    'All',
    'Food',
    'Transport',
    'Entertainment',
    'Bills',
    'Other',
  ];

  // Helper method for icons
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'All Expenses',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 1. THE SEARCH BAR
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value
                      .toLowerCase(); // Update state as user types
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by title...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. THE CATEGORY FILTER CHIPS
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            padding: const EdgeInsets.only(bottom: 12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      selectedColor: isDark
                          ? primaryColor
                          : primaryColor.withOpacity(0.15),
                      backgroundColor: isDark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      side: BorderSide.none,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? (isDark ? Colors.white : primaryColor)
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 3. THE EXPENSE LIST (STREAM BUILDER)
          Expanded(
            child: StreamBuilder<List<ExpenseModel>>(
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

                final allExpenses = snapshot.data ?? [];

                // --- THE FILTERING ENGINE ---
                final filteredExpenses = allExpenses.where((expense) {
                  // 1. Check Category
                  final matchesCategory =
                      _selectedCategory == 'All' ||
                      expense.category == _selectedCategory;

                  // 2. Check Search Query
                  final matchesSearch = expense.title.toLowerCase().contains(
                    _searchQuery,
                  );

                  return matchesCategory && matchesSearch;
                }).toList();

                if (filteredExpenses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No expenses found.",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = filteredExpenses[index];
                    return Card(
                      elevation: 0,
                      color: isDark ? Colors.grey[900] : Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark
                              ? Colors.grey[800]!
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          // Tap to edit, just like on the dashboard!
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(25.0),
                              ),
                            ),
                            builder: (context) =>
                                AddExpenseBottomSheet(existingExpense: expense),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: Icon(
                            _getCategoryIcon(expense.category),
                            size: 20,
                            color: primaryColor,
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
                          DateFormat('MMM dd, yyyy').format(expense.date),
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
                                color: isDark
                                    ? Colors.blue[300]
                                    : const Color(0xFF1E3A8A),
                              ),
                            );
                          },
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
    );
  }
}
