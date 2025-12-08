class Expense {
  final int? id;
  final String name;
  final String category;
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
      'category': category,
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
    return Expense(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
    );
  }
}
