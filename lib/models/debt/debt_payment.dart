class DebtPayment {
  final int? id;
  final int debtId;
  final double amount;
  final DateTime date;
  final String? paymentMethod;
  final int purchaseId; // qué compra cubre

  const DebtPayment({
    this.id,
    required this.debtId,
    required this.amount,
    required this.date,
    this.paymentMethod,
    required this.purchaseId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debtId': debtId,
      'amount': amount,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'purchaseId': purchaseId,
    };
  }

  factory DebtPayment.fromMap(Map<String, dynamic> map) {
    return DebtPayment(
      id: map['id'],
      debtId: map['debtId'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      paymentMethod: map['paymentMethod'],
      purchaseId: map['purchaseId'],
    );
  }
}
