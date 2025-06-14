class Lens {
  final int? lensId;
  final String brand;
  final String type;
  final double price;
  final int stock;
  final int branchId;
  final int shopId;

  Lens({
    this.lensId,
    required this.brand,
    required this.type,
    required this.price,
    required this.stock,
    required this.branchId,
    required this.shopId,
  });

  factory Lens.fromMap(Map<String, dynamic> map) => Lens(
    lensId: map['lens_id'] as int?,
    brand: map['brand'] as String,
    type: map['type'] as String,
    price: map['price'] is int ? (map['price'] as int).toDouble() : map['price'] as double,
    stock: map['stock'] as int,
    branchId: map['branch_id'] as int,
    shopId: map['shop_id'] as int,
  );

  Map<String, dynamic> toMap() => {
    'lens_id': lensId,
    'brand': brand,
    'type': type,
    'price': price,
    'stock': stock,
    'branch_id': branchId,
    'shop_id': shopId,
  };
}
