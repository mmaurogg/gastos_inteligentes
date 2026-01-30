enum CreditStatus { pending, paid }

class Credit {
  final int? id;
  final double amount;

  Credit({required this.id, required this.amount});
}
