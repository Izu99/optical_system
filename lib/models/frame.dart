class Frame {
  final int? frameId;
  final String brand;
  final String size;
  final double wholeSalePrice;
  final String color;
  final String model;
  final double sellingPrice;
  final int stock;
  final int branchId;
  final int shopId;
  final String? imagePath; // Local path or URL for the frame image

  Frame({
    this.frameId,
    required this.brand,
    required this.size,
    required this.wholeSalePrice,
    required this.color,
    required this.model,
    required this.sellingPrice,
    required this.stock,
    required this.branchId,
    required this.shopId,
    this.imagePath,
  });

  factory Frame.fromMap(Map<String, dynamic> map) => Frame(
        frameId: map['frame_id'] as int?,
        brand: map['brand'] as String,
        size: map['size'] as String,
        wholeSalePrice: map['whole_sale_price'] is int ? (map['whole_sale_price'] as int).toDouble() : map['whole_sale_price'] as double,
        color: map['color'] as String,
        model: map['model'] as String,
        sellingPrice: map['selling_price'] is int ? (map['selling_price'] as int).toDouble() : map['selling_price'] as double,
        stock: map['stock'] as int,
        branchId: map['branch_id'] as int,
        shopId: map['shop_id'] as int,
        imagePath: map['image_path'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'frame_id': frameId,
        'brand': brand,
        'size': size,
        'whole_sale_price': wholeSalePrice,
        'color': color,
        'model': model,
        'selling_price': sellingPrice,
        'stock': stock,
        'branch_id': branchId,
        'shop_id': shopId,
        'image_path': imagePath,
      };

  int? get id => frameId;
  String get name => '$brand $model';
}
