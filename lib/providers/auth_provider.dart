import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyLastUserName = 'last_user_name'; // Add this
  static const String guestId = 'guest';

  String _userId = guestId;
  String _userName = 'Guest';

  String get userId => _userId;
  String get userName => _userName;
  bool get isGuest => _userId == guestId;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString(_keyUserId) ?? guestId;
    _userName = prefs.getString(_keyUserName) ?? 'Guest';
    notifyListeners();
  }

  // Get the last successfully logged in username for auto-fill
  Future<String> getLastLoginUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastUserName) ?? '';
  }

  Future<void> login(String username, String password) async {
    // 模拟登录：只要用户名不为空
    if (username.isEmpty) return;

    // 简单模拟: user_id = username_md5 (或者直接用 username 当 ID)
    // 为了防止与 'guest' 冲突，加个前缀
    final newUserId = 'user_$username';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, newUserId);
    await prefs.setString(_keyUserName, username);
    await prefs.setString(_keyLastUserName, username); // Save to history

    _userId = newUserId;
    _userName = username;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);

    _userId = guestId;
    _userName = 'Guest';
    notifyListeners();
  }
}
