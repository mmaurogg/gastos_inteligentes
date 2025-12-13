import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../db/database_helper.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  DateTimeRange? _selectedDateRange;

  List<Expense> get expenses {
    if (_selectedDateRange == null) {
      return _expenses;
    }
    return _expenses.where((expense) {
      return expense.date.isAfter(
            _selectedDateRange!.start.subtract(const Duration(days: 1)),
          ) &&
          expense.date.isBefore(
            _selectedDateRange!.end.add(const Duration(days: 1)),
          );
    }).toList();
  }

  double get totalExpenses {
    return expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  void setDateRange(DateTimeRange? range) {
    _selectedDateRange = range;
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

  Future<void> deleteExpense(int id) async {
    await _dbHelper.deleteExpense(id);
    await loadExpenses();
  }
}
