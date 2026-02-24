import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Save Currency to the Cloud
  Future<void> updateCurrency(String newCurrency) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // We use SetOptions(merge: true) so it creates the document if it doesn't exist,
    // but only updates the 'currency' field without overwriting other future data (like display name).
    await _firestore.collection('users').doc(user.uid).set({
      'currency': newCurrency,
    }, SetOptions(merge: true));
  }

  // 2. Fetch Currency from the Cloud
  Future<String?> getUserCurrency() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey('currency')) {
        return doc.data()!['currency'] as String;
      }
    } catch (e) {
      print("Error fetching currency: $e");
    }
    return null; // Returns null if the user hasn't set a preference yet
  }

  // --- NEW: Budget Functions ---

  // 1. Save Budget to the Cloud
  Future<void> updateBudget(double newBudget) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'monthlyBudget': newBudget,
    }, SetOptions(merge: true));
  }

  // 2. Fetch Budget from the Cloud
  Future<double?> getUserBudget() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey('monthlyBudget')) {
        // Firestore sometimes saves doubles as ints, so we use .toDouble() to be safe
        return (doc.data()!['monthlyBudget'] as num).toDouble();
      }
    } catch (e) {
      print("Error fetching budget: $e");
    }
    return null;
  }
}