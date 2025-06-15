class Lens {
  final int? lensId;
  final String power;
  final String coating;
  final String category;
  final double cost;
  final int stock;
  final double sellingPrice;
  final int branchId;
  final int shopId;

  Lens({
    this.lensId,
    required this.power,
    required this.coating,
    required this.category,
    required this.cost,
    required this.stock,
    required this.sellingPrice,
    required this.branchId,
    required this.shopId,
  });

  factory Lens.fromMap(Map<String, dynamic> map) => Lens(
    lensId: map['lens_id'] as int?,
    power: map['power'] as String,
    coating: map['coating'] as String,
    category: map['category'] as String,
    cost: map['cost'] is int ? (map['cost'] as int).toDouble() : map['cost'] as double,
    stock: map['stock'] as int,
    sellingPrice: map['selling_price'] is int ? (map['selling_price'] as int).toDouble() : map['selling_price'] as double,
    branchId: map['branch_id'] as int,
    shopId: map['shop_id'] as int,
  );

  Map<String, dynamic> toMap() => {
    'lens_id': lensId,
    'power': power,
    'coating': coating,
    'category': category,
    'cost': cost,
    'stock': stock,
    'selling_price': sellingPrice,
    'branch_id': branchId,
    'shop_id': shopId,
  };

  int? get id => lensId;
  String get name => '$power $category';
}
