class Payment {
  final int? paymentId;
  final int billingId;
  final double advancePaid;
  final double balanceAmount;
  final double totalAmount;
  final double discount;
  final double fittingCharges;
  final double grandTotal;
  final String paymentType;

  Payment({
    this.paymentId,
    required this.billingId,
    required this.advancePaid,
    required this.balanceAmount,
    required this.totalAmount,
    required this.discount,
    required this.fittingCharges,
    required this.grandTotal,
    required this.paymentType,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      paymentId: map['payment_id'],
      billingId: map['billing_id'],
      advancePaid: (map['advance_paid'] as num).toDouble(),
      balanceAmount: (map['balance_amount'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
      fittingCharges: (map['fitting_charges'] as num).toDouble(),
      grandTotal: (map['grand_total'] as num).toDouble(),
      paymentType: map['payment_type'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'payment_id': paymentId,
      'billing_id': billingId,
      'advance_paid': advancePaid,
      'balance_amount': balanceAmount,
      'total_amount': totalAmount,
      'discount': discount,
      'fitting_charges': fittingCharges,
      'grand_total': grandTotal,
      'payment_type': paymentType,
    };
  }
}
