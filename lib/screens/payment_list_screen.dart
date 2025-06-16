import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../db/payment_helper.dart';
import '../widget/create_payment_dialog.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  List<Payment> _payments = [];
  List<Payment> _filteredPayments = [];
  final TextEditingController _searchController = TextEditingController();
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

  List<Widget> _buildPageNumbers() {
    List<Widget> widgets = [];
    if (_totalPages <= 1) return widgets;
    int start = (_currentPage - 2).clamp(0, _totalPages - 1);
    int end = (_currentPage + 2).clamp(0, _totalPages - 1);
    if (start > 0) {
      widgets.add(_pageButton(1, 0));
      if (start > 1) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...'),
        ));
      }
    }
    for (int i = start; i <= end; i++) {
      widgets.add(_pageButton(i + 1, i));
    }
    if (end < _totalPages - 1) {
      if (end < _totalPages - 2) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...'),
        ));
      }
      widgets.add(_pageButton(_totalPages, _totalPages - 1));
    }
    return widgets;
  }

  Widget _pageButton(int label, int pageIndex) {
    final isSelected = _currentPage == pageIndex;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.15) : null,
          side: BorderSide(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
          ),
          minimumSize: const Size(36, 36),
          padding: EdgeInsets.zero,
        ),
        onPressed: isSelected ? null : () => setState(() => _currentPage = pageIndex),
        child: Text(
          label.toString(),
          style: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
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
                            controller: ScrollController(),
                            child: SingleChildScrollView(
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.first_page_rounded),
                  onPressed: _currentPage > 0 ? () => setState(() => _currentPage = 0) : null,
                  tooltip: 'First Page',
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                  tooltip: 'Previous Page',
                ),
                ..._buildPageNumbers(),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _currentPage < _totalPages - 1 ? () => setState(() => _currentPage++) : null,
                  tooltip: 'Next Page',
                ),
                IconButton(
                  icon: const Icon(Icons.last_page_rounded),
                  onPressed: _currentPage < _totalPages - 1 ? () => setState(() => _totalPages > 0 ? _currentPage = _totalPages - 1 : 0) : null,
                  tooltip: 'Last Page',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
