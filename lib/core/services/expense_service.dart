import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a new expense to the cloud
  Future<void> addExpense(ExpenseModel expense) async {
    try {
      // 1. Double-check we have a logged-in user
      final user = _auth.currentUser;
      if (user == null) throw Exception('User is not logged in');

      // 2. Save it to a highly secure path: users -> [uid] -> expenses -> [expenseId]
      await _db
          .collection('users')
          .doc(user.uid) // The user's private folder
          .collection('expenses') // Their list of expenses
          .doc(expense.id) // The specific expense document
          .set(expense.toMap()); // Convert our model to a map and save!
    } catch (e) {
      throw Exception('Failed to save expense: ${e.toString()}');
    }
  }

  // NEW: Fetch a real-time stream of the user's expenses
  Stream<List<ExpenseModel>> getUserExpenses() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User is not logged in');

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .orderBy(
          'date',
          descending: true,
        ) // Sort so the newest expenses are at the top
        .snapshots() // This makes it a real-time stream!
        .map((snapshot) {
          // Convert the raw Firestore Maps back into our clean Dart Objects
          return snapshot.docs
              .map((doc) => ExpenseModel.fromMap(doc.data()))
              .toList();
        });
  }

  // NEW: Delete an expense from the cloud
  Future<void> deleteExpense(String expenseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User is not logged in');

      // Point directly to the specific expense ID and call delete()
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .doc(expenseId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete expense: ${e.toString()}');
    }
  }

  // NEW: Update an existing expense
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User is not logged in');

      // Point directly to the existing document ID and update it
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .doc(expense.id)
          .update(expense.toMap());
    } catch (e) {
      throw Exception('Failed to update expense: ${e.toString()}');
    }
  }
}
