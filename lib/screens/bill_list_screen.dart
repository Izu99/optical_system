import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../models/customer.dart';
import '../models/bill_item.dart';
import '../db/bill_helper.dart';
import '../db/customer_helper.dart';
import '../widget/create_bill_dialog.dart';
import '../widget/pagination.dart';

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

  final ScrollController _horizontalScrollController = ScrollController();

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
      // No need to set result.invoiceDate or result.deliveryDate here, as Bill is immutable.
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
                        : Column(
                            children: [
                              // Table Header: add more padding to each column for readability
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text('Customer', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text('Sales Person', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text('Invoice Date', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text('Delivery Date', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text('Invoice Time', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text('Delivery Time', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text('Bill Items', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                    const SizedBox(width: 100), // Actions column
                                  ],
                                ),
                              ),
                              // Table Body
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _currentPageBills.length,
                                  itemBuilder: (context, index) {
                                    final bill = _currentPageBills[index];
                                    final serial = _currentPage * _pageSize + index + 1;
                                    return GestureDetector(
                                      onTap: () => _showBillDialog(bill: bill),
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
                                                serial.toString(),
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                _getCustomerName(bill.customerId),
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                bill.salesPerson,
                                                style: Theme.of(context).textTheme.bodyMedium,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                bill.invoiceDate != null
                                                    ? "${bill.invoiceDate!.day.toString().padLeft(2, '0')}-${bill.invoiceDate!.month.toString().padLeft(2, '0')}-${bill.invoiceDate!.year}"
                                                    : '-',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                bill.deliveryDate != null
                                                    ? "${bill.deliveryDate!.day.toString().padLeft(2, '0')}-${bill.deliveryDate!.month.toString().padLeft(2, '0')}-${bill.deliveryDate!.year}"
                                                    : '-',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                bill.invoiceTime ?? '-',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                bill.deliveryTime ?? '-',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: FutureBuilder<List<BillItem>>(
                                                future: BillHelper.instance.getBillItems(bill.billingId!),
                                                builder: (context, snapshot) {
                                                  final items = snapshot.data ?? [];
                                                  if (items.isEmpty) return const Text('-');
                                                  final summary = items.map((item) {
                                                    final frame = item.frameId != null ? 'Frame x${item.frameQuantity ?? 1}' : '';
                                                    final lens = item.lensId != null ? 'Lens x${item.lensQuantity ?? 1}' : '';
                                                    return [frame, lens].where((s) => s.isNotEmpty).join(', ');
                                                  }).join(' | ');
                                                  return Text(summary, overflow: TextOverflow.ellipsis);
                                                },
                                              ),
                                            ),
                                            SizedBox(
                                              width: 100,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit_rounded, size: 18),
                                                    tooltip: 'Edit',
                                                    onPressed: () => _showBillDialog(bill: bill),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_rounded, size: 18),
                                                    color: Colors.red,
                                                    tooltip: 'Delete',
                                                    onPressed: () => _deleteBill(bill),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // Pagination Controls
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: SmartPaginationControls(
                                  currentPage: _currentPage,
                                  totalPages: _totalPages,
                                  totalItems: _filteredBills.length,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
