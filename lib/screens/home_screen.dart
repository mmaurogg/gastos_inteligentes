import 'package:flutter/material.dart';
import 'package:gastos_inteligentes/screens/widgets/expandible_button.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../models/expense.dart';
import '../models/income.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'permissions_screen.dart';
import 'api_key_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load expenses when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ExpenseProvider>(context, listen: false).loadExpenses();
        Provider.of<IncomeProvider>(context, listen: false).loadIncomes();
      }
    });
  }

  DateTimeRange? _selectedDateRange;
  String _currentViewFilter = 'balance'; // 'income', 'expense', 'balance'

  void _selectDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _selectedDateRange,
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      if (mounted) {
        Provider.of<ExpenseProvider>(
          context,
          listen: false,
        ).setDateRange(picked);
        Provider.of<IncomeProvider>(
          context,
          listen: false,
        ).setDateRange(picked);
      }
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
    });
    if (mounted) {
      Provider.of<ExpenseProvider>(context, listen: false).setDateRange(null);
      Provider.of<IncomeProvider>(context, listen: false).setDateRange(null);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gemini_api_key');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const ApiKeyScreen()),
      (route) => false,
    );
  }

  List<dynamic> _groupTransactionsByMonth(List<dynamic> transactions) {
    List<dynamic> groupedList = [];
    String? lastMonth;

    // Sort transactions by date descending
    transactions.sort((a, b) => b.date.compareTo(a.date));

    for (var transaction in transactions) {
      String month = DateFormat('MMMM yyyy').format(transaction.date);
      if (month != lastMonth) {
        groupedList.add(month);
        lastMonth = month;
      }
      groupedList.add(transaction);
    }
    return groupedList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Gastos IA'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PermissionsScreen(),
                ),
              );
            },
            tooltip: 'Permisos',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Consumer2<ExpenseProvider, IncomeProvider>(
        builder: (context, expenseProvider, incomeProvider, child) {
          return Column(
            children: [
              _buildFilterBar(),

              _buildDashboardHeader(
                expenseProvider.totalExpenses,
                incomeProvider.totalIncomes,
              ),

              Expanded(
                child: Builder(
                  builder: (context) {
                    List<dynamic> transactions = [];
                    if (_currentViewFilter == 'income') {
                      transactions = incomeProvider.incomes;
                    } else if (_currentViewFilter == 'expense') {
                      transactions = expenseProvider.expenses;
                    } else {
                      transactions = [
                        ...expenseProvider.expenses,
                        ...incomeProvider.incomes,
                      ];
                    }

                    if (transactions.isEmpty) {
                      return const Center(
                        child: Text('No hay movimientos en este periodo.'),
                      );
                    }

                    final groupedTransactions = _groupTransactionsByMonth(
                      transactions,
                    );

                    return ListView.builder(
                      itemCount: groupedTransactions.length,
                      itemBuilder: (context, index) {
                        final item = groupedTransactions[index];
                        if (item is String) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              item.toUpperCase(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          );
                        }

                        final isExpense = item is Expense;
                        final id = isExpense ? item.id : (item as Income).id;
                        final name = isExpense
                            ? item.name
                            : (item as Income).name;
                        final category = isExpense
                            ? item.category
                            : (item as Income).category;
                        final date = isExpense
                            ? item.date
                            : (item as Income).date;
                        final amount = isExpense
                            ? item.amount
                            : (item as Income).amount;

                        return Dismissible(
                          key: Key('${isExpense ? 'exp' : 'inc'}_$id'),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (direction) {
                            if (isExpense) {
                              expenseProvider.deleteExpense(id!);
                            } else {
                              incomeProvider.deleteIncome(id!);
                            }
                          },
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => isExpense
                                      ? AddExpenseScreen(expenseToEdit: item)
                                      : AddIncomeScreen(
                                          incomeToEdit: item as Income,
                                        ),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              backgroundColor: isExpense
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : Colors.green[100],
                              child: category.isNotEmpty
                                  ? Text(
                                      category[0].toUpperCase(),
                                      style: TextStyle(
                                        color: isExpense
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Colors.green[800],
                                      ),
                                    )
                                  : Icon(
                                      Icons.category,
                                      color: isExpense
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Colors.green[800],
                                    ),
                            ),
                            title: Text(name),
                            subtitle: Text(
                              DateFormat('dd/MM/yyyy').format(date),
                            ),
                            trailing: Text(
                              '${isExpense ? '-' : ''}${NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0).format(amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isExpense ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: ExpandableFab(
        icon: Icon(
          Icons.monetization_on_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddIncomeScreen(),
                ),
              );
            },
            heroTag: 'add_income',
            backgroundColor: Colors.green[400],
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddExpenseScreen(),
                ),
              );
            },
            heroTag: 'add_expense',
            backgroundColor: Colors.red[400],
            child: const Icon(Icons.wallet, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader(double totalExpenses, double totalIncomes) {
    final balance = totalIncomes - totalExpenses;
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _currentViewFilter = 'income'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                decoration: BoxDecoration(
                  color: _currentViewFilter == 'income'
                      ? Colors.green.withOpacity(0.1)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ingresos:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
            InkWell(
              onTap: () => setState(() => _currentViewFilter = 'expense'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                decoration: BoxDecoration(
                  color: _currentViewFilter == 'expense'
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gastos:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
            InkWell(
              onTap: () => setState(() => _currentViewFilter = 'balance'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                decoration: BoxDecoration(
                  color: _currentViewFilter == 'balance'
                      ? Colors.blue.withOpacity(0.1)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Balance:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
  }

  Widget _buildFilterBar() {
    String dateText = 'Todo';
    if (_selectedDateRange != null) {
      dateText =
          '${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Row(
            children: [
              if (_selectedDateRange != null)
                IconButton(
                  icon: const Icon(Icons.filter_alt_off),
                  onPressed: _clearDateRange,
                  tooltip: 'Limpiar filtro',
                ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _selectDateRange,
                tooltip: 'Filtrar por fecha',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
