import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastos_inteligentes/providers/expense_provider.dart';
import 'package:gastos_inteligentes/providers/income_provider.dart';
import 'package:intl/intl.dart';

class BalanceHeader extends StatefulWidget {
  const BalanceHeader({super.key});

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

        final balance = incomeProv.totalIncomes - expenseProv.totalExpenses;
        /*  String periodText = 'Todo';
        if (_selectedDateRange != null) {
          if (_selectedDateRange!.start.year == _selectedDateRange!.end.year &&
              _selectedDateRange!.start.month ==
                  _selectedDateRange!.end.month) {
            periodText = DateFormat(
              'MMMM yyyy',
            ).format(_selectedDateRange!.start);
          } else {
            periodText =
                '${DateFormat('MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM yyyy').format(_selectedDateRange!.end)}';
          }
        } */

        return Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                /* Text(
                  periodText.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ), */
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  decoration: BoxDecoration(
                    //color: Colors.green,
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
                        ).format(incomeProv.totalIncomes),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: const Divider(),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  decoration: BoxDecoration(
                    //color: Theme.of(context).colorScheme.primary,
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
                        ).format(expenseProv.totalExpenses),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: const Divider(),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  decoration: BoxDecoration(
                    //color: Theme.of(context).colorScheme.primary,
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
              ],
            ),
          ),
        );
      },
    );
  }
}
