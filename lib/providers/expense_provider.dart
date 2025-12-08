import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../db/database_helper.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  double _totalExpenses = 0.0;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Expense> get expenses => _expenses;
  double get totalExpenses => _totalExpenses;

  Future<void> loadExpenses() async {
    _expenses = await _dbHelper.getExpenses();
    _totalExpenses = await _dbHelper.getTotalExpenses();
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await _dbHelper.insertExpense(expense);
    await loadExpenses();
  }

  Future<void> deleteExpense(int id) async {
    await _dbHelper.deleteExpense(id);
    await loadExpenses();
  }
}
