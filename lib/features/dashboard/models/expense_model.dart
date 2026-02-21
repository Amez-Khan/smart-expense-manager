import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  // ARCHITECT NOTE: Firestore doesn't understand Dart objects.
  // We have to convert our Expense into a "Map" (a dictionary) before saving it.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      // Firestore uses a special 'Timestamp' format for dates
      'date': Timestamp.fromDate(date),
    };
  }

  // When we fetch data BACK from Firestore, we convert the Map back into a Dart object
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      // Ensure the amount is always a double, even if someone typed an integer
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
    );
  }
}