import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/debt.dart';
import '../db/database_helper.dart';

final debtProvider = ChangeNotifierProvider((ref) => DebtProvider());

class DebtProvider with ChangeNotifier {
  List<Debt> _debts = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Debt> get debts => _debts;

  Future<void> loadDebts() async {
    _debts = await _dbHelper.getDebts();
    notifyListeners();
  }

  Future<void> addDebt(Debt debt) async {
    await _dbHelper.insertDebt(debt);
    await loadDebts();
  }

  Future<void> updateDebt(Debt debt) async {
    await _dbHelper.updateDebt(debt);
    await loadDebts();
  }

  Future<void> deleteDebt(int id) async {
    await _dbHelper.deleteDebt(id);
    await loadDebts();
  }

  double get totalPendingDebts {
    return _debts
        .where(
          (d) =>
              d.status == DebtStatus.pending || d.status == DebtStatus.overdue,
        )
        .fold(0.0, (sum, item) => sum + item.originalAmount);
  }
}
