import 'dart:convert';

import 'package:gastos_inteligentes/models/movement.dart';

class Expense extends Movement {
  final int? debtId;

  Expense({
    super.id,
    required super.name,
    required super.category,
    required super.amount,
    required super.date,
    super.type = MovementType.expense,
    this.debtId,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': jsonEncode(category),
      'amount': amount,
      'date': date.toIso8601String(),
      'debtId': debtId,
    };
  }

  @override
  String toString() {
    return 'Expense{id: $id, name: $name, category: $category, amount: $amount, date: $date, debtId: $debtId}';
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
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

    return Expense(
      id: map['id'],
      name: map['name'],
      category: categories,
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      debtId: map['debtId'],
    );
  }
}
