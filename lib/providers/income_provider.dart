import 'package:flutter/material.dart';
import '../models/income.dart';
import '../db/database_helper.dart';

class IncomeProvider with ChangeNotifier {
  List<Income> _incomes = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  DateTimeRange? _selectedDateRange;
  String? _selectedCategory;

  String? get selectedCategory => _selectedCategory;

  List<String> get categories {
    return _incomes.map((e) => e.category).toSet().toList()..sort();
  }

  List<Income> get incomes {
    Iterable<Income> filtered = _incomes;

    if (_selectedDateRange != null) {
      filtered = filtered.where((income) {
        return income.date.isAfter(
              _selectedDateRange!.start.subtract(const Duration(days: 1)),
            ) &&
            income.date.isBefore(
              _selectedDateRange!.end.add(const Duration(days: 1)),
            );
      });
    }

    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered.where(
        (income) => income.category == _selectedCategory,
      );
    }

    return filtered.toList();
  }

  double get totalIncomes {
    return incomes.fold(0.0, (sum, item) => sum + item.amount);
  }

  void setDateRange(DateTimeRange? range) {
    _selectedDateRange = range;
    notifyListeners();
  }

  void setCategory(String? category) {
    _selectedCategory = category;
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
