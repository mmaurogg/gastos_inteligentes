enum DebtStatus { pending, partiallyPaid, paid, overdue }

class Debt {
  final int? id;

  // Relación
  final int expenseId; // gasto que originó la deuda

  // Montos
  final double originalAmount; // monto total de la deuda
  final double paidAmount; // cuánto se ha pagado
  final double? interestRate; // tasa (mensual o por periodo)
  final double interestAmount; // intereses generados

  // Fechas
  final DateTime createdAt; // fecha de compra
  final DateTime dueDate; // vencimiento
  final DateTime? paidAt; // cuando se saldó

  // Estado
  final DebtStatus status;

  const Debt({
    this.id,
    required this.expenseId,
    required this.originalAmount,
    required this.paidAmount,
    this.interestRate,
    required this.interestAmount,
    required this.createdAt,
    required this.dueDate,
    required this.status,
    this.paidAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expenseId': expenseId,
      'originalAmount': originalAmount,
      'paidAmount': paidAmount,
      'interestRate': interestRate,
      'interestAmount': interestAmount,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'status': status.name,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      expenseId: map['expenseId'],
      originalAmount: map['originalAmount'],
      paidAmount: map['paidAmount'],
      interestRate: map['interestRate'],
      interestAmount: map['interestAmount'],
      createdAt: DateTime.parse(map['createdAt']),
      dueDate: DateTime.parse(map['dueDate']),
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt']) : null,
      status: DebtStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DebtStatus.pending,
      ),
    );
  }
}
