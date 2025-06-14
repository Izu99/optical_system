class Shop {
  final int? shopId;
  final String name;
  final String contactNumber;
  final String email;
  final String headofficeAddress;

  Shop({
    this.shopId,
    required this.name,
    required this.contactNumber,
    required this.email,
    required this.headofficeAddress,
  });

  Map<String, dynamic> toMap() {
    return {
      'shop_id': shopId,
      'name': name,
      'contact_number': contactNumber,
      'email': email,
      'headoffice_address': headofficeAddress,
    };
  }

  factory Shop.fromMap(Map<String, dynamic> map) {
    return Shop(
      shopId: map['shop_id'],
      name: map['name'],
      contactNumber: map['contact_number'],
      email: map['email'],
      headofficeAddress: map['headoffice_address'],
    );
  }

  Shop copyWith({
    int? shopId,
    String? name,
    String? contactNumber,
    String? email,
    String? headofficeAddress,
  }) {
    return Shop(
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      headofficeAddress: headofficeAddress ?? this.headofficeAddress,
    );
  }
}
