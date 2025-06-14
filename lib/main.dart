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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize database
  await DatabaseHelper.instance.database;

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
            home: const LoginRegisterScreen(),
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