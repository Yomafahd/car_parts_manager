enum Permission {
  // Inventory
  viewInventory,
  addInventory,
  editInventory,
  deleteInventory,

  // Sales
  makeSales,
  viewSales,

  // Customers
  viewCustomers,
  addCustomers,

  // Reports
  viewReports,

  // Employees/Users
  viewEmployees,
  manageEmployees,
}

enum UserRole {
  owner,           // المالك - صلاحيات كاملة
  manager,         // المدير - إدارة الموظفين والتقارير
  employee,        // الموظف - بيع وعمليات أساسية
  inventoryManager // مشرف المخزون - إدارة المخزون فقط
}

class SystemUser {
  String id;
  String name;
  String email;
  String phone;
  UserRole role;
  List<Permission> permissions;
  bool isActive;
  String? passwordHash; // demo-only: hashed password

  static List<Permission> _getDefaultPermissions(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Permission.values;
      case UserRole.manager:
        return [
          Permission.viewInventory,
          Permission.addInventory,
          Permission.editInventory,
          Permission.makeSales,
          Permission.viewSales,
          Permission.viewCustomers,
          Permission.addCustomers,
          Permission.viewReports,
          Permission.viewEmployees,
        ];
      case UserRole.employee:
        return [
          Permission.viewInventory,
          Permission.makeSales,
          Permission.viewSales,
          Permission.viewCustomers,
        ];
      case UserRole.inventoryManager:
        return [
          Permission.viewInventory,
          Permission.addInventory,
          Permission.editInventory,
          Permission.deleteInventory,
        ];
    }
  }

  SystemUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    List<Permission>? permissions,
    this.isActive = true,
    this.passwordHash,
  }) : permissions = permissions ?? _getDefaultPermissions(role);

  bool hasPermission(Permission permission) => permissions.contains(permission);

  bool get canViewInventory => hasPermission(Permission.viewInventory);
  bool get canAddInventory => hasPermission(Permission.addInventory);
  bool get canEditInventory => hasPermission(Permission.editInventory);
  bool get canDeleteInventory => hasPermission(Permission.deleteInventory);
  bool get canMakeSales => hasPermission(Permission.makeSales);
  bool get canManageUsers => hasPermission(Permission.manageEmployees);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.toString(),
      'permissions': permissions.map((p) => p.toString()).toList(),
      'isActive': isActive,
      'passwordHash': passwordHash,
    };
  }

  factory SystemUser.fromMap(Map<String, dynamic> map) {
    return SystemUser(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      role: UserRole.values.firstWhere((e) => e.toString() == map['role']),
      permissions: (map['permissions'] as List<dynamic>)
          .map((p) => Permission.values.firstWhere((e) => e.toString() == p))
          .toList(),
      isActive: (map['isActive'] as bool?) ?? true,
      passwordHash: map['passwordHash'] as String?,
    );
  }
}
