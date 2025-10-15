import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLoggedIn = await AuthService.checkLoggedIn();
  runApp(MyApp(initialLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool initialLoggedIn;
  const MyApp({super.key, required this.initialLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام إدارة قطع الغيار',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Tajawal',
      ),
      home: initialLoggedIn ? const MainNavigationScreen() : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
 
