import 'package:flutter/material.dart';
import '../models/branch.dart';
import '../db/branch_helper.dart';
import '../widget/create_branch_dialog.dart';
import '../widget/pagination.dart'; // Import the pagination widget

class BranchListScreen extends StatefulWidget {
  const BranchListScreen({super.key});

  @override
  State<BranchListScreen> createState() => _BranchListScreenState();
}

class _BranchListScreenState extends State<BranchListScreen> {
  List<Branch> _branches = [];
  List<Branch> _filteredBranches = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  int _currentPage = 0;
  static const int _pageSize = 10;

  int get _totalPages => (_filteredBranches.length / _pageSize).ceil();

  List<Branch> get _currentPageBranches {
    if (_filteredBranches.isEmpty) {
      return [];
    }
    final start = _currentPage * _pageSize;
    final end = (_currentPage + 1) * _pageSize;
    return _filteredBranches.sublist(
      start,
      end > _filteredBranches.length ? _filteredBranches.length : end,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadBranches();
    _searchController.addListener(_filterBranches);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final branches = await BranchHelper.instance.getAllBranches();
      setState(() {
        _branches = branches;
        _filteredBranches = branches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading branches: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _filterBranches() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBranches = _branches.where((branch) {
        return branch.branchName.toLowerCase().contains(query) ||
            branch.branchCode.toLowerCase().contains(query) ||
            branch.contactNumber.toLowerCase().contains(query);
      }).toList();
      _currentPage = 0; // Reset to first page on search
    });
  }

  Future<void> _showCreateBranchDialog() async {
    final result = await showDialog<Branch>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CreateBranchDialog(),
    );
    if (result != null) {
      await _loadBranches();
    }
  }

  Future<bool> _showUpdateConfirmationDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Branch'),
        content: const Text('Are you sure you want to update this branch?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    return confirm == true;
  }

  Future<void> _showEditBranchDialog(Branch branch) async {
    final result = await showDialog<Branch>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateBranchDialog(
        branch: branch,
        isEdit: true,
        onUpdate: () async {
          final confirmed = await _showUpdateConfirmationDialog();
          return confirmed;
        },
      ),
    );
    if (result != null) {
      await _loadBranches();
    }
  }

  Future<void> _deleteBranch(Branch branch) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Branch'),
        content: Text('Are you sure you want to delete ${branch.branchName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && branch.branchId != null) {
      try {
        await BranchHelper.instance.deleteBranch(branch.branchId!);
        await _loadBranches();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${branch.branchName} deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting branch: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
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
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search branches',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await showDialog<Branch>(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const CreateBranchDialog(),
                          );
                          if (result != null) {
                            await _loadBranches();
                          }
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Branch'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                // Branches Table
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Card(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredBranches.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.account_balance_rounded,
                                        size: 64,
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _branches.isEmpty ? 'No branches yet' : 'No matching branches',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _branches.isEmpty
                                            ? 'Click the Add Branch button to add your first branch'
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
                                            flex: 2,
                                            child: Text(
                                              'Branch Name',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Branch Code',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Contact Number',
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
                                        itemCount: _currentPageBranches.length,
                                        itemBuilder: (context, index) {
                                          final branch = _currentPageBranches[index];
                                          final serial = _currentPage * _pageSize + index + 1;
                                          return Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
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
                                                  flex: 2,
                                                  child: Text(
                                                    branch.branchName,
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    branch.branchCode,
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    branch.contactNumber,
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
                                                          _showEditBranchDialog(branch);
                                                        },
                                                        icon: const Icon(Icons.edit_rounded),
                                                        iconSize: 18,
                                                        tooltip: 'Edit',
                                                      ),
                                                      IconButton(
                                                        onPressed: () => _deleteBranch(branch),
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
                                    // New Pagination Controls - Same as Customer Screen
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: SmartPaginationControls(
                                        currentPage: _currentPage,
                                        totalPages: _totalPages,
                                        totalItems: _filteredBranches.length,
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