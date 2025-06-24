import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../db/payment_helper.dart';
import '../widget/create_payment_dialog.dart';
import '../widget/pagination.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  List<Payment> _payments = [];
  List<Payment> _filteredPayments = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  bool _isLoading = true;
  int _currentPage = 0;
  static const int _pageSize = 10;

  int get _totalPages => (_filteredPayments.length / _pageSize).ceil();

  List<Payment> get _currentPagePayments {
    final start = _currentPage * _pageSize;
    final end = (_currentPage + 1) * _pageSize;
    return _filteredPayments.sublist(
      start,
      end > _filteredPayments.length ? _filteredPayments.length : end,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterPayments);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    final payments = await PaymentHelper.instance.getAllPayments();
    setState(() {
      _payments = payments;
      _filteredPayments = payments;
      _isLoading = false;
    });
  }

  void _filterPayments() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPayments = _payments.where((p) {
        return p.paymentType.toLowerCase().contains(query) ||
               p.billingId.toString().contains(query);
      }).toList();
      _currentPage = 0;
    });
  }

  Future<void> _showPaymentDialog({Payment? payment}) async {
    final result = await showDialog<Payment>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreatePaymentDialog(
        payment: payment,
        isEdit: payment != null,
        onUpdate: () async => true,
      ),
    );
    if (result != null) {
      await _loadData();
    }
  }

  Future<void> _deletePayment(Payment payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text('Are you sure you want to delete this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && payment.paymentId != null) {
      await PaymentHelper.instance.deletePayment(payment.paymentId!);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment deleted'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search payments',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _showPaymentDialog();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Payment'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredPayments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.payments_rounded, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  _payments.isEmpty ? 'No payments yet' : 'No matching payments',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _payments.isEmpty ? 'Click the Add button to add your first payment' : 'Try adjusting your search terms',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Scrollbar(
                            thumbVisibility: true,
                            trackVisibility: true,
                            controller: _horizontalScrollController,
                            child: SingleChildScrollView(
                              controller: _horizontalScrollController, // ADD THIS LINE
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                showCheckboxColumn: false,
                                columns: const [
                                  DataColumn(label: Text('#')),
                                  DataColumn(label: Text('Bill ID')),
                                  DataColumn(label: Text('Advance Paid')),
                                  DataColumn(label: Text('Balance')),
                                  DataColumn(label: Text('Total')),
                                  DataColumn(label: Text('Discount')),
                                  DataColumn(label: Text('Fitting')),
                                  DataColumn(label: Text('Grand Total')),
                                  DataColumn(label: Text('Type')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: List<DataRow>.generate(_currentPagePayments.length, (index) {
                                  final payment = _currentPagePayments[index];
                                  final serial = _currentPage * _pageSize + index + 1;
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(serial.toString())),
                                      DataCell(Text(payment.billingId.toString())),
                                      DataCell(Text(payment.advancePaid.toStringAsFixed(2))),
                                      DataCell(Text(payment.balanceAmount.toStringAsFixed(2))),
                                      DataCell(Text(payment.totalAmount.toStringAsFixed(2))),
                                      DataCell(Text(payment.discount.toStringAsFixed(2))),
                                      DataCell(Text(payment.fittingCharges.toStringAsFixed(2))),
                                      DataCell(Text(payment.grandTotal.toStringAsFixed(2))),
                                      DataCell(Text(payment.paymentType)),
                                      DataCell(Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_rounded),
                                            tooltip: 'Edit',
                                            onPressed: () => _showPaymentDialog(payment: payment),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_rounded),
                                            color: Colors.red,
                                            tooltip: 'Delete',
                                            onPressed: () => _deletePayment(payment),
                                          ),
                                        ],
                                      )),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
              ),
            ),
          ),
          // Pagination Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SmartPaginationControls(
              currentPage: _currentPage,
              totalPages: _totalPages,
              totalItems: _filteredPayments.length,
              itemsPerPage: _pageSize,
              onFirst: _currentPage > 0 ? () => setState(() => _currentPage = 0) : null,
              onPrevious: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
              onNext: _currentPage < _totalPages - 1 ? () => setState(() => _currentPage++) : null,
              onLast: _currentPage < _totalPages - 1 ? () => setState(() => _currentPage = _totalPages - 1) : null,
              onPageSelect: (page) => setState(() => _currentPage = page),
              showItemsInfo: true,
            ),
          ),
        ],
      ),
    );
  }
}