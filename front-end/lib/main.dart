import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'services/api_service.dart';
import 'views/login_view.dart';
import 'views/nhanvien/home_nhanvien_view.dart';
import 'views/quanly/home_quanly_view.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => ApiService()),
        ChangeNotifierProvider(create: (context) => AuthController(context.read<ApiService>())),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý chấm công',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authController = context.read<AuthController>();
    
    final isLoggedIn = await authController.checkLoggedInStatus();
    
    if (isLoggedIn && authController.user == null) {
      await authController.refreshUserData();
    }
    FlutterNativeSplash.remove();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();


    if (authController.isLoggedIn) {
      return _buildHomeByRole(authController);
    } else {
      return const LoginView();
    }
  }

  Widget _buildHomeByRole(AuthController authController) {
    final user = authController.user;
    if (user == null) return const LoginView();
    
    switch (user.role) {
      case 'NhanVien':
        return HomeNhanVienView(currentUser: user);
      case 'QuanLy':
        return HomeQuanLyView(
          role: user.role,
          maQL: user.id,
          hoTenQL: user.hoTen,
        );
      default:
        return const LoginView();
    }
  }
}