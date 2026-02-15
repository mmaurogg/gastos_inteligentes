import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/debt_provider.dart';
import '../providers/expense_provider.dart';
import '../models/debt/debt_purchase.dart';
import 'add_expense_screen.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(debtProvider).loadDebtPurchases();
      ref.read(debtProvider).loadDebts();
      // Note: ExpenseProvider loads expenses based on date range in HomeScreen.
      // We might miss some expense names if they are outside the range.
      // For now, we rely on what's available or implemented later.
    });
  }

  @override
  Widget build(BuildContext context) {
    final debtProv = ref.watch(debtProvider);
    final expenseProv = ref.watch(expenseProvider);
    final debtPurchases = debtProv.debtPurchases;
    final debts = debtProv.debts;

    double totalPaid = 0;
    for (var purchase in debtPurchases) {
      totalPaid += purchase.paidAmount;
    }
    final totalPending = debtProv.totalPendingDebts;

    return Column(
      children: [
        // Summary Cards
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildSummaryCard(
                context,
                'Pendiente',
                totalPending,
                Colors.orange,
                Icons.pending_actions,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                context,
                'Pagado',
                totalPaid,
                Colors.green,
                Icons.check_circle_outline,
              ),
            ],
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Movimientos de Deuda',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // List of Purchases
        Expanded(
          child: debtPurchases.isEmpty
              ? const Center(child: Text('No hay deudas registradas.'))
              : ListView.builder(
                  itemCount: debtPurchases.length,
                  itemBuilder: (context, index) {
                    final purchase = debtPurchases[index];

                    // Resolve Expense Name
                    String expenseName = 'Gasto #${purchase.expenseId}';
                    try {
                      final expense = expenseProv.expenses.firstWhere(
                        (e) => e.id == purchase.expenseId,
                      );
                      expenseName = expense.name;
                    } catch (e) {
                      // Expense not found in current list
                    }

                    // Resolve Debt Name
                    String debtName = 'Crédito #${purchase.debtId}';
                    try {
                      final debt = debts.firstWhere(
                        (d) => d.id == purchase.debtId,
                      );
                      debtName = debt.name;
                    } catch (e) {
                      // Debt not found
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        onTap: () async {
                          final expense = await expenseProv.getExpenseById(
                            purchase.expenseId,
                          );
                          if (expense != null && mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddExpenseScreen(expenseToEdit: expense),
                              ),
                            );
                          }
                        },
                        leading: CircleAvatar(
                          backgroundColor: Colors.red[100],
                          child: const Icon(
                            Icons.credit_card,
                            color: Colors.red,
                          ),
                        ),
                        title: Text(expenseName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(debtName),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'dd/MM/yyyy',
                              ).format(purchase.createdAt),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              NumberFormat.currency(
                                locale: 'en_US',
                                symbol: '\$',
                                decimalDigits: 0,
                              ).format(purchase.originalAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              purchase.status.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: purchase.status == DebtStatus.paid
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                NumberFormat.currency(
                  locale: 'en_US',
                  symbol: '\$',
                  decimalDigits: 0,
                ).format(amount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
