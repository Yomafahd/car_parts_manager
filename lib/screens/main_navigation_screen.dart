import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'users_management_screen.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'inventory_screen.dart' if (dart.library.html) 'inventory_screen_web.dart' as inv;

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser!;

    final screens = <Widget>[
      const inv.InventoryScreen(),
      const DashboardScreen(),
      if (user.canManageUsers) const UsersManagementScreen(),
    ];

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.inventory_2),
        label: 'المخزون',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'لوحة التحكم',
      ),
      if (user.canManageUsers)
        const BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'المستخدمين',
        ),
    ];

    // Ensure index is valid if permissions changed
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('مرحباً ${user.name}'),
        backgroundColor: _getColorByRole(user.role),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: items,
      ),
    );
  }

  Color _getColorByRole(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Colors.red.shade700;
      case UserRole.manager:
        return Colors.orange.shade700;
      case UserRole.inventoryManager:
        return Colors.green.shade700;
      case UserRole.employee:
        return Colors.blue.shade700;
    }
  }
}
