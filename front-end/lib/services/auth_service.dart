import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _userKey = 'user_data';

  // Lưu thông tin user (bao gồm cả thông tin đăng nhập)
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  // Lấy thông tin user đã lưu
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  // Xóa tất cả dữ liệu đăng nhập
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Kiểm tra xem user đã đăng nhập chưa
  static Future<bool> isLoggedIn() async {
    final userData = await getUser();
    return userData != null && 
           userData['id'] != null && 
           userData['id'].toString().isNotEmpty;
  }

  // Lấy ID user nhanh
  static Future<String?> getUserId() async {
    final userData = await getUser();
    return userData?['id']?.toString();
  }

  // Lấy role user nhanh
  static Future<String?> getUserRole() async {
    final userData = await getUser();
    return userData?['role']?.toString();
  }

  // Lấy thông tin chi tiết user
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final userData = await getUser();
    return userData?['user_info'];
  }

  // Kiểm tra role cụ thể
  static Future<bool> isUserRole(String role) async {
    final userRole = await getUserRole();
    return userRole?.toLowerCase() == role.toLowerCase();
  }

  // Lưu thêm thông tin tùy chỉnh
  static Future<void> saveCustomData(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    }
  }

  // Lấy thông tin tùy chỉnh
  static Future<dynamic> getCustomData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.get(key);
  }
}