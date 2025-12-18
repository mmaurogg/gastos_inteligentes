import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/speech_service.dart';
import '../services/ai_service.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expenseToEdit;

  const AddExpenseScreen({super.key, this.expenseToEdit});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final SpeechService _speechService = SpeechService();

  AIService? _aiService;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();

  String textToShow = "Presiona el micrófono para hablar...";
  String? _recognizedTextAI;
  bool _isListening = false;
  bool _isProcessing = false;
  double _cardBottomPosition = 0.0;
  bool _isCardVisible = true;

  String? resultMessage;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    if (widget.expenseToEdit != null) {
      _nameController.text = widget.expenseToEdit!.name;
      _categoryController.text = widget.expenseToEdit!.category;
      _amountController.text = widget.expenseToEdit!.amount.toStringAsFixed(0);
    }
  }

  void _initSpeech() async {
    await _speechService.init();
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key');
    if (apiKey != null) {
      _aiService = AIService(apiKey);
    }
    setState(() {});
  }

  void _startRecording() async {
    setState(() {
      _isListening = true;
      _recognizedTextAI = "";
      _isCardVisible = true;
    });
    await _speechService.startListening((text) {
      setState(() {
        _recognizedTextAI = text;
      });
    });
  }

  void _stopRecording() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() {
        _isListening = false;
        textToShow = _recognizedTextAI!;
      });
    }
  }

  void _processWithAI() async {
    if (_recognizedTextAI == null ||
        _recognizedTextAI!.isEmpty ||
        _recognizedTextAI == "Presiona el micrófono para hablar...") {
      setState(() {
        resultMessage = "Por favor graba o escribe algo primero.";
      });
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    if (_aiService == null) {
      setState(() {
        _isProcessing = false;
        resultMessage = "API Key no configurada. Ve a configuración.";
      });
      return;
    }

    final expense = await _aiService!.parseExpenseFromText(_recognizedTextAI!);

    setState(() {
      _isProcessing = false;
    });

    if (!mounted) return;

    if (expense != null) {
      _nameController.text = expense.name;
      _categoryController.text = expense.category;
      _amountController.text = expense.amount.toStringAsFixed(0);

      setState(() {
        resultMessage = "Datos extraídos con éxito!";
      });
    } else {
      setState(() {
        resultMessage = "Error al procesar con IA. Verifica tu API Key.";
      });
    }
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final expense = Expense(
        id: widget.expenseToEdit?.id,
        name: _nameController.text,
        category: _categoryController.text,
        amount: double.parse(_amountController.text),
        date: widget.expenseToEdit?.date ?? DateTime.now(),
      );

      if (widget.expenseToEdit != null) {
        Provider.of<ExpenseProvider>(
          context,
          listen: false,
        ).updateExpense(expense);
      } else {
        Provider.of<ExpenseProvider>(
          context,
          listen: false,
        ).addExpense(expense);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.expenseToEdit != null ? 'Editar Gasto' : 'Agregar Gasto',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
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
                          validator: (value) =>
                              value!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _categoryController,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
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
                          validator: (value) =>
                              value!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                if (_isCardVisible)
                  Positioned(
                    bottom: _cardBottomPosition,
                    left: 16,
                    right: 16,
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) {
                        setState(() {
                          _cardBottomPosition -= details.delta.dy;
                          // Clamp to screen bounds (approximate)
                          if (_cardBottomPosition < 0) _cardBottomPosition = 0;
                          if (_cardBottomPosition >
                              MediaQuery.of(context).size.height - 300) {
                            _cardBottomPosition =
                                MediaQuery.of(context).size.height - 300;
                          }
                        });
                      },
                      child: Card(
                        color: Colors.grey[100],
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (resultMessage != null)
                                  Expanded(
                                    child: Center(child: Text(resultMessage!)),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _isCardVisible = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                right: 16.0,
                                left: 16.0,
                                bottom: 16.0,
                              ),
                              child: Text(
                                textToShow,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        height: 180,
        padding: const EdgeInsets.only(bottom: 50),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Bottom Left: Voice Record
            GestureDetector(
              onTapDown: (_) => _startRecording(),
              onTapUp: (_) => _stopRecording(),
              onTapCancel: () => _stopRecording(),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: _isListening
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Bottom Left: Voice Record

                    // Top Button: Save
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: IconButton(
                        onPressed: _saveExpense,
                        icon: const Icon(Icons.save, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 40),
                    // Bottom Right: AI Process
                    _isProcessing
                        ? CircleAvatar(
                            radius: 30,
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.purple,
                            child: IconButton(
                              onPressed: _processWithAI,
                              icon: const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
