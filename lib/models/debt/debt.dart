class Debt {
  final int? id;
  final String name;
  final int debtPurchase; // día de corte
  final int paymentDay; // día límite de pago
  final double interestRate; // mensual (ej: 0.03)

  Debt({
    this.id,
    required this.name,
    required this.debtPurchase,
    required this.paymentDay,
    required this.interestRate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'debtPurchase': debtPurchase,
      'paymentDay': paymentDay,
      'interestRate': interestRate,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      name: map['name'],
      debtPurchase: map['debtPurchase'],
      paymentDay: map['paymentDay'],
      interestRate: map['interestRate'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Debt && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
