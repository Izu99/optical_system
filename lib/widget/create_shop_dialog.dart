// This file is now obsolete. Shop creation is handled automatically and only a single shop is supported.
// This file is kept for reference but is not used anywhere in the app.

import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../db/shop_helper.dart';
import 'custom_dialog_top_bar.dart';

class CreateShopDialog extends StatefulWidget {
  final Shop? shop;
  final bool isEdit;
  const CreateShopDialog({super.key, this.shop, this.isEdit = false});

  @override
  State<CreateShopDialog> createState() => _CreateShopDialogState();
}

class _CreateShopDialogState extends State<CreateShopDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController = TextEditingController();
  late final TextEditingController _contactController = TextEditingController();
  late final TextEditingController _emailController = TextEditingController();
  late final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setControllerText();
  }

  @override
  void didUpdateWidget(covariant CreateShopDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shop != widget.shop) {
      _setControllerText();
    }
  }

  void _setControllerText() {
    _nameController.text = widget.shop?.name ?? '';
    _contactController.text = widget.shop?.contactNumber ?? '';
    _emailController.text = widget.shop?.email ?? '';
    _addressController.text = widget.shop?.headofficeAddress ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      final shop = Shop(
        shopId: widget.isEdit ? widget.shop!.shopId : null,
        name: _nameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        email: _emailController.text.trim(),
        headofficeAddress: _addressController.text.trim(),
      );
      if (widget.isEdit) {
        await ShopHelper.instance.updateShop(shop);
      } else {
        await ShopHelper.instance.createShop(shop);
      }
      if (mounted) {
        Navigator.of(context).pop(shop);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit ? 'Shop updated successfully' : '${shop.name} created successfully'),
            backgroundColor: widget.isEdit ? Theme.of(context).colorScheme.primary : Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      String errorMessage = widget.isEdit ? 'Error updating shop' : 'Error creating shop';
      if (e.toString().contains('UNIQUE constraint failed: shops.email')) {
        errorMessage = 'Email already added';
      }
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

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    // Improved email regex (same as employee registration)
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,} 24').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
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
      child: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.black.withOpacity(0.3),
          ),
          Center(
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
                  // Custom Top Bar
                  CustomDialogTopBar(
                    title: widget.isEdit ? 'Edit Shop' : 'Create Shop',
                    icon: Icons.store_rounded,
                    onClose: () => Navigator.of(context).pop(),
                    onMinimize: null, // Optionally implement minimize logic
                    onMaximize: null, // Optionally implement maximize logic
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    iconColor: Theme.of(context).colorScheme.primary,
                    borderRadius: 20,
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Shop Name',
                                hintText: 'Enter shop name',
                                prefixIcon: Icon(Icons.store_rounded),
                              ),
                              validator: (value) => _validateRequired(value, 'Shop Name'),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _contactController,
                              decoration: const InputDecoration(
                                labelText: 'Contact Number',
                                hintText: 'Enter contact number',
                                prefixIcon: Icon(Icons.phone_rounded),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) => _validateRequired(value, 'Contact Number'),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'Enter email address',
                                prefixIcon: Icon(Icons.email_rounded),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Head Office Address',
                                hintText: 'Enter head office address',
                                prefixIcon: Icon(Icons.location_on_rounded),
                              ),
                              maxLines: 3,
                              validator: (value) => _validateRequired(value, 'Head Office Address'),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
