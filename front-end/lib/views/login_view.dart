import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../controllers/auth_controller.dart';
import 'package:quanlychamcong/views/Cham_cong.dart';
import 'package:quanlychamcong/views/nhanvien/home_nhanvien_view.dart';
import 'package:quanlychamcong/views/quanly/home_quanly_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoading = false;

  void login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên đăng nhập và mật khẩu')),
      );
      return;
    }

    setState(() => isLoading = true);

    final authController = context.read<AuthController>();
    final success = await authController.login(
      _usernameController.text,
      _passwordController.text,
    );

    setState(() => isLoading = false);

    if (success && authController.user != null) {
      _navigateToHome(authController.user!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authController.errorMessage ?? 'Đăng nhập thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToHome(User user) {
    Widget homePage;
    switch (user.role) {
      case 'NhanVien':
        homePage = HomeNhanVienView(currentUser: user);
        break;
      case 'QuanLy':
        homePage = HomeQuanLyView(role: user.role);
        break;
      default:
        homePage = const LoginView();
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => homePage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập hệ thống')),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Thêm spacing phía trên để căn giữa khi không có bàn phím
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            
            // Logo hoặc icon app
            const Icon(
              Icons.fingerprint,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            
            const Text(
              'QUẢN LÝ CHẤM CÔNG',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 40),
            
            // Form đăng nhập
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Tên đăng nhập',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              onSubmitted: (_) => login(),
            ),
            const SizedBox(height: 30),
            
            // Nút đăng nhập
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : login,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'ĐĂNG NHẬP',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Nút Chấm công (không cần đăng nhập)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChamCongView()),
                  );
                },
                child: const Text(
                  'CHẤM CÔNG',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            
            // Thông báo lỗi
            if (context.watch<AuthController>().errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  context.watch<AuthController>().errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            // Spacing phía dưới
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}