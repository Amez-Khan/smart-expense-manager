import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/models/expense_model.dart';
import '../../../../core/services/expense_service.dart';
import '../../../../main.dart';
import '../../dashboard/widgets/add_expense_bottom_sheet.dart';

class AllExpensesPage extends StatefulWidget {
  final DateTime? selectedMonth; // <-- Add this
  const AllExpensesPage({super.key, this.selectedMonth}); // <-- Update constructor

  @override
  State<AllExpensesPage> createState() => _AllExpensesPageState();
}

class _AllExpensesPageState extends State<AllExpensesPage> {
  final ExpenseService _expenseService = ExpenseService();

  // --- STATE FOR SEARCH & FILTER ---
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // NEW: Simplified Time Filter instead of a complex calendar
  String _selectedTimeFilter = 'All Time';

  late Stream<List<ExpenseModel>> _expensesStream;

  @override
  void initState() {
    super.initState();
    // Start the stream once when the page loads!
    _expensesStream = _expenseService.getUserExpenses();
    // NEW: If they came from a specific month on the dashboard, auto-apply the filter!
    if (widget.selectedMonth != null) {
      _selectedTimeFilter = 'This Month';
    }
  }

  final List<String> _categories = [
    'All',
    'Food',
    'Transport',
    'Entertainment',
    'Bills',
    'Other',
  ];

// --- SMART FILTER MENU ---
  List<String> get _dynamicTimeFilters {
    final now = DateTime.now();
    final referenceDate = widget.selectedMonth ?? now;

    // Check if the user is looking at the actual, current calendar month
    final isCurrentRealMonth = referenceDate.year == now.year && referenceDate.month == now.month;

    if (isCurrentRealMonth) {
      // If they are in the present, show everything
      return ['All Time', 'Today', 'Last 7 Days', 'This Month', 'Last Month'];
    } else {
      // If they are in the past, hide the confusing relative dates!
      // (Note: I kept 'All Time' here just in case they want a quick way to
      // clear the month filter and see all history, but you can delete it from
      // this array if you want it strictly locked to the past months!)
      return ['All Time', 'This Month', 'Last Month'];
    }
  }

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

  // --- DYNAMIC APPBAR TITLE ---
  String _getAppBarTitle() {
    final referenceDate = widget.selectedMonth ?? DateTime.now();

    switch (_selectedTimeFilter) {
      case 'Today':
        return "Today's Expenses";
      case 'Last 7 Days':
        return "Last 7 Days";
      case 'This Month':
        return "${DateFormat('MMMM yyyy').format(referenceDate)} Expenses";
      case 'Last Month':
      // Safely calculate exactly one month ago from the reference date
        final lastMonthDate = DateTime(referenceDate.year, referenceDate.month - 1);
        return "${DateFormat('MMMM yyyy').format(lastMonthDate)} Expenses";
      case 'All Time':
      default:
        return "All Expenses";
    }
  }
  // Native Export Logic (PDF & CSV)
  Future<void> _exportData(
    List<ExpenseModel> expenses,
    double total,
    String format,
  )
  async {
    final output = await getTemporaryDirectory();
    final String timestamp = DateFormat(
      'yyyyMMdd_HHmmss',
    ).format(DateTime.now());

    if (format == 'CSV') {
      // Grab the current user's name from Firebase
      final userName = FirebaseAuth.instance.currentUser?.displayName;
      final displayName = (userName == null || userName.isEmpty)
          ? 'User'
          : userName;
      final currentDate = DateFormat('MMM dd, yyyy').format(DateTime.now());

      List<List<dynamic>> rows = [];

      // --- 1. METADATA HEADER (Structured for Excel) ---
      rows.add(["App:", "Smart Expense"]);
      rows.add(["Generated For:", displayName]);
      rows.add(["Date:", currentDate]);
      rows.add([]); // Blank row to separate header from data

      // --- 2. DATA TABLE ---
      rows.add(["Date", "Title", "Category", "Amount"]); // Column Headers

      for (var e in expenses) {
        rows.add([
          DateFormat('yyyy-MM-dd').format(e.date),
          e.title,
          e.category,
          e.amount,
        ]);
      }

      // --- 3. TOTAL ROW ---
      rows.add(["", "", "Total", total]);

      // Native CSV conversion to avoid package errors
      String csvData = rows
          .map((row) {
            return row
                .map((cell) {
                  String str = cell.toString();
                  if (str.contains(',') || str.contains('"')) {
                    return '"${str.replaceAll('"', '""')}"';
                  }
                  return str;
                })
                .join(',');
          })
          .join('\n');

      final file = File('${output.path}/Expenses_$timestamp.csv');
      await file.writeAsString(csvData);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'My Expense Report (CSV)');
    }
    else if (format == 'PDF') {
      final pdf = pw.Document();

      // Grab the current user's name from Firebase.
      // If they haven't set a display name, it safely defaults to 'User'
      final userName = FirebaseAuth.instance.currentUser?.displayName;
      final displayName = (userName == null || userName.isEmpty)
          ? 'User'
          : userName;

      pdf.addPage(
        pw.MultiPage(
          // Adds a clean, professional margin around the entire document
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // 1. Main Title
              pw.Text(
                'Expense Report',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),

              // 2. Branded Subtitle with dynamic name
              pw.Text(
                'Generated by Smart Expense for $displayName',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 12),

              // 3. Date
              pw.Text(
                'Date: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 24),

              // 4. Data Table (Auto-spans across multiple pages)
              pw.Table.fromTextArray(
                headers: ['Date', 'Title', 'Category', 'Amount'],
                data: expenses
                    .map(
                      (e) => [
                        DateFormat('yyyy-MM-dd').format(e.date),
                        e.title,
                        e.category,
                        e.amount.toStringAsFixed(2),
                      ],
                    )
                    .toList(),

                // Professional Table Styling
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue900,
                ),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  ),
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  3: pw
                      .Alignment
                      .centerRight, // Aligns the money column to the right perfectly
                },
              ),

              pw.SizedBox(height: 20),

              // 5. Total Calculator at the bottom
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Total: ${total.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ];
          },
        ),
      );

      // Save and share the file
      final file = File('${output.path}/Expenses_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'My Expense Report (PDF)');
    }
  }

  void _showExportOptions(List<ExpenseModel> currentList, double currentTotal) {
    if (currentList.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export!')));
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Export Data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Export as PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _exportData(currentList, currentTotal, 'PDF');
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text('Export as CSV'),
                onTap: () {
                  Navigator.pop(context);
                  _exportData(currentList, currentTotal, 'CSV');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        // NEW: Calls your dynamic title generator
        title: Text(
            _getAppBarTitle(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
        ),
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
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final allExpenses = snapshot.data ?? [];

          // --- THE SIMPLIFIED FILTERING ENGINE ---
          final filteredExpenses = allExpenses.where((expense) {
            final matchesCategory = _selectedCategory == 'All' || expense.category == _selectedCategory;
            final matchesSearch = expense.title.toLowerCase().contains(_searchQuery);

            // NEW: Smart Time Logic
            bool matchesTime = true;
            final realNow = DateTime.now(); // Always actual today for "Today" filters
            final referenceDate = widget.selectedMonth ?? realNow; // The dashboard month

            if (_selectedTimeFilter == 'Today') {
              matchesTime = expense.date.year == realNow.year && expense.date.month == realNow.month && expense.date.day == realNow.day;
            } else if (_selectedTimeFilter == 'Last 7 Days') {
              matchesTime = expense.date.isAfter(realNow.subtract(const Duration(days: 7)));
            } else if (_selectedTimeFilter == 'This Month') {
              // Uses the dashboard month!
              matchesTime = expense.date.year == referenceDate.year && expense.date.month == referenceDate.month;
            } else if (_selectedTimeFilter == 'Last Month') {
              final lastMonth = referenceDate.month == 1 ? 12 : referenceDate.month - 1;
              final lastMonthYear = referenceDate.month == 1 ? referenceDate.year - 1 : referenceDate.year;
              matchesTime = expense.date.year == lastMonthYear && expense.date.month == lastMonth;
            }

            return matchesCategory && matchesSearch && matchesTime;
          }).toList();

          final filteredTotal = filteredExpenses.fold(
            0.0,
            (sum, item) => sum + item.amount,
          );

          return Column(
            children: [
              // 1. SEARCH BAR & MENU BUTTONS
              Container(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) => setState(
                          () => _searchQuery = value.toLowerCase().trim(),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by title...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey[900]
                              : Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // NEW: Simple Dropdown Menu for Time
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.calendar_month,
                        color: _selectedTimeFilter != 'All Time'
                            ? primaryColor
                            : Colors.grey,
                      ),
                      tooltip: 'Filter by Time',
                      onSelected: (String result) {
                        setState(() {
                          _selectedTimeFilter = result;
                        });
                      },
                      itemBuilder: (BuildContext context) {
                        return _dynamicTimeFilters.map((String choice) {
                          return PopupMenuItem<String>(
                            value: choice,
                            child: Text(
                              choice,
                              style: TextStyle(
                                fontWeight: _selectedTimeFilter == choice
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _selectedTimeFilter == choice
                                    ? primaryColor
                                    : null,
                              ),
                            ),
                          );
                        }).toList();
                      },
                    ),

                    // Export Button
                    IconButton(
                      icon: const Icon(
                        Icons.import_export_rounded,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          _showExportOptions(filteredExpenses, filteredTotal),
                      tooltip: 'Export Data',
                    ),
                  ],
                ),
              ),

              // 2. CHIPS ROW
              Container(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      // Show Active Time Filter Chip
                      if (_selectedTimeFilter != 'All Time')
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InputChip(
                            label: Text(
                              _selectedTimeFilter,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onDeleted: () => setState(
                              () => _selectedTimeFilter = 'All Time',
                            ),
                            deleteIconColor: Colors.white,
                            backgroundColor: primaryColor,
                          ),
                        ),
                      // Standard Category Chips
                      ..._categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) =>
                                setState(() => _selectedCategory = category),
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
                      }),
                    ],
                  ),
                ),
              ),

              // 3. DYNAMIC TOTAL SUMMARY
              if (filteredExpenses.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: primaryColor.withOpacity(0.1),
                  child: ValueListenableBuilder<String>(
                    valueListenable: currencyNotifier,
                    builder: (context, symbol, child) {
                      return Text(
                        'Total for this view: $symbol${filteredTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isDark ? Colors.blue[300] : primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ),

              // 4. THE EXPENSE LIST
              Expanded(
                child: filteredExpenses.isEmpty
                    ? Center(
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
                              "No expenses match your filters.",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
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
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(25.0),
                                    ),
                                  ),
                                  builder: (context) => AddExpenseBottomSheet(
                                    existingExpense: expense,
                                  ),
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
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
