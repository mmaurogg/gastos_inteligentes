import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastos_inteligentes/providers/expense_provider.dart';
import 'package:gastos_inteligentes/providers/income_provider.dart';
import 'package:intl/intl.dart';

class BalanceHeader extends StatefulWidget {
  const BalanceHeader({
    super.key,
    this.onPressIncome,
    this.onPressExpense,
    this.onPressBalance,
    required this.selectedFilter,
  });

  final VoidCallback? onPressIncome;
  final VoidCallback? onPressExpense;
  final VoidCallback? onPressBalance;

  final String selectedFilter;

  @override
  State<BalanceHeader> createState() => _BalanceHeaderState();
}

class _BalanceHeaderState extends State<BalanceHeader> {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final expenseProv = ref.watch(expenseProvider);
        final incomeProv = ref.watch(incomeProvider);

        final totalIncomes = widget.selectedFilter == 'expense'
            ? 0
            : incomeProv.totalIncomes;
        final totalExpenses = widget.selectedFilter == 'income'
            ? 0
            : expenseProv.totalExpenses;

        final balance = totalIncomes - totalExpenses;

        return Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: widget.onPressIncome,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    decoration: BoxDecoration(
                      color: widget.selectedFilter == 'income'
                          ? Theme.of(context).colorScheme.primary.withAlpha(30)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: const Icon(
                            Icons.arrow_upward,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Ingresos:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Spacer(),
                        Text(
                          NumberFormat.currency(
                            locale: 'en_US',
                            symbol: '\$',
                            decimalDigits: 0,
                          ).format(totalIncomes),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: const Divider(),
                ),
                GestureDetector(
                  onTap: widget.onPressExpense,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    decoration: BoxDecoration(
                      color: widget.selectedFilter == 'expense'
                          ? Theme.of(context).colorScheme.primary.withAlpha(30)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.red.shade100,
                          child: const Icon(Icons.wallet, color: Colors.red),
                        ),

                        const SizedBox(width: 12),

                        const Text(
                          'Gastos:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        Spacer(),
                        Text(
                          NumberFormat.currency(
                            locale: 'en_US',
                            symbol: '\$',
                            decimalDigits: 0,
                          ).format(totalExpenses),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: const Divider(),
                ),
                GestureDetector(
                  onTap: widget.onPressBalance,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    decoration: BoxDecoration(
                      color: widget.selectedFilter == 'balance'
                          ? Theme.of(context).colorScheme.primary.withAlpha(30)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Balance:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: balance >= 0
                                ? Theme.of(context).colorScheme.primary
                                : Colors.red,
                          ),
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'en_US',
                            symbol: '\$',
                            decimalDigits: 0,
                          ).format(balance),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: balance >= 0
                                ? Theme.of(context).colorScheme.primary
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
