import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../db/customer_helper.dart';
import '../widget/create_customer_dialog.dart';
import '../widget/pagination.dart'; // Import the new pagination widget

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  int _currentPage = 0;
  static const int _pageSize = 10;

  int get _totalPages => (_filteredCustomers.length / _pageSize).ceil();

  List<Customer> get _currentPageCustomers {
    final start = _currentPage * _pageSize;
    final end = (_currentPage + 1) * _pageSize;
    return _filteredCustomers.sublist(
      start,
      end > _filteredCustomers.length ? _filteredCustomers.length : end,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_filterCustomers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customers = await DatabaseHelper.instance.getAllCustomers();
      setState(() {
        _customers = customers;
        _filteredCustomers = customers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading customers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCustomers = _customers.where((customer) {
        return customer.name.toLowerCase().contains(query) ||
            customer.email.toLowerCase().contains(query) ||
            customer.phoneNumber.toLowerCase().contains(query);
      }).toList();
      _currentPage = 0; // Reset to first page on search
    });
  }

  Future<bool> _showUpdateConfirmationDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Customer'),
        content: const Text('Are you sure you want to update this customer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    return confirm == true;
  }

  Future<void> _showEditCustomerDialog(Customer customer) async {
    final result = await showDialog<Customer>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateCustomerDialog(
        customer: customer,
        isEdit: true,
        onUpdate: () async {
          final confirmed = await _showUpdateConfirmationDialog();
          return confirmed;
        },
      ),
    );
    if (result != null) {
      await _loadCustomers();
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && customer.id != null) {
      try {
        await DatabaseHelper.instance.deleteCustomer(customer.id!);
        await _loadCustomers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${customer.name} deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting customer: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _onPageChanged(int pageIndex) {
    setState(() {
      _currentPage = pageIndex;
    });
  }

  Widget _buildCustomerRow(Customer customer, int index) {
    return GestureDetector(
      onTap: () => _showEditCustomerDialog(customer),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                (_currentPage * _pageSize + index + 1).toString(), // Show row number
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                customer.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                customer.email,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                customer.phoneNumber,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                customer.address,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      _showEditCustomerDialog(customer);
                    },
                    icon: const Icon(Icons.edit_rounded),
                    iconSize: 18,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    onPressed: () => _deleteCustomer(customer),
                    icon: const Icon(Icons.delete_rounded),
                    iconSize: 18,
                    color: Colors.red,
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search customers',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await showDialog<Customer>(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const CreateCustomerDialog(),
                          );
                          if (result != null) {
                            await _loadCustomers();
                          }
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Customer'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                // Customers Table
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Card(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredCustomers.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline_rounded,
                                        size: 64,
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _customers.isEmpty ? 'No customers yet' : 'No matching customers',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _customers.isEmpty 
                                            ? 'Click the Create button to add your first customer'
                                            : 'Try adjusting your search terms',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: [
                                    // Table Header
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 40,
                                            child: Text(
                                              '#',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Name',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Email',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              'Phone Number',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Address',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 100), // Actions column
                                        ],
                                      ),
                                    ),
                                    // Table Body
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: _currentPageCustomers.length,
                                        itemBuilder: (context, index) {
                                          final customer = _currentPageCustomers[index];
                                          return _buildCustomerRow(customer, index);
                                        },
                                      ),
                                    ),
                                    // New Pagination Controls
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: SmartPaginationControls(
  currentPage: _currentPage,
  totalPages: _totalPages,
  totalItems: _filteredCustomers.length,
  itemsPerPage: _pageSize,
  onFirst: _currentPage > 0 ? () => _onPageChanged(0) : null,
  onPrevious: _currentPage > 0 ? () => _onPageChanged(_currentPage - 1) : null,
  onNext: _currentPage < _totalPages - 1 ? () => _onPageChanged(_currentPage + 1) : null,
  onLast: _currentPage < _totalPages - 1 ? () => _onPageChanged(_totalPages - 1) : null,
  onPageSelect: _onPageChanged,
  showItemsInfo: true,
),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}