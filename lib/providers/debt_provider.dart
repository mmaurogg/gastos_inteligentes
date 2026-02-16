import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/debt/debt.dart';
import '../models/debt/debt_purchase.dart';
import '../models/debt/debt_payment.dart';
import '../db/database_helper.dart';

final debtProvider = ChangeNotifierProvider((ref) => DebtProvider());

class DebtProvider with ChangeNotifier {
  List<Debt> _debts = [];
  List<DebtPurchase> _debtPurchases = [];
  List<DebtPayment> _debtPayments = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Debt> get debts => _debts;
  List<DebtPurchase> get debtPurchases => _debtPurchases;
  List<DebtPayment> get debtPayments => _debtPayments;

  // --- Debt Accounts ---
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

  Future<Debt?> getDebtById(int id) async {
    return await _dbHelper.getDebtById(id);
  }

  // --- Debt Purchases ---
  Future<void> loadDebtPurchases() async {
    _debtPurchases = await _dbHelper.getDebtPurchases();
    notifyListeners();
  }

  Future<int> addDebtPurchase(DebtPurchase purchase) async {
    final id = await _dbHelper.insertDebtPurchase(purchase);
    await loadDebtPurchases();
    return id;
  }

  Future<void> updateDebtPurchase(DebtPurchase purchase) async {
    await _dbHelper.updateDebtPurchase(purchase);
    await loadDebtPurchases();
  }

  Future<void> deleteDebtPurchase(int id) async {
    await _dbHelper.deleteDebtPurchase(id);
    await loadDebtPurchases();
  }

  Future<DebtPurchase?> getDebtPurchaseById(int id) async {
    return await _dbHelper.getDebtPurchaseById(id);
  }

  // --- Debt Payments ---
  Future<void> loadDebtPayments() async {
    _debtPayments = await _dbHelper.getDebtPayments();
    notifyListeners();
  }

  Future<void> addDebtPayment(DebtPayment payment) async {
    await _dbHelper.insertDebtPayment(payment);
    await loadDebtPayments();
  }

  Future<void> updateDebtPayment(DebtPayment payment) async {
    await _dbHelper.updateDebtPayment(payment);
    await loadDebtPayments();
  }

  Future<void> deleteDebtPayment(int id) async {
    await _dbHelper.deleteDebtPayment(id);
    await loadDebtPayments();
  }

  // Helper getters
  double get totalPendingDebts {
    return _debtPurchases
        .where(
          (d) =>
              d.status == DebtStatus.pending || d.status == DebtStatus.overdue,
        )
        .fold(
          0.0,
          (sum, item) => sum + (item.originalAmount - item.paidAmount),
        );
  }
}
