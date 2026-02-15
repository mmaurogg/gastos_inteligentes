import 'package:flutter/material.dart';
import 'package:gastos_inteligentes/models/debt/debt.dart';
import 'package:gastos_inteligentes/models/debt/debt_purchase.dart';
import 'package:gastos_inteligentes/providers/debt_provider.dart';
import 'package:gastos_inteligentes/screens/add_debt_screen.dart';
import 'package:gastos_inteligentes/screens/widgets/custom_chip_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/formatters.dart';
import 'package:flutter/services.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final Expense? expenseToEdit;

  const AddExpenseScreen({super.key, this.expenseToEdit});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final List<String> _categorysSelected = [];

  DateTime _selectedDate = DateTime.now();
  bool _isCredit = false;
  Debt? _selectedDebt;

  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    if (widget.expenseToEdit != null) {
      _nameController.text = widget.expenseToEdit!.name;
      _categorysSelected.addAll(widget.expenseToEdit!.category);
      _selectedDate = widget.expenseToEdit!.date;
      _amountController.text = NumberFormat.decimalPattern(
        'en_US',
      ).format(widget.expenseToEdit!.amount);
      _isCredit = widget.expenseToEdit!.debtPurchaseId != null;
      if (_isCredit && widget.expenseToEdit!.debtPurchaseId != null) {
        _loadSelectedDebt(widget.expenseToEdit!.debtPurchaseId!);
      }
    }
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  Future<void> _loadSelectedDebt(int debtId) async {
    //TODO: alto consumo pero necesitamos que haya lista de deudas por que3 si no se bloquea el droopdown
    await ref.read(debtProvider).loadDebts();
    final debt = await ref.read(debtProvider).getDebtById(debtId);
    if (mounted) {
      setState(() {
        _selectedDebt = debt;
      });
    }
  }

  void _showAddCategoryDialog() {
    final TextEditingController newCategoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nueva etiqueta'),
          content: TextField(
            controller: newCategoryController,
            decoration: const InputDecoration(
              hintText: 'Nombre de la etiqueta',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final newCategory = newCategoryController.text
                    .trim()
                    .toLowerCase();
                if (newCategory.isNotEmpty) {
                  setState(() {
                    if (!_categories.contains(newCategory)) {
                      _categories.add(newCategory);
                    }
                    if (!_categorysSelected.contains(newCategory)) {
                      _categorysSelected.add(newCategory);
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _showRenameCategoryDialog(String oldName) {
    final TextEditingController renameController = TextEditingController(
      text: oldName,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Renombrar etiqueta'),
          content: TextField(
            controller: renameController,
            decoration: const InputDecoration(hintText: 'Nuevo nombre'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = renameController.text.trim().toLowerCase();
                if (newName.isNotEmpty && newName != oldName) {
                  ref.read(expenseProvider).renameCategory(oldName, newName);
                  setState(() {
                    if (_categorysSelected.contains(oldName)) {
                      _categorysSelected.remove(oldName);
                      _categorysSelected.add(newName);
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Renombrar'),
            ),
          ],
        );
      },
    );
  }

  void _saveExpense() async {
    if (_categorysSelected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una etiqueta')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Remove commas before parsing
      final amountText = _amountController.text.replaceAll(',', '');
      final amount = double.parse(amountText);
      final expense = Expense(
        id: widget.expenseToEdit?.id,
        name: _nameController.text,
        category: _categorysSelected,
        amount: amount,
        date: _selectedDate,
        debtPurchaseId: _selectedDebt?.id,
      );

      if (widget.expenseToEdit != null) {
        if (_isCredit) {
          if (_selectedDebt?.id == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Debe seleccionar una deuda')),
            );
            return;
          }

          if (widget.expenseToEdit?.debtPurchaseId != null) {
            // Caso: ya tenia credito asociado
            var debtPurchase = await ref
                .read(debtProvider)
                .getDebtPurchaseById(widget.expenseToEdit!.debtPurchaseId!);

            if (debtPurchase == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ocdurrio un error al actualizar el el gasto'),
                ),
              );
              return;
            }
            debtPurchase.originalAmount = amount;
            debtPurchase.debtId = _selectedDebt!.id!;
            debtPurchase.createdAt = _selectedDate;

            await ref.read(debtProvider).updateDebtPurchase(debtPurchase);
          } else {
            // Caso: no tenia credito asociado y se agrego despues
            final debtPurchase = DebtPurchase(
              expenseId: widget.expenseToEdit!.id!,
              debtId: _selectedDebt!.id!,
              originalAmount: amount,
              paidAmount: 0,
              createdAt: _selectedDate,
              status: DebtStatus.pending,
            );

            final debtPurchaseId = await ref
                .read(debtProvider)
                .addDebtPurchase(debtPurchase);

            expense.debtPurchaseId = debtPurchaseId;
          }
        } else {
          // Caso: ya tenia credito asociado y se le quito
          if (widget.expenseToEdit?.debtPurchaseId != null) {
            await ref
                .read(debtProvider)
                .deleteDebtPurchase(widget.expenseToEdit!.debtPurchaseId!);
          }
          expense.debtPurchaseId = null;
        }

        await ref.read(expenseProvider).updateExpense(expense);
      } else {
        if (_isCredit) {
          if (_selectedDebt?.id == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Debe seleccionar una deuda')),
            );
            return;
          }

          // Primer guardado para obtener el id
          final expenseId = await ref.read(expenseProvider).addExpense(expense);

          final debtPurchase = DebtPurchase(
            expenseId: expenseId,
            debtId: _selectedDebt!.id!,
            originalAmount: amount,
            paidAmount: 0,
            createdAt: _selectedDate,
            status: DebtStatus.pending,
          );

          final debtPurchaseId = await ref
              .read(debtProvider)
              .addDebtPurchase(debtPurchase);

          final updatedExpense = Expense(
            id: expenseId,
            name: expense.name,
            category: expense.category,
            amount: expense.amount,
            date: expense.date,
            debtPurchaseId: debtPurchaseId,
          );

          // Segundo guardado para actualizar el gasto con el id de la deuda
          await ref.read(expenseProvider).updateExpense(updatedExpense);
        } else {
          await ref.read(expenseProvider).addExpense(expense);
        }
      }

      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerCategories = ref.watch(expenseProvider).categories;

    // Merge provider categories with locally selected ones to ensure new ones show up
    _categories = {...providerCategories, ..._categorysSelected}.toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.expenseToEdit != null ? 'Editar Gasto' : 'Agregar Gasto',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Form Fields
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Producto',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_bag),
                      ),
                      validator: (value) => value!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Valor',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsSeparatorInputFormatter(),
                      ],
                      validator: (value) => value!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Fecha',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: 16),
                    CustomChipBar(
                      title: "Categoria",
                      values: _categories,
                      selectedValues: _categorysSelected,
                      onSelected: (value) {
                        setState(() {
                          if (_categorysSelected.contains(value)) {
                            _categorysSelected.remove(value);
                          } else {
                            _categorysSelected.add(value);
                          }
                        });
                      },
                      onLongPress: _showRenameCategoryDialog,
                      onAdd: _showAddCategoryDialog,
                    ),
                    const SizedBox(height: 16),

                    Card(
                      child: SwitchListTile(
                        title: const Text('Pagar con Crédito'),
                        value: _isCredit,
                        onChanged: (value) async {
                          if (value) await ref.read(debtProvider).loadDebts();

                          setState(() {
                            _isCredit = value;
                          });
                        },
                        secondary: const Icon(Icons.credit_card),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_isCredit)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<Debt>(
                                value: _selectedDebt,
                                decoration: const InputDecoration(
                                  labelText: 'seleccione un credito',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.credit_card),
                                ),
                                onTap: () {
                                  if (ref.read(debtProvider).debts.isEmpty) {
                                    ref.read(debtProvider).loadDebts();
                                  }
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDebt = value;
                                  });
                                },
                                items: ref.watch(debtProvider).debts.map((
                                  debt,
                                ) {
                                  return DropdownMenuItem(
                                    value: debt,
                                    child: Text(debt.name),
                                  );
                                }).toList(),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AddDebtScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveExpense,
        child: const Icon(Icons.save),
      ),
    );
  }
}
