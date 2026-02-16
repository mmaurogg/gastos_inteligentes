import 'dart:convert';

import 'package:gastos_inteligentes/models/movement.dart';

class Income extends Movement {
  Income({
    super.id,
    required super.name,
    required super.category,
    required super.amount,
    required super.date,
    super.type = MovementType.income,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': jsonEncode(category),
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Income{id: $id, name: $name, category: $category, amount: $amount, date: $date}';
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    List<String> categories = [];
    if (map['category'] != null) {
      try {
        final decoded = jsonDecode(map['category']);
        if (decoded is List) {
          categories = List<String>.from(decoded);
        } else if (decoded is String) {
          categories = [decoded];
        }
      } catch (e) {
        // Fallback for old data that might be plain strings
        categories = [map['category'].toString()];
      }
    }

    return Income(
      id: map['id'],
      name: map['name'],
      category: categories,
      amount: map['amount'],
      date: DateTime.parse(map['date']),
    );
  }
}
