import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/expense_model.dart';
import '../../../../core/services/expense_service.dart';
import '../../../../main.dart';

class AnalyticsPage extends StatefulWidget {
  final DateTime? selectedMonth;
  const AnalyticsPage({super.key, this.selectedMonth});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final ExpenseService _expenseService = ExpenseService();
  late Stream<List<ExpenseModel>> _expensesStream;

  @override
  void initState() {
    super.initState();
    _expensesStream = _expenseService.getUserExpenses();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food': return const Color(0xFFE63946);
      case 'Transport': return const Color(0xFFF4A261);
      case 'Entertainment': return const Color(0xFF2A9D8F);
      case 'Bills': return const Color(0xFF264653);
      case 'Other': return const Color(0xFF8D99AE);
      default: return const Color(0xFF2563EB);
    }
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final referenceDate = widget.selectedMonth ?? DateTime.now();
    final monthName = DateFormat('MMMM yyyy').format(referenceDate);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: Text('$monthName Insights', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: _expensesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading insights', style: TextStyle(color: Colors.red)));
          }

          final allExpenses = snapshot.data ?? [];

          final currentMonthExpenses = allExpenses.where((expense) {
            return expense.date.year == referenceDate.year && expense.date.month == referenceDate.month;
          }).toList();

          if (currentMonthExpenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("No expenses logged for $monthName.", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            );
          }

          double totalSpent = 0;
          Map<String, double> categoryTotals = {};

          for (var expense in currentMonthExpenses) {
            totalSpent += expense.amount;
            categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
          }

          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          List<PieChartSectionData> pieSections = sortedCategories.map((entry) {
            final percentage = (entry.value / totalSpent) * 100;
            return PieChartSectionData(
              color: _getCategoryColor(entry.key),
              value: entry.value,
              title: '${percentage.toStringAsFixed(0)}%',
              radius: 50,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PREMIUM CHART CARD (Kept from the new design) ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                      ],
                      border: isDark ? Border.all(color: Colors.grey[800]!) : null,
                    ),
                    child: SizedBox(
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 75,
                              sections: pieSections,
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Total Spent",
                                style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              ValueListenableBuilder<String>(
                                valueListenable: currencyNotifier,
                                builder: (context, symbol, child) {
                                  return Text(
                                    '$symbol${totalSpent.toStringAsFixed(0)}',
                                    style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF1E3A8A)
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- SPENDING BREAKDOWN LIST (Reverted to your established Card pattern) ---
                  Text(
                    'Spending Breakdown',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedCategories.length,
                    itemBuilder: (context, index) {
                      final category = sortedCategories[index].key;
                      final amount = sortedCategories[index].value;
                      final percentage = (amount / totalSpent) * 100;

                      return Card(
                        elevation: 0,
                        color: isDark ? Colors.grey[900] : Colors.white,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: _getCategoryColor(category).withOpacity(0.15),
                            child: Icon(_getCategoryIcon(category), color: _getCategoryColor(category), size: 22),
                          ),
                          title: Text(
                              category,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                          ),
                          subtitle: Text(
                              '${percentage.toStringAsFixed(1)}% of total',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500])
                          ),
                          trailing: ValueListenableBuilder<String>(
                            valueListenable: currencyNotifier,
                            builder: (context, symbol, child) {
                              return Text(
                                '$symbol${amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? Colors.blue[300] : const Color(0xFF1E3A8A)
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}