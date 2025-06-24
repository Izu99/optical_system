class Employee {
  final int? userId;
  final String role; // 'manager', 'sales-person', or 'fitter'
  final int branchId;
  final String email;
  final String? name;
  final String? phone;
  final String? address;
  final String? imagePath;

  static const String roleFitter = 'fitter';
  static const String roleSalesPerson = 'sales-person';
  static const String roleManager = 'manager';

  Employee({
    this.userId,
    required this.role,
    required this.branchId,
    required this.email,
    this.name,
    this.phone,
    this.address,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'role': role,
      'branch_id': branchId,
      'email': email,
      'name': name,
      'phone': phone,
      'address': address,
      'image_path': imagePath,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      userId: map['user_id'],
      role: map['role'],
      branchId: map['branch_id'],
      email: map['email'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      imagePath: map['image_path'],
    );
  }

  static String displayRole(String role) {
    switch (role) {
      case roleManager:
        return 'Manager';
      case roleSalesPerson:
        return 'S-P';
      case roleFitter:
        return 'Fitter';
      default:
        return role;
    }
  }
}
