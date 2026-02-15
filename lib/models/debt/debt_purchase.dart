enum DebtStatus { pending, partiallyPaid, paid, overdue }

class DebtPurchase {
  final int? id;

  // Relación
  int expenseId; // gasto que originó la deuda
  int debtId; // deuda a la que pertenece

  // Montos
  double originalAmount; // monto total de la deuda
  double paidAmount; // cuánto se ha pagado
  double? interestAmount; // intereses generados

  // Fechas
  DateTime createdAt; // fecha de compra
  DateTime? dueDate; // vencimiento
  DateTime? paidAt; // cuando se saldó

  // Estado
  DebtStatus status;

  DebtPurchase({
    this.id,
    required this.expenseId,
    required this.debtId,
    required this.originalAmount,
    required this.paidAmount,
    this.interestAmount,
    required this.createdAt,
    this.dueDate,
    this.paidAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expenseId': expenseId,
      'debtId': debtId,
      'originalAmount': originalAmount,
      'paidAmount': paidAmount,
      'interestAmount': interestAmount,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'status': status.name,
    };
  }

  factory DebtPurchase.fromMap(Map<String, dynamic> map) {
    return DebtPurchase(
      id: map['id'],
      expenseId: map['expenseId'],
      debtId: map['debtId'],
      originalAmount: map['originalAmount'],
      paidAmount: map['paidAmount'],
      interestAmount: map['interestAmount'],
      createdAt: DateTime.parse(map['createdAt']),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt']) : null,
      status: DebtStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DebtStatus.pending,
      ),
    );
  }
}
