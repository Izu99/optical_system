import '../models/bill_item.dart';

class BillItemEditState {
  int? frameId;
  int? lensId;
  int frameQuantity;
  int lensQuantity;
  String? frameBrand;
  String? frameSize;
  String? frameColor;
  String? lensPower;
  String? lensCoating;
  String? lensCategory;

  BillItemEditState({
    this.frameId,
    this.lensId,
    this.frameQuantity = 1,
    this.lensQuantity = 1,
    this.frameBrand,
    this.frameSize,
    this.frameColor,
    this.lensPower,
    this.lensCoating,
    this.lensCategory,
  });

  BillItem toBillItem(int billingId) => BillItem(
    billingId: billingId,
    frameId: frameId,
    lensId: lensId,
    frameQuantity: frameId != null ? frameQuantity : null,
    lensQuantity: lensId != null ? lensQuantity : null,
  );
}
