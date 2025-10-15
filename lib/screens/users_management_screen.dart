import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  List<SystemUser> _users = [];
  bool _isLoading = true;

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
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentUser!;
    if (!currentUser.canManageUsers) {
      return Scaffold(
        appBar: AppBar(title: const Text('غير مصرح')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('غير مصرح لك بالوصول إلى هذه الصفحة'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('العودة'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة المستخدمين - ${_users.length}')
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: _getUserRoleIcon(user.role),
                    title: Text(user.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email),
                        Text(
                          _getRoleName(user.role),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user.isActive ? Icons.check_circle : Icons.block,
                          color: user.isActive ? Colors.green : Colors.red,
                        ),
                        if (currentUser.role == UserRole.owner)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editUser(user),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: currentUser.role == UserRole.owner
          ? FloatingActionButton(
              onPressed: _addNewUser,
              backgroundColor: Colors.purple[700],
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }

  Icon _getUserRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return const Icon(Icons.security, color: Colors.red);
      case UserRole.manager:
        return const Icon(Icons.manage_accounts, color: Colors.orange);
      case UserRole.employee:
        return const Icon(Icons.person, color: Colors.blue);
      case UserRole.inventoryManager:
        return const Icon(Icons.inventory_2, color: Colors.green);
    }
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'مالك النظام';
      case UserRole.manager:
        return 'مدير';
      case UserRole.employee:
        return 'موظف';
      case UserRole.inventoryManager:
        return 'مشرف مخزون';
    }
  }

  void _addNewUser() {
    showDialog(
      context: context,
      builder: (context) => AddUserDialog(onUserAdded: _loadUsers),
    );
  }

  void _editUser(SystemUser user) {
    showDialog(
      context: context,
      builder: (context) => EditUserDialog(user: user, onUserUpdated: _loadUsers),
    );
  }
}

class AddUserDialog extends StatefulWidget {
  final VoidCallback onUserAdded;
  const AddUserDialog({super.key, required this.onUserAdded});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.employee;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة مستخدم جديد'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'الاسم الكامل'),
              validator: (value) => (value == null || value.isEmpty) ? 'يرجى إدخال الاسم' : null,
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
              validator: (value) => (value == null || value.isEmpty) ? 'يرجى إدخال البريد الإلكتروني' : null,
            ),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'رقم الهاتف'),
            ),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور'),
              validator: (value) => (value == null || value.isEmpty) ? 'يرجى إدخال كلمة المرور' : null,
            ),
            DropdownButtonFormField<UserRole>(
              initialValue: _selectedRole,
              items: UserRole.values
                  .map((role) => DropdownMenuItem(value: role, child: Text(_getRoleName(role))))
                  .toList(),
              onChanged: (value) => setState(() => _selectedRole = value ?? UserRole.employee),
              decoration: const InputDecoration(labelText: 'الدور'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: _addUser, child: const Text('إضافة')),
      ],
    );
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'مالك';
      case UserRole.manager:
        return 'مدير';
      case UserRole.employee:
        return 'موظف';
      case UserRole.inventoryManager:
        return 'مشرف مخزون';
    }
  }

  Future<void> _addUser() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final newUser = SystemUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _selectedRole,
    );
    await AuthService.addUser(newUser, _passwordController.text);
    if (!mounted) return;
    Navigator.pop(context);
    widget.onUserAdded();
  }
}

class EditUserDialog extends StatefulWidget {
  final SystemUser user;
  final VoidCallback onUserUpdated;
  const EditUserDialog({super.key, required this.user, required this.onUserUpdated});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  UserRole _selectedRole = UserRole.employee;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _selectedRole = widget.user.role;
    _isActive = widget.user.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل مستخدم'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'الاسم الكامل'),
              validator: (value) => (value == null || value.isEmpty) ? 'يرجى إدخال الاسم' : null,
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
            ),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'رقم الهاتف'),
            ),
            DropdownButtonFormField<UserRole>(
              initialValue: _selectedRole,
              items: UserRole.values
                  .map((role) => DropdownMenuItem(value: role, child: Text(_getRoleName(role))))
                  .toList(),
              onChanged: (value) => setState(() => _selectedRole = value ?? UserRole.employee),
              decoration: const InputDecoration(labelText: 'الدور'),
            ),
            SwitchListTile(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              title: const Text('نشط'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: _save, child: const Text('حفظ')),
      ],
    );
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'مالك';
      case UserRole.manager:
        return 'مدير';
      case UserRole.employee:
        return 'موظف';
      case UserRole.inventoryManager:
        return 'مشرف مخزون';
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = SystemUser(
      id: widget.user.id,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _selectedRole,
      isActive: _isActive,
      permissions: widget.user.permissions,
    );
    await AuthService.updateUser(updated);
    if (!mounted) return;
    Navigator.pop(context);
    widget.onUserUpdated();
  }
}
