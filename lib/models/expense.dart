import 'dart:convert';

class Expense {
  final int? id;
  final String name;
  final List<String> category;
  final double amount;
  final DateTime date;

  Expense({
    this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.date,
  });

  // Convert a Expense into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': jsonEncode(category),
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  // Implement toString to make it easier to see information about
  // each expense when using the print statement.
  @override
  String toString() {
    return 'Expense{id: $id, name: $name, category: $category, amount: $amount, date: $date}';
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
    );
  }
}
