import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dart:io';
import 'theme.dart';
import 'screens/login_register_screen.dart';
import 'db/customer_helper.dart';
import 'screens/shop_form_screen.dart';
import 'db/shop_helper.dart';
import 'models/shop.dart';
import 'models/branch.dart';
import 'models/employee.dart';
import 'models/frame.dart';
import 'models/lens.dart';
import 'models/prescription.dart';
import 'db/branch_helper.dart';
import 'db/employee_helper.dart';
import 'db/frame_helper.dart';
import 'db/lens_helper.dart';
import 'db/prescription_helper.dart';
import 'models/customer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize database
  await DatabaseHelper.instance.database;

  // Insert sample data
  await insertSampleData();

  runApp(const MyApp());

  // Ensure proper integration of bitsdojo_window
  doWhenWindowReady(() {
    const minSize = Size(1280, 720);
    appWindow.minSize = minSize;
    appWindow.size = minSize;
    appWindow.alignment = Alignment.center;
    appWindow.maximize();
    appWindow.show();
  });
}

Future<void> insertSampleData() async {
  // --- SHOP ---
  final shops = [
    Shop(name: 'Colombo Optics', contactNumber: '0112123456', email: 'colombo@optics.lk', headofficeAddress: 'No. 1, Galle Road, Colombo'),
    Shop(name: 'Kandy Vision', contactNumber: '0812233445', email: 'kandy@vision.lk', headofficeAddress: 'No. 2, Peradeniya Rd, Kandy'),
    Shop(name: 'Galle Eye Care', contactNumber: '0912345678', email: 'galle@eyecare.lk', headofficeAddress: 'No. 3, Main St, Galle'),
    Shop(name: 'Jaffna Opticals', contactNumber: '0212233445', email: 'jaffna@opticals.lk', headofficeAddress: 'No. 4, KKS Rd, Jaffna'),
    Shop(name: 'Matara Lens House', contactNumber: '0412233445', email: 'matara@lens.lk', headofficeAddress: 'No. 5, Beach Rd, Matara'),
  ];
  List<int> shopIds = [];
  for (final shop in shops) {
    try {
      final id = await ShopHelper.instance.createShop(shop);
      shopIds.add(id);
    } catch (_) {
      // Shop may already exist, get its id
      final all = await ShopHelper.instance.getAllShops();
      shopIds.add(all.firstWhere((s) => s.name == shop.name).shopId!);
    }
  }

  // --- BRANCH ---
  final branches = [
    Branch(branchName: 'Colombo Fort', contactNumber: '0112123001', branchCode: 'CF01', shopId: shopIds[0]),
    Branch(branchName: 'Kandy City', contactNumber: '0812233002', branchCode: 'KC01', shopId: shopIds[1]),
    Branch(branchName: 'Galle Center', contactNumber: '0912343003', branchCode: 'GC01', shopId: shopIds[2]),
    Branch(branchName: 'Jaffna Town', contactNumber: '0212233004', branchCode: 'JT01', shopId: shopIds[3]),
    Branch(branchName: 'Matara Main', contactNumber: '0412233005', branchCode: 'MM01', shopId: shopIds[4]),
  ];
  List<int> branchIds = [];
  for (final branch in branches) {
    try {
      final id = await BranchHelper.instance.createBranch(branch);
      branchIds.add(id);
    } catch (_) {
      final all = await BranchHelper.instance.getAllBranches();
      branchIds.add(all.firstWhere((b) => b.branchName == branch.branchName).branchId!);
    }
  }

  // --- EMPLOYEE ---
  final employees = [
    Employee(role: 'manager', branchId: branchIds[0], email: 'nimal@colombo.lk', name: 'Nimal Perera', phone: '0771234567', address: 'Colombo 01'),
    Employee(role: 'sales-person', branchId: branchIds[1], email: 'kamal@kandy.lk', name: 'Kamal Silva', phone: '0772345678', address: 'Kandy'),
    Employee(role: 'manager', branchId: branchIds[2], email: 'saman@galle.lk', name: 'Saman Fernando', phone: '0773456789', address: 'Galle'),
    Employee(role: 'sales-person', branchId: branchIds[3], email: 'rani@jaffna.lk', name: 'Rani Nadarajah', phone: '0774567890', address: 'Jaffna'),
    Employee(role: 'manager', branchId: branchIds[4], email: 'sunil@matara.lk', name: 'Sunil Jayasinghe', phone: '0775678901', address: 'Matara'),
  ];
  for (final emp in employees) {
    try {
      await EmployeeHelper.instance.createEmployee(emp);
    } catch (_) {}
  }

  // --- CUSTOMER ---
  final customers = [
    Customer(name: 'Chathura Gunasekara', email: 'chathura@gmail.com', phoneNumber: '0711111111', address: 'Colombo', createdAt: DateTime.now()),
    Customer(name: 'Harsha Wijeratne', email: 'harsha@gmail.com', phoneNumber: '0722222222', address: 'Kandy', createdAt: DateTime.now()),
    Customer(name: 'Nadeesha Perera', email: 'nadeesha@gmail.com', phoneNumber: '0733333333', address: 'Galle', createdAt: DateTime.now()),
    Customer(name: 'Sivakumar S', email: 'sivakumar@gmail.com', phoneNumber: '0744444444', address: 'Jaffna', createdAt: DateTime.now()),
    Customer(name: 'Sanduni Herath', email: 'sanduni@gmail.com', phoneNumber: '0755555555', address: 'Matara', createdAt: DateTime.now()),
  ];
  List<int> customerIds = [];
  for (final c in customers) {
    try {
      final id = await DatabaseHelper.instance.createCustomer(c);
      customerIds.add(id);
    } catch (_) {
      final all = await DatabaseHelper.instance.getAllCustomers();
      customerIds.add(all.firstWhere((cu) => cu.email == c.email).id!);
    }
  }

  // --- FRAME ---
  final frames = [
    Frame(brand: 'Ravin', size: 'Medium', wholeSalePrice: 2500, color: 'Black', model: 'R001', sellingPrice: 3500, stock: 10, branchId: branchIds[0], shopId: shopIds[0]),
    Frame(brand: 'VisionPro', size: 'Large', wholeSalePrice: 3000, color: 'Brown', model: 'V101', sellingPrice: 4000, stock: 8, branchId: branchIds[1], shopId: shopIds[1]),
    Frame(brand: 'OptiMax', size: 'Small', wholeSalePrice: 2000, color: 'Blue', model: 'O201', sellingPrice: 3200, stock: 12, branchId: branchIds[2], shopId: shopIds[2]),
    Frame(brand: 'LankaLens', size: 'Medium', wholeSalePrice: 2700, color: 'Grey', model: 'L301', sellingPrice: 3700, stock: 7, branchId: branchIds[3], shopId: shopIds[3]),
    Frame(brand: 'CeylonOptic', size: 'Large', wholeSalePrice: 3500, color: 'Silver', model: 'C401', sellingPrice: 4500, stock: 5, branchId: branchIds[4], shopId: shopIds[4]),
  ];
  for (final f in frames) {
    try {
      await FrameHelper.instance.createFrame(f);
    } catch (_) {}
  }

  // --- LENS ---
  final lenses = [
    Lens(power: '-1.00', coating: 'Anti-Reflective', category: 'Single Vision', cost: 1500, stock: 20, sellingPrice: 2500, branchId: branchIds[0], shopId: shopIds[0]),
    Lens(power: '-2.00', coating: 'Blue Cut', category: 'Bifocal', cost: 2000, stock: 15, sellingPrice: 3000, branchId: branchIds[1], shopId: shopIds[1]),
    Lens(power: '-3.00', coating: 'Photochromic', category: 'Progressive', cost: 2500, stock: 10, sellingPrice: 3500, branchId: branchIds[2], shopId: shopIds[2]),
    Lens(power: '-4.00', coating: 'Scratch Resistant', category: 'Single Vision', cost: 1800, stock: 18, sellingPrice: 2800, branchId: branchIds[3], shopId: shopIds[3]),
    Lens(power: '-5.00', coating: 'UV Protection', category: 'Bifocal', cost: 2200, stock: 12, sellingPrice: 3200, branchId: branchIds[4], shopId: shopIds[4]),
  ];
  for (final l in lenses) {
    try {
      await LensHelper.instance.createLens(l);
    } catch (_) {}
  }

  // --- PRESCRIPTION ---
  final prescriptions = [
    Prescription(leftPd: 30.5, rightPd: 31.0, leftAdd: 1.0, rightAdd: 1.0, leftAxis: 90, leftSph: -1.0, rightAxis: 85, rightCyl: -0.5, rightSph: -1.25, customerId: customerIds[0], shopId: shopIds[0], branchId: branchIds[0]),
    Prescription(leftPd: 29.0, rightPd: 29.5, leftAdd: 0.75, rightAdd: 0.75, leftAxis: 80, leftSph: -2.0, rightAxis: 75, rightCyl: -0.75, rightSph: -2.25, customerId: customerIds[1], shopId: shopIds[1], branchId: branchIds[1]),
    Prescription(leftPd: 32.0, rightPd: 32.5, leftAdd: 1.25, rightAdd: 1.25, leftAxis: 100, leftSph: -3.0, rightAxis: 95, rightCyl: -1.0, rightSph: -3.25, customerId: customerIds[2], shopId: shopIds[2], branchId: branchIds[2]),
    Prescription(leftPd: 28.5, rightPd: 29.0, leftAdd: 0.5, rightAdd: 0.5, leftAxis: 70, leftSph: -4.0, rightAxis: 65, rightCyl: -1.25, rightSph: -4.25, customerId: customerIds[3], shopId: shopIds[3], branchId: branchIds[3]),
    Prescription(leftPd: 31.5, rightPd: 32.0, leftAdd: 1.5, rightAdd: 1.5, leftAxis: 110, leftSph: -5.0, rightAxis: 105, rightCyl: -1.5, rightSph: -5.25, customerId: customerIds[4], shopId: shopIds[4], branchId: branchIds[4]),
  ];
  for (final p in prescriptions) {
    try {
      await PrescriptionHelper.instance.createPrescription(p);
    } catch (_) {}
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'POS System',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const LoginRegisterScreen(), // <--- Set your desired start screen here
          );
        },
      ),
    );
  }
}

/// A custom top bar for dialogs/pages with window controls (close, minimize, maximize), theme-driven.
class CustomDialogTopBar extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onClose;
  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;
  final Color? backgroundColor;
  final Color? iconColor;
  final double borderRadius;

  const CustomDialogTopBar({
    super.key,
    required this.title,
    required this.icon,
    this.onClose,
    this.onMinimize,
    this.onMaximize,
    this.backgroundColor,
    this.iconColor,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bg = backgroundColor ?? colorScheme.primary.withOpacity(0.05);
    final ic = iconColor ?? colorScheme.primary;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ic,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.minimize_rounded),
                tooltip: 'Minimize',
                onPressed: onMinimize,
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                color: colorScheme.primary,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.crop_square_rounded),
                tooltip: 'Maximize',
                onPressed: onMaximize,
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                color: colorScheme.primary,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close',
                onPressed: onClose ?? () => exit(0),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.error.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                color: colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The ShopGateScreen checks for the existence of a shop in the database
/// and navigates to the appropriate form (add or update) accordingly.
class ShopGateScreen extends StatefulWidget {
  const ShopGateScreen({Key? key}) : super(key: key);

  @override
  State<ShopGateScreen> createState() => _ShopGateScreenState();
}

class _ShopGateScreenState extends State<ShopGateScreen> {
  Future<Shop?>? _shopFuture;

  @override
  void initState() {
    super.initState();
    _shopFuture = ShopHelper.instance.getShop(1); // Pass id 1
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Shop?>(
      future: _shopFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final shop = snapshot.data;
        // If no shop, show add form; else, show update form
        return ShopFormScreen(
          shop: shop, // null for add, not null for update
        );
      },
    );
  }
}