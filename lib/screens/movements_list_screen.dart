import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/movement.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import 'widgets/balance_header.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';

class MovementsScreen extends ConsumerStatefulWidget {
  const MovementsScreen({super.key});

  @override
  ConsumerState<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends ConsumerState<MovementsScreen> {
  DateTimeRange? _selectedDateRange;
  String _currentViewFilter = 'balance'; // 'income', 'expense', 'balance'

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(expenseProvider).setDateRange(_selectedDateRange);
        ref.read(incomeProvider).setDateRange(_selectedDateRange);
        ref.read(expenseProvider).loadExpenses();
        ref.read(incomeProvider).loadIncomes();
      }
    });
  }

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
        ref.read(expenseProvider).setDateRange(picked);
        ref.read(incomeProvider).setDateRange(picked);
      }
    }
  }

  void _loadPreviousMonth() {
    if (_selectedDateRange == null) return;

    final currentStart = _selectedDateRange!.start;
    final newStart = DateTime(currentStart.year, currentStart.month - 1, 1);
    final newRange = DateTimeRange(
      start: newStart,
      end: _selectedDateRange!.end,
    );

    setState(() {
      _selectedDateRange = newRange;
    });

    if (mounted) {
      ref.read(expenseProvider).setDateRange(newRange);
      ref.read(incomeProvider).setDateRange(newRange);
    }
  }

  void _filterByMonthString(String monthStr) {
    try {
      final date = DateFormat('MMMM yyyy').parse(monthStr);
      final range = DateTimeRange(
        start: DateTime(date.year, date.month, 1),
        end: DateTime(date.year, date.month + 1, 0),
      );
      setState(() {
        _selectedDateRange = range;
      });
      if (mounted) {
        ref.read(expenseProvider).setDateRange(range);
        ref.read(incomeProvider).setDateRange(range);
      }
    } catch (e) {
      // Ignore
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
    });
    if (mounted) {
      ref.read(expenseProvider).setDateRange(null);
      ref.read(incomeProvider).setDateRange(null);
    }
  }

  List<dynamic> _groupTransactionsByMonth(List<dynamic> transactions) {
    List<dynamic> groupedList = [];
    String? lastMonth;
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
    final expenseProv = ref.watch(expenseProvider);
    final incomeProv = ref.watch(incomeProvider);

    return Column(
      children: [
        BalanceHeader(
          selectedFilter: _currentViewFilter,
          onPressIncome: () => setState(() => _currentViewFilter = 'income'),
          onPressExpense: () => setState(() => _currentViewFilter = 'expense'),
          onPressBalance: () => setState(() => _currentViewFilter = 'balance'),
        ),
        _buildCategoryFilter(expenseProv, incomeProv),
        _buildFilterBar(),
        Expanded(
          child: Builder(
            builder: (context) {
              List<dynamic> transactions = [];
              if (_currentViewFilter == 'income') {
                transactions = incomeProv.incomes;
              } else if (_currentViewFilter == 'expense') {
                transactions = expenseProv.expenses;
              } else {
                transactions = [...expenseProv.expenses, ...incomeProv.incomes];
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
                itemCount: groupedTransactions.length + 1,
                itemBuilder: (context, index) {
                  if (index == groupedTransactions.length) {
                    return _buildLoadMoreButton();
                  }

                  final item = groupedTransactions[index];
                  if (item is String) {
                    return _buildMonthHeader(item);
                  }

                  if (item is Movement) {
                    return _buildMovementTile(item, expenseProv, incomeProv);
                  }

                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadMoreButton() {
    final now = DateTime.now();
    final currentMonthEnd = DateTime(now.year, now.month + 1, 0);
    final isExpandingMode =
        _selectedDateRange != null &&
        _selectedDateRange!.end.year == currentMonthEnd.year &&
        _selectedDateRange!.end.month == currentMonthEnd.month &&
        _selectedDateRange!.end.day == currentMonthEnd.day;

    if (!isExpandingMode) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: OutlinedButton.icon(
        onPressed: _loadPreviousMonth,
        icon: const Icon(Icons.history),
        label: const Text('Cargar mes anterior'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildMonthHeader(String month) {
    return InkWell(
      onTap: () => _filterByMonthString(month),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              month.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Icon(
              Icons.filter_list,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementTile(
    Movement item,
    ExpenseProvider expenseProv,
    IncomeProvider incomeProv,
  ) {
    final isExpense = item is Expense;
    final category = item.category;

    return Dismissible(
      key: Key('${isExpense ? 'exp' : 'inc'}_${item.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) {
        return showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: const Text('¿Estás seguro de eliminar este movimiento?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  if (isExpense) {
                    expenseProv.deleteExpense(item.id!);
                  } else {
                    incomeProv.deleteIncome(item.id!);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => isExpense
                  ? AddExpenseScreen(expenseToEdit: item)
                  : AddIncomeScreen(incomeToEdit: item as Income),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: isExpense
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.green[100],
          child: category.isNotEmpty
              ? Text(
                  category[0][0].toUpperCase(),
                  style: TextStyle(
                    color: isExpense
                        ? Theme.of(context).colorScheme.primary
                        : Colors.green[800],
                  ),
                )
              : Icon(
                  Icons.category,
                  color: isExpense
                      ? Theme.of(context).colorScheme.primary
                      : Colors.green[800],
                ),
        ),
        title: Text(item.name),
        subtitle: Text(DateFormat('dd/MM/yyyy').format(item.date)),
        trailing: Text(
          '${isExpense ? '-' : ''}${NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0).format(item.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isExpense ? Colors.red : Colors.green,
          ),
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
          TextButton.icon(
            icon: Icon(
              _selectedDateRange != null ? Icons.clear : Icons.calendar_today,
            ),
            label: Text(
              _selectedDateRange != null
                  ? 'Limpiar fecha'
                  : 'Filtrar por fecha',
            ),
            onPressed: _selectedDateRange != null
                ? _clearDateRange
                : _selectDateRange,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(
    ExpenseProvider expenseProvider,
    IncomeProvider incomeProvider,
  ) {
    List<String> categories = [];
    String? selectedCategory;
    Function(String?) onCategorySelected;

    if (_currentViewFilter == 'income') {
      categories = incomeProvider.categories;
      selectedCategory = incomeProvider.selectedCategory;
      onCategorySelected = (cat) => incomeProvider.setCategory(cat);
    } else if (_currentViewFilter == 'expense') {
      categories = expenseProvider.categories;
      selectedCategory = expenseProvider.selectedCategory;
      onCategorySelected = (cat) => expenseProvider.setCategory(cat);
    } else {
      categories = {
        ...expenseProvider.categories,
        ...incomeProvider.categories,
      }.toList()..sort();
      selectedCategory = expenseProvider.selectedCategory;
      onCategorySelected = (cat) {
        expenseProvider.setCategory(cat);
        incomeProvider.setCategory(cat);
      };
    }

    if (categories.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: const Text('Todas'),
                selected: selectedCategory == null,
                onSelected: (selected) =>
                    selected ? onCategorySelected(null) : null,
              ),
            );
          }
          final category = categories[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(category),
              selected: selectedCategory == category,
              onSelected: (selected) =>
                  onCategorySelected(selected ? category : null),
            ),
          );
        },
      ),
    );
  }
}
