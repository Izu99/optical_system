import 'package:flutter/material.dart';

class PaginatedCustomerTable extends StatelessWidget {
  final List<Customer> customers;
  final int rowsPerPage;
  final void Function(Customer)? onRowTap;

  const PaginatedCustomerTable({
    Key? key,
    required this.customers,
    this.rowsPerPage = 10,
    this.onRowTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PaginatedDataTable(
      header: const Text('Customers'),
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('Phone')),
        DataColumn(label: Text('Address')),
        DataColumn(label: Text('Created At')),
      ],
      source: _CustomerDataSource(customers, onRowTap),
      rowsPerPage: rowsPerPage,
      showFirstLastButtons: true,
    );
  }
}

class _CustomerDataSource extends DataTableSource {
  final List<Customer> customers;
  final void Function(Customer)? onRowTap;

  _CustomerDataSource(this.customers, this.onRowTap);

  @override
  DataRow getRow(int index) {
    if (index >= customers.length) return const DataRow(cells: []);
    final customer = customers[index];
    return DataRow(
      cells: [
        DataCell(Text(customer.id?.toString() ?? '')),
        DataCell(Text(customer.name)),
        DataCell(Text(customer.email)),
        DataCell(Text(customer.phoneNumber)),
        DataCell(Text(customer.address)),
        DataCell(Text(customer.createdAt.toString())),
      ],
      onSelectChanged: onRowTap != null ? (_) => onRowTap!(customer) : null,
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => customers.length;
  @override
  int get selectedRowCount => 0;
}

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
