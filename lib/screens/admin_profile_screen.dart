// screens/shop_screen.dart
import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../db/shop_helper.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool _isUpdating = false;
  Shop? _currentShop;

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  Future<void> _loadShop() async {
    setState(() => _isLoading = true);
    try {
      final shop = await ShopHelper.instance.getShop(1); // Pass id 1
      if (shop != null) {
        setState(() {
          _currentShop = shop;
          _isUpdating = true;
          _shopNameController.text = shop.name;
          _ownerNameController.text = ''; // No ownerName in model
          _addressController.text = shop.headofficeAddress;
          _phoneController.text = shop.contactNumber;
          _emailController.text = shop.email;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading shop: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveShop() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final shop = Shop(
        shopId: _currentShop?.shopId,
        name: _shopNameController.text.trim(),
        contactNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        headofficeAddress: _addressController.text.trim(),
      );
      if (_isUpdating) {
        await ShopHelper.instance.updateShop(shop);
        _showSuccessSnackBar('Shop updated successfully!');
      } else {
        final id = await ShopHelper.instance.createShop(shop);
        setState(() {
          _currentShop = shop.copyWith(shopId: id);
          _isUpdating = true;
        });
        _showSuccessSnackBar('Shop created successfully!');
      }
    } catch (e) {
      _showErrorSnackBar('Error saving shop: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Update Shop Details'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Icon(
                              _isUpdating ? Icons.edit : Icons.add_business,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isUpdating ? 'Update Your Shop' : 'Setup Your Shop',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isUpdating 
                                  ? 'Modify your shop information below'
                                  : 'Enter your shop details to get started',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Form Fields
                    TextFormField(
                      controller: _shopNameController,
                      decoration: const InputDecoration(
                        labelText: 'Shop Name',
                        hintText: 'Enter your shop name',
                        prefixIcon: Icon(Icons.store),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Shop name is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _ownerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Owner Name',
                        hintText: 'Enter owner name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        return null; // No ownerName in model, so skip validation
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        hintText: 'Enter shop address',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Address is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Enter phone number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter email address',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Save Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveShop,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isUpdating ? 'Update Shop' : 'Save Shop',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    
                    if (_isUpdating) ...[
                      const SizedBox(height: 16),
                      // Remove createdAt display if not present in Shop model
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}