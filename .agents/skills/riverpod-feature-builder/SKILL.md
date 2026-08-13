---
name: riverpod-feature-builder
description: Workflow estandarizado y plantillas para construir nuevas funcionalidades de punta a punta: Modelo -> Base de datos SQLite -> Provider de Riverpod -> Pantallas UI.
---

# Skill: Riverpod Feature Builder (`riverpod-feature-builder`)

Esta habilidad debe usarse como referencia al agregar un nuevo módulo o entidad al sistema (ej. Presupuestos, Categorías, Metas de Ahorro).

---

## Flujo Secuencial de Construcción

```
1. Model (lib/models/)
   ↓
2. Database (lib/db/database_helper.dart)
   ↓
3. Provider (lib/providers/)
   ↓
4. UI Screen / Widgets (lib/screens/)
```

---

## Paso 1: Crear el Modelo (`lib/models/`)

Crear una clase inmutable con soporte para SQLite:

```dart
class Category {
  final int? id;
  final String name;
  final String iconName;

  Category({
    this.id,
    required this.name,
    required this.iconName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'] ?? '',
      iconName: map['iconName'] ?? 'help_outline',
    );
  }
}
```

---

## Paso 2: Integrar en DatabaseHelper (`lib/db/database_helper.dart`)

1. Crear sentencias SQL en `_onCreate` / `_onUpgrade`.
2. Añadir métodos CRUD de operaciones básicas:

```dart
Future<int> insertCategory(Category category) async {
  final db = await database;
  return await db.insert('categories', category.toMap());
}

Future<List<Category>> getCategories() async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query('categories');
  return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
}
```

---

## Paso 3: Crear el Provider Riverpod (`lib/providers/`)

Usar `StateNotifier` y `StateNotifierProvider` para gestionar el estado de la entidad:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/database_helper.dart';
import '../models/category.dart';

class CategoryNotifier extends StateNotifier<List<Category>> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  CategoryNotifier() : super([]) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    final list = await _dbHelper.getCategories();
    state = list;
  }

  Future<void> addCategory(Category category) async {
    await _dbHelper.insertCategory(category);
    await loadCategories();
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  return CategoryNotifier();
});
```

---

## Paso 4: Construir la Pantalla UI (`lib/screens/`)

Extender de `ConsumerWidget` o `ConsumerStatefulWidget` para consumir el estado en la interfaz:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_provider.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final item = categories[index];
          return ListTile(
            title: Text(item.name),
          );
        },
      ),
    );
  }
}
```
