import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import '../models/user_model.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const Center(child: Text('المخزون')),
    const Center(child: Text('المبيعات')),
    const Center(child: Text('العملاء')),
    const Center(child: Text('التقارير')),
  ];

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser!;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام إدارة قطع غيار MG - مصر'),
        backgroundColor: Colors.blue[700],
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _getRoleText(user.role),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.blue),
                  ),
                  onSelected: (value) async {
                    if (value == 'profile') {
                      _showProfileDialog();
                    } else if (value == 'logout') {
                      await _logout();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline),
                          SizedBox(width: 12),
                          Text('الملف الشخصي'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 12),
                          Text('تسجيل الخروج', 
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[900]!],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 50, color: Colors.blue),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '📊 ${_getRoleText(user.role)} - صلاحيات محدودة',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard,
                    title: 'لوحة التحكم',
                    index: 0,
                  ),
                  _buildDrawerItem(
                    icon: Icons.inventory_2_outlined,
                    title: 'المخزون',
                    index: 1,
                    enabled: user.canViewInventory,
                  ),
                  _buildDrawerItem(
                    icon: Icons.point_of_sale,
                    title: 'المبيعات',
                    index: 2,
                    enabled: user.canMakeSales,
                  ),
                  _buildDrawerItem(
                    icon: Icons.people_outline,
                    title: 'العملاء',
                    index: 3,
                    enabled: user.hasPermission(Permission.viewCustomers),
                  ),
                  _buildDrawerItem(
                    icon: Icons.assessment_outlined,
                    title: 'التقارير',
                    index: 4,
                    enabled: user.hasPermission(Permission.viewReports),
                  ),
                  const Divider(),
                  
                  ListTile(
                    leading: Icon(Icons.admin_panel_settings, color: Colors.grey[400]),
                    title: Row(
                      children: [
                        Text(
                          'إدارة المستخدمين',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.lock, size: 16, color: Colors.grey),
                      ],
                    ),
                    enabled: false,
                  ),
                  ListTile(
                    leading: Icon(Icons.settings_outlined, color: Colors.grey[400]),
                    title: Row(
                      children: [
                        Text(
                          'الإعدادات',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.lock, size: 16, color: Colors.grey),
                      ],
                    ),
                    enabled: false,
                  ),
                ],
              ),
            ),
            
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: Colors.red),
              ),
              onTap: _logout,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      
      body: _screens[_selectedIndex],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    bool enabled = true,
  }) {
    final isSelected = _selectedIndex == index;
    
    return ListTile(
      leading: Icon(
        icon,
        color: !enabled 
            ? Colors.grey[400] 
            : isSelected 
                ? Colors.blue[700] 
                : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: !enabled 
              ? Colors.grey[400] 
              : isSelected 
                  ? Colors.blue[700] 
                  : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue[50],
      enabled: enabled,
      onTap: enabled ? () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      } : null,
    );
  }

  void _showProfileDialog() {
    final user = AuthService.currentUser!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الملف الشخصي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileRow('الاسم', user.name),
            _buildProfileRow('البريد', user.email),
            _buildProfileRow('الهاتف', user.phone),
            _buildProfileRow('الدور', _getRoleText(user.role)),
            const Divider(),
            const Text(
              'الصلاحيات:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: user.permissions.map((p) {
                return Chip(
                  label: Text(
                    _getPermissionText(p),
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: Colors.blue[50],
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'المالك';
      case UserRole.manager:
        return 'المدير';
      case UserRole.inventoryManager:
        return 'مشرف المخزون';
      case UserRole.employee:
        return 'موظف';
    }
  }

  String _getPermissionText(Permission permission) {
    switch (permission) {
      case Permission.viewInventory:
        return 'عرض المخزون';
      case Permission.addInventory:
        return 'إضافة للمخزون';
      case Permission.editInventory:
        return 'تعديل المخزون';
      case Permission.deleteInventory:
        return 'حذف من المخزون';
      case Permission.makeSales:
        return 'إجراء مبيعات';
      case Permission.viewSales:
        return 'عرض المبيعات';
      case Permission.viewCustomers:
        return 'عرض العملاء';
      case Permission.addCustomers:
        return 'إضافة عملاء';
      case Permission.viewReports:
        return 'عرض التقارير';
      case Permission.viewEmployees:
        return 'عرض الموظفين';
      case Permission.manageEmployees:
        return 'إدارة الموظفين';
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}