---
name: db-migration-helper
description: Guía paso a paso para realizar migraciones de SQLite, modificar tablas o agregar nuevas columnas en database_helper.dart y sincronizar modelos y providers.
---

# Skill: Database Migration Helper (`db-migration-helper`)

Esta habilidad debe activarse cuando se necesite modificar el esquema de la base de datos SQLite (`expenses.db`), agregar campos a tablas existentes o crear nuevas entidades.

---

## Procedimiento Estándar de Migración

### 1. Incrementar Versión de la Base de Datos
En [database_helper.dart](../../../lib/db/database_helper.dart):

- Localiza la propiedad `version` dentro del método `_initDatabase()`.
- Incremente el número de versión (ejemplo: cambiar de `version: 6` a `version: 7`).

```dart
Future<Database> _initDatabase() async {
  String path = join(await getDatabasesPath(), 'expenses.db');
  return await openDatabase(
    path,
    version: 7, // <--- Incrementar versión
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );
}
```

---

### 2. Implementar la Migración en `_onUpgrade`
Agrega un bloque condicional en `_onUpgrade` para aplicar los cambios de manera incremental sin afectar los datos previos de los usuarios.

#### Ejemplo A: Agregar una columna nueva
```dart
if (oldVersion < 7) {
  await db.execute('ALTER TABLE expenses ADD COLUMN notes TEXT');
}
```

#### Ejemplo B: Crear una nueva tabla
```dart
if (oldVersion < 7) {
  await db.execute('''
    CREATE TABLE categories(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      color TEXT
    )
  ''');
}
```

---

### 3. Actualizar `_onCreate`
Asegúrate de que la función `_onCreate` cree la tabla completa con el esquema actualizado para instalaciones nuevas de la app.

---

### 4. Sincronizar el Modelo (Data Object)
Actualiza el modelo correspondiente en `lib/models/`:
- Agrega la nueva propiedad al constructor y a la lista de atributos.
- Actualiza el método `toMap()` para incluir la nueva columna.
- Actualiza el constructor/factory `fromMap(Map<String, dynamic> map)` para deserializar el nuevo campo con fallback seguro.

```dart
factory Expense.fromMap(Map<String, dynamic> map) {
  return Expense(
    id: map['id'],
    name: map['name'],
    category: map['category'],
    amount: map['amount'],
    date: DateTime.parse(map['date']),
    notes: map['notes'] ?? '', // Fallback seguro
  );
}
```

---

### 5. Actualizar Consultas en `DatabaseHelper` y Providers
- Actualiza los métodos CRUD (`insertExpense`, `updateExpense`, `getExpenses`) en `DatabaseHelper`.
- Notifica o recarga los datos en el provider correspondiente (`lib/providers/`).
