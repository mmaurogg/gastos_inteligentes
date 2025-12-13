import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/expense.dart';

class AIService {
  final String _apiKey;
  late final GenerativeModel _model;

  AIService(this._apiKey) {
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
  }

  Future<Expense?> parseExpenseFromText(String text) async {
    if (_apiKey.isEmpty) {
      print('API Key is missing');
      return null;
    }

    final prompt =
        '''
    Analiza el siguiente texto y extrae los detalles del gasto en formato JSON.
    El JSON debe tener las siguientes claves:
    - "name": (string) nombre del producto o servicio.
    - "category": (string) categoría del gasto (ej. Comida, Transporte, Servicios, Varios).
    - "amount": (double) valor numérico del gasto.
    
    Texto: "$text"
    
    Responde ÚNICAMENTE con el JSON válido, sin bloques de código markdown.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      String? responseText = response.text;
      if (responseText == null) return null;

      // Clean up markdown if present (Gemini sometimes adds ```json ... ```)
      responseText = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final Map<String, dynamic> jsonMap = jsonDecode(responseText);

      return Expense(
        name: jsonMap['name'] ?? 'Desconocido',
        category: jsonMap['category'] ?? 'Varios',
        amount: (jsonMap['amount'] is int)
            ? (jsonMap['amount'] as int).toDouble()
            : (jsonMap['amount'] ?? 0.0),
        date: DateTime.now(),
      );
    } catch (e) {
      print('Error parsing expense with AI: $e');
      return null;
    }
  }
}
