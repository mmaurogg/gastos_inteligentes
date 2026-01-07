import 'package:flutter/material.dart';
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
    }
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
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

  void _saveExpense() {
    if (_categorysSelected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una etiqueta')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Remove commas before parsing
      final amountText = _amountController.text.replaceAll(',', '');
      final expense = Expense(
        id: widget.expenseToEdit?.id,
        name: _nameController.text,
        category: _categorysSelected,
        amount: double.parse(amountText),
        date: _selectedDate,
      );

      if (widget.expenseToEdit != null) {
        ref.read(expenseProvider).updateExpense(expense);
      } else {
        ref.read(expenseProvider).addExpense(expense);
      }
      Navigator.pop(context);
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
