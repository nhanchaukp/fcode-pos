import 'dart:convert';
import 'package:fcode_pos/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPrefs {
  static const _keyUser = 'user_info';

  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_keyUser, jsonEncode(user.toMap()));
  }

  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyUser);
    if (data == null) return null;
    return User.fromJson(jsonDecode(data));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_keyUser);
  }
}
