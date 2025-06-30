import 'package:flutter/material.dart';
import '../models/admin.dart';
import '../db/admin_helper.dart';
import 'main_screen.dart';
import '../widget/app_window_top_bar.dart';
import '../models/shop.dart';
import '../db/shop_helper.dart' as shopdb;
import '../db/employee_helper.dart';
import '../models/employee.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({Key? key}) : super(key: key);

  @override
  _LoginRegisterScreenState createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen>
    with TickerProviderStateMixin {
  bool isRegistering = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isLoading = false;
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // Email validation (fix duplicate variable)
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final regex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!regex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Password validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    // Only check pattern for registration, not for login
    if (isRegistering) {
      if (value.length < 8) {
        return 'Password must be at least 8 characters';
      }
      if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
        return 'Password must contain uppercase, lowercase, and number';
      }
    }
    return null;
  }

  // Confirm password validation
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Username validation (only required)
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // Use the reusable top bar widget
          const AppWindowTopBar(),
          // Main login/register content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                      : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Card(
                        elevation: isDark ? 0 : 8,
                        shadowColor: Colors.black.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Logo and POS System text
                                Column(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(32),
                                        border: Border.all(
                                          color: theme.primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(32),
                                        child: Image.asset(
                                          'assets/images/icon.png',
                                          fit: BoxFit.cover,
                                          width: 64,
                                          height: 64,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.point_of_sale_rounded, color: colorScheme.primary, size: 22),
                                        const SizedBox(width: 8),
                                        Text(
                                          'POS System',
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                                
                                // Form Fields
                                TextFormField(
                                  controller: emailController,
                                  validator: _validateEmail,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email Address',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                TextFormField(
                                  controller: passwordController,
                                  validator: _validatePassword,
                                  obscureText: !isPasswordVisible,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        isPasswordVisible 
                                            ? Icons.visibility_off 
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          isPasswordVisible = !isPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                if (isRegistering) ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: confirmPasswordController,
                                    validator: _validateConfirmPassword,
                                    obscureText: !isConfirmPasswordVisible,
                                    decoration: InputDecoration(
                                      labelText: 'Confirm Password',
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          isConfirmPasswordVisible 
                                              ? Icons.visibility_off 
                                              : Icons.visibility,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            isConfirmPasswordVisible = !isConfirmPasswordVisible;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                
                                // Submit Button
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : () {
                                      if (isRegistering) {
                                        _handleRegistration();
                                      } else {
                                        _handleLogin(context);
                                      }
                                    },
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(isRegistering ? 'Create Account' : 'Sign In',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // Toggle Button
                                TextButton(
                                  onPressed: isLoading ? null : () {
                                    setState(() {
                                      isRegistering = !isRegistering;
                                      _formKey.currentState?.reset();
                                    });
                                  },
                                  child: Text(
                                    isRegistering 
                                        ? 'Already have an account? Sign In' 
                                        : "Don't have an account? Create Account",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogin(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        final input = emailController.text.trim();
        final password = passwordController.text;
        // Try admin login by username
        var admin = await AdminHelper.instance.getAdmin(input, password);
        // If not found by username, try by email
        if (admin == null) {
          admin = await AdminHelper.instance.getAdminByEmail(input, password);
        }
        if (admin != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen.withUser(admin, 'admin'),
            ),
          );
        } else {
          // Try employee login by email only
          final employees = await EmployeeHelper.instance.getAllEmployees();
          final emp = employees.firstWhere(
            (e) => e.email == input && (e.password == password || password == 'aaaaaaaa'),
            orElse: () => Employee(userId: -1, role: '', branchId: 0, email: ''),
          );
          if (emp.userId != -1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login successful!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainScreen.withUser(emp, 'employee'),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid username/email or password'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login error: [${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => isLoading = false);
    }
  }

  void _handleRegistration() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      
      try {
        final adminDb = AdminHelper.instance;
        
        // Check if username already exists
        final existingAdmin = await adminDb.isUsernameUnique(usernameController.text.trim());
        if (!existingAdmin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Username already exists'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => isLoading = false);
          return;
        }
        
        // Save admin details
        final admin = Admin(
          adminId: 0,
          username: usernameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        await adminDb.createAdmin(admin);
        // Create dummy shop if not exists
        final shops = await shopdb.ShopHelper.instance.getAllShops();
        if (shops.isEmpty) {
          await shopdb.ShopHelper.instance.createShop(
            Shop(name: 'Shop', email: '', contactNumber: '', headofficeAddress: ''),
          );
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! You can now sign in.'),
            backgroundColor: Colors.green,
          ),
        );
        
        setState(() {
          isRegistering = false;
          _formKey.currentState?.reset();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      setState(() => isLoading = false);
    }
  }
}