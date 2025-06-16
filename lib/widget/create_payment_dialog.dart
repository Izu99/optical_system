import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../db/payment_helper.dart';

class CreatePaymentDialog extends StatefulWidget {
  final Payment? payment;
  final bool isEdit;
  final Future<bool> Function()? onUpdate;
  const CreatePaymentDialog({super.key, this.payment, this.isEdit = false, this.onUpdate});

  @override
  State<CreatePaymentDialog> createState() => _CreatePaymentDialogState();
}

class _CreatePaymentDialogState extends State<CreatePaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late int _billingId;
  late double _advancePaid;
  late double _balanceAmount;
  late double _totalAmount;
  late double _discount;
  late double _fittingCharges;
  late double _grandTotal;
  String _paymentType = 'Cash';
  bool _isLoading = false;

  final _types = ['Cash', 'Card', 'Online', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.payment != null) {
      _billingId = widget.payment!.billingId;
      _advancePaid = widget.payment!.advancePaid;
      _balanceAmount = widget.payment!.balanceAmount;
      _totalAmount = widget.payment!.totalAmount;
      _discount = widget.payment!.discount;
      _fittingCharges = widget.payment!.fittingCharges;
      _grandTotal = widget.payment!.grandTotal;
      _paymentType = widget.payment!.paymentType;
    } else {
      _billingId = 0;
      _advancePaid = 0;
      _balanceAmount = 0;
      _totalAmount = 0;
      _discount = 0;
      _fittingCharges = 0;
      _grandTotal = 0;
      _paymentType = 'Cash';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      final payment = Payment(
        paymentId: widget.isEdit ? widget.payment!.paymentId : null,
        billingId: _billingId,
        advancePaid: _advancePaid,
        balanceAmount: _balanceAmount,
        totalAmount: _totalAmount,
        discount: _discount,
        fittingCharges: _fittingCharges,
        grandTotal: _grandTotal,
        paymentType: _paymentType,
      );
      if (widget.isEdit) {
        await PaymentHelper.instance.updatePayment(payment);
      } else {
        await PaymentHelper.instance.createPayment(payment);
      }
      if (mounted) {
        Navigator.of(context).pop(payment);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit ? 'Payment updated successfully' : 'Payment created successfully'),
            backgroundColor: widget.isEdit ? Theme.of(context).colorScheme.primary : Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error saving payment'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
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
                    widget.isEdit ? 'Edit Payment' : 'Add Payment',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    initialValue: _billingId.toString(),
                    decoration: const InputDecoration(labelText: 'Bill ID', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _billingId = int.tryParse(v) ?? 0,
                    validator: (v) => (v == null || v.isEmpty) ? 'Bill ID required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _advancePaid.toString(),
                    decoration: const InputDecoration(labelText: 'Advance Paid', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _advancePaid = double.tryParse(v) ?? 0,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _balanceAmount.toString(),
                    decoration: const InputDecoration(labelText: 'Balance Amount', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _balanceAmount = double.tryParse(v) ?? 0,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _totalAmount.toString(),
                    decoration: const InputDecoration(labelText: 'Total Amount', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _totalAmount = double.tryParse(v) ?? 0,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _discount.toString(),
                    decoration: const InputDecoration(labelText: 'Discount', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _discount = double.tryParse(v) ?? 0,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _fittingCharges.toString(),
                    decoration: const InputDecoration(labelText: 'Fitting Charges', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _fittingCharges = double.tryParse(v) ?? 0,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _grandTotal.toString(),
                    decoration: const InputDecoration(labelText: 'Grand Total', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _grandTotal = double.tryParse(v) ?? 0,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _paymentType,
                    decoration: const InputDecoration(labelText: 'Payment Type', border: OutlineInputBorder()),
                    items: _types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (v) => setState(() => _paymentType = v ?? 'Cash'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
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
