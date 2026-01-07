import 'package:flutter/material.dart';
import 'package:gastos_inteligentes/screens/widgets/custom_chip_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/income.dart';
import '../providers/income_provider.dart';
import '../utils/formatters.dart';
import 'package:flutter/services.dart';

class AddIncomeScreen extends ConsumerStatefulWidget {
  final Income? incomeToEdit;

  const AddIncomeScreen({super.key, this.incomeToEdit});

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
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
    if (widget.incomeToEdit != null) {
      _nameController.text = widget.incomeToEdit!.name;
      _categorysSelected.addAll(widget.incomeToEdit!.category);
      _selectedDate = widget.incomeToEdit!.date;
      _amountController.text = NumberFormat.decimalPattern(
        'en_US',
      ).format(widget.incomeToEdit!.amount);
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
                final newCategory = newCategoryController.text.trim();
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
                  ref.read(incomeProvider).renameCategory(oldName, newName);
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

  void _saveIncome() {
    if (_categorysSelected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una etiqueta')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Remove commas before parsing
      final amountText = _amountController.text.replaceAll(',', '');
      final income = Income(
        id: widget.incomeToEdit?.id,
        name: _nameController.text,
        category: _categorysSelected,
        amount: double.parse(amountText),
        date: _selectedDate,
      );

      if (widget.incomeToEdit != null) {
        ref.read(incomeProvider).updateIncome(income);
      } else {
        ref.read(incomeProvider).addIncome(income);
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
    final providerCategories = ref.watch(incomeProvider).categories;

    // Merge provider categories with locally selected ones to ensure new ones show up
    _categories = {...providerCategories, ..._categorysSelected}.toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.incomeToEdit != null ? 'Editar Ingreso' : 'Agregar Ingreso',
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
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Concepto del Ingreso',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_wallet),
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
        onPressed: _saveIncome,
        child: const Icon(Icons.save),
      ),
    );
  }
}
