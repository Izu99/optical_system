import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../models/customer.dart';
import '../models/bill_item.dart';
import '../db/bill_helper.dart';
import '../db/customer_helper.dart';
import '../widget/create_bill_dialog.dart';

class BillListScreen extends StatefulWidget {
  const BillListScreen({super.key});

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends State<BillListScreen> {
  List<Bill> _bills = [];
  List<Bill> _filteredBills = [];
  List<Customer> _customers = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  int _currentPage = 0;
  static const int _pageSize = 10;

  int get _totalPages => (_filteredBills.length / _pageSize).ceil();

  List<Bill> get _currentPageBills {
    final start = _currentPage * _pageSize;
    final end = (_currentPage + 1) * _pageSize;
    return _filteredBills.sublist(
      start,
      end > _filteredBills.length ? _filteredBills.length : end,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterBills);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    final bills = await BillHelper.instance.getAllBills();
    final customers = await DatabaseHelper.instance.getAllCustomers();
    setState(() {
      _bills = bills;
      _filteredBills = bills;
      _customers = customers;
      _isLoading = false;
    });
  }

  void _filterBills() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBills = _bills.where((bill) {
        final customer = _customers.firstWhere((c) => c.id == bill.customerId, orElse: () => Customer(id: 0, name: '', email: '', phoneNumber: '', address: '', createdAt: DateTime.now()));
        return customer.name.toLowerCase().contains(query) ||
            bill.salesPerson.toLowerCase().contains(query) ||
            (bill.invoiceDate?.toString() ?? '').toLowerCase().contains(query);
      }).toList();
      _currentPage = 0;
    });
  }

  String _getCustomerName(int customerId) {
    final customer = _customers.firstWhere((c) => c.id == customerId, orElse: () => Customer(id: 0, name: 'Unknown', email: '', phoneNumber: '', address: '', createdAt: DateTime.now()));
    return customer.name;
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

  // Helper to show the bill dialog for add/edit
  Future<void> _showBillDialog({Bill? bill}) async {
    final result = await showDialog<Bill>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateBillDialog(
        bill: bill,
        isEdit: bill != null,
        onUpdate: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Update Bill'),
              content: const Text('Are you sure you want to update this bill?'),
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
        },
      ),
    );
    if (result != null) {
      await _loadData();
    }
  }

  Future<void> _deleteBill(Bill bill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bill'),
        content: const Text('Are you sure you want to delete this bill?'),
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
    if (confirm == true && bill.billingId != null) {
      await BillHelper.instance.deleteBill(bill.billingId!);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill deleted'), backgroundColor: Colors.red),
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
                      hintText: 'Search bills',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _showBillDialog();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Bill'),
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
                    : _filteredBills.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_rounded, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  _bills.isEmpty ? 'No bills yet' : 'No matching bills',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _bills.isEmpty ? 'Click the Add button to add your first bill' : 'Try adjusting your search terms',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('#')),
                                DataColumn(label: Text('Customer')),
                                DataColumn(label: Text('Sales Person')),
                                DataColumn(label: Text('Invoice Date')),
                                DataColumn(label: Text('Delivery Date')),
                                DataColumn(label: Text('Invoice Time')),
                                DataColumn(label: Text('Delivery Time')),
                                DataColumn(label: Text('Bill Items')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: List<DataRow>.generate(_currentPageBills.length, (index) {
                                final bill = _currentPageBills[index];
                                final serial = _currentPage * _pageSize + index + 1;
                                return DataRow(
                                  onSelectChanged: (_) => _showBillDialog(bill: bill),
                                  cells: [
                                    DataCell(Text(serial.toString())),
                                    DataCell(Text(_getCustomerName(bill.customerId))),
                                    DataCell(Text(bill.salesPerson)),
                                    DataCell(Text(bill.invoiceDate?.toLocal().toString().split(' ')[0] ?? '-')),
                                    DataCell(Text(bill.deliveryDate?.toLocal().toString().split(' ')[0] ?? '-')),
                                    DataCell(Text(bill.invoiceTime ?? '-')),
                                    DataCell(Text(bill.deliveryTime ?? '-')),
                                    DataCell(
                                      FutureBuilder<List<BillItem>>(
                                        future: BillHelper.instance.getBillItems(bill.billingId!),
                                        builder: (context, snapshot) {
                                          final items = snapshot.data ?? [];
                                          if (items.isEmpty) return const Text('-');
                                          // Summarize items
                                          final summary = items.map((item) {
                                            final frame = item.frameId != null ? 'Frame x${item.frameQuantity ?? 1}' : '';
                                            final lens = item.lensId != null ? 'Lens x${item.lensQuantity ?? 1}' : '';
                                            return [frame, lens].where((s) => s.isNotEmpty).join(', ');
                                          }).join(' | ');
                                          return Text(summary, overflow: TextOverflow.ellipsis);
                                        },
                                      ),
                                    ),
                                    DataCell(Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_rounded),
                                          tooltip: 'Edit',
                                          onPressed: () => _showBillDialog(bill: bill),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_rounded),
                                          color: Colors.red,
                                          tooltip: 'Delete',
                                          onPressed: () => _deleteBill(bill),
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
