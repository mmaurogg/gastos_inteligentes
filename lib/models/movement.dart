enum MovementType { income, expense }

abstract class Movement {
  final int? id;
  final MovementType type;
  final String name;
  final List<String> category;
  final double amount;
  final DateTime date;

  Movement({
    this.id,
    required this.type,
    required this.name,
    required this.category,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Movement{id: $id, type: $type, name: $name, category: $category, amount: $amount, date: $date}';
  }
}
