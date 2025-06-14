class Prescription {
  final int? prescriptionId;
  final double leftPd;
  final double rightPd;
  final double? rightAdd;
  final double? leftAdd;
  final double? leftAxis;
  final double? leftSph;
  final double? rightAxis;
  final double? rightCyl;
  final double? rightSph;
  final int customerId;
  final int shopId;
  final int branchId;

  Prescription({
    this.prescriptionId,
    required this.leftPd,
    required this.rightPd,
    this.rightAdd,
    this.leftAdd,
    this.leftAxis,
    this.leftSph,
    this.rightAxis,
    this.rightCyl,
    this.rightSph,
    required this.customerId,
    required this.shopId,
    required this.branchId,
  });

  factory Prescription.fromMap(Map<String, dynamic> map) => Prescription(
    prescriptionId: map['prescription_id'],
    leftPd: map['left_pd'],
    rightPd: map['right_pd'],
    rightAdd: map['right_add'],
    leftAdd: map['left_add'],
    leftAxis: map['left_axis'],
    leftSph: map['left_sph'],
    rightAxis: map['right_axis'],
    rightCyl: map['right_cyl'],
    rightSph: map['right_sph'],
    customerId: map['customer_id'],
    shopId: map['shop_id'],
    branchId: map['branch_id'],
  );

  Map<String, dynamic> toMap() => {
    'prescription_id': prescriptionId,
    'left_pd': leftPd,
    'right_pd': rightPd,
    'right_add': rightAdd,
    'left_add': leftAdd,
    'left_axis': leftAxis,
    'left_sph': leftSph,
    'right_axis': rightAxis,
    'right_cyl': rightCyl,
    'right_sph': rightSph,
    'customer_id': customerId,
    'shop_id': shopId,
    'branch_id': branchId,
  };
}
