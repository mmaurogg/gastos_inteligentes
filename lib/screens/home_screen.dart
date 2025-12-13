import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import 'add_expense_screen.dart';
import 'permissions_screen.dart';

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
      }
    });
  }

  DateTimeRange? _selectedDateRange;

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
      }
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
    });
    if (mounted) {
      Provider.of<ExpenseProvider>(context, listen: false).setDateRange(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Gastos IA'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
            tooltip: 'Filtrar por fecha',
          ),
          if (_selectedDateRange != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: _clearDateRange,
              tooltip: 'Limpiar filtro',
            ),
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
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildDashboardHeader(provider.totalExpenses),
              Expanded(
                child: provider.expenses.isEmpty
                    ? const Center(
                        child: Text('No hay gastos en este periodo.'),
                      )
                    : ListView.builder(
                        itemCount: provider.expenses.length,
                        itemBuilder: (context, index) {
                          final expense = provider.expenses[index];
                          return Dismissible(
                            key: Key(expense.id.toString()),
                            background: Container(color: Colors.red),
                            onDismissed: (direction) {
                              provider.deleteExpense(expense.id!);
                            },
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(expense.category[0].toUpperCase()),
                              ),
                              title: Text(expense.name),
                              subtitle: Text(
                                DateFormat('dd/MM/yyyy').format(expense.date),
                              ),
                              trailing: Text(
                                '\$${expense.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDashboardHeader(double total) {
    String dateText = 'Todos los tiempos';
    if (_selectedDateRange != null) {
      dateText =
          '${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}';
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              dateText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(
                  context,
                ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Gastado:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
