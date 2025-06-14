import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../db/employee_helper.dart';
import '../db/branch_helper.dart';
import '../models/branch.dart';
import '../theme.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  List<Employee> _employees = [];
  List<Branch> _branches = [];
  String _search = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final employees = await EmployeeHelper.instance.getAllEmployees();
    final branches = await BranchHelper.instance.getAllBranches();
    setState(() {
      _employees = employees;
      _branches = branches;
      _isLoading = false;
    });
  }

  void _searchEmployees(String query) async {
    setState(() => _isLoading = true);
    final employees = await EmployeeHelper.instance.searchEmployees(query);
    setState(() {
      _employees = employees;
      _search = query;
      _isLoading = false;
    });
  }

  void _showEmployeeDialog({Employee? employee}) async {
    final result = await showDialog<Employee>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmployeeDialog(
        branches: _branches,
        employee: employee,
        onUpdate: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Update Employee'),
              content: const Text('Are you sure you want to update this employee?'),
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
        },
      ),
    );
    if (result != null) {
      await _loadData();
    }
  }

  void _deleteEmployee(Employee employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete \\${employee.name ?? employee.email}?'),
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
    if (confirm == true) {
      await EmployeeHelper.instance.deleteEmployee(employee.userId!);
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee deleted'), backgroundColor: Colors.red),
      );
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'manager':
        return Colors.green.shade100;
      case 'reception':
        return Colors.yellow.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  int _currentPage = 0;
  static const int _pageSize = 10;

  int get _totalPages => (_employees.length / _pageSize).ceil();

  List<Employee> get _currentPageEmployees {
    final start = _currentPage * _pageSize;
    final end = (_currentPage + 1) * _pageSize;
    return _employees.sublist(
      start,
      end > _employees.length ? _employees.length : end,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: _searchEmployees,
                    decoration: const InputDecoration(
                      hintText: 'Search employees',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showEmployeeDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Employee'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                  child: Text('#', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                ),
                SizedBox(
                  width: 200,
                  child: Text('Name', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
                SizedBox(
                  width: 180, // Reduced from 200 or previous value
                  child: Text('Email', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 1,
                  child: Text('Phone', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 1,
                  child: Text('Address', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
                SizedBox(
                  width: 80,
                  child: Text('Branch', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 1,
                  child: Text('Role', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 100), // Actions column
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _employees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No employees found',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Click the Add button to add your first employee',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _currentPageEmployees.length,
                        itemBuilder: (context, index) {
                          final emp = _currentPageEmployees[index];
                          final serial = _currentPage * _pageSize + index + 1;
                          final branch = _branches.firstWhere(
                            (b) => b.branchId == emp.branchId,
                            orElse: () => Branch(branchId: 0, branchName: 'Unknown', contactNumber: '', branchCode: '', shopId: 0),
                          );
                          return InkWell(
                            onTap: () => _showEmployeeDialog(employee: emp),
                            child: Container(
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
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  
                                  SizedBox(
                                    width: 200,
                                    child: Text(
                                      emp.name ?? '',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 180, // Reduced from 200 or previous value
                                    child: Text(
                                      emp.email,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      emp.phone ?? '',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      emp.address ?? '',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      branch.branchName,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Builder(
                                        builder: (context) {
                                          final roleColors = Theme.of(context).extension<AppRoleColors>();
                                          final isManager = emp.role == 'manager';
                                          final bgColor = isManager ? roleColors?.managerBg : roleColors?.receptionBg;
                                          final textColor = isManager ? roleColors?.managerText : roleColors?.receptionText;
                                          final badgeRadius = roleColors?.badgeRadius ?? BorderRadius.circular(8);
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: bgColor,
                                              borderRadius: badgeRadius,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                                children: [
                                                Icon(
                                                  isManager ? Icons.verified_user : Icons.person,
                                                  size: 14,
                                                  color: textColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 5, bottom: 5),
                                                  child: Text(
                                                    isManager ? 'Manager' : 'Reception',
                                                    style: TextStyle(
                                                      color: textColor,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            _showEmployeeDialog(employee: emp);
                                          },
                                          icon: const Icon(Icons.edit_rounded),
                                          iconSize: 18,
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            _deleteEmployee(emp);
                                          },
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
                            ),
                          );
                        },
                      ),
          ),
          if (_totalPages > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.first_page_rounded),
                    onPressed: _currentPage > 0 ? () => setState(() => _currentPage = 0) : null,
                    tooltip: 'First Page',
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                    tooltip: 'Previous Page',
                  ),
                  // ... page numbers ...
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _currentPage < _totalPages - 1 ? () => setState(() => _currentPage++) : null,
                    tooltip: 'Next Page',
                  ),
                  IconButton(
                    icon: const Icon(Icons.last_page_rounded),
                    onPressed: _currentPage < _totalPages - 1 ? () => setState(() => _currentPage = _totalPages - 1) : null,
                    tooltip: 'Last Page',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class EmployeeDialog extends StatefulWidget {
  final List<Branch> branches;
  final Employee? employee;
  final Future<bool> Function()? onUpdate;
  const EmployeeDialog({super.key, required this.branches, this.employee, this.onUpdate});

  @override
  State<EmployeeDialog> createState() => _EmployeeDialogState();
}

class _EmployeeDialogState extends State<EmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _role;
  Branch? _branch;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.employee != null) {
      _role = widget.employee!.role;
      _branch = widget.branches.firstWhere((b) => b.branchId == widget.employee!.branchId, orElse: () => widget.branches.first);
      _emailController.text = widget.employee!.email;
      _nameController.text = widget.employee!.name ?? '';
      _phoneController.text = widget.employee!.phone ?? '';
      _addressController.text = widget.employee!.address ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
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
                    widget.employee == null ? 'Add Employee' : 'Edit Employee',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _role,
                          items: const [
                            DropdownMenuItem(value: 'manager', child: Text('Manager')),
                            DropdownMenuItem(value: 'reception', child: Text('Reception')),
                          ],
                          onChanged: (v) => setState(() => _role = v),
                          decoration: const InputDecoration(labelText: 'Role'),
                          validator: (v) => v == null ? 'Select role' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<Branch>(
                          value: _branch,
                          items: widget.branches.map((b) => DropdownMenuItem(value: b, child: Text(b.branchName))).toList(),
                          onChanged: (v) => setState(() => _branch = v),
                          decoration: const InputDecoration(labelText: 'Branch'),
                          validator: (v) => v == null ? 'Select branch' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Phone'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final regex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
                      if (!regex.hasMatch(v)) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    maxLines: 3,
                    minLines: 1,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final isManager = _role == 'manager';
                            final branchId = _branch!.branchId!;
                            if (isManager) {
                              // Check if another manager exists for this branch (excluding self if editing)
                              final existingManager = await EmployeeHelper.instance.getManagerForBranch(branchId);
                              if (existingManager != null && (widget.employee == null || existingManager.userId != widget.employee!.userId)) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('A manager already exists for this branch.'), backgroundColor: Colors.red),
                                  );
                                }
                                return;
                              }
                            }
                            final emp = Employee(
                              userId: widget.employee?.userId,
                              role: _role!,
                              branchId: branchId,
                              email: _emailController.text.trim(),
                              name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
                              phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
                              address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
                            );
                            if (widget.employee == null) {
                              await EmployeeHelper.instance.createEmployee(emp);
                              if (context.mounted) Navigator.of(context).pop(emp);
                            } else {
                              if (widget.onUpdate != null) {
                                final confirmed = await widget.onUpdate!();
                                if (!confirmed) return;
                              }
                              await EmployeeHelper.instance.updateEmployee(emp);
                              if (context.mounted) Navigator.of(context).pop(emp);
                            }
                          }
                        },
                        child: Text(widget.employee == null ? 'Add' : 'Update'),
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