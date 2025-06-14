class Branch {
  final int? branchId;
  final String branchName;
  final String contactNumber;
  final String branchCode;
  final int shopId;

  Branch({
    this.branchId,
    required this.branchName,
    required this.contactNumber,
    required this.branchCode,
    required this.shopId,
  });

  Map<String, dynamic> toMap() {
    return {
      'branch_id': branchId,
      'branch_name': branchName,
      'contact_number': contactNumber,
      'branch_code': branchCode,
      'shop_id': shopId,
    };
  }

  factory Branch.fromMap(Map<String, dynamic> map) {
    return Branch(
      branchId: map['branch_id'],
      branchName: map['branch_name'],
      contactNumber: map['contact_number'],
      branchCode: map['branch_code'],
      shopId: map['shop_id'],
    );
  }

  Branch copyWith({
    int? branchId,
    String? branchName,
    String? contactNumber,
    String? branchCode,
    int? shopId,
  }) {
    return Branch(
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      contactNumber: contactNumber ?? this.contactNumber,
      branchCode: branchCode ?? this.branchCode,
      shopId: shopId ?? this.shopId,
    );
  }
}
