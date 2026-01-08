import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/income.dart';
import '../db/database_helper.dart';

final incomeProvider = ChangeNotifierProvider((ref) => IncomeProvider());

class IncomeProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Income> _incomes = [];

  DateTimeRange? _selectedDateRange;
  String? _selectedCategory;

  String? get selectedCategory => _selectedCategory;

  List<String> get categories {
    return _incomes.expand((e) => e.category).toSet().toList()..sort();
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
        (income) => income.category.contains(_selectedCategory),
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

  Future<void> renameCategory(String oldName, String newName) async {
    for (var income in _incomes) {
      if (income.category.contains(oldName)) {
        final newCategories = income.category
            .map((c) => c == oldName ? newName : c)
            .toList();
        final updatedIncome = Income(
          id: income.id,
          name: income.name,
          category: newCategories,
          amount: income.amount,
          date: income.date,
        );
        await _dbHelper.updateIncome(updatedIncome);
      }
    }
    await loadIncomes();
  }
}
