import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../models/customer.dart';
import '../db/bill_helper.dart';
import '../db/customer_helper.dart';
import '../db/frame_helper.dart';
import '../db/lens_helper.dart';
import '../models/frame.dart';
import '../models/lens.dart';
import '../models/employee.dart';
import '../db/employee_helper.dart';
import '../models/payment.dart';
import '../db/payment_helper.dart';
import '../models/bill_item_edit_state.dart';
import '../models/prescription.dart';
import '../db/prescription_helper.dart';

class CreateBillDialog extends StatefulWidget {
  final Bill? bill;
  final bool isEdit;
  final Future<bool> Function()? onUpdate;
  const CreateBillDialog({super.key, this.bill, this.isEdit = false, this.onUpdate});

  @override
  State<CreateBillDialog> createState() => _CreateBillDialogState();
}

class _CreateBillDialogState extends State<CreateBillDialog> {
  final _formKey = GlobalKey<FormState>();
  Customer? _selectedCustomer;
  DateTime? _invoiceDate;
  DateTime? _deliveryDate;
  String? _invoiceTime;
  String? _deliveryTime;
  List<BillItem> _items = [];
  List<Customer> _customers = [];
  List<Frame> _frames = [];
  List<Lens> _lenses = [];
  List<Employee> _employees = [];
  bool _isLoading = false;

  late final TextEditingController _salesPersonController = TextEditingController();
  late final TextEditingController _invoiceTimeController = TextEditingController();
  late final TextEditingController _deliveryTimeController = TextEditingController();
  final TextEditingController _customerSearchController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerEmailController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _customerAddressController = TextEditingController();

  // Payment fields
  final TextEditingController _advancePaidController = TextEditingController();
  final TextEditingController _balanceAmountController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _fittingChargesController = TextEditingController();
  final TextEditingController _grandTotalController = TextEditingController();
  String _paymentType = 'Cash';
  final List<String> _paymentTypes = ['Cash', 'Card', 'Online', 'Other'];
  Employee? _selectedSalesPerson;

  // Remove old single frame/lens selection state
  // Add a list to track BillItem editing state
  List<BillItemEditState> _billItemStates = [];

  // --- Prescription fields ---
  final TextEditingController _leftPdController = TextEditingController();
  final TextEditingController _rightPdController = TextEditingController();
  final TextEditingController _leftAddController = TextEditingController();
  final TextEditingController _rightAddController = TextEditingController();
  final TextEditingController _leftAxisController = TextEditingController();
  final TextEditingController _rightAxisController = TextEditingController();
  final TextEditingController _leftSphController = TextEditingController();
  final TextEditingController _rightSphController = TextEditingController();
  final TextEditingController _rightCylController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    try {
      final customers = await DatabaseHelper.instance.getAllCustomers();
      final frames = await FrameHelper.instance.getAllFrames();
      final lenses = await LensHelper.instance.getAllLenses();
      final employees = await EmployeeHelper.instance.getAllEmployees();
      setState(() {
        _customers = customers;
        _frames = frames;
        _lenses = lenses;
        _employees = employees;
      });

      // Initialize form data if editing
      if (widget.bill != null) {
        await _initializeEditData();
      } else {
        _initializeNewBillData();
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _initializeEditData() async {
    final bill = widget.bill!;
    // Find and set customer
    final customer = _customers.firstWhere(
      (c) => c.id == bill.customerId,
      orElse: () => Customer(id: 0, name: '', email: '', phoneNumber: '', address: '', createdAt: DateTime.now()),
    );
    // Load bill items
    List<BillItem> billItems = [];
    try {
      billItems = await BillHelper.instance.getBillItems(bill.billingId!);
    } catch (e) {
      print('Error loading bill items: $e');
    }
    // Load payment
    Payment? payment;
    try {
      payment = await PaymentHelper.instance.getPaymentByBillId(bill.billingId!);
    } catch (e) {
      print('Error loading payment: $e');
    }
    // Find and set sales person (by name or email)
    Employee? salesPerson;
    if (bill.salesPerson.isNotEmpty) {
      salesPerson = _employees.firstWhere(
        (e) => (e.name != null && e.name == bill.salesPerson) || e.email == bill.salesPerson,
        orElse: () => _employees.isNotEmpty ? _employees.first : Employee(userId: 0, role: '', branchId: 0, email: '', name: '', phone: '', address: '', imagePath: ''),
      );
    }
    setState(() {
      // Set customer data
      if (customer.id != 0) {
        _selectedCustomer = customer;
        _customerSearchController.text = customer.name;
        _customerNameController.text = customer.name;
        _customerEmailController.text = customer.email;
        _customerPhoneController.text = customer.phoneNumber;
        _customerAddressController.text = customer.address;
      }
      // Set bill data
      _selectedSalesPerson = salesPerson;
      _salesPersonController.text = salesPerson?.name ?? salesPerson?.email ?? '';
      _invoiceDate = bill.invoiceDate;
      _deliveryDate = bill.deliveryDate;
      _invoiceTime = bill.invoiceTime;
      _invoiceTimeController.text = bill.invoiceTime ?? '';
      _deliveryTime = bill.deliveryTime;
      _deliveryTimeController.text = bill.deliveryTime ?? '';
      // Set bill items as edit states
      _billItemStates = billItems.isNotEmpty
        ? billItems.map((item) {
            final frame = _frames.firstWhereOrNull((f) => f.frameId == item.frameId);
            final lens = _lenses.firstWhereOrNull((l) => l.lensId == item.lensId);
            return BillItemEditState(
              frameId: item.frameId,
              lensId: item.lensId,
              frameQuantity: item.frameQuantity ?? 1,
              lensQuantity: item.lensQuantity ?? 1,
              frameBrand: frame?.brand,
              frameSize: frame?.size,
              frameColor: frame?.color,
              lensPower: lens?.power,
              lensCoating: lens?.coating,
              lensCategory: lens?.category,
            );
          }).toList()
        : [BillItemEditState()];
      // Set payment fields
      if (payment != null) {
        _advancePaidController.text = payment.advancePaid.toString();
        _balanceAmountController.text = payment.balanceAmount.toString();
        _totalAmountController.text = payment.totalAmount.toString();
        _discountController.text = payment.discount.toString();
        _fittingChargesController.text = payment.fittingCharges.toString();
        _grandTotalController.text = payment.grandTotal.toString();
        _paymentType = payment.paymentType;
      } else {
        _advancePaidController.text = '';
        _balanceAmountController.text = '';
        _totalAmountController.text = '';
        _discountController.text = '';
        _fittingChargesController.text = '';
        _grandTotalController.text = '';
        _paymentType = 'Cash';
      }
    });

    // Load latest prescription for this customer
    Prescription? latestPrescription;
    try {
      if (customer.id != null) {
        final prescriptions = await PrescriptionHelper.instance.getPrescriptionsByCustomerId(customer.id!);
        if (prescriptions.isNotEmpty) {
          latestPrescription = prescriptions.last;
        }
      }
    } catch (e) {
      print('Error loading prescription: $e');
    }
    if (latestPrescription != null) {
      _leftPdController.text = latestPrescription.leftPd.toString();
      _rightPdController.text = latestPrescription.rightPd.toString();
      _leftAddController.text = latestPrescription.leftAdd?.toString() ?? '';
      _rightAddController.text = latestPrescription.rightAdd?.toString() ?? '';
      _leftAxisController.text = latestPrescription.leftAxis?.toString() ?? '';
      _rightAxisController.text = latestPrescription.rightAxis?.toString() ?? '';
      _leftSphController.text = latestPrescription.leftSph?.toString() ?? '';
      _rightSphController.text = latestPrescription.rightSph?.toString() ?? '';
      _rightCylController.text = latestPrescription.rightCyl?.toString() ?? '';
    }
  }

  void _initializeNewBillData() {
    setState(() {
      _salesPersonController.text = '';
      _invoiceTimeController.text = TimeOfDay.now().format(context);
      _deliveryTimeController.text = TimeOfDay.now().format(context);
      _invoiceDate = DateTime.now();
      _deliveryDate = DateTime.now();
      _billItemStates = [ BillItemEditState() ];
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSalesPerson == null) return; // Ensure sales person is selected
    if (widget.isEdit && widget.onUpdate != null) {
      final confirmed = await widget.onUpdate!();
      if (!confirmed) return;
    }
    setState(() { _isLoading = true; });
    try {
      _invoiceDate ??= DateTime.now();
      _deliveryDate ??= DateTime.now();
      _invoiceTime ??= TimeOfDay.now().format(context);
      _deliveryTime ??= TimeOfDay.now().format(context);
      Customer? customerToUse = _selectedCustomer;
      if (customerToUse == null) {
        final newCustomer = Customer(
          name: _customerNameController.text.trim(),
          email: _customerEmailController.text.trim(),
          phoneNumber: _customerPhoneController.text.trim(),
          address: _customerAddressController.text.trim(),
          createdAt: DateTime.now(),
        );
        final newId = await DatabaseHelper.instance.createCustomer(newCustomer);
        customerToUse = newCustomer.copyWith(id: newId);
      } else {
        // Always update customer with latest form values
        final updatedCustomer = customerToUse.copyWith(
          name: _customerNameController.text.trim(),
          email: _customerEmailController.text.trim(),
          phoneNumber: _customerPhoneController.text.trim(),
          address: _customerAddressController.text.trim(),
        );
        await DatabaseHelper.instance.updateCustomer(updatedCustomer);
        customerToUse = updatedCustomer;
      }
      final bill = Bill(
        billingId: widget.isEdit ? widget.bill!.billingId : null,
        deliveryDate: _deliveryDate,
        invoiceDate: _invoiceDate,
        invoiceTime: _invoiceTime,
        deliveryTime: _deliveryTime,
        salesPerson: _selectedSalesPerson!.name ?? _selectedSalesPerson!.email,
        customerId: customerToUse.id!,
      );
      int billingId;
      if (widget.isEdit) {
        await BillHelper.instance.updateBill(bill);
        billingId = bill.billingId!;
        // Delete old items
        final oldItems = await BillHelper.instance.getBillItems(bill.billingId!);
        for (final old in oldItems) {
          await BillHelper.instance.deleteBillItem(old.billingItemId!);
        }
      } else {
        billingId = await BillHelper.instance.createBill(bill);
      }
      // Add new items from _billItemStates
      _items = _billItemStates.map((e) => e.toBillItem(billingId)).toList();
      for (final item in _items) {
        if ((item.frameId == null && item.lensId == null) || 
            ((item.frameQuantity ?? 0) <= 0 && (item.lensQuantity ?? 0) <= 0)) {
          continue;
        }
        await BillHelper.instance.createBillItem(
          item.copyWith(
            billingId: billingId,
            frameQuantity: item.frameQuantity ?? 0,
            lensQuantity: item.lensQuantity ?? 0,
          ),
        );
      }
      // --- Save or Update Payment to DB ---
      Payment? existingPayment;
      if (widget.isEdit) {
        try {
          existingPayment = await PaymentHelper.instance.getPaymentByBillId(billingId);
        } catch (_) {}
      }
      final payment = Payment(
        paymentId: existingPayment?.paymentId,
        billingId: billingId,
        advancePaid: double.tryParse(_advancePaidController.text) ?? 0,
        balanceAmount: double.tryParse(_balanceAmountController.text) ?? 0,
        totalAmount: double.tryParse(_totalAmountController.text) ?? 0,
        discount: double.tryParse(_discountController.text) ?? 0,
        fittingCharges: double.tryParse(_fittingChargesController.text) ?? 0,
        grandTotal: double.tryParse(_grandTotalController.text) ?? 0,
        paymentType: _paymentType,
      );
      if (widget.isEdit && existingPayment != null) {
        await PaymentHelper.instance.updatePayment(payment);
      } else {
        await PaymentHelper.instance.createPayment(payment);
      }
      // --- After bill item creation, reduce stock ---
      for (final item in _items) {
        if (item.frameId != null && item.frameQuantity != null && item.frameQuantity! > 0) {
          final frame = _frames.firstWhere((f) => f.frameId == item.frameId);
          final updatedFrame = Frame(
            frameId: frame.frameId,
            brand: frame.brand,
            size: frame.size,
            wholeSalePrice: frame.wholeSalePrice,
            color: frame.color,
            model: frame.model,
            sellingPrice: frame.sellingPrice,
            stock: frame.stock - item.frameQuantity!,
            branchId: frame.branchId,
            shopId: frame.shopId,
            imagePath: frame.imagePath,
          );
          await FrameHelper.instance.updateFrame(updatedFrame);
        }
        if (item.lensId != null && item.lensQuantity != null && item.lensQuantity! > 0) {
          final lens = _lenses.firstWhere((l) => l.lensId == item.lensId);
          final updatedLens = Lens(
            lensId: lens.lensId,
            power: lens.power,
            coating: lens.coating,
            category: lens.category,
            cost: lens.cost,
            stock: lens.stock - item.lensQuantity!,
            sellingPrice: lens.sellingPrice,
            branchId: lens.branchId,
            shopId: lens.shopId,
          );
          await LensHelper.instance.updateLens(updatedLens);
        }
      }
      // --- Save prescription if provided ---
      final prescription = Prescription(
        leftPd: double.tryParse(_leftPdController.text) ?? 0,
        rightPd: double.tryParse(_rightPdController.text) ?? 0,
        leftAdd: _leftAddController.text.isNotEmpty ? double.tryParse(_leftAddController.text) : null,
        rightAdd: _rightAddController.text.isNotEmpty ? double.tryParse(_rightAddController.text) : null,
        leftAxis: _leftAxisController.text.isNotEmpty ? double.tryParse(_leftAxisController.text) : null,
        rightAxis: _rightAxisController.text.isNotEmpty ? double.tryParse(_rightAxisController.text) : null,
        leftSph: _leftSphController.text.isNotEmpty ? double.tryParse(_leftSphController.text) : null,
        rightSph: _rightSphController.text.isNotEmpty ? double.tryParse(_rightSphController.text) : null,
        rightCyl: _rightCylController.text.isNotEmpty ? double.tryParse(_rightCylController.text) : null,
        customerId: customerToUse.id!,
        shopId: 1, // TODO: Replace with actual shopId if available
        branchId: 1, // TODO: Replace with actual branchId if available
      );
      await PrescriptionHelper.instance.createPrescription(prescription);
      if (mounted) {
        Navigator.of(context).pop(bill);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit ? 'Bill updated successfully' : 'Bill created successfully'),
            backgroundColor: widget.isEdit ? Theme.of(context).colorScheme.primary : Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving bill/payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit ? 'Error updating bill' : 'Error creating bill'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
          child: Form( 
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    Text(
                      widget.isEdit ? 'Edit Bill' : 'Add Bill',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Customer section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Autocomplete<Customer>(
                          displayStringForOption: (c) => c.name,
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            final q = textEditingValue.text.toLowerCase();
                            final filtered = _customers.where((c) =>
                              c.name.toLowerCase().contains(q) ||
                              c.email.toLowerCase().contains(q) ||
                              c.phoneNumber.toLowerCase().contains(q)
                            ).toList();
                            return filtered.take(4);
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            // Sync with our internal controller
                            if (controller.text != _customerSearchController.text) {
                              controller.text = _customerSearchController.text;
                            }
                            
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: 'Customer Name',
                                border: const OutlineInputBorder(),
                                suffixIcon: controller.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      tooltip: 'Clear',
                                      onPressed: () {
                                        setState(() {
                                          controller.clear();
                                          _customerSearchController.clear();
                                          _selectedCustomer = null;
                                          _customerNameController.clear();
                                          _customerEmailController.clear();
                                          _customerPhoneController.clear();
                                          _customerAddressController.clear();
                                        });
                                      },
                                    )
                                  : null,
                              ),
                              validator: (v) => _validateRequired(v, 'Customer Name'),
                              onChanged: (v) {
                                setState(() {
                                  _customerSearchController.text = v;
                                  _customerNameController.text = v;
                                  
                                  final found = _customers.firstWhere(
                                    (c) => c.name.toLowerCase() == v.toLowerCase(),
                                    orElse: () => Customer(id: 0, name: '', email: '', phoneNumber: '', address: '', createdAt: DateTime.now()),
                                  );
                                  
                                  if (found.id != 0) {
                                    _selectedCustomer = found;
                                    _customerEmailController.text = found.email;
                                    _customerPhoneController.text = found.phoneNumber;
                                    _customerAddressController.text = found.address;
                                  } else {
                                    _selectedCustomer = null;
                                    if (v.isEmpty) {
                                      _customerEmailController.clear();
                                      _customerPhoneController.clear();
                                      _customerAddressController.clear();
                                    }
                                  }
                                });
                              },
                            );
                          },
                          onSelected: (Customer selection) {
                            setState(() {
                              _selectedCustomer = selection;
                              _customerSearchController.text = selection.name;
                              _customerNameController.text = selection.name;
                              _customerEmailController.text = selection.email;
                              _customerPhoneController.text = selection.phoneNumber;
                              _customerAddressController.text = selection.address;
                            });
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                child: SizedBox(
                                  height: 200,
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(option.name),
                                        subtitle: Text(option.phoneNumber),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _customerEmailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _customerPhoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validatePhone,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _customerAddressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => _validateRequired(v, 'Address'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // --- Sales Person Autocomplete ---
                    Autocomplete<Employee>(
                      displayStringForOption: (e) => e.name ?? e.email,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final q = textEditingValue.text.toLowerCase();
                        return _employees.where((e) =>
                          (e.name?.toLowerCase().contains(q) ?? false) ||
                          e.email.toLowerCase().contains(q)
                        ).toList();
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        if (_selectedSalesPerson != null && controller.text != (_selectedSalesPerson!.name ?? _selectedSalesPerson!.email)) {
                          controller.text = _selectedSalesPerson!.name ?? _selectedSalesPerson!.email;
                        }
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Sales Person',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => _selectedSalesPerson == null ? 'Please select a sales person' : null,
                          readOnly: false,
                        );
                      },
                      onSelected: (Employee selection) {
                        setState(() {
                          _selectedSalesPerson = selection;
                        });
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            child: SizedBox(
                              height: 200,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    title: Text(option.name ?? option.email),
                                    subtitle: Text(option.email),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InputDatePickerFormField(
                            initialDate: _invoiceDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            fieldLabelText: 'Invoice Date',
                            onDateSubmitted: (d) => _invoiceDate = d,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InputDatePickerFormField(
                            initialDate: _deliveryDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            fieldLabelText: 'Delivery Date',
                            onDateSubmitted: (d) => _deliveryDate = d,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _invoiceTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Invoice Time',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => _invoiceTime = v,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _deliveryTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Delivery Time',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => _deliveryTime = v,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // --- Prescription Section ---
                    Text('Prescription', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _leftPdController,
                            decoration: const InputDecoration(
                              labelText: 'Left PD',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _rightPdController,
                            decoration: const InputDecoration(
                              labelText: 'Right PD',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _leftAddController,
                            decoration: const InputDecoration(
                              labelText: 'Left Add',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _rightAddController,
                            decoration: const InputDecoration(
                              labelText: 'Right Add',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _leftAxisController,
                            decoration: const InputDecoration(
                              labelText: 'Left Axis',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _rightAxisController,
                            decoration: const InputDecoration(
                              labelText: 'Right Axis',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _leftSphController,
                            decoration: const InputDecoration(
                              labelText: 'Left Sph',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _rightSphController,
                            decoration: const InputDecoration(
                              labelText: 'Right Sph',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _rightCylController,
                            decoration: const InputDecoration(
                              labelText: 'Right Cyl',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // --- Bill Items Section ---
                    Text('Bill Items', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        for (int i = 0; i < _billItemStates.length; i++)
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.03),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text('Item #${i + 1}', style: Theme.of(context).textTheme.bodyMedium),
                                      const Spacer(),
                                      if (_billItemStates.length > 1)
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: 'Remove Item',
                                          onPressed: () {
                                            setState(() {
                                              _billItemStates.removeAt(i);
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                  // Frame selection row
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: DropdownButtonFormField<String>(
                                          value: _billItemStates[i].frameBrand,
                                          decoration: const InputDecoration(labelText: 'Frame Brand', border: OutlineInputBorder()),
                                          items: _frames.map((f) => f.brand).toSet().map((brand) => DropdownMenuItem<String>(value: brand, child: Text(brand))).toList(),
                                          onChanged: (v) {
                                            setState(() {
                                              _billItemStates[i].frameBrand = v;
                                              _billItemStates[i].frameSize = null;
                                              _billItemStates[i].frameColor = null;
                                              _billItemStates[i].frameId = null;
                                            });
                                          },
                                          isExpanded: true,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 2,
                                        child: DropdownButtonFormField<String>(
                                          value: _billItemStates[i].frameSize,
                                          decoration: const InputDecoration(labelText: 'Size', border: OutlineInputBorder()),
                                          items: _frames.where((f) => f.brand == _billItemStates[i].frameBrand).map((f) => f.size).toSet().map((size) => DropdownMenuItem<String>(value: size, child: Text(size))).toList(),
                                          onChanged: _billItemStates[i].frameBrand == null ? null : (v) {
                                            setState(() {
                                              _billItemStates[i].frameSize = v;
                                              _billItemStates[i].frameColor = null;
                                              _billItemStates[i].frameId = null;
                                            });
                                          },
                                          isExpanded: true,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 2,
                                        child: DropdownButtonFormField<String>(
                                          value: _billItemStates[i].frameColor,
                                          decoration: const InputDecoration(labelText: 'Color', border: OutlineInputBorder()),
                                          items: _frames.where((f) => f.brand == _billItemStates[i].frameBrand && f.size == _billItemStates[i].frameSize).map((f) => f.color).toSet().map((color) => DropdownMenuItem<String>(value: color, child: Text(color))).toList(),
                                          onChanged: _billItemStates[i].frameBrand == null || _billItemStates[i].frameSize == null ? null : (v) {
                                            setState(() {
                                              _billItemStates[i].frameColor = v;
                                              final frame = _frames.firstWhereOrNull((f) => f.brand == _billItemStates[i].frameBrand && f.size == _billItemStates[i].frameSize && f.color == v);
                                              _billItemStates[i].frameId = frame?.frameId;
                                            });
                                          },
                                          isExpanded: true,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 60,
                                        child: TextFormField(
                                          enabled: _billItemStates[i].frameId != null,
                                          initialValue: _billItemStates[i].frameQuantity.toString(),
                                          decoration: const InputDecoration(labelText: 'Qty'),
                                          keyboardType: TextInputType.number,
                                          onChanged: (v) {
                                            setState(() {
                                              _billItemStates[i].frameQuantity = int.tryParse(v) ?? 1;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Lens selection row
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: DropdownButtonFormField<String>(
                                          value: _billItemStates[i].lensPower,
                                          decoration: const InputDecoration(labelText: 'Lens Power', border: OutlineInputBorder()),
                                          items: _lenses.map((l) => l.power).toSet().map((power) => DropdownMenuItem<String>(value: power, child: Text(power))).toList(),
                                          onChanged: (v) {
                                            setState(() {
                                              _billItemStates[i].lensPower = v;
                                              _billItemStates[i].lensCoating = null;
                                              _billItemStates[i].lensCategory = null;
                                              _billItemStates[i].lensId = null;
                                            });
                                          },
                                          isExpanded: true,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 2,
                                        child: DropdownButtonFormField<String>(
                                          value: _billItemStates[i].lensCoating,
                                          decoration: const InputDecoration(labelText: 'Coating', border: OutlineInputBorder()),
                                          items: _lenses.where((l) => l.power == _billItemStates[i].lensPower).map((l) => l.coating).toSet().map((coating) => DropdownMenuItem<String>(value: coating, child: Text(coating))).toList(),
                                          onChanged: _billItemStates[i].lensPower == null ? null : (v) {
                                            setState(() {
                                              _billItemStates[i].lensCoating = v;
                                              _billItemStates[i].lensCategory = null;
                                              _billItemStates[i].lensId = null;
                                            });
                                          },
                                          isExpanded: true,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 2,
                                        child: DropdownButtonFormField<String>(
                                          value: _billItemStates[i].lensCategory,
                                          decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                                          items: _lenses.where((l) => l.power == _billItemStates[i].lensPower && l.coating == _billItemStates[i].lensCoating).map((l) => l.category).toSet().map((cat) => DropdownMenuItem<String>(value: cat, child: Text(cat))).toList(),
                                          onChanged: _billItemStates[i].lensPower == null || _billItemStates[i].lensCoating == null ? null : (v) {
                                            setState(() {
                                              _billItemStates[i].lensCategory = v;
                                              final lens = _lenses.firstWhereOrNull((l) => l.power == _billItemStates[i].lensPower && l.coating == _billItemStates[i].lensCoating && l.category == v);
                                              _billItemStates[i].lensId = lens?.lensId;
                                            });
                                          },
                                          isExpanded: true,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 60,
                                        child: TextFormField(
                                          enabled: _billItemStates[i].lensId != null,
                                          initialValue: _billItemStates[i].lensQuantity.toString(),
                                          decoration: const InputDecoration(labelText: 'Qty'),
                                          keyboardType: TextInputType.number,
                                          onChanged: (v) {
                                            setState(() {
                                              _billItemStates[i].lensQuantity = int.tryParse(v) ?? 1;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add Frame/Lens Item'),
                              onPressed: () {
                                setState(() {
                                  _billItemStates.add(BillItemEditState());
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Payment section
                    Text('Payment Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _paymentType,
                      decoration: const InputDecoration(
                        labelText: 'Payment Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _paymentTypes.map((type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      )).toList(),
                      onChanged: (v) {
                        setState(() {
                          _paymentType = v!;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _advancePaidController,
                      decoration: const InputDecoration(
                        labelText: 'Advance Paid',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _balanceAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Balance Amount',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _totalAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Total Amount',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _discountController,
                      decoration: const InputDecoration(
                        labelText: 'Discount',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fittingChargesController,
                      decoration: const InputDecoration(
                        labelText: 'Fitting Charges',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _grandTotalController,
                      decoration: const InputDecoration(
                        labelText: 'Grand Total',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
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
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(widget.isEdit ? 'Update Bill' : 'Create Bill'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _salesPersonController.dispose();
    _invoiceTimeController.dispose();
    _deliveryTimeController.dispose();
    _customerSearchController.dispose();
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    _advancePaidController.dispose();
    _balanceAmountController.dispose();
    _totalAmountController.dispose();
    _discountController.dispose();
    _fittingChargesController.dispose();
    _grandTotalController.dispose();
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
}
