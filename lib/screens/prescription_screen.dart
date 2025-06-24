import 'package:flutter/material.dart';
import '../models/prescription.dart';
import '../models/customer.dart';
import '../db/prescription_helper.dart';
import '../db/customer_helper.dart';
import '../widget/pagination.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  List<Prescription> _prescriptions = [];
  List<Prescription> _filteredPrescriptions = [];
  List<Customer> _customers = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  int _currentPage = 0;
  static const int _pageSize = 10;

  int get _totalPages => (_filteredPrescriptions.length / _pageSize).ceil();

  List<Prescription> get _currentPagePrescriptions {
    final start = _currentPage * _pageSize;
    final end = (_currentPage + 1) * _pageSize;
    return _filteredPrescriptions.sublist(
      start,
      end > _filteredPrescriptions.length ? _filteredPrescriptions.length : end,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterPrescriptions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    try {
      final customers = await DatabaseHelper.instance.getAllCustomers();
      final prescriptions = await PrescriptionHelper.instance.getAllPrescriptions();
      setState(() {
        _customers = customers;
        _prescriptions = prescriptions;
        _filteredPrescriptions = prescriptions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filterPrescriptions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPrescriptions = _prescriptions.where((p) {
        final customer = _customers.firstWhere(
          (c) => c.id == p.customerId, 
          orElse: () => Customer(id: 0, name: '', email: '', phoneNumber: '', address: '', createdAt: DateTime.now())
        );
        return customer.name.toLowerCase().contains(query) ||
               customer.email.toLowerCase().contains(query) ||
               customer.phoneNumber.toLowerCase().contains(query);
      }).toList();
      _currentPage = 0;
    });
  }

  Future<void> _showPrescriptionDialog({Prescription? prescription}) async {
    // Check if there are any customers before showing the dialog
    if (_customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add customers first before creating prescriptions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog<Prescription>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PrescriptionDialog(
        customers: _customers,
        prescription: prescription,
        isEdit: prescription != null,
      ),
    );
    if (result != null) {
      await _loadData();
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
                      hintText: 'Search prescriptions by customer name, email, or phone',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showPrescriptionDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Prescription'),
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
                    : _filteredPrescriptions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.assignment,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _prescriptions.isEmpty ? 'No prescriptions yet' : 'No matching prescriptions',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _prescriptions.isEmpty
                                      ? 'Click the Add button to add your first prescription'
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
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Customer',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Left PD',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Right PD',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Left Add',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Right Add',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Left Axis',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Right Axis',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Left Sph',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Right Sph',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Right Cyl',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(width: 100), // Actions column
                                  ],
                                ),
                              ),
                              // Table Body
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _currentPagePrescriptions.length,
                                  itemBuilder: (context, index) {
                                    final p = _currentPagePrescriptions[index];
                                    final serial = _currentPage * _pageSize + index + 1;
                                    final customer = _customers.firstWhere(
                                      (c) => c.id == p.customerId, 
                                      orElse: () => Customer(id: 0, name: 'Unknown Customer', email: '', phoneNumber: '', address: '', createdAt: DateTime.now())
                                    );
                                    return Container(
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
                                              customer.name,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              p.leftPd.toString(),
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              p.rightPd.toString(),
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              p.leftAdd?.toString() ?? '',
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              p.rightAdd?.toString() ?? '',
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              p.leftAxis?.toString() ?? '',
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              p.rightAxis?.toString() ?? '',
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              p.leftSph?.toString() ?? '',
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              p.rightSph?.toString() ?? '',
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              p.rightCyl?.toString() ?? '',
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 100,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  onPressed: () => _showPrescriptionDialog(prescription: p),
                                                  icon: const Icon(Icons.edit_rounded),
                                                  iconSize: 18,
                                                  tooltip: 'Edit',
                                                ),
                                                IconButton(
                                                  onPressed: () async {
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: const Text('Delete Prescription'),
                                                        content: const Text('Are you sure you want to delete this prescription?'),
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
                                                    if (confirm == true) {
                                                      await PrescriptionHelper.instance.deletePrescription(p.prescriptionId!);
                                                      await _loadData();
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('Prescription deleted'), backgroundColor: Colors.red),
                                                        );
                                                      }
                                                    }
                                                  },
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
                                  totalItems: _filteredPrescriptions.length,
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class PrescriptionDialog extends StatefulWidget {
  final List<Customer> customers;
  final Prescription? prescription;
  final bool isEdit;
  const PrescriptionDialog({super.key, required this.customers, this.prescription, this.isEdit = false});

  @override
  State<PrescriptionDialog> createState() => _PrescriptionDialogState();
}

class _PrescriptionDialogState extends State<PrescriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  Customer? _selectedCustomer;
  final TextEditingController _leftPdController = TextEditingController();
  final TextEditingController _rightPdController = TextEditingController();
  final TextEditingController _leftAddController = TextEditingController();
  final TextEditingController _rightAddController = TextEditingController();
  final TextEditingController _leftAxisController = TextEditingController();
  final TextEditingController _rightAxisController = TextEditingController();
  final TextEditingController _leftSphController = TextEditingController();
  final TextEditingController _rightSphController = TextEditingController();
  final TextEditingController _rightCylController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final validCustomers = widget.customers.where((c) => c.id != null && c.name.trim().isNotEmpty).toList();
    if (widget.prescription != null) {
      final foundCustomer = validCustomers.where((c) => c.id == widget.prescription!.customerId).toList();
      _selectedCustomer = foundCustomer.isNotEmpty ? foundCustomer.first : null;
      _leftPdController.text = widget.prescription!.leftPd.toString();
      _rightPdController.text = widget.prescription!.rightPd.toString();
      _leftAddController.text = widget.prescription!.leftAdd?.toString() ?? '';
      _rightAddController.text = widget.prescription!.rightAdd?.toString() ?? '';
      _leftAxisController.text = widget.prescription!.leftAxis?.toString() ?? '';
      _rightAxisController.text = widget.prescription!.rightAxis?.toString() ?? '';
      _leftSphController.text = widget.prescription!.leftSph?.toString() ?? '';
      _rightSphController.text = widget.prescription!.rightSph?.toString() ?? '';
      _rightCylController.text = widget.prescription!.rightCyl?.toString() ?? '';
    } else {
      _selectedCustomer = null; // Do not auto-select any customer
    }
  }

  @override
  void dispose() {
    _leftPdController.dispose();
    _rightPdController.dispose();
    _leftAddController.dispose();
    _rightAddController.dispose();
    _leftAxisController.dispose();
    _rightAxisController.dispose();
    _leftSphController.dispose();
    _rightSphController.dispose();
    _rightCylController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() { _isLoading = true; });
    try {
      final prescription = Prescription(
        prescriptionId: widget.isEdit ? widget.prescription!.prescriptionId : null,
        leftPd: double.tryParse(_leftPdController.text) ?? 0,
        rightPd: double.tryParse(_rightPdController.text) ?? 0,
        leftAdd: _leftAddController.text.isNotEmpty ? double.tryParse(_leftAddController.text) : null,
        rightAdd: _rightAddController.text.isNotEmpty ? double.tryParse(_rightAddController.text) : null,
        leftAxis: _leftAxisController.text.isNotEmpty ? double.tryParse(_leftAxisController.text) : null,
        rightAxis: _rightAxisController.text.isNotEmpty ? double.tryParse(_rightAxisController.text) : null,
        leftSph: _leftSphController.text.isNotEmpty ? double.tryParse(_leftSphController.text) : null,
        rightSph: _rightSphController.text.isNotEmpty ? double.tryParse(_rightSphController.text) : null,
        rightCyl: _rightCylController.text.isNotEmpty ? double.tryParse(_rightCylController.text) : null,
        customerId: _selectedCustomer!.id!,
        shopId: 1, // Replace with actual shopId
        branchId: 1, // Replace with actual branchId
      );
      
      if (widget.isEdit) {
        await PrescriptionHelper.instance.updatePrescription(prescription);
      } else {
        await PrescriptionHelper.instance.createPrescription(prescription);
      }
      
      if (mounted) Navigator.of(context).pop(prescription);
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final validCustomers = widget.customers.where((c) => c.id != null && c.name.trim().isNotEmpty).toList();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isEdit ? 'Edit Prescription' : 'Add Prescription',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<Customer>(
                          value: _selectedCustomer,
                          decoration: const InputDecoration(
                            labelText: 'Customer',
                            border: OutlineInputBorder(),
                          ),
                          items: validCustomers.map((customer) {
                            return DropdownMenuItem<Customer>(
                              value: customer,
                              child: Text(
                                customer.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (Customer? value) {
                            setState(() {
                              _selectedCustomer = value;
                            });
                          },
                          validator: (value) => value == null ? 'Please select a customer' : null,
                          isExpanded: true,
                          hint: const Text('Customer'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _leftPdController,
                                decoration: const InputDecoration(
                                  labelText: 'Left PD',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Required';
                                  if (double.tryParse(value) == null) return 'Invalid number';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _rightPdController,
                                decoration: const InputDecoration(
                                  labelText: 'Right PD',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Required';
                                  if (double.tryParse(value) == null) return 'Invalid number';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _leftAddController,
                                decoration: const InputDecoration(
                                  labelText: 'Left Add',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                // Only validate if not empty
                                validator: (value) {
                                  if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                                    return 'Invalid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _rightAddController,
                                decoration: const InputDecoration(
                                  labelText: 'Right Add',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                // Only validate if not empty
                                validator: (value) {
                                  if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                                    return 'Invalid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _leftAxisController,
                                decoration: const InputDecoration(
                                  labelText: 'Left Axis',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                // Only validate if not empty
                                validator: (value) {
                                  if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                                    return 'Invalid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _rightAxisController,
                                decoration: const InputDecoration(
                                  labelText: 'Right Axis',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                // Only validate if not empty
                                validator: (value) {
                                  if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                                    return 'Invalid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _leftSphController,
                                decoration: const InputDecoration(
                                  labelText: 'Left Sph',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                // Only validate if not empty
                                validator: (value) {
                                  if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                                    return 'Invalid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _rightSphController,
                                decoration: const InputDecoration(
                                  labelText: 'Right Sph',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                                    return 'Invalid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _rightCylController,
                          decoration: const InputDecoration(
                            labelText: 'Right Cyl',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(widget.isEdit ? 'Update' : 'Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}