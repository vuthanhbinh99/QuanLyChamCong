import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'dart:io';
import 'dart:async';

class AuthController extends ChangeNotifier {
  final ApiService apiService;
  String? get currentUserId => _user?.id;
  String? get currentUserRole => _user?.role;

  User? _user;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isConnected = true;

  AuthController(this.apiService) {
    _loadStoredUser(); // Tự động tải user khi khởi tạo
  }



  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;

  // Tải thông tin user từ Shared Preferences
  Future<void> _loadStoredUser() async {
    try {
      final storedUser = await AuthService.getUser();
      if (storedUser != null) {
        _user = User.fromJson(storedUser);
        notifyListeners();
        print('✅ Đã tải user từ storage: ${_user?.id}');
      }
    } catch (e) {
      print('❌ Lỗi tải user từ storage: $e');
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Kiểm tra kết nối server
      _isConnected = await apiService.healthCheck();
      if (!_isConnected) {
        _errorMessage = "Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Gọi API login
      final result = await apiService.login(username, password);
      
      if (result != null && result['success'] == true) {
        _user = User.fromJson(result);
        // Lưu thông tin user vào Shared Preferences
        await AuthService.saveUser(result);
        
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } 
      if (result != null && result.containsKey('error')) {
         _errorMessage = result['error']; // Lấy lỗi từ Backend
      } else {
         _errorMessage = "Thông tin đăng nhập không chính xác.";
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } on SocketException {
      _errorMessage = "Không tìm thấy Máy chủ Chấm công.\nHãy đảm bảo bạn đang kết nối đúng mạng nội bộ.";
      _isLoading = false;
      notifyListeners();
      return false;
    }on TimeoutException{
     _errorMessage = "Hệ thống chấm công phản hồi quá lâu.\nVui lòng thử lại sau giây lát.";
      _isLoading = false;
      notifyListeners();
      return false;
    }catch (e) {
   String errorMsg = e.toString();
      if (errorMsg.startsWith("Exception: ")) {
        errorMsg = errorMsg.replaceFirst("Exception: ", "");
      }
      _errorMessage = errorMsg;
      print("⚠️ Lỗi đăng nhập: $errorMsg");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    // Xóa dữ liệu khỏi Shared Preferences
    await AuthService.logout();
    
    _user = null;
    _errorMessage = null;
    notifyListeners();
    
    print('✅ Đã đăng xuất');
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Kiểm tra trạng thái đăng nhập
  Future<bool> checkLoggedInStatus() async {
    return await AuthService.isLoggedIn();
  }

  // Helper methods
  bool get isLoggedIn => _user != null;
  bool get isEmployee => _user?.isNhanVien ?? false;
  bool get isManager => _user?.isQuanLy ?? false;
  bool get isAdmin => _user?.isQuanTriVien ?? false;

  // Kiểm tra kết nối server
  Future<void> checkConnection() async {
    _isConnected = await apiService.healthCheck();
    notifyListeners();
  }

  // Refresh user data từ storage
  Future<void> refreshUserData() async {
    await _loadStoredUser();
  }
}