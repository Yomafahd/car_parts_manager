import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'users_management_screen.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  List<SystemUser> _users = [];
  // Email/password fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await AuthService.getAllUsers();
    if (!mounted) return;
    setState(() {
      _users = users;
      _loading = false;
      // Seed demo owner password if missing
      if (_users.isNotEmpty && _users.first.passwordHash == null) {
        // no-op here; owner still can log in via user picker below
      }
    });
  }

  Future<void> _loginWithEmailPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await AuthService.loginWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ بيانات الدخول غير صحيحة'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        actions: [
          IconButton(
            tooltip: 'تحديث المستخدمين',
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh),
          ),
          if (AuthService.currentUser?.canManageUsers ?? true)
            IconButton(
              tooltip: 'إدارة المستخدمين',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UsersManagementScreen()),
                );
              },
              icon: const Icon(Icons.manage_accounts),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'تسجيل الدخول',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'أدخل البريد الإلكتروني' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'كلمة المرور',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'أدخل كلمة المرور' : null,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loginWithEmailPassword,
                          icon: const Icon(Icons.login),
                          label: const Text('تسجيل الدخول'),
                          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          'أو اختر مستخدمًا سريعًا (للتجربة)',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: _users.map((u) {
                            return OutlinedButton.icon(
                              onPressed: u.isActive
                                  ? () {
                                      AuthService.setCurrentUser(u);
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                            builder: (_) => const MainNavigationScreen()),
                                      );
                                    }
                                  : null,
                              icon: Icon(_roleIcon(u.role)),
                              label: Text(u.name),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  IconData _roleIcon(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Icons.security;
      case UserRole.manager:
        return Icons.manage_accounts;
      case UserRole.employee:
        return Icons.person;
      case UserRole.inventoryManager:
        return Icons.inventory_2;
    }
  }
}
