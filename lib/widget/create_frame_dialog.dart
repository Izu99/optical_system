import 'package:flutter/material.dart';
import '../models/frame.dart';

class CreateFrameDialog extends StatefulWidget {
  final Frame? frame;
  final bool isEdit;
  final int branchId;
  final int shopId;
  const CreateFrameDialog({Key? key, this.frame, this.isEdit = false, required this.branchId, required this.shopId}) : super(key: key);

  @override
  State<CreateFrameDialog> createState() => _CreateFrameDialogState();
}

class _CreateFrameDialogState extends State<CreateFrameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brandController = TextEditingController();
  late final TextEditingController _sizeController = TextEditingController();
  late final TextEditingController _wholeSalePriceController = TextEditingController();
  late final TextEditingController _colorController = TextEditingController();
  late final TextEditingController _modelController = TextEditingController();
  late final TextEditingController _sellingPriceController = TextEditingController();
  late final TextEditingController _stockController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setControllerText();
  }

  @override
  void didUpdateWidget(covariant CreateFrameDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frame != widget.frame) {
      _setControllerText();
    }
  }

  void _setControllerText() {
    _brandController.text = widget.frame?.brand ?? '';
    _sizeController.text = widget.frame?.size ?? '';
    _wholeSalePriceController.text = widget.frame?.wholeSalePrice.toString() ?? '';
    _colorController.text = widget.frame?.color ?? '';
    _modelController.text = widget.frame?.model ?? '';
    _sellingPriceController.text = widget.frame?.sellingPrice.toString() ?? '';
    _stockController.text = widget.frame?.stock.toString() ?? '';
  }

  @override
  void dispose() {
    _brandController.dispose();
    _sizeController.dispose();
    _wholeSalePriceController.dispose();
    _colorController.dispose();
    _modelController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      final frame = Frame(
        frameId: widget.isEdit ? widget.frame!.frameId : null,
        brand: _brandController.text.trim(),
        size: _sizeController.text.trim(),
        wholeSalePrice: double.tryParse(_wholeSalePriceController.text.trim()) ?? 0.0,
        color: _colorController.text.trim(),
        model: _modelController.text.trim(),
        sellingPrice: double.tryParse(_sellingPriceController.text.trim()) ?? 0.0,
        stock: int.tryParse(_stockController.text.trim()) ?? 0,
        branchId: widget.branchId,
        shopId: widget.shopId,
        imagePath: null,
      );
      Navigator.of(context).pop(frame);
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit ? 'Error updating frame' : 'Error creating frame'),
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
      backgroundColor: Colors.transparent,
      child: Center(
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        widget.isEdit ? 'Edit Frame' : 'Add Frame',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(
                          labelText: 'Brand',
                          prefixIcon: Icon(Icons.label_rounded),
                        ),
                        validator: (value) => _validateRequired(value, 'Brand'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sizeController,
                        decoration: const InputDecoration(
                          labelText: 'Size',
                          prefixIcon: Icon(Icons.straighten_rounded),
                        ),
                        validator: (value) => _validateRequired(value, 'Size'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _wholeSalePriceController,
                        decoration: const InputDecoration(
                          labelText: 'Wholesale Price',
                          prefixIcon: Icon(Icons.attach_money_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateRequired(value, 'Wholesale Price'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _colorController,
                        decoration: const InputDecoration(
                          labelText: 'Color',
                          prefixIcon: Icon(Icons.color_lens_rounded),
                        ),
                        validator: (value) => _validateRequired(value, 'Color'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: 'Model',
                          prefixIcon: Icon(Icons.qr_code_rounded),
                        ),
                        validator: (value) => _validateRequired(value, 'Model'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sellingPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Selling Price',
                          prefixIcon: Icon(Icons.price_check_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateRequired(value, 'Selling Price'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(
                          labelText: 'Stock',
                          prefixIcon: Icon(Icons.confirmation_number_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateRequired(value, 'Stock'),
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
            ],
          ),
        ),
      ),
    );
  }
}
