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
}