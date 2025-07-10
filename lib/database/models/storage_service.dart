import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const String _tokenKey = 'access_token';
  static const String _userProfileKey = 'user_profile';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProfileKey, jsonEncode(profile));
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileString = prefs.getString(_userProfileKey);
    return profileString != null ? jsonDecode(profileString) : null;
  }

  static Future<void> clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}