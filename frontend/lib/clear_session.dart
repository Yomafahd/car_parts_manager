import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  print('تم مسح الجلسة');
}
