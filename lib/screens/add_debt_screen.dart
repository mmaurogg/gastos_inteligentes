import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/debt/debt.dart';
import '../providers/debt_provider.dart';

class AddDebtScreen extends ConsumerStatefulWidget {
  final Debt? debtToEdit;

  const AddDebtScreen({super.key, this.debtToEdit});

  @override
  ConsumerState<AddDebtScreen> createState() => _AddDebtWidgetState();
}

class _AddDebtWidgetState extends ConsumerState<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _interestRateController = TextEditingController();

  int _selectedDebtPurchaseDay = 1;
  int _selectedPaymentDay = 1;

  @override
  void initState() {
    super.initState();
    if (widget.debtToEdit != null) {
      _nameController.text = widget.debtToEdit!.name;
      _selectedDebtPurchaseDay = widget.debtToEdit!.debtPurchase;
      _selectedPaymentDay = widget.debtToEdit!.paymentDay;
      _interestRateController.text = (widget.debtToEdit!.interestRate * 100)
          .toString(); // Convert 0.03 to 3
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _interestRateController.dispose();
    super.dispose();
  }

  void _saveDebt() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final interestRate =
          (double.tryParse(_interestRateController.text) ?? 0.0) /
          100; // Convert 3 to 0.03

      final debt = Debt(
        id: widget.debtToEdit?.id,
        name: name,
        debtPurchase: _selectedDebtPurchaseDay,
        paymentDay: _selectedPaymentDay,
        interestRate: interestRate,
      );

      if (widget.debtToEdit != null) {
        await ref.read(debtProvider).updateDebt(debt);
      } else {
        await ref.read(debtProvider).addDebt(debt);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.debtToEdit != null
              ? 'Editar Deuda'
              : 'Agregar Cuentas por Pagar',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Deuda',
                  hintText: 'Ej: Tarjeta de Crédito, Préstamo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedDebtPurchaseDay,
                      decoration: const InputDecoration(
                        labelText: 'Día de Corte',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.date_range),
                        helperText: 'Día del mes',
                      ),
                      items: List.generate(31, (index) => index + 1)
                          .map(
                            (day) => DropdownMenuItem(
                              value: day,
                              child: Text(day.toString()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDebtPurchaseDay = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedPaymentDay,
                      decoration: const InputDecoration(
                        labelText: 'Día de Pago',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event),
                        helperText: 'Día del mes',
                      ),
                      items: List.generate(31, (index) => index + 1)
                          .map(
                            (day) => DropdownMenuItem(
                              value: day,
                              child: Text(day.toString()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentDay = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _interestRateController,
                decoration: const InputDecoration(
                  labelText: 'Tasa de Interés Mensual (%)',
                  hintText: 'Ej: 3.5',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.percent),
                  suffixText: '%',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa la tasa de interés';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveDebt,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
