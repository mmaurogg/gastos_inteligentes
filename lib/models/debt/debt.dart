class Debt {

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
