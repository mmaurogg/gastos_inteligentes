import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/speech_service.dart';
import '../services/ai_service.dart';
import '../models/income.dart';
import '../providers/income_provider.dart';
import '../utils/formatters.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gastos_inteligentes/screens/widgets/custom_chip_bar.dart';

class AddIncomeScreen extends StatefulWidget {
  final Income? incomeToEdit;

  const AddIncomeScreen({super.key, this.incomeToEdit});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final SpeechService _speechService = SpeechService();
  AIService? _aiService;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  String textToShow = "Presiona el micrófono para hablar...";
  String? _recognizedTextAI;
  bool _isListening = false;
  bool _isProcessing = false;
  double _cardBottomPosition = 0.0;
  bool _isCardVisible = true;

  String? alertMessage;

  final List<String> _categories = ['Sueldo', 'Regalo', 'Otros'];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    if (widget.incomeToEdit != null) {
      _nameController.text = widget.incomeToEdit!.name;
      _categoryController.text = widget.incomeToEdit!.category;
      _selectedDate = widget.incomeToEdit!.date;
      _amountController.text = NumberFormat.decimalPattern(
        'en_US',
      ).format(widget.incomeToEdit!.amount);
    }
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
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
      _recognizedTextAI = text;
    });
  }

  void _stopRecording() async {
    if (_isListening) {
      await _speechService.stopListening();
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _isListening = false;
        textToShow = _recognizedTextAI!;
      });
    }
  }

  void _processWithAI() async {
    if (_isListening) return;

    if (_recognizedTextAI == null || _recognizedTextAI!.isEmpty) {
      setState(() {
        alertMessage = "Por favor graba o escribe algo primero.";
      });
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    if (_aiService == null) {
      setState(() {
        _isProcessing = false;
        alertMessage = "API Key no configurada. Ve a configuración.";
      });
      return;
    }

    final income = await _aiService!.parseIncomeFromText(_recognizedTextAI!);

    setState(() {
      _isProcessing = false;
    });

    if (!mounted) return;

    if (income != null) {
      _nameController.text = income.name;
      _categoryController.text = income.category;
      _amountController.text = NumberFormat.decimalPattern(
        'en_US',
      ).format(income.amount);

      setState(() {
        alertMessage = "Datos extraídos con éxito!";
      });
    } else {
      setState(() {
        alertMessage = "Error al procesar con IA. Verifica tu API Key.";
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
                final newCategory = newCategoryController.text.trim();
                if (newCategory.isNotEmpty) {
                  setState(() {
                    if (!_categories.contains(newCategory)) {
                      _categories.add(newCategory);
                    }
                    _categoryController.text = newCategory;
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

  void _saveIncome() {
    if (_formKey.currentState!.validate()) {
      // Remove commas before parsing
      final amountText = _amountController.text.replaceAll(',', '');
      final income = Income(
        id: widget.incomeToEdit?.id,
        name: _nameController.text,
        category: _categoryController.text,
        amount: double.parse(amountText),
        date: _selectedDate,
      );

      if (widget.incomeToEdit != null) {
        Provider.of<IncomeProvider>(
          context,
          listen: false,
        ).updateIncome(income);
      } else {
        Provider.of<IncomeProvider>(context, listen: false).addIncome(income);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.incomeToEdit != null ? 'Editar Ingreso' : 'Agregar Ingreso',
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
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Concepto del Ingreso',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.account_balance_wallet),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: CustomChipBar(
                            values: _categories,
                            selectedValue: _categoryController.text,
                            onSelected: (value) {
                              setState(() {
                                _categoryController.text = value;
                              });
                            },
                            //onAdd: _showAddCategoryDialog,
                          ),
                        ),
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
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            ThousandsSeparatorInputFormatter(),
                          ],
                          validator: (value) =>
                              value!.isEmpty ? 'Requerido' : null,
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
                                if (alertMessage != null)
                                  Expanded(
                                    child: Center(child: Text(alertMessage!)),
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
            GestureDetector(
              onTapDown: (_) => _startRecording(),
              onTapUp: (_) => _stopRecording(),
              onTapCancel: () => _stopRecording(),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: _isListening
                    ? Colors.red
                    : Colors.green, // Green for income
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
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: IconButton(
                        onPressed: _saveIncome,
                        icon: const Icon(Icons.save, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 40),
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
