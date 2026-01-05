import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:quanlychamcong/services/api_service.dart';
import 'package:quanlychamcong/views/dang_ky_guong_mat_view.dart'; 
import 'quanly_don_xin.dart';
import 'package:quanlychamcong/views/quanly/bao_cao_view.dart';
import 'package:quanlychamcong/views/quanly/danh_sach_nhan_vien_view.dart';
import 'package:quanlychamcong/controllers/auth_controller.dart';
import 'package:quanlychamcong/views/login_view.dart';
import 'package:quanlychamcong/views/quanly/cham_cong_nhan_vien.dart';
import 'package:quanlychamcong/views/user_guide_view.dart';

class HomeQuanLyView extends StatefulWidget {
  final String role;
  final String? maQL;
  final String? hoTenQL;

  const HomeQuanLyView({
    super.key, 
    required this.role,
    this.maQL,
    this.hoTenQL,
  });

  @override
  State<HomeQuanLyView> createState() => _HomeQuanLyViewState();
}

class _HomeQuanLyViewState extends State<HomeQuanLyView> {
  final ApiService apiService = ApiService();
  
  List<Map<String, dynamic>> _chamCongList = [];
  bool _isLoading = false;
  int _pendingDonXinCount = 0;
  
  late String _maQL;
  late String _hoTenQL;

  final List<MenuItem> menuItems = const [
    MenuItem(title: 'Duyệt đơn xin', icon: Icons.assignment_turned_in, route: '/duyet_don_xin'),
    MenuItem(title: 'Danh sách nhân viên', icon: Icons.group, route: '/danh_sach_nhan_vien'),
    MenuItem(title: 'Xem báo cáo phòng', icon: Icons.bar_chart, route: '/xem_bao_cao_phong'),
    MenuItem(title: 'Chấm công nhân viên', icon: Icons.fingerprint, route: '/cham_cong_nhan_vien'),
    MenuItem(title: 'Đăng ký gương mặt', icon: Icons.face, route: '/dang_ky_guong_mat'),
  ];

  @override
  void initState() {
    super.initState();
    final authController = context.read<AuthController>();
    _maQL = widget.maQL ?? authController.currentUserId ?? 'QL001';
    _hoTenQL = widget.hoTenQL ?? 'Quản Lý';
    
    _loadChamCongToday();
    _loadPendingDonXin();
    // Auto refresh mỗi 30 giây
    Future.delayed(const Duration(seconds: 30), _autoRefresh);
  }

  Future<void> _autoRefresh() async {
    if (mounted) {
      await _loadChamCongToday();
      await _loadPendingDonXin();
      Future.delayed(const Duration(seconds: 30), _autoRefresh);
    }
  }

  Future<void> _loadPendingDonXin() async {
    try {
      // TODO: Gọi API để lấy số lượng đơn chưa duyệt
      // Tạm thời để 0
      setState(() => _pendingDonXinCount = 0);
    } catch (e) {
      print('Error loading pending don xin: $e');
    }
  }

  Future<void> _loadChamCongToday() async {
    setState(() => _isLoading = true);

    try {
      // Load pending don xin instead of attendance
      // TODO: Create endpoint to get pending don xin by manager
      // For now, we'll use mock data or fetch from donxin API
      setState(() {
        _chamCongList = []; // Will be populated from API
      });
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'đúng giờ':
        return Colors.green;
      case 'muộn':
        return Colors.orange;
      case 'vắng':
        return Colors.red;
      case 'phép':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Quản Lý'),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Hướng dẫn sử dụng',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UserGuideView(userRole: 'QuanLy'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChamCongToday,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: _loadChamCongToday,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 180,
            decoration: const BoxDecoration(color: Colors.green),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.manage_accounts, size: 30, color: Colors.green),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _hoTenQL,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _maQL,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ...menuItems.map((item) => ListTile(
                      leading: Icon(item.icon, color: Colors.green),
                      title: Text(item.title),
                      onTap: () => _onMenuItemTap(context, item),
                    )),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: Colors.orange),
                  title: const Text('Hướng dẫn sử dụng', style: TextStyle(color: Colors.orange)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserGuideView(userRole: 'QuanLy'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.manage_accounts, size: 40, color: Colors.green),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào, $_hoTenQL!',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text('Mã QL: $_maQL', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Notification card for pending requests
            if (_pendingDonXinCount > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications, color: Colors.orange[700], size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Có đơn chờ duyệt',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Bạn có $_pendingDonXinCount đơn xin chưa duyệt',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuanLyDonXinTheoUserView(
                              userId: _maQL,
                              currentManagerId: _maQL,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('Duyệt'),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Quick actions
            const Text('Thao tác nhanh:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildQuickActionIcon(
                  context: context,
                  icon: Icons.group,
                  label: 'Danh sách\nNhân Viên',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DanhSachNhanVienView(),
                      ),
                    );
                  },
                ),
                _buildQuickActionIcon(
                  context: context,
                  icon: Icons.assignment_turned_in,
                  label: 'Duyệt\nđơn xin',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuanLyDonXinTheoUserView(
                          userId: _maQL,
                          currentManagerId: _maQL,
                        ),
                      ),
                    );
                  },
                ),
                _buildQuickActionIcon(
                  context: context,
                  icon: Icons.bar_chart,
                  label: 'Báo cáo\nphòng',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BaoCaoView(
                          userId: _maQL,
                          userRole: 'QuanLy',
                        ),
                      ),
                    );
                  },
                ),
                _buildQuickActionIcon(
                  context: context,
                  icon: Icons.fingerprint,
                  label: 'Chấm công\nNV',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChamCongNhanVienView(maQL: _maQL),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Pending requests section
            const Text('Đơn xin chờ duyệt:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(
                child: SizedBox(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  ),
                ),
              )
            else if (_chamCongList.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Không có đơn xin chờ duyệt',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              _buildPendingDonXinList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingDonXinList() {
    // TODO: Replace with actual pending don xin data from API
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _chamCongList.length,
        itemBuilder: (context, index) {
          final item = _chamCongList[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.2),
              child: const Icon(Icons.assignment, color: Colors.green),
            ),
            title: Text(item['ten_nv'] ?? '-'),
            subtitle: Text('Mã NV: ${item['ma_nv'] ?? '-'}'),
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuanLyDonXinTheoUserView(
                      userId: _maQL,
                      currentManagerId: _maQL,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Duyệt', style: TextStyle(fontSize: 12)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActionIcon({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.green, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMenuItemTap(BuildContext context, MenuItem item) {
    Navigator.pop(context);

    switch (item.route) {
      case '/danh_sach_nhan_vien':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DanhSachNhanVienView()),
        );
        break;
      case '/duyet_don_xin':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuanLyDonXinTheoUserView(
              userId: _maQL,
              currentManagerId: _maQL,
            ),
          ),
        );
        break;
      case '/xem_bao_cao_phong':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BaoCaoView(userId: _maQL, userRole: 'QuanLy'),
          ),
        );
        break;
      case '/cham_cong_nhan_vien':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChamCongNhanVienView(maQL: _maQL),
          ),
        );
        break;
      case '/dang_ky_guong_mat':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DangKyGuongMatView(userId: _maQL)),
        );
        break;
      default:
        break;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('HỦY'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ĐĂNG XUẤT', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _logout(context);
      }
    });
  }

  Future<void> _logout(BuildContext context) async {
    final authController = context.read<AuthController>();
    await authController.logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }
}

class MenuItem {
  final String title;
  final IconData icon;
  final String route;

  const MenuItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}
