import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../db/employee_helper.dart';
import '../db/branch_helper.dart';
import '../models/branch.dart';
import '../theme.dart';
import '../widget/pagination.dart'; // Import the pagination widget

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  List<Branch> _branches = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  int _currentPage = 0;
  static const int _pageSize = 10;

  int get _totalPages => (_filteredEmployees.length / _pageSize).ceil();

  List<Employee> get _currentPageEmployees {
    final start = _currentPage * _pageSize;
    final end = (_currentPage + 1) * _pageSize;
    return _filteredEmployees.sublist(
      start,
      end > _filteredEmployees.length ? _filteredEmployees.length : end,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterEmployees);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final employees = await EmployeeHelper.instance.getAllEmployees();
      final branches = await BranchHelper.instance.getAllBranches();
      setState(() {
        _employees = employees;
        _filteredEmployees = employees;
        _branches = branches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading employees: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterEmployees() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEmployees = _employees.where((employee) {
        return (employee.name?.toLowerCase().contains(query) ?? false) ||
            employee.email.toLowerCase().contains(query) ||
            (employee.phone?.toLowerCase().contains(query) ?? false) ||
            employee.role.toLowerCase().contains(query);
      }).toList();
      _currentPage = 0; // Reset to first page on search
    });
  }

  Future<bool> _showUpdateConfirmationDialog() async {
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
  }

  void _showEmployeeDialog({Employee? employee}) async {
    final result = await showDialog<Employee>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmployeeDialog(
        branches: _branches,
        employee: employee,
        onUpdate: () async {
          final confirmed = await _showUpdateConfirmationDialog();
          return confirmed;
        },
      ),
    );
    if (result != null) {
      await _loadData();
    }
  }

  Future<void> _deleteEmployee(Employee employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.name ?? employee.email}?'),
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

    if (confirm == true && employee.userId != null) {
      try {
        await EmployeeHelper.instance.deleteEmployee(employee.userId!);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${employee.name ?? employee.email} deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting employee: $e'),
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

  Widget _buildRoleBadge(String role) {
    final roleColors = Theme.of(context).extension<AppRoleColors>();
    final pageTheme = Theme.of(context).extension<AppPageTheme>();
    Color bg;
    Color fg;
    IconData roleIconData;
    BorderRadius badgeRadius = roleColors?.badgeRadius ?? pageTheme?.badgeRadius ?? BorderRadius.circular(20);
    List<BoxShadow> badgeShadow = pageTheme?.badgeShadow ?? [];
    double badgeWidth = pageTheme?.badgeWidth ?? 120;
    double badgeIconSize = pageTheme?.badgeIconSize ?? 16;
    double badgeLetterSpacing = pageTheme?.badgeLetterSpacing ?? 0.3;
    EdgeInsets badgePadding = pageTheme?.badgePadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    switch (role) {
      case Employee.roleManager:
        bg = roleColors?.managerBg ?? Colors.green.shade100;
        fg = roleColors?.managerText ?? Colors.green.shade800;
        roleIconData = Icons.verified_user;
        break;
      case Employee.roleSalesPerson:
        bg = roleColors?.salesPersonBg ?? Colors.blue.shade100;
        fg = roleColors?.salesPersonText ?? Colors.blue.shade800;
        roleIconData = Icons.person_outline;
        break;
      case Employee.roleFitter:
        bg = roleColors?.fitterBg ?? Colors.indigo.shade100;
        fg = roleColors?.fitterText ?? Colors.indigo.shade800;
        roleIconData = Icons.handyman;
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        roleIconData = Icons.person;
    }

    return Container(
      width: badgeWidth,
      alignment: Alignment.center,
      child: Container(
        padding: badgePadding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: badgeRadius,
          boxShadow: badgeShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(roleIconData, color: fg, size: badgeIconSize),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                Employee.displayRole(role),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  letterSpacing: badgeLetterSpacing,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageTheme = Theme.of(context).extension<AppPageTheme>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                // Search Bar
                Container(
                  padding: pageTheme?.searchBarPadding ?? const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: pageTheme?.searchBarFillColor ?? Theme.of(context).cardColor,
                    borderRadius: pageTheme?.searchBarRadius ?? BorderRadius.circular(12),
                    boxShadow: pageTheme?.cardShadow ?? [],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: pageTheme?.searchBarRadius ?? BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).dividerColor.withOpacity(0.3),
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by name, email, phone, or role...',
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              border: InputBorder.none,
                              contentPadding: pageTheme?.searchFieldPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showEmployeeDialog(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Employee'),
                        style: ElevatedButton.styleFrom(
                          padding: pageTheme?.buttonPadding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: pageTheme?.buttonRadius ?? BorderRadius.circular(12),
                          ),
                          elevation: pageTheme?.buttonElevation ?? 0,
                        ),
                      ),
                    ],
                  ),
                ),
                // Table
                Expanded(
                  child: Padding(
                    padding: pageTheme?.cardMargin ?? const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Card(
                      elevation: pageTheme?.cardElevation ?? 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: pageTheme?.cardRadius ?? BorderRadius.circular(16),
                      ),
                      shadowColor: Colors.transparent,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredEmployees.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline_rounded,
                                        size: pageTheme?.emptyIconSize ?? 80,
                                        color: Theme.of(context).colorScheme.primary.withOpacity(pageTheme?.emptyIconOpacity ?? 0.3),
                                      ),
                                      SizedBox(height: pageTheme?.emptySpacing.vertical ?? 24),
                                      Text(
                                        _employees.isEmpty ? 'No employees yet' : 'No matching employees',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: (pageTheme?.emptySpacing.vertical ?? 12) / 2),
                                      Text(
                                        _employees.isEmpty 
                                            ? 'Click the Add Employee button to get started'
                                            : 'Try adjusting your search terms',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                                      padding: pageTheme?.tableHeaderPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                      decoration: BoxDecoration(
                                        color: pageTheme?.tableHeaderBg ?? Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                        borderRadius: BorderRadius.only(
                                          topLeft: pageTheme != null ? pageTheme.cardRadius.topLeft : const Radius.circular(16),
                                          topRight: pageTheme != null ? pageTheme.cardRadius.topRight : const Radius.circular(16),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: pageTheme?.serialWidth ?? 50,
                                            child: Text(
                                              '#',
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              'Name',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              'Email',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              'Address',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          SizedBox(
                                            width: pageTheme?.badgeWidth ?? 120,
                                            child: Text(
                                              'Role',
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Branch',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          SizedBox(
                                            width: 100,
                                            child: Text(
                                              'Actions',
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Table Rows
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: _currentPageEmployees.length,
                                        itemBuilder: (context, index) {
                                          final emp = _currentPageEmployees[index];
                                          final serial = _currentPage * _pageSize + index + 1;
                                          final isEven = index % 2 == 0;
                                          return Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () => _showEmployeeDialog(employee: emp),
                                              borderRadius: pageTheme?.tableRowPadding != null ? BorderRadius.circular(8) : BorderRadius.circular(8),
                                              child: Container(
                                                padding: pageTheme?.tableRowPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                                decoration: BoxDecoration(
                                                  color: isEven 
                                                    ? pageTheme?.tableEvenRowBg ?? Theme.of(context).colorScheme.surface
                                                    : pageTheme?.tableOddRowBg ?? Theme.of(context).colorScheme.surface.withOpacity(0.5),
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      color: pageTheme != null
                                                        ? pageTheme.tableBorderColor.withOpacity(pageTheme.tableBorderOpacity)
                                                        : Theme.of(context).dividerColor.withOpacity(0.1),
                                                    ),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    // Serial Number
                                                    SizedBox(
                                                      width: pageTheme?.serialWidth ?? 50,
                                                      child: Container(
                                                        padding: pageTheme?.serialPadding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                          borderRadius: pageTheme?.serialRadius ?? BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          serial.toString(),
                                                          textAlign: TextAlign.center,
                                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                            fontWeight: FontWeight.w600,
                                                            color: Theme.of(context).colorScheme.primary,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    // Name
                                                    Expanded(
                                                      flex: 3,
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            emp.name ?? '-',
                                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          if (emp.phone != null && emp.phone!.isNotEmpty)
                                                            Text(
                                                              emp.phone!,
                                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    // Email
                                                    Expanded(
                                                      flex: 3,
                                                      child: Text(
                                                        emp.email,
                                                        style: Theme.of(context).textTheme.bodyMedium,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    // Address
                                                    Expanded(
                                                      flex: 3,
                                                      child: Text(
                                                        emp.address ?? '-',
                                                        style: Theme.of(context).textTheme.bodyMedium,
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 2,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    // Role Badge
                                                    _buildRoleBadge(emp.role),
                                                    const SizedBox(width: 16),
                                                    // Branch
                                                    Expanded(
                                                      flex: 2,
                                                      child: Text(
                                                        _branches.firstWhere(
                                                          (b) => b.branchId == emp.branchId,
                                                          orElse: () => Branch(
                                                            branchId: 0,
                                                            branchName: '-',
                                                            contactNumber: '',
                                                            branchCode: '',
                                                            shopId: 0,
                                                          ),
                                                        ).branchName,
                                                        style: Theme.of(context).textTheme.bodyMedium,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    // Actions
                                                    SizedBox(
                                                      width: 100,
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Container(
                                                            decoration: BoxDecoration(
                                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                              borderRadius: pageTheme?.iconButtonRadius ?? BorderRadius.circular(8),
                                                            ),
                                                            child: IconButton(
                                                              icon: const Icon(Icons.edit_rounded, size: 18),
                                                              color: Theme.of(context).colorScheme.primary,
                                                              tooltip: 'Edit Employee',
                                                              onPressed: () => _showEmployeeDialog(employee: emp),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Container(
                                                            decoration: BoxDecoration(
                                                              color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                                                              borderRadius: pageTheme?.iconButtonRadius ?? BorderRadius.circular(8),
                                                            ),
                                                            child: IconButton(
                                                              icon: const Icon(Icons.delete_rounded, size: 18),
                                                              color: Theme.of(context).colorScheme.error,
                                                              tooltip: 'Delete Employee',
                                                              onPressed: () => _deleteEmployee(emp),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    // Pagination
                                    Container(
                                      padding: pageTheme?.paginationPadding ?? const EdgeInsets.all(20.0),
                                      decoration: BoxDecoration(
                                        color: pageTheme?.paginationBg ?? Theme.of(context).colorScheme.surface.withOpacity(0.5),
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: pageTheme != null ? pageTheme.cardRadius.bottomLeft : const Radius.circular(16),
                                          bottomRight: pageTheme != null ? pageTheme.cardRadius.bottomRight : const Radius.circular(16),
                                        ),
                                      ),
                                      child: SmartPaginationControls(
                                        currentPage: _currentPage,
                                        totalPages: _totalPages,
                                        totalItems: _filteredEmployees.length,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Keep the EmployeeDialog class unchanged
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
  final TextEditingController _passwordController = TextEditingController();
  String? _generatedPassword;

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
      _passwordController.text = widget.employee!.password ?? '';
    } else {
      // Generate random password for new employee
      _generatedPassword = _generateRandomPassword();
      _passwordController.text = _generatedPassword!;
    }
  }

  String _generateRandomPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(8, (index) => chars[(chars.length * (index + DateTime.now().millisecondsSinceEpoch) % chars.length) % chars.length]).join();
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
                            DropdownMenuItem(value: Employee.roleManager, child: Text('Manager')),
                            DropdownMenuItem(value: Employee.roleSalesPerson, child: Text('S/Person')),
                            DropdownMenuItem(value: Employee.roleFitter, child: Text('Fitter')),
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
                  const SizedBox(height: 16),
                  if (widget.employee == null) ...[
                    TextFormField(
                      controller: _passwordController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Generated Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_generatedPassword != null)
                      SelectableText('Give this password to the employee: $_generatedPassword', style: const TextStyle(color: Colors.blue)),
                  ],
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
                          if (!_formKey.currentState!.validate()) return;
                          final emp = Employee(
                            userId: widget.employee?.userId,
                            role: _role!,
                            branchId: _branch!.branchId!,
                            email: _emailController.text.trim(),
                            name: _nameController.text.trim(),
                            phone: _phoneController.text.trim(),
                            address: _addressController.text.trim(),
                            password: _passwordController.text.trim(),
                          );
                          if (widget.employee == null) {
                            await EmployeeHelper.instance.createEmployee(emp);
                          } else {
                            if (widget.onUpdate != null) {
                              final ok = await widget.onUpdate!();
                              if (!ok) return;
                            }
                            await EmployeeHelper.instance.updateEmployee(emp);
                          }
                          if (mounted) Navigator.of(context).pop(emp);
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

