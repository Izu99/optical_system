import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../models/admin.dart';
import '../db/employee_helper.dart';
import '../db/admin_helper.dart';

class ProfileScreen extends StatefulWidget {
  final String userType; // 'admin' or 'employee'
  final dynamic user; // Admin or Employee object
  const ProfileScreen({super.key, required this.userType, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _role;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _passwordError;
  String? _confirmError;
  String? _currentError;

  @override
  void initState() {
    super.initState();
    if (widget.userType == 'employee') {
      final Employee emp = widget.user as Employee;
      _nameController.text = emp.name ?? '';
      _emailController.text = emp.email;
      _phoneController.text = emp.phone ?? '';
      _addressController.text = emp.address ?? '';
      _role = Employee.displayRole(emp.role);
    } else {
      final Admin admin = widget.user as Admin;
      _nameController.text = admin.username;
      _emailController.text = admin.email;
      _role = 'Admin';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfileAndPassword() async {
    setState(() {
      _passwordError = null;
      _confirmError = null;
      _currentError = null;
    });
    // Validate name and phone
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required'), backgroundColor: Colors.red),
      );
      return;
    }
    if (widget.userType == 'employee' && _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is required'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (widget.userType == 'employee') {
        final Employee emp = widget.user as Employee;
        final updated = Employee(
          userId: emp.userId,
          role: emp.role,
          branchId: emp.branchId,
          email: emp.email, // email not editable
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          imagePath: emp.imagePath,
          password: _newPasswordController.text.isNotEmpty ? _newPasswordController.text : emp.password,
        );
        await EmployeeHelper.instance.updateEmployee(updated);
      } else {
        final Admin admin = widget.user as Admin;
        final updated = Admin(
          adminId: admin.adminId,
          username: _nameController.text.trim(),
          email: admin.email, // email not editable
          password: _newPasswordController.text.isNotEmpty ? _newPasswordController.text : admin.password,
        );
        await AdminHelper.instance.updateAdmin(updated);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_role ?? '', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                readOnly: false,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              if (widget.userType == 'employee') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  readOnly: false,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  readOnly: false,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
              ],
              const SizedBox(height: 32),
              Text('Change Password', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: !_showCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  errorText: _currentError,
                  suffixIcon: IconButton(
                    icon: Icon(_showCurrentPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_showNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password (8 chars, 1 capital, 1 number)',
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(_showNewPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_showConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  errorText: _confirmError,
                  suffixIcon: IconButton(
                    icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfileAndPassword,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Update Profile & Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
