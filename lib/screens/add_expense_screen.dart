import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/speech_service.dart';
import '../services/ai_service.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final SpeechService _speechService = SpeechService();
  final AIService _aiService = AIService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();

  String _recognizedText = "Presiona el micrófono para hablar...";
  bool _isListening = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    await _speechService.init();
    setState(() {});
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() {
        _isListening = false;
      });
    } else {
      setState(() {
        _isListening = true;
        _recognizedText = "";
      });
      await _speechService.startListening((text) {
        setState(() {
          _recognizedText = text;
        });
      });
    }
  }

  void _processWithAI() async {
    if (_recognizedText.isEmpty ||
        _recognizedText == "Presiona el micrófono para hablar...") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor graba o escribe algo primero.'),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final expense = await _aiService.parseExpenseFromText(_recognizedText);

    setState(() {
      _isProcessing = false;
    });

    if (!mounted) return;

    if (expense != null) {
      _nameController.text = expense.name;
      _categoryController.text = expense.category;
      _amountController.text = expense.amount.toStringAsFixed(0);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos extraídos con éxito!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al procesar con IA. Verifica tu API Key.'),
        ),
      );
    }
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final expense = Expense(
        name: _nameController.text,
        category: _categoryController.text,
        amount: double.parse(_amountController.text),
        date: DateTime.now(),
      );

      Provider.of<ExpenseProvider>(context, listen: false).addExpense(expense);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Gasto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Voice Input Section
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        _recognizedText,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingActionButton(
                            onPressed: _toggleListening,
                            backgroundColor: _isListening
                                ? Colors.red
                                : Colors.blue,
                            child: Icon(_isListening ? Icons.stop : Icons.mic),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _processWithAI,
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: const Text('Procesar con IA'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

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
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
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
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Guardar Gasto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
