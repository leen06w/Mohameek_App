import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class SessionService {
  static const _userKey = 'app_user';
  static const _accessTokenKey = 'accessToken';

  Future<void> saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toMap()));
  }

  Future<AppUser?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_userKey);

    if (json == null) return null;

    return AppUser.fromMap(jsonDecode(json));
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    final user = await getUser();
    return user != null;
  }
}