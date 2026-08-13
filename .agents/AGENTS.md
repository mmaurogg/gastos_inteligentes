# Reglas del Agente para Gastos Inteligentes (`AGENTS.md`)

Este archivo define las convenciones de arquitectura, guía de diseño, estructura del código y estándares para la aplicación **Gastos Inteligentes** (Flutter).

---

## 1. Información General del Proyecto

- **Nombre:** Gastos Inteligentes (`gastos_inteligentes`)
- **Tecnología:** Flutter (Dart SDK >= 3.9)
- **Gestión de Estado:** Riverpod (`flutter_riverpod: ^2.5.1`)
- **Persistencia Local:** SQLite (`sqflite: ^2.3.0`) + `shared_preferences`
- **Inteligencia Artificial:** Google Generative AI / Gemini API (`google_generative_ai: ^0.4.0`)
- **Reconocimiento de Voz:** `speech_to_text` / `speech_service.dart` + `permission_handler`

---

## 2. Estructura de Directorios

```
lib/
├── config/         # Ajustes globales, temas y constantes del sistema
├── db/             # Conexión, versiones y migraciones de SQLite (DatabaseHelper)
├── models/         # Modelos de datos inmutables (Expense, Income, Debt, etc.)
│   └── debt/       # Submodelos para deudas, pagos y compras a cuotas
├── providers/      # Contenedores de estado de Riverpod (StateNotifierProvider)
├── screens/        # Vistas de la aplicación (Home, Add Expense, Debts, etc.)
│   └── widgets/    # Componentes y widgets reutilizables de UI
├── services/       # Integraciones externas (AIService, SpeechService, PermissionService)
└── utils/          # Helpers de formato (moneda, fecha, parsing)
```

---

## 3. Principios de Arquitectura y Convenciones

### A. Gestión de Estado (Riverpod)
1. **Providers:** Utilizar `StateNotifierProvider` para gestionar listas de movimientos, deudas, ingresos y gastos.
2. **Desacoplamiento:** Las pantallas UI (`screens/`) no ejecutan SQL ni invocan Gemini directamente; interactúan únicamente a través de Providers o Servicios instanciados.
3. **Refresco de Estado:** Al crear, editar o eliminar registros, los providers deben actualizar su estado interno (`state = await _databaseHelper.get...()`) o notificar inmediatamente a la vista.

### B. Persistencia y Base de Datos (SQLite)
1. **Control de Versiones:** La base de datos local se llama `expenses.db`. Toda modificación de tablas debe incrementar `version` en [database_helper.dart](../../../lib/db/database_helper.dart) y manejarse en `_onUpgrade`.
2. **Modelos:** Cada entidad debe tener métodos `toMap()` y `fromMap(Map<String, dynamic> map)` compatibles con SQLite.
3. **Fechas:** Las fechas se guardan como cadenas ISO 8601 (`date.toIso8601String()`) en la base de datos.

### C. Servicios de Inteligencia Artificial (Gemini)
1. **API Key:** Se almacena en `SharedPreferences` de forma local. Siempre verificar que `_apiKey.isNotEmpty` antes de realizar llamadas a `google_generative_ai`.
2. **Modelo Recomendado:** `gemini-2.5-flash` para obtener respuestas rápidas de baja latencia en procesamiento de texto/voz.
3. **Formato JSON:** Indicar explícitamente en las instrucciones del prompt que la IA debe retornar JSON limpio sin bloques markdown (````json ... ````).

### D. UI y Experiencia de Usuario
1. **Material Design:** Respetar los componentes Material 3.
2. **Idiomas y Formato:** Idioma principal en español. Fechas e importes formateados con la librería `intl` (ejemplo: formateo de moneda local).
3. **Manejo de Errores:** Evitar crasheos en silencio; notificar errores en la UI mediante `SnackBar` o diálogos descriptivos en español.

---

## 4. Skills Disponibles para el Agente

Cuando se trabaje en tareas específicas de este proyecto, utilizar las siguientes habilidades ubicadas en `.agents/skills/`:

1. **`db-migration-helper`**: Para alterar tablas SQLite o crear nuevas entidades sin corrupción de datos.
2. **`gemini-ai-parsing`**: Para agregar o modificar prompts de extracción inteligente de gastos e ingresos.
3. **`riverpod-feature-builder`**: Para implementar módulos completos desde el Modelo hasta las Pantallas UI.
