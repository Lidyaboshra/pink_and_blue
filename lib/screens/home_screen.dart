import 'package:flutter/material.dart';
import 'menu_screen.dart';
import 'cart_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin_panel.dart';   // Make sure this import exists

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
    // Check role when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).checkUserRole();
    });
  }

  final List<Widget> _screens = [
    const MenuScreen(),
    const CartScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pink & Blue", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF69B4),
        foregroundColor: Colors.white,
        actions: [
          // Admin Button
          if (authProvider.role == UserRole.admin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, size: 28),
              tooltip: "Admin Panel",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPanel()),
                );
              },
            ),
          
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login'); // or push to LoginScreen
              }
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFFF69B4),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Menu"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
        ],
      ),
    );
  }
}