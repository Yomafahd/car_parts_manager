import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import '../models/user_model.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const Center(child: Text('المخزون')),
    const Center(child: Text('المبيعات')),
    const Center(child: Text('العملاء')),
    const UsersManagementScreen(),
    const Center(child: Text('التقارير المتقدمة')),
    const Center(child: Text('الإعدادات')),
  ];

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser!;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام إدارة قطع غيار MG - مصر'),
        backgroundColor: Colors.red[700],
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
                      'المالك',
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
                    child: Icon(Icons.person, color: Colors.red),
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
                  colors: [Colors.red[700]!, Colors.red[900]!],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 50, color: Colors.red),
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
                    child: const Text(
                      '👑 المالك - صلاحيات كاملة',
                      style: TextStyle(
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
                  ),
                  _buildDrawerItem(
                    icon: Icons.point_of_sale,
                    title: 'المبيعات',
                    index: 2,
                  ),
                  _buildDrawerItem(
                    icon: Icons.people_outline,
                    title: 'العملاء',
                    index: 3,
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.admin_panel_settings,
                    title: 'إدارة المستخدمين',
                    index: 4,
                    badge: '👑',
                  ),
                  _buildDrawerItem(
                    icon: Icons.analytics_outlined,
                    title: 'التقارير المتقدمة',
                    index: 5,
                    badge: '👑',
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'الإعدادات',
                    index: 6,
                    badge: '👑',
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
    String? badge,
  }) {
    final isSelected = _selectedIndex == index;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.red[700] : Colors.grey[700],
      ),
      title: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.red[700] : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Text(badge, style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
      selected: isSelected,
      selectedTileColor: Colors.red[50],
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
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
            _buildProfileRow('الدور', 'المالك'),
            _buildProfileRow('الصلاحيات', 'جميع الصلاحيات'),
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

class UsersManagementScreen extends StatelessWidget {
  const UsersManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<SystemUser>>(
        future: AuthService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا يوجد مستخدمون'));
          }
          
          final users = snapshot.data!;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getRoleColor(user.role),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(user.name),
                  subtitle: Text('${user.email}\n${_getRoleText(user.role)}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!user.isActive)
                        const Chip(
                          label: Text('غير نشط', style: TextStyle(fontSize: 10)),
                          backgroundColor: Colors.grey,
                        ),
                      const SizedBox(width: 8),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('تعديل'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('حذف'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: Colors.red[700],
        icon: const Icon(Icons.add),
        label: const Text('إضافة مستخدم'),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Colors.red[700]!;
      case UserRole.manager:
        return Colors.blue[700]!;
      case UserRole.inventoryManager:
        return Colors.green[700]!;
      case UserRole.employee:
        return Colors.orange[700]!;
    }
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
}
