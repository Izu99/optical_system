class Bill {
  final int? billingId;
  final DateTime? deliveryDate;
  final DateTime? invoiceDate;
  final String? invoiceTime;
  final String? deliveryTime;
  final String salesPerson;
  final int customerId;

  Bill({
    this.billingId,
    this.deliveryDate,
    this.invoiceDate,
    this.invoiceTime,
    this.deliveryTime,
    required this.salesPerson,
    required this.customerId,
  });

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      billingId: map['billing_id'],
      deliveryDate: map['delivery_date'] != null ? DateTime.parse(map['delivery_date']) : null,
      invoiceDate: map['invoice_date'] != null ? DateTime.parse(map['invoice_date']) : null,
      invoiceTime: map['invoice_time'],
      deliveryTime: map['delivery_time'],
      salesPerson: map['sales_person'],
      customerId: map['customer_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'billing_id': billingId,
      'delivery_date': deliveryDate?.toIso8601String(),
      'invoice_date': invoiceDate?.toIso8601String(),
      'invoice_time': invoiceTime,
      'delivery_time': deliveryTime,
      'sales_person': salesPerson,
      'customer_id': customerId,
    };
  }
}
