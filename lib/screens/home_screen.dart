import 'package:flutter/material.dart';
import 'package:pink_and_blue/providers/cart_provider.dart';
import 'package:pink_and_blue/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'menu_screen.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'admin_orders_screen.dart'; // New screen
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).checkUserRole();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final isAdmin = authProvider.role == UserRole.admin;
    final user = Supabase.instance.client.auth.currentUser;

    // Dynamic screens based on role
    final List<Widget> screens = isAdmin
        ? [
            const MenuScreen(),
            const CartScreen(),
            const AdminOrdersScreen(), // Special screen for admin
          ]
        : [
            const MenuScreen(),
            const CartScreen(),
            if (user != null) const OrderHistoryScreen(),
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pink & Blue",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF69B4),
        foregroundColor: Colors.white,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, size: 28),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminPanel())),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ); // or push to LoginScreen
              }
            },
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFFF69B4),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: isAdmin
            ? [
                const BottomNavigationBarItem(
                    icon: Icon(Icons.menu_book), label: "Menu"),
                BottomNavigationBarItem(
                  icon: Badge(
                    label: Text(cartProvider.totalItemCount.toString()),
                    isLabelVisible: cartProvider.totalItemCount > 0,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.shopping_cart),
                  ),
                  label: "Cart",
                ),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.assignment), label: "All Orders"),
              ]
            : [
                const BottomNavigationBarItem(
                    icon: Icon(Icons.menu_book), label: "Menu"),
                BottomNavigationBarItem(
                  icon: Badge(
                    label: Text(cartProvider.totalItemCount.toString()),
                    isLabelVisible: cartProvider.totalItemCount > 0,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.shopping_cart),
                  ),
                  label: "Cart",
                ),
                if (user != null)
                  const BottomNavigationBarItem(
                      icon: Icon(Icons.history), label: "History"),
              ],
      ),
    );
  }
}
