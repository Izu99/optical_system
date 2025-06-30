import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../theme.dart';
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
  List<BillItem> _billItemStates = [];

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
        ? billItems
        : [BillItem(billingId: bill.billingId!)];
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
      _billItemStates = [ BillItem(billingId: widget.isEdit ? widget.bill!.billingId! : 0) ];
      _advancePaidController.text = '';
      _balanceAmountController.text = '';
      _totalAmountController.text = '';
      _discountController.text = '';
      _fittingChargesController.text = '';
      _grandTotalController.text = '';
    });
  }

  void _autoCalculatePaymentFields() {
    double total = 0;
    for (final state in _billItemStates) {
      // Calculate frame price
      if (state.frameId != null && (state.frameQuantity ?? 0) > 0) {
        final frame = _frames.firstWhereOrNull((f) => f.frameId == state.frameId);
        if (frame != null) {
          total += frame.sellingPrice * (state.frameQuantity ?? 0);
        }
      }
      // Calculate lens price
      if (state.lensId != null && (state.lensQuantity ?? 0) > 0) {
        final lens = _lenses.firstWhereOrNull((l) => l.lensId == state.lensId);
        if (lens != null) {
          total += lens.sellingPrice * (state.lensQuantity ?? 0);
        }
      }
    }
    _totalAmountController.text = total.toStringAsFixed(2);

    // Parse user-entered values (treat empty as 0)
    double discount = double.tryParse(_discountController.text) ?? 0;
    double fitting = double.tryParse(_fittingChargesController.text) ?? 0;
    double advance = double.tryParse(_advancePaidController.text) ?? 0;
    double grandTotal = total - discount + fitting;
    _grandTotalController.text = grandTotal.toStringAsFixed(2);
    double balance = grandTotal - advance;
    _balanceAmountController.text = balance.toStringAsFixed(2);
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
      // --- Prescription logic ---
      int? prescriptionIdToUse;
      if (widget.isEdit && widget.bill?.prescriptionId != null) {
        // Update the prescription linked to this bill
        prescriptionIdToUse = widget.bill!.prescriptionId;
      }
      final prescription = Prescription(
        prescriptionId: prescriptionIdToUse,
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
      if (widget.isEdit && prescriptionIdToUse != null) {
        // Update the existing prescription
        await PrescriptionHelper.instance.updatePrescription(prescription);
      } else {
        // Create a new prescription
        prescriptionIdToUse = await PrescriptionHelper.instance.createPrescription(prescription);
      }
      // --- Bill logic ---
      final bill = Bill(
        billingId: widget.isEdit ? widget.bill!.billingId : null,
        deliveryDate: _deliveryDate,
        invoiceDate: _invoiceDate,
        invoiceTime: _invoiceTime,
        deliveryTime: _deliveryTime,
        salesPerson: _selectedSalesPerson!.name ?? _selectedSalesPerson!.email,
        customerId: customerToUse.id!,
        prescriptionId: prescriptionIdToUse,
      );
      int billingId;
      if (widget.isEdit) {
        await BillHelper.instance.updateBill(bill);
        billingId = bill.billingId!;

        // --- Stock adjustment logic for UPDATE ---
        final oldItems = await BillHelper.instance.getBillItems(bill.billingId!);

        // Calculate old quantities
        final Map<int, int> oldFrameQty = {};
        final Map<int, int> oldLensQty = {};
        for (final old in oldItems) {
          if (old.frameId != null) {
            oldFrameQty[old.frameId!] = (oldFrameQty[old.frameId!] ?? 0) + (old.frameQuantity ?? 0);
          }
          if (old.lensId != null) {
            oldLensQty[old.lensId!] = (oldLensQty[old.lensId!] ?? 0) + (old.lensQuantity ?? 0);
          }
        }

        // Calculate new quantities
        final Map<int, int> newFrameQty = {};
        final Map<int, int> newLensQty = {};
        for (final item in _billItemStates) {
          if (item.frameId != null && (item.frameQuantity ?? 0) > 0) {
            newFrameQty[item.frameId!] = (newFrameQty[item.frameId!] ?? 0) + (item.frameQuantity ?? 0);
          }
          if (item.lensId != null && (item.lensQuantity ?? 0) > 0) {
            newLensQty[item.lensId!] = (newLensQty[item.lensId!] ?? 0) + (item.lensQuantity ?? 0);
          }
        }

        // Adjust frame stock based on difference
        final frameIds = {...oldFrameQty.keys, ...newFrameQty.keys};
        for (final frameId in frameIds) {
          final oldQ = oldFrameQty[frameId] ?? 0;
          final newQ = newFrameQty[frameId] ?? 0;
          final diff = oldQ - newQ;
          if (diff != 0) {
            final frame = _frames.firstWhereOrNull((f) => f.frameId == frameId);
            if (frame != null) {
              final updatedFrame = copyFrameWithStock(frame, frame.stock + diff);
              await FrameHelper.instance.updateFrame(updatedFrame);
              // Update local list for next calculations
              final index = _frames.indexWhere((f) => f.frameId == frameId);
              if (index != -1) {
                _frames[index] = updatedFrame;
              }
            }
          }
        }

        // Adjust lens stock based on difference
        final lensIds = {...oldLensQty.keys, ...newLensQty.keys};
        for (final lensId in lensIds) {
          final oldQ = oldLensQty[lensId] ?? 0;
          final newQ = newLensQty[lensId] ?? 0;
          final diff = oldQ - newQ;
          if (diff != 0) {
            final lens = _lenses.firstWhereOrNull((l) => l.lensId == lensId);
            if (lens != null) {
              final updatedLens = copyLensWithStock(lens, lens.stock + diff);
              await LensHelper.instance.updateLens(updatedLens);
              // Update local list for next calculations
              final index = _lenses.indexWhere((l) => l.lensId == lensId);
              if (index != -1) {
                _lenses[index] = updatedLens;
              }
            }
          }
        }

        // Remove all old bill items
        for (final old in oldItems) {
          await BillHelper.instance.deleteBillItem(old.billingItemId!);
        }
      } else {
        // CREATE new bill
        billingId = await BillHelper.instance.createBill(bill);

        // For NEW bills, reduce stock directly
        for (final item in _billItemStates) {
          if (item.frameId != null && (item.frameQuantity ?? 0) > 0) {
            final frame = _frames.firstWhereOrNull((f) => f.frameId == item.frameId);
            if (frame != null) {
              final updatedFrame = copyFrameWithStock(frame, frame.stock - item.frameQuantity!);
              await FrameHelper.instance.updateFrame(updatedFrame);
              // Update local list
              final index = _frames.indexWhere((f) => f.frameId == item.frameId);
              if (index != -1) {
                _frames[index] = updatedFrame;
              }
            }
          }
          if (item.lensId != null && (item.lensQuantity ?? 0) > 0) {
            final lens = _lenses.firstWhereOrNull((l) => l.lensId == item.lensId);
            if (lens != null) {
              final updatedLens = copyLensWithStock(lens, lens.stock - item.lensQuantity!);
              await LensHelper.instance.updateLens(updatedLens);
              // Update local list
              final index = _lenses.indexWhere((l) => l.lensId == item.lensId);
              if (index != -1) {
                _lenses[index] = updatedLens;
              }
            }
          }
        }
      }
      // Add new items from _billItemStates (for both CREATE and UPDATE)
      _items = _billItemStates;
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
    final pageTheme = Theme.of(context).extension<AppPageTheme>();
    final dialogWidth = 1200.0;
    final sectionPadding = const EdgeInsets.all(16.0);
    final sectionBg = Theme.of(context).colorScheme.surface;
    final sectionRadius = BorderRadius.circular(12);
    final labelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: pageTheme?.dialogRadius ?? BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth),
        child: Padding(
          padding: pageTheme?.dialogPadding ?? const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SizedBox(
              width: dialogWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 48), child: CircularProgressIndicator()))
                  else ...[
                    Text(
                      widget.isEdit ? 'Edit Bill' : 'Add Bill',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // --- Main Grid Layout ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Left Column: Customer + Items ---
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              // Customer Section
                              Container(
                                padding: sectionPadding,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: sectionBg,
                                  borderRadius: sectionRadius,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Customer Details', style: labelStyle),
                                    const SizedBox(height: 8),
                                    // Customer search and auto-fill
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
                                            ), // <-- this closes SizedBox
                                          ), // <-- this closes Material
                                        ); // <-- this closes Align
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
                              ),
                              // Bill Items Section
                              Container(
                                padding: sectionPadding,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: sectionBg,
                                  borderRadius: sectionRadius,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Bill Items', style: labelStyle),
                                    const SizedBox(height: 8),
                                    Column(
                                      children: [
                                        for (int i = 0; i < _billItemStates.length; i++)
                                          _BillItemSelector(
                                            key: ValueKey('bill_item_$i'),
                                            frames: _frames,
                                            lenses: _lenses,
                                            billItem: _billItemStates[i],
                                            onChanged: (updated) {
                                              setState(() {
                                                _billItemStates[i] = updated;
                                                _autoCalculatePaymentFields();
                                              });
                                            },
                                            onRemove: _billItemStates.length > 1
                                                ? () {
                                                    setState(() {
                                                      _billItemStates.removeAt(i);
                                                      _autoCalculatePaymentFields();
                                                    });
                                                  }
                                                : null,
                                          ),
                                        Row(
                                          children: [
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.add),
                                              label: const Text('Add Frame/Lens Item'),
                                              onPressed: () {
                                                setState(() {
                                                  _billItemStates.add(BillItem(billingId: widget.isEdit ? widget.bill!.billingId! : 0));
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // --- Right Column: Prescription + Payment ---
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              // Prescription Section
                              Container(
                                padding: sectionPadding,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: sectionBg,
                                  borderRadius: sectionRadius,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Prescription', style: labelStyle),
                                    const SizedBox(height: 8),
                                    // --- Prescription Grid: 3 fields per row ---
                                    Table(
                                      columnWidths: const {
                                        0: FlexColumnWidth(1),
                                        1: FlexColumnWidth(1),
                                        2: FlexColumnWidth(1),
                                      },
                                      children: [
                                        TableRow(children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: TextFormField(
                                              controller: _leftSphController,
                                              decoration: const InputDecoration(
                                                labelText: 'Left Sph',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: TextInputType.number,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: TextFormField(
                                              controller: _leftAxisController,
                                              decoration: const InputDecoration(
                                                labelText: 'Left Axis',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: TextInputType.number,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: TextFormField(
                                              controller: _leftAddController,
                                              decoration: const InputDecoration(
                                                labelText: 'Left Add',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: TextInputType.number,
                                            ),
                                          ),
                                        ]),
                                        TableRow(children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: TextFormField(
                                              controller: _rightSphController,
                                              decoration: const InputDecoration(
                                                labelText: 'Right Sph',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: TextInputType.number,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: TextFormField(
                                              controller: _rightAxisController,
                                              decoration: const InputDecoration(
                                                labelText: 'Right Axis',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: TextInputType.number,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: TextFormField(
                                              controller: _rightAddController,
                                              decoration: const InputDecoration(
                                                labelText: 'Right Add',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: TextInputType.number,
                                            ),
                                          ),
                                        ]),
                                        TableRow(children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: TextFormField(
                                              controller: _leftPdController,
                                              decoration: const InputDecoration(
                                                labelText: 'Left PD',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: TextInputType.number,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: TextFormField(
                                              controller: _rightPdController,
                                              decoration: const InputDecoration(
                                                labelText: 'Right PD',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: TextInputType.number,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: TextFormField(
                                              controller: _rightCylController,
                                              decoration: const InputDecoration(
                                                labelText: 'Right Cyl',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: TextInputType.number,
                                            ),
                                          ),
                                        ]),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Payment Section
                              Container(
                                padding: sectionPadding,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: sectionBg,
                                  borderRadius: sectionRadius,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Payment Details', style: labelStyle),
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
                                        hintText: '0',
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => setState(_autoCalculatePaymentFields),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _balanceAmountController,
                                      decoration: const InputDecoration(
                                        labelText: 'Balance Amount',
                                        border: OutlineInputBorder(),
                                        hintText: '0',
                                      ),
                                      keyboardType: TextInputType.number,
                                      readOnly: true,
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _totalAmountController,
                                      decoration: const InputDecoration(
                                        labelText: 'Total Amount',
                                        border: OutlineInputBorder(),
                                        hintText: '0',
                                      ),
                                      keyboardType: TextInputType.number,
                                      readOnly: true,
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _discountController,
                                      decoration: const InputDecoration(
                                        labelText: 'Discount',
                                        border: OutlineInputBorder(),
                                        hintText: '0',
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => setState(_autoCalculatePaymentFields),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _fittingChargesController,
                                      decoration: const InputDecoration(
                                        labelText: 'Fitting Charges',
                                        border: OutlineInputBorder(),
                                        hintText: '0',
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => setState(_autoCalculatePaymentFields),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _grandTotalController,
                                      decoration: const InputDecoration(
                                        labelText: 'Grand Total',
                                        border: OutlineInputBorder(),
                                        hintText: '0',
                                      ),
                                      keyboardType: TextInputType.number,
                                      readOnly: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // --- Action Buttons ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(widget.isEdit ? 'Update Bill' : 'Create Bill'),
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

// --- Bill Item Selector Widget ---
class _BillItemSelector extends StatefulWidget {
  final List<Frame> frames;
  final List<Lens> lenses;
  final BillItem billItem;
  final ValueChanged<BillItem> onChanged;
  final VoidCallback? onRemove;
  const _BillItemSelector({Key? key, required this.frames, required this.lenses, required this.billItem, required this.onChanged, this.onRemove}) : super(key: key);

  @override
  State<_BillItemSelector> createState() => _BillItemSelectorState();
}

class _BillItemSelectorState extends State<_BillItemSelector> {
  String? selectedFrameBrand;
  String? selectedFrameSize;
  String? selectedFrameColor;
  String? selectedLensPower;
  String? selectedLensCoating;
  String? selectedLensCategory;
  int? frameQuantity;
  int? lensQuantity;

  @override
  void initState() {
    super.initState();
    // If editing, prefill dropdowns from selected frame/lens
    final frame = widget.billItem.frameId != null ? widget.frames.firstWhereOrNull((f) => f.frameId == widget.billItem.frameId) : null;
    final lens = widget.billItem.lensId != null ? widget.lenses.firstWhereOrNull((l) => l.lensId == widget.billItem.lensId) : null;
    selectedFrameBrand = frame?.brand;
    selectedFrameSize = frame?.size;
    selectedFrameColor = frame?.color;
    selectedLensPower = lens?.power;
    selectedLensCoating = lens?.coating;
    selectedLensCategory = lens?.category;
    frameQuantity = widget.billItem.frameQuantity;
    lensQuantity = widget.billItem.lensQuantity;
  }

  @override
  Widget build(BuildContext context) {
    // Frame dropdowns
    final brands = widget.frames.map((f) => f.brand).toSet().toList();
    final sizes = selectedFrameBrand == null ? <String>[] : widget.frames.where((f) => f.brand == selectedFrameBrand).map((f) => f.size).toSet().toList();
    final colors = (selectedFrameBrand == null || selectedFrameSize == null)
        ? <String>[]
        : widget.frames.where((f) => f.brand == selectedFrameBrand && f.size == selectedFrameSize).map((f) => f.color).toSet().toList();
    // Lens dropdowns
    final powers = widget.lenses.map((l) => l.power).toSet().toList();
    final coatings = selectedLensPower == null ? <String>[] : widget.lenses.where((l) => l.power == selectedLensPower).map((l) => l.coating).toSet().toList();
    final categories = (selectedLensPower == null || selectedLensCoating == null)
        ? <String>[]
        : widget.lenses.where((l) => l.power == selectedLensPower && l.coating == selectedLensCoating).map((l) => l.category).toSet().toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Theme.of(context).colorScheme.primary.withOpacity(0.03),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Text('Item', style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                if (widget.onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Remove Item',
                    onPressed: widget.onRemove,
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
                    value: selectedFrameBrand,
                    decoration: const InputDecoration(labelText: 'Frame Brand', border: OutlineInputBorder()),
                    items: brands.map((brand) => DropdownMenuItem<String>(value: brand, child: Text(brand))).toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedFrameBrand = v;
                        selectedFrameSize = null;
                        selectedFrameColor = null;
                        // Clear frameId
                        widget.onChanged(widget.billItem.copyWith(frameId: null));
                      });
                    },
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: selectedFrameSize,
                    decoration: const InputDecoration(labelText: 'Size', border: OutlineInputBorder()),
                    items: sizes.map((size) => DropdownMenuItem<String>(value: size, child: Text(size))).toList(),
                    onChanged: selectedFrameBrand == null ? null : (v) {
                      setState(() {
                        selectedFrameSize = v;
                        selectedFrameColor = null;
                        widget.onChanged(widget.billItem.copyWith(frameId: null));
                      });
                    },
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: selectedFrameColor,
                    decoration: const InputDecoration(labelText: 'Color', border: OutlineInputBorder()),
                    items: colors.map((color) => DropdownMenuItem<String>(value: color, child: Text(color))).toList(),
                    onChanged: selectedFrameBrand == null || selectedFrameSize == null ? null : (v) {
                      setState(() {
                        selectedFrameColor = v;
                        // Set frameId if all selected
                        final frame = widget.frames.firstWhereOrNull((f) => f.brand == selectedFrameBrand && f.size == selectedFrameSize && f.color == v);
                        int qty = frameQuantity ?? 1;
                        widget.onChanged(widget.billItem.copyWith(frameId: frame?.frameId, frameQuantity: qty));
                      });
                    },
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    enabled: widget.billItem.frameId != null,
                    initialValue: (frameQuantity ?? 1).toString(), // Default to 1 if null
                    decoration: const InputDecoration(labelText: 'Qty'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      setState(() {
                        frameQuantity = int.tryParse(v) ?? 1;
                        widget.onChanged(widget.billItem.copyWith(frameQuantity: frameQuantity));
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
                    value: selectedLensPower,
                    decoration: const InputDecoration(labelText: 'Lens Power', border: OutlineInputBorder()),
                    items: powers.map((power) => DropdownMenuItem<String>(value: power, child: Text(power))).toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedLensPower = v;
                        selectedLensCoating = null;
                        selectedLensCategory = null;
                        widget.onChanged(widget.billItem.copyWith(lensId: null));
                      });
                    },
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: selectedLensCoating,
                    decoration: const InputDecoration(labelText: 'Coating', border: OutlineInputBorder()),
                    items: coatings.map((coating) => DropdownMenuItem<String>(value: coating, child: Text(coating))).toList(),
                    onChanged: selectedLensPower == null ? null : (v) {
                      setState(() {
                        selectedLensCoating = v;
                        selectedLensCategory = null;
                        widget.onChanged(widget.billItem.copyWith(lensId: null));
                      });
                    },
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: selectedLensCategory,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: categories.map((cat) => DropdownMenuItem<String>(value: cat, child: Text(cat))).toList(),
                    onChanged: selectedLensPower == null || selectedLensCoating == null ? null : (v) {
                      setState(() {
                        selectedLensCategory = v;
                        final lens = widget.lenses.firstWhereOrNull((l) => l.power == selectedLensPower && l.coating == selectedLensCoating && l.category == v);
                        int qty = lensQuantity ?? 1;
                        widget.onChanged(widget.billItem.copyWith(lensId: lens?.lensId, lensQuantity: qty));
                      });
                    },
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    enabled: widget.billItem.lensId != null,
                    initialValue: (lensQuantity ?? 1).toString(), // Default to 1 if null
                    decoration: const InputDecoration(labelText: 'Qty'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      setState(() {
                        lensQuantity = int.tryParse(v) ?? 1;
                        widget.onChanged(widget.billItem.copyWith(lensQuantity: lensQuantity));
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
                  ),
      ),
    );
  }
       
}

// Utility: create a copy of Frame with new stock
Frame copyFrameWithStock(Frame frame, int newStock) {
  return Frame(
    frameId: frame.frameId,
    brand: frame.brand,
    size: frame.size,
    wholeSalePrice: frame.wholeSalePrice,
    color: frame.color,
    model: frame.model,
    sellingPrice: frame.sellingPrice,
    stock: newStock,
    branchId: frame.branchId,
    shopId: frame.shopId,
    imagePath: frame.imagePath,
  );
}
// Utility: create a copy of Lens with new stock
Lens copyLensWithStock(Lens lens, int newStock) {
  return Lens(
    lensId: lens.lensId,
    power: lens.power,
    coating: lens.coating,
    category: lens.category,
    cost: lens.cost,
    stock: newStock,
    sellingPrice: lens.sellingPrice,
    branchId: lens.branchId,
    shopId: lens.shopId,
  );
}

// Utility function to restore stock for all items in a bill (for deletion)
Future<void> restoreStockForBill(int billingId) async {
  // Get all bill items for this bill
  final billItems = await BillHelper.instance.getBillItems(billingId);
  // Restore frame stock
  for (final item in billItems) {
    if (item.frameId != null && item.frameQuantity != null && item.frameQuantity! > 0) {
      final frame = await FrameHelper.instance.getFrameById(item.frameId!);
      if (frame != null) {
        final updatedFrame = copyFrameWithStock(frame, frame.stock + item.frameQuantity!);
        await FrameHelper.instance.updateFrame(updatedFrame);
      }
    }
    if (item.lensId != null && item.lensQuantity != null && item.lensQuantity! > 0) {
      final lens = await LensHelper.instance.getLensById(item.lensId!);
      if (lens != null) {
        final updatedLens = copyLensWithStock(lens, lens.stock + item.lensQuantity!);
        await LensHelper.instance.updateLens(updatedLens);
      }
    }
  }
}

// Example usage: Call this before deleting a bill
// await restoreStockForBill(bill.billingId!);
// await BillHelper.instance.deleteBill(bill.billingId!);
