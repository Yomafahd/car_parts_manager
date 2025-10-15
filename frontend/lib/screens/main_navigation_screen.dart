import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'owner_manager_screen.dart';
import 'dashboard_screen.dart';
import 'competitors_screen.dart';
import 'login_screen.dart';
import 'inventory_screen.dart' if (dart.library.html) 'inventory_screen_web_fixed.dart' as inv;
import 'ai_assistant_screen.dart';
import 'home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = 1; // Dashboard بدلاً من HomeScreen
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser!;

    final screens = <Widget>[
      const HomeScreen(),
      const DashboardScreen(),
      const inv.InventoryScreen(),
      const CompetitorsScreen(),
      const AIAssistantScreen(),
      if (user.role == UserRole.owner || user.role == UserRole.manager) const OwnerManagerScreen(),
    ];

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'الرئيسية',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'لوحة التحكم',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.inventory_2),
        label: 'المخزون',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.groups_3),
        label: 'المنافسون في مصر',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.auto_awesome),
        label: 'المساعد الذكي',
      ),
      if (user.role == UserRole.owner || user.role == UserRole.manager)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'الإدارة',
        ),
    ];

    // Ensure index is valid if permissions changed
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    // Determine a safe, effective index and label for the title
    final int effectiveIndex = _currentIndex.clamp(0, items.length - 1).toInt();
    // ignore: avoid_print
    print('[FrontendMainNav] effectiveIndex=$effectiveIndex currentIndex=$_currentIndex');
    final currentLabel = items[effectiveIndex].label ?? '';
    final bool isHome = effectiveIndex == 0;

    return Scaffold(
      appBar: isHome
          ? null
          : AppBar(
              title: Row(
                children: [
                  const Icon(Icons.car_repair),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'متجر الأبرار لقطع الغيار — مرحباً ${user.name}${currentLabel.isNotEmpty ? ' - $currentLabel' : ''}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: _getColorByRole(user.role),
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  tooltip: 'المساعد',
                  icon: const Icon(Icons.auto_awesome),
                  onPressed: () => setState(() => _currentIndex = 4),
                ),
                IconButton(
                  tooltip: 'بحث',
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // Placeholder: open a search dialog or navigate to search screen
                    showSearchNotice();
                  },
                ),
                IconButton(
                  tooltip: 'سلة التسوق',
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    showCartNotice();
                  },
                ),
                IconButton(
                  tooltip: 'المتجر',
                  icon: const Icon(Icons.storefront),
                  onPressed: _openStoreLandingPage,
                ),
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
      body: screens[effectiveIndex],
      floatingActionButton: isHome
          ? null
          : FloatingActionButton(
              heroTag: 'ai-fab',
              backgroundColor: Colors.teal.shade600,
              tooltip: 'المساعد الذكي',
              child: const Icon(Icons.auto_awesome, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
                );
              },
            ),
      floatingActionButtonLocation: isHome ? null : FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: effectiveIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: _getColorByRole(user.role),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
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

  Future<void> _openStoreLandingPage() async {
    if (!kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('صفحة المتجر متاحة على نسخة الويب فقط')),
      );
      return;
    }
    final uri = Uri.parse('${Uri.base.origin}/landing.html');
    final ok = await launchUrl(
      uri,
      webOnlyWindowName: '_blank',
      mode: LaunchMode.platformDefault,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح صفحة المتجر')),
      );
    }
  }

  void showSearchNotice() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة البحث سيتم تفعيلها لاحقاً')),
    );
  }

  void showCartNotice() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سلة التسوق مجرد عرض توضيحي حالياً')),
    );
  }
}
