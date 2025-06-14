import 'package:flutter/material.dart';
import '../models/branch.dart';
import '../models/shop.dart';
import '../db/branch_helper.dart';
import '../db/shop_helper.dart';

class CreateBranchDialog extends StatefulWidget {
  final Branch? branch;
  final bool isEdit;
  final Future<bool> Function()? onUpdate;
  const CreateBranchDialog({super.key, this.branch, this.isEdit = false, this.onUpdate});

  @override
  State<CreateBranchDialog> createState() => _CreateBranchDialogState();
}

class _CreateBranchDialogState extends State<CreateBranchDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _codeController;
  Shop? _selectedShop;
  List<Shop> _shops = [];
  bool _isLoading = false;
  bool _isLoadingShops = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.branch?.branchName ?? '');
    _contactController = TextEditingController(text: widget.branch?.contactNumber ?? '');
    _codeController = TextEditingController(text: widget.branch?.branchCode ?? '');
    _loadShops();
  }

  Future<void> _loadShops() async {
    try {
      final shops = await ShopHelper.instance.getAllShops();
      setState(() {
        _shops = shops;
        _selectedShop = shops.isNotEmpty ? shops.first : null;
        _isLoadingShops = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingShops = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading shops: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_shops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add a shop first'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      if (widget.isEdit && widget.onUpdate != null) {
        final confirmed = await widget.onUpdate!();
        if (!confirmed) return;
      }
      setState(() { _isLoading = true; });
      try {
        final branch = Branch(
          branchId: widget.isEdit ? widget.branch!.branchId : null,
          branchName: _nameController.text.trim(),
          contactNumber: _contactController.text.trim(),
          branchCode: _codeController.text.trim(),
          shopId: _selectedShop?.shopId ?? _shops.first.shopId!, // Always assign the only shop's id
        );
        if (widget.isEdit) {
          await BranchHelper.instance.updateBranch(branch);
        } else {
          await BranchHelper.instance.createBranch(branch);
        }
        if (mounted) {
          Navigator.of(context).pop(branch);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isEdit ? 'Branch updated successfully' : '${branch.branchName} created successfully'),
              backgroundColor: widget.isEdit ? Theme.of(context).colorScheme.primary : Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() { _isLoading = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isEdit ? 'Error updating branch' : 'Error creating branch'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
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
                    widget.isEdit ? 'Edit Branch' : 'Add Branch',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_isLoadingShops)
                    const Center(child: CircularProgressIndicator())
                  else if (_shops.isEmpty)
                    Center(
                      child: Text(
                        'Please add a shop before creating a branch.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  else ...[
                    if (_shops.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Shop: ${_shops.first.name}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Branch Name',
                        hintText: 'Enter branch name',
                        prefixIcon: Icon(Icons.account_balance_rounded),
                      ),
                      validator: (value) => _validateRequired(value, 'Branch Name'),
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
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Branch Code',
                        hintText: 'Enter branch code',
                        prefixIcon: Icon(Icons.code_rounded),
                      ),
                      validator: (value) => _validateRequired(value, 'Branch Code'),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
