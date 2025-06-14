class Customer {
  final int? id;
  final String name;
  final String email;
  final String phoneNumber;
  final String address;
  final DateTime createdAt;

  Customer({
    this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.address,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      address: map['address'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? address,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
