import 'package:flutter/material.dart';
import '../db/lens_helper.dart';
import '../models/lens.dart';

class LensListScreen extends StatefulWidget {
  final int branchId;
  final int shopId;
  const LensListScreen({Key? key, required this.branchId, required this.shopId}) : super(key: key);

  @override
  State<LensListScreen> createState() => _LensListScreenState();
}

class _LensListScreenState extends State<LensListScreen> {
  late Future<List<Lens>> _lensesFuture;

  @override
  void initState() {
    super.initState();
    _lensesFuture = _loadLenses();
  }

  Future<List<Lens>> _loadLenses() async {
    final all = await LensHelper.instance.getAllLenses();
    return all.where((l) => l.branchId == widget.branchId && l.shopId == widget.shopId).toList();
  }

  void _refresh() {
    setState(() {
      _lensesFuture = _loadLenses();
    });
  }

  Future<void> _showCreateOrEditDialog({Lens? lens}) async {
    final result = await showDialog<Lens>(
      context: context,
      builder: (context) => _CreateLensDialog(
        lens: lens,
        isEdit: lens != null,
        branchId: widget.branchId,
        shopId: widget.shopId,
      ),
    );
    if (result != null) {
      if (lens == null) {
        await LensHelper.instance.createLens(result);
      } else {
        await LensHelper.instance.updateLens(result);
      }
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Lenses',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateOrEditDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Lens'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Lens>>(
                future: _lensesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: \\${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No lenses found.'));
                  }
                  final lenses = snapshot.data!;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final table = SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          showCheckboxColumn: false,
                          columns: const [
                            DataColumn(label: Text('Power')),
                            DataColumn(label: Text('Coating')),
                            DataColumn(label: Text('Category')),
                            DataColumn(label: Text('Cost')),
                            DataColumn(label: Text('Stock')),
                            DataColumn(label: Text('Selling Price')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: lenses.map((lens) {
                            return DataRow(
                              onSelectChanged: (_) => _showCreateOrEditDialog(lens: lens),
                              cells: [
                                DataCell(Text(lens.power)),
                                DataCell(Text(lens.coating)),
                                DataCell(Text(lens.category)),
                                DataCell(Text(lens.cost.toString())),
                                DataCell(Text(lens.stock.toString())),
                                DataCell(Text(lens.sellingPrice.toString())),
                                DataCell(Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded),
                                      onPressed: () => _showCreateOrEditDialog(lens: lens),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_rounded),
                                      color: Colors.red,
                                      tooltip: 'Delete',
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete Lens'),
                                            content: const Text('Are you sure you want to delete this lens?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true && lens.lensId != null) {
                                          await LensHelper.instance.deleteLens(lens.lensId!);
                                          _refresh();
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Lens deleted'), backgroundColor: Colors.red),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                        ),
                        child: table,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateLensDialog extends StatefulWidget {
  final Lens? lens;
  final bool isEdit;
  final int branchId;
  final int shopId;
  const _CreateLensDialog({Key? key, this.lens, this.isEdit = false, required this.branchId, required this.shopId}) : super(key: key);

  @override
  State<_CreateLensDialog> createState() => _CreateLensDialogState();
}

class _CreateLensDialogState extends State<_CreateLensDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _powerController = TextEditingController();
  late final TextEditingController _coatingController = TextEditingController();
  late final TextEditingController _categoryController = TextEditingController();
  late final TextEditingController _costController = TextEditingController();
  late final TextEditingController _stockController = TextEditingController();
  late final TextEditingController _sellingPriceController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setControllerText();
  }

  void _setControllerText() {
    _powerController.text = widget.lens?.power ?? '';
    _coatingController.text = widget.lens?.coating ?? '';
    _categoryController.text = widget.lens?.category ?? '';
    _costController.text = widget.lens?.cost.toString() ?? '';
    _stockController.text = widget.lens?.stock.toString() ?? '';
    _sellingPriceController.text = widget.lens?.sellingPrice.toString() ?? '';
  }

  @override
  void dispose() {
    _powerController.dispose();
    _coatingController.dispose();
    _categoryController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      final lens = Lens(
        lensId: widget.isEdit ? widget.lens!.lensId : null,
        power: _powerController.text.trim(),
        coating: _coatingController.text.trim(),
        category: _categoryController.text.trim(),
        cost: double.tryParse(_costController.text.trim()) ?? 0.0,
        stock: int.tryParse(_stockController.text.trim()) ?? 0,
        sellingPrice: double.tryParse(_sellingPriceController.text.trim()) ?? 0.0,
        branchId: widget.branchId,
        shopId: widget.shopId,
      );
      Navigator.of(context).pop(lens);
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit ? 'Error updating lens' : 'Error creating lens'),
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
                        widget.isEdit ? 'Edit Lens' : 'Add Lens',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _powerController,
                        decoration: const InputDecoration(
                          labelText: 'Power',
                          prefixIcon: Icon(Icons.flash_on_rounded),
                        ),
                        validator: (value) => _validateRequired(value, 'Power'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _coatingController,
                        decoration: const InputDecoration(
                          labelText: 'Coating',
                          prefixIcon: Icon(Icons.blur_on_rounded),
                        ),
                        validator: (value) => _validateRequired(value, 'Coating'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_rounded),
                        ),
                        validator: (value) => _validateRequired(value, 'Category'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _costController,
                        decoration: const InputDecoration(
                          labelText: 'Cost',
                          prefixIcon: Icon(Icons.attach_money_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateRequired(value, 'Cost'),
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
