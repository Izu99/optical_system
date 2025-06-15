class BillItem {
  final int? billingItemId;
  final int billingId;
  final int? frameId;
  final int? lensId;
  final int? lensQuantity;
  final int? frameQuantity;

  BillItem({
    this.billingItemId,
    required this.billingId,
    this.frameId,
    this.lensId,
    this.lensQuantity,
    this.frameQuantity,
  });

  BillItem copyWith({
    int? billingItemId,
    int? billingId,
    int? frameId,
    int? lensId,
    int? lensQuantity,
    int? frameQuantity,
  }) {
    return BillItem(
      billingItemId: billingItemId ?? this.billingItemId,
      billingId: billingId ?? this.billingId,
      frameId: frameId ?? this.frameId,
      lensId: lensId ?? this.lensId,
      lensQuantity: lensQuantity ?? this.lensQuantity,
      frameQuantity: frameQuantity ?? this.frameQuantity,
    );
  }

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      billingItemId: map['billing_item_id'],
      billingId: map['billing_id'],
      frameId: map['frame_id'],
      lensId: map['lens_id'],
      lensQuantity: map['lens_quantity'],
      frameQuantity: map['frame_quantity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'billing_item_id': billingItemId,
      'billing_id': billingId,
      'frame_id': frameId,
      'lens_id': lensId,
      'lens_quantity': lensQuantity,
      'frame_quantity': frameQuantity,
    };
  }
}
