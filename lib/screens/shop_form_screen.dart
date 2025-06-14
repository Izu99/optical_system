import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../db/shop_helper.dart';

class ShopFormScreen extends StatefulWidget {
  final Shop? shop;
  const ShopFormScreen({super.key, this.shop});

  @override
  State<ShopFormScreen> createState() => _ShopFormScreenState();
}

class _ShopFormScreenState extends State<ShopFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  void _loadShop() {
    if (widget.shop != null) {
      nameController.text = widget.shop!.name;
      emailController.text = widget.shop!.email;
      contactController.text = widget.shop!.contactNumber;
      addressController.text = widget.shop!.headofficeAddress;
    }
  }

  Future<void> _saveShop() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      final newShop = Shop(
        shopId: widget.shop?.shopId,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        contactNumber: contactController.text.trim(),
        headofficeAddress: addressController.text.trim(),
      );
      try {
        if (widget.shop == null) {
          await ShopHelper.instance.createShop(newShop);
        } else {
          await ShopHelper.instance.updateShop(newShop);
        }
        setState(() { isLoading = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.shop == null ? 'Shop created!' : 'Shop updated!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to refresh list
        }
      } catch (e) {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 120, vertical: 40),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Shop',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Shop Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final regex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4} $');
                        if (!regex.hasMatch(v)) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: contactController,
                      decoration: const InputDecoration(labelText: 'Contact Number'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Head Office Address'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      icon: Icon(widget.shop == null ? Icons.add_business : Icons.save),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          'Update Shop',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                      ),
                      onPressed: isLoading ? null : _saveShop,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
