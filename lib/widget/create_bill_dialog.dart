import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../models/customer.dart';
import '../db/bill_helper.dart';
import '../db/customer_helper.dart';
import '../db/frame_helper.dart';
import '../db/lens_helper.dart';
import '../models/frame.dart';
import '../models/lens.dart';

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
  String? _salesPerson;
  DateTime? _invoiceDate;
  DateTime? _deliveryDate;
  String? _invoiceTime;
  String? _deliveryTime;
  List<BillItem> _items = [];
  List<Customer> _customers = [];
  List<Frame> _frames = [];
  List<Lens> _lenses = [];
  bool _isLoading = false;

  late final TextEditingController _salesPersonController = TextEditingController();
  late final TextEditingController _invoiceTimeController = TextEditingController();
  late final TextEditingController _deliveryTimeController = TextEditingController();
  final TextEditingController _customerSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    final customers = await DatabaseHelper.instance.getAllCustomers();
    final frames = await FrameHelper.instance.getAllFrames();
    final lenses = await LensHelper.instance.getAllLenses();
    setState(() {
      _customers = customers;
      _frames = frames;
      _lenses = lenses;
      _isLoading = false;
    });
    if (widget.bill != null) {
      setState(() {
        _selectedCustomer = customers.firstWhere(
          (c) => c.id == widget.bill!.customerId,
          orElse: () => customers.isNotEmpty ? customers.first : Customer(id: 0, name: '', email: '', phoneNumber: '', address: '', createdAt: DateTime.now()),
        );
      });
      final billItems = await BillHelper.instance.getBillItems(widget.bill!.billingId!);
      setState(() {
        _items = billItems;
      });
    } else {
      _salesPersonController.text = '';
      _invoiceTimeController.text = TimeOfDay.now().format(context);
      _deliveryTimeController.text = TimeOfDay.now().format(context);
    }
  }

  Future<void> _addNewCustomerDialog() async {
    final formKey = GlobalKey<FormState>();
    String name = '', email = '', phone = '', address = '';
    bool loading = false;
    final result = await showDialog<Customer>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Add New Customer'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Name'),
                      onChanged: (v) => name = v,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Email'),
                      onChanged: (v) => email = v,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      onChanged: (v) => phone = v,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Address'),
                      onChanged: (v) => address = v,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setState(() => loading = true);
                        final newCustomer = Customer(
                          name: name,
                          email: email,
                          phoneNumber: phone,
                          address: address,
                          createdAt: DateTime.now(),
                        );
                        final id = await DatabaseHelper.instance.createCustomer(newCustomer);
                        final created = newCustomer.copyWith(id: id);
                        setState(() => loading = false);
                        Navigator.of(context).pop(created);
                      },
                child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        _customers.add(result);
        _selectedCustomer = result;
        _customerSearchController.text = result.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCustomer == null) return;
    if (widget.isEdit && widget.onUpdate != null) {
      final confirmed = await widget.onUpdate!();
      if (!confirmed) return;
    }
    setState(() { _isLoading = true; });
    try {
      // Ensure dates and times are set
      _invoiceDate ??= DateTime.now();
      _deliveryDate ??= DateTime.now();
      _invoiceTime ??= TimeOfDay.now().format(context);
      _deliveryTime ??= TimeOfDay.now().format(context);
      final bill = Bill(
        billingId: widget.isEdit ? widget.bill!.billingId : null,
        deliveryDate: _deliveryDate,
        invoiceDate: _invoiceDate,
        invoiceTime: _invoiceTime,
        deliveryTime: _deliveryTime,
        salesPerson: _salesPerson ?? _salesPersonController.text,
        customerId: _selectedCustomer!.id!,
      );
      int billingId;
      if (widget.isEdit) {
        await BillHelper.instance.updateBill(bill);
        billingId = bill.billingId!;
        final oldItems = await BillHelper.instance.getBillItems(bill.billingId!);
        for (final old in oldItems) {
          await BillHelper.instance.deleteBillItem(old.billingItemId!);
        }
      } else {
        billingId = await BillHelper.instance.createBill(bill);
      }
      // Validate and save BillItems
      for (final item in _items) {
        if ((item.frameId == null && item.lensId == null) || ((item.frameQuantity ?? 0) <= 0 && (item.lensQuantity ?? 0) <= 0)) {
          continue; // skip invalid items
        }
        await BillHelper.instance.createBillItem(
          item.copyWith(
            billingId: billingId,
            frameQuantity: item.frameQuantity ?? 0,
            lensQuantity: item.lensQuantity ?? 0,
          ),
        );
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
      setState(() { _isLoading = false; });
      String errorMessage = widget.isEdit ? 'Error updating bill' : 'Error creating bill';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
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
                  Text(
                    widget.isEdit ? 'Edit Bill' : 'Add Bill',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Customer Autocomplete
                  Autocomplete<Customer>(
                    displayStringForOption: (c) => c.name,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return _customers;
                      }
                      return _customers.where((Customer c) {
                        final q = textEditingValue.text.toLowerCase();
                        return c.name.toLowerCase().contains(q) ||
                               c.email.toLowerCase().contains(q) ||
                               c.phoneNumber.toLowerCase().contains(q);
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      _customerSearchController.text = controller.text;
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Customer',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            tooltip: 'Add New Customer',
                            onPressed: _addNewCustomerDialog,
                          ),
                        ),
                        validator: (v) => _selectedCustomer == null ? 'Please select a customer' : null,
                        onChanged: (v) {
                          setState(() {
                            _selectedCustomer = _customers.firstWhere(
                              (c) => c.name.toLowerCase() == v.toLowerCase(),
                              orElse: () => Customer(id: 0, name: '', email: '', phoneNumber: '', address: '', createdAt: DateTime.now()),
                            );
                          });
                        },
                      );
                    },
                    onSelected: (Customer selection) {
                      setState(() {
                        _selectedCustomer = selection;
                        _customerSearchController.text = selection.name;
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _salesPersonController,
                    decoration: const InputDecoration(
                      labelText: 'Sales Person',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _salesPerson = v,
                    validator: (v) => _validateRequired(v, 'Sales Person'),
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
                  Text('Bill Item', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.03),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int>(
                              value: _items.isNotEmpty ? _items[0].frameId : null,
                              decoration: const InputDecoration(
                                labelText: 'Frame',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<int>(value: null, child: Text('None')),
                                ..._frames.map((frame) => DropdownMenuItem<int>(
                                      value: frame.frameId,
                                      child: Text('${frame.brand} (${frame.model})'),
                                    ))
                              ],
                              onChanged: (v) {
                                setState(() {
                                  if (_items.isEmpty) {
                                    _items.add(BillItem(billingId: widget.bill?.billingId ?? 0, frameId: v));
                                  } else {
                                    _items[0] = _items[0].copyWith(frameId: v);
                                  }
                                });
                              },
                              isExpanded: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int>(
                              value: _items.isNotEmpty ? _items[0].lensId : null,
                              decoration: const InputDecoration(
                                labelText: 'Lens',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<int>(value: null, child: Text('None')),
                                ..._lenses.map((lens) => DropdownMenuItem<int>(
                                      value: lens.lensId,
                                      child: Text('${lens.power} ${lens.category}'),
                                    ))
                              ],
                              onChanged: (v) {
                                setState(() {
                                  if (_items.isEmpty) {
                                    _items.add(BillItem(billingId: widget.bill?.billingId ?? 0, lensId: v));
                                  } else {
                                    _items[0] = _items[0].copyWith(lensId: v);
                                  }
                                });
                              },
                              isExpanded: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue: _items.isNotEmpty && _items[0].frameQuantity != null ? _items[0].frameQuantity.toString() : '',
                              decoration: const InputDecoration(
                                labelText: 'Frame Qty',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                setState(() {
                                  if (_items.isEmpty) {
                                    _items.add(BillItem(billingId: widget.bill?.billingId ?? 0, frameQuantity: int.tryParse(v)));
                                  } else {
                                    _items[0] = _items[0].copyWith(frameQuantity: int.tryParse(v));
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue: _items.isNotEmpty && _items[0].lensQuantity != null ? _items[0].lensQuantity.toString() : '',
                              decoration: const InputDecoration(
                                labelText: 'Lens Qty',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                setState(() {
                                  if (_items.isEmpty) {
                                    _items.add(BillItem(billingId: widget.bill?.billingId ?? 0, lensQuantity: int.tryParse(v)));
                                  } else {
                                    _items[0] = _items[0].copyWith(lensQuantity: int.tryParse(v));
                                  }
                                });
                              },
                            ),
                          ),
                        ],
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
        ),
      ),
    );
  }
}
