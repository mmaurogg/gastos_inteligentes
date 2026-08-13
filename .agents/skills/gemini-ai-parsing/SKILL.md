---
name: gemini-ai-parsing
description: Pautas para la interacción con la API de Gemini (google_generative_ai), diseño de prompts para extracción de gastos e ingresos desde texto o voz, y deserialización segura en JSON.
---

# Skill: Gemini AI Parsing (`gemini-ai-parsing`)

Esta habilidad aplica cuando se extiende o ajusta la lógica de procesamiento de lenguaje natural en [ai_service.dart](../../../lib/services/ai_service.dart) para interpretar gastos, ingresos, notas de voz o compras a cuotas.

---

## Patrón de Configuración de Gemini AI

En `AIService`, inicializar el modelo `gemini-2.5-flash` asegurando el chequeo de la API Key:

```dart
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  final String _apiKey;
  late final GenerativeModel _model;

  AIService(this._apiKey) {
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
  }
}
```

---

## Estructura de Prompts e Ingeniería de Instrucciones

Al redactar o modificar prompts de extracción:

1. **Definir formato de salida:** Exigir JSON estricto especificando tipos de datos (`string`, `double`, `int`).
2. **Eliminar formato Markdown:** Incluir siempre la instrucción explicitando:
   `"Responde ÚNICAMENTE con el JSON válido, sin bloques de código markdown."`
3. **Manejo de Limpieza de Cadena:** En la respuesta devuelta por `response.text`, limpiar espacios e intromisiones de bloques ````json ... ```` antes de invocar `jsonDecode`.

```dart
String cleanText = response.text!.trim();
if (cleanText.startsWith('```json')) {
  cleanText = cleanText.replaceAll('```json', '').replaceAll('```', '').trim();
}
```

---

## Ejemplo: Parsing de Transacción Inteligente

```dart
Future<Map<String, dynamic>?> _parseFromText(String prompt) async {
  if (_apiKey.isEmpty) return null;

  try {
    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);

    if (response.text == null) return null;

    String cleanText = response.text!.trim();
    if (cleanText.startsWith('```json')) {
      cleanText = cleanText.replaceAll('```json', '').replaceAll('```', '').trim();
    } else if (cleanText.startsWith('```')) {
      cleanText = cleanText.replaceAll('```', '').trim();
    }

    return jsonDecode(cleanText) as Map<String, dynamic>;
  } catch (e) {
    print('Error en AIService: $e');
    return null;
  }
}
```

---

## Manejo de Excepciones y Caso Borde (Fallback)

- Si la API Key no es válida o está vacía, retornar `null` para que la UI le permita al usuario escribir manualmente o configurar su clave en `api_key_screen.dart`.
- Si el análisis JSON falla por mala estructura, capturar la excepción en un bloque `try/catch` y devolver valores predeterminados seguros (`'Desconocido'`, `0.0`, `DateTime.now()`).
