/// Payment status helpers for student panel
class PaymentStatus {
  final double amount;
  final double paidAmount;
  final DateTime dueDate;
  final bool paid;
  final String? description;

  PaymentStatus({
    required this.amount,
    required this.paidAmount,
    required this.dueDate,
    required this.paid,
    this.description,
  });

  double get remaining => (amount - paidAmount).clamp(0, amount);
  bool get isFullyPaid => paidAmount >= amount;
  bool get isPartial => paidAmount > 0 && paidAmount < amount;
}
