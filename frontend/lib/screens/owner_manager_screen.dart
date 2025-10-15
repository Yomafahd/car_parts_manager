import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'users_management_screen.dart';
import 'api_manager_screen.dart';
import 'finance_pricing_screen.dart';

class OwnerManagerScreen extends StatelessWidget {
  const OwnerManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = AuthService.currentUser;
    if (me == null || (me.role != UserRole.owner && me.role != UserRole.manager)) {
      return const Center(child: Text('هذه الشاشة مخصصة للمالك/المدير'));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('الإدارة — المالك/المدير')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _AdminCard(
              color: Colors.indigo,
              icon: Icons.people,
              title: 'المستخدمين والصلاحيات',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UsersManagementScreen()),
              ),
            ),
            _AdminCard(
              color: Colors.teal,
              icon: Icons.key,
              title: 'إدارة مفاتيح وواجهات API',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ApiManagerScreen()),
              ),
            ),
            _AdminCard(
              color: Colors.orange,
              icon: Icons.attach_money,
              title: 'التمويل والتسعير',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FinancePricingScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _AdminCard({required this.color, required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 42),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
