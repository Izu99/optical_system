import 'package:flutter/material.dart';
import '../widget/sidebar.dart';
import './customer_list_screen.dart';
import './branch_list_screen.dart';
import './login_register_screen.dart';
import './shop_form_screen.dart';
import './employee_screen.dart';
import '../db/shop_helper.dart';
import '../widget/app_window_top_bar.dart';
import './frame_list_screen.dart';
import './lens_list_screen.dart';
import './prescription_screen.dart';
import './bill_list_screen.dart';
import './payment_list_screen.dart';
import './dashboard_screen.dart';
import './profile_screen.dart';
import '../models/employee.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  // Add a named constructor to accept user and userType
  MainScreen.withUser(dynamic user, String userType, {Key? key}) : super(key: key) {
    _initialUser = user;
    _initialUserType = userType;
  }

  static dynamic _initialUser;
  static String? _initialUserType;

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  String _currentPage = 'shop';
  bool _shopExists = false;
  String? _userName;
  String? _userRole;

  dynamic _currentUser; // Admin or Employee
  String _currentUserType = 'admin'; // or 'employee'

  @override
  void initState() {
    super.initState();
    _checkShopExists();
    if (MainScreen._initialUser != null && MainScreen._initialUserType != null) {
      setUser(MainScreen._initialUser, MainScreen._initialUserType!);
    }
  }

  Future<void> _checkShopExists() async {
    final shops = await ShopHelper.instance.getAllShops();
    setState(() {
      _shopExists = shops.isNotEmpty;
      if (!_shopExists) {
        _currentPage = 'shop';
      } else {
        // Ensure the current page updates correctly after shop creation
        _currentPage = 'dashboard';
      }
    });
  }

  void _onPageChanged(String page) async {
    if (!_shopExists && page != 'shop') {
      // Show dialog to set up shop first
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Set Up Shop First'),
          content: const Text('Please set up your shop before accessing other features.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() {
      _currentPage = page;
    });
  }

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case 'login_register':
        return const LoginRegisterScreen();
      case 'customers':
        return const CustomersScreen();
      case 'branches':
        return const BranchListScreen();
      case 'employees':
        return const EmployeeScreen();
      case 'dashboard':
        return const DashboardScreen();
      case 'orders':
        return _buildPlaceholderPage('Orders', Icons.shopping_cart_rounded);
      case 'shop':
        return const ShopFormScreen();
      case 'admin_profile':
        return ProfileScreen(userType: _currentUserType, user: _currentUser);
      case 'frames':
        return const FrameListScreen(branchId: 1, shopId: 1); // TODO: Replace with actual selected branch/shop
      case 'lenses':
        return const LensListScreen(branchId: 1, shopId: 1); // TODO: Replace with actual selected branch/shop
      case 'prescriptions':
        return const PrescriptionScreen();
      case 'bills':
        return const BillListScreen();
      case 'payments':
        return const PaymentListScreen();
      default:
        return const CustomersScreen();
    }
  }

  Widget _buildPlaceholderPage(String title, IconData icon) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '$title Page',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void refreshShopState() {
    _checkShopExists();
  }

  // Set user after login
  void setUser(dynamic user, String userType) {
    setState(() {
      _currentUser = user;
      _currentUserType = userType;
      if (userType == 'admin') {
        _userName = user.username ?? user.name ?? user.email ?? 'Admin';
        _userRole = 'Admin';
      } else if (userType == 'employee') {
        _userName = user.name?.isNotEmpty == true ? user.name : user.email;
        _userRole = (user.role != null && user.role.isNotEmpty)
          ? Employee.displayRole(user.role)
          : 'Admin';
      } else {
        _userName = 'Unknown';
        _userRole = 'Admin';
      }
    });
  }

  static MainScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainScreenState>();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Row(
        children: [
          Sidebar(
            currentPage: _currentPage,
            onPageChanged: _onPageChanged,
            userName: _userName,
            userRole: _userRole,
          ),
          Expanded(
            child: Column(
              children: [
                // Top bar: logo + POS System text (left, drag area), window controls (right)
                AppWindowTopBar(
                  leading: Row(
                    children: [
                      Image.asset(
                        'assets/images/icon.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'POS System',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                // Main content
                Expanded(
                  child: _buildCurrentPage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
