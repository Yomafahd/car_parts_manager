import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert' as conv;
import '../models/user_model.dart';

class AuthService {
  static SystemUser? _currentUser;

  static SystemUser? get currentUser => _currentUser;

  static void setCurrentUser(SystemUser user) {
    _currentUser = user;
  }

  static const String _usersKey = 'system_users';
  static const String _currentUserKey = 'current_user';

  // Internal helper to load all users from storage, seeding with owner if empty
  static Future<List<SystemUser>> _getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null) {
      // Seed with a default owner account
      final owner = SystemUser(
        id: '1',
        name: 'Owner',
        email: 'owner@example.com',
        phone: '0000000000',
        role: UserRole.owner,
        passwordHash: _hashPassword('admin123'), // default demo password
      );
      await prefs.setString(_usersKey, json.encode([owner.toMap()]));
      return [owner];
    }
    final List<dynamic> list = json.decode(raw) as List<dynamic>;
    return list
        .map((e) => SystemUser.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<List<SystemUser>> getAllUsers() async {
    return _getAllUsers();
  }

  static Future<void> _saveAllUsers(List<SystemUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, json.encode(users.map((u) => u.toMap()).toList()));
  }

  static Future<void> addUser(SystemUser user, String password) async {
    // Store a hash of the password for demo purposes
    user.passwordHash = _hashPassword(password);
    final users = await _getAllUsers();
    users.add(user);
    await _saveAllUsers(users);
  }

  static Future<void> updateUser(SystemUser updatedUser) async {
    final users = await _getAllUsers();
    final idx = users.indexWhere((u) => u.id == updatedUser.id);
    if (idx != -1) {
      users[idx] = updatedUser;
      await _saveAllUsers(users);
      // update current user cache if same id
      if (_currentUser?.id == updatedUser.id) {
        _currentUser = updatedUser;
      }
    }
  }

  // Demo-only password hashing and login
  static String _hashPassword(String password) {
    final bytes = conv.utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<bool> loginWithEmailAndPassword(String email, String password) async {
    final users = await _getAllUsers();
    final user = users.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
      orElse: () => SystemUser(
        id: '',
        name: '',
        email: '',
        phone: '',
        role: UserRole.employee,
      ),
    );
    if (user.id.isEmpty) return false;
    if (!(user.isActive)) return false;
    final hash = _hashPassword(password);
    final ok = user.passwordHash != null && user.passwordHash == hash;
    if (ok) {
      setCurrentUser(user);
      await _saveCurrentUser(user);
    }
    return ok;
  }

  static Future<bool> checkLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_currentUserKey);
    if (raw == null) return false;
    try {
      final Map<String, dynamic> map = json.decode(raw) as Map<String, dynamic>;
      final user = SystemUser.fromMap(map);
      _currentUser = user;
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> persistCurrentUser() async {
    final user = _currentUser;
    if (user == null) return;
    await _saveCurrentUser(user);
  }

  static Future<void> _saveCurrentUser(SystemUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, json.encode(user.toMap()));
  }

  static Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }
}
