import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../db/database_helper.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  DateTimeRange? _selectedDateRange;
  String? _selectedCategory;

  String? get selectedCategory => _selectedCategory;

  List<String> get categories {
    return _expenses.map((e) => e.category).toSet().toList()..sort();
  }

  List<Expense> get expenses {
    Iterable<Expense> filtered = _expenses;

    if (_selectedDateRange != null) {
      filtered = filtered.where((expense) {
        return expense.date.isAfter(
              _selectedDateRange!.start.subtract(const Duration(days: 1)),
            ) &&
            expense.date.isBefore(
              _selectedDateRange!.end.add(const Duration(days: 1)),
            );
      });
    }

    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered.where(
        (expense) => expense.category == _selectedCategory,
      );
    }

    return filtered.toList();
  }

  double get totalExpenses {
    return expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  void setDateRange(DateTimeRange? range) {
    _selectedDateRange = range;
    notifyListeners();
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> loadExpenses() async {
    _expenses = await _dbHelper.getExpenses();
    // _totalExpenses is now calculated dynamically based on the filtered list
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await _dbHelper.insertExpense(expense);
    await loadExpenses();
  }

  Future<void> updateExpense(Expense expense) async {
    await _dbHelper.updateExpense(expense);
    await loadExpenses();
  }

  Future<void> deleteExpense(int id) async {
    await _dbHelper.deleteExpense(id);
    await loadExpenses();
  }
}
