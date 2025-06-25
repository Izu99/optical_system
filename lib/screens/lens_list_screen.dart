import 'package:flutter/material.dart';
import '../db/lens_helper.dart';
import '../models/lens.dart';
import '../widget/pagination.dart'; // Import the pagination widget
import '../theme.dart';

class LensListScreen extends StatefulWidget {
  final int branchId;
  final int shopId;
  const LensListScreen({Key? key, required this.branchId, required this.shopId}) : super(key: key);

  @override
  State<LensListScreen> createState() => _LensListScreenState();
}

class _LensListScreenState extends State<LensListScreen> {
  List<Lens> _lenses = [];
  List<Lens> _filteredLenses = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  int _currentPage = 0;
  static const int _pageSize = 10;

  int get _totalPages => (_filteredLenses.length / _pageSize).ceil();

  List<Lens> get _currentPageLenses {
    final start = _currentPage * _pageSize;
    final end = (_currentPage + 1) * _pageSize;
    return _filteredLenses.sublist(
      start,
      end > _filteredLenses.length ? _filteredLenses.length : end,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadLenses();
    _searchController.addListener(_filterLenses);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final all = await LensHelper.instance.getAllLenses();
      final lenses = all.where((l) => l.branchId == widget.branchId && l.shopId == widget.shopId).toList();
      setState(() {
        _lenses = lenses;
        _filteredLenses = lenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading lenses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterLenses() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLenses = _lenses.where((lens) {
        return lens.power.toLowerCase().contains(query) ||
            lens.coating.toLowerCase().contains(query) ||
            lens.category.toLowerCase().contains(query);
      }).toList();
      _currentPage = 0; // Reset to first page on search
    });
  }

  Future<void> _showCreateOrEditDialog({Lens? lens}) async {
    final result = await showDialog<Lens>(
      context: context,
      barrierDismissible: false,
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
      await _loadLenses();
    }
  }

  Future<void> _deleteLens(Lens lens) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lens'),
        content: Text('Are you sure you want to delete this lens (${lens.power} ${lens.coating})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && lens.lensId != null) {
      try {
        await LensHelper.instance.deleteLens(lens.lensId!);
        await _loadLenses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lens deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting lens: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _onPageChanged(int pageIndex) {
    setState(() {
      _currentPage = pageIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                // Search Bar and Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search lenses',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateOrEditDialog(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Lens'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                // Lenses Table
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Card(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredLenses.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.remove_red_eye_rounded,
                                        size: 64,
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _lenses.isEmpty ? 'No lenses yet' : 'No matching lenses',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _lenses.isEmpty 
                                            ? 'Click the Add Lens button to add your first lens'
                                            : 'Try adjusting your search terms',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: [
                                    // Table Header
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 40,
                                            child: Text(
                                              '#',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              'Power',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              'Coating',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              'Category',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              'Cost',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              'Stock',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              'Selling Price',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 100), // Actions column
                                        ],
                                      ),
                                    ),
                                    // Table Body
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: _currentPageLenses.length,
                                        itemBuilder: (context, index) {
                                          final lens = _currentPageLenses[index];
                                          final serial = _currentPage * _pageSize + index + 1;
                                          return Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: index % 2 == 0
                                                ? Theme.of(context).extension<AppPageTheme>()?.tableEvenRowBg ?? Theme.of(context).colorScheme.surface
                                                : Theme.of(context).extension<AppPageTheme>()?.tableOddRowBg ?? Theme.of(context).colorScheme.surface.withOpacity(0.5),
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 40,
                                                  child: Text(
                                                    serial.toString(),
                                                    textAlign: TextAlign.center,
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    lens.power,
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    lens.coating,
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    lens.category,
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    lens.cost.toString(),
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    lens.stock.toString(),
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    lens.sellingPrice.toString(),
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 100,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      IconButton(
                                                        onPressed: () {
                                                          _showCreateOrEditDialog(lens: lens);
                                                        },
                                                        icon: const Icon(Icons.edit_rounded),
                                                        iconSize: 18,
                                                        tooltip: 'Edit',
                                                      ),
                                                      IconButton(
                                                        onPressed: () => _deleteLens(lens),
                                                        icon: const Icon(Icons.delete_rounded),
                                                        iconSize: 18,
                                                        color: Colors.red,
                                                        tooltip: 'Delete',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    // Pagination Controls
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: SmartPaginationControls(
                                        currentPage: _currentPage,
                                        totalPages: _totalPages,
                                        totalItems: _filteredLenses.length,
                                        itemsPerPage: _pageSize,
                                        onFirst: _currentPage > 0 ? () => _onPageChanged(0) : null,
                                        onPrevious: _currentPage > 0 ? () => _onPageChanged(_currentPage - 1) : null,
                                        onNext: _currentPage < _totalPages - 1 ? () => _onPageChanged(_currentPage + 1) : null,
                                        onLast: _currentPage < _totalPages - 1 ? () => _onPageChanged(_totalPages - 1) : null,
                                        onPageSelect: _onPageChanged,
                                        showItemsInfo: true,
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
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