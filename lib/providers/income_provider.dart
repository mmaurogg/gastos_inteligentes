import 'package:flutter/material.dart';
import '../models/income.dart';
import '../db/database_helper.dart';

class IncomeProvider with ChangeNotifier {
  List<Income> _incomes = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  DateTimeRange? _selectedDateRange;

  List<Income> get incomes {
    if (_selectedDateRange == null) {
      return _incomes;
    }
    return _incomes.where((income) {
      return income.date.isAfter(
            _selectedDateRange!.start.subtract(const Duration(days: 1)),
          ) &&
          income.date.isBefore(
            _selectedDateRange!.end.add(const Duration(days: 1)),
          );
    }).toList();
  }

  double get totalIncomes {
    return incomes.fold(0.0, (sum, item) => sum + item.amount);
  }

  void setDateRange(DateTimeRange? range) {
    _selectedDateRange = range;
    notifyListeners();
  }

  Future<void> loadIncomes() async {
    _incomes = await _dbHelper.getIncomes();
    notifyListeners();
  }

  Future<void> addIncome(Income income) async {
    await _dbHelper.insertIncome(income);
    await loadIncomes();
  }

  Future<void> updateIncome(Income income) async {
    await _dbHelper.updateIncome(income);
    await loadIncomes();
  }

  Future<void> deleteIncome(int id) async {
    await _dbHelper.deleteIncome(id);
    await loadIncomes();
  }
}
