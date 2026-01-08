import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:quanlychamcong/services/api_service.dart';
import 'package:quanlychamcong/views/dang_ky_guong_mat_view.dart'; 
import 'quanly_don_xin.dart';
import 'package:quanlychamcong/views/quanly/bao_cao_view.dart';
import 'package:quanlychamcong/views/quanly/danh_sach_nhan_vien_view.dart';
import 'package:quanlychamcong/controllers/auth_controller.dart';
import 'package:quanlychamcong/views/login_view.dart';
import 'package:quanlychamcong/views/quanly/cham_cong_nhan_vien.dart';
import 'package:quanlychamcong/views/user_guide_view.dart';
import 'package:quanlychamcong/views/quanly/lich_su_cham_cong_quanly.dart';

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

class _HomeQuanLyViewState extends State<HomeQuanLyView>
    with WidgetsBindingObserver {
  final ApiService apiService = ApiService();
  
  List<dynamic> _pendingDonXinList = [];
  bool _isLoading = false;
  int _pendingDonXinCount = 0;
  
  late String _maQL;
  late String _hoTenQL;
  Timer? _autoRefreshTimer;
  bool _isPageActive = true;

  final List<MenuItem> menuItems = const [
    MenuItem(title: 'Duyệt đơn xin', icon: Icons.assignment_turned_in, route: '/duyet_don_xin'),
    MenuItem(title: 'Danh sách nhân viên', icon: Icons.group, route: '/danh_sach_nhan_vien'),
    MenuItem(title: 'Xem báo cáo phòng', icon: Icons.bar_chart, route: '/xem_bao_cao_phong'),
    MenuItem(title: 'Chấm công nhân viên', icon: Icons.fingerprint, route: '/cham_cong_nhan_vien'),
    MenuItem(title: 'Lịch sử chấm công', icon: Icons.history, route: '/lich_su_cham_cong'),
    MenuItem(title: 'Đăng ký gương mặt', icon: Icons.face, route: '/dang_ky_guong_mat'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final authController = context.read<AuthController>();
    _maQL = widget.maQL ?? authController.currentUserId ?? 'QL001';
    _hoTenQL = widget.hoTenQL ?? 'Quản Lý';
    
    // Load tên quản lý từ API nếu chưa có
    if (_hoTenQL == 'Quản Lý') {
      _loadQuanLyInfo();
    }
    
    _loadPendingDonXin();
    // Auto refresh mỗi 30 giây để tránh lag khi dữ liệu nhiều
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _isPageActive) {
        _loadPendingDonXin();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _isPageActive = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPendingDonXin() async {
    try {
      setState(() => _isLoading = true);
      
      final pendingRequests = await apiService.getPendingDonXinByQuanLy(_maQL);
      
      setState(() {
        _pendingDonXinList = pendingRequests;
        _pendingDonXinCount = pendingRequests.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pending don xin: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadQuanLyInfo() async {
    try {
      final quanLyInfo = await apiService.getQuanLyInfo(_maQL);
      if (quanLyInfo != null && mounted) {
        setState(() {
          _hoTenQL = quanLyInfo['HoTenQL'] ?? 'Quản Lý';
        });
      }
    } catch (e) {
      print('Error loading quan ly info: $e');
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
            onPressed: _loadPendingDonXin,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: _loadPendingDonXin,
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
                    _hoTenQL.isEmpty ? 'Quản Lý' : _hoTenQL,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mã: $_maQL',
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
            // Welcome card - hiển thị tên quản lý
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(Icons.manage_accounts, size: 40, color: Colors.green),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hoTenQL,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mã: $_maQL',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quản lý phòng ban',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
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
              GestureDetector(
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
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[50]!, Colors.amber[50]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.orange, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.orange[200],
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.notifications_active,
                          color: Colors.orange[900],
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Có đơn chờ duyệt',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.orange,
                              ),
                            ),
                            Text(
                              'Bạn có $_pendingDonXinCount đơn xin chưa duyệt',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                    ],
                  ),
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
                _buildQuickActionIcon(
                  context: context,
                  icon: Icons.history,
                  label: 'Lịch sử\nchấm công',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LichSuChamCongQuanLyView(
                          maQL: _maQL,
                          hoTenQL: _hoTenQL,
                        ),
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
            else if (_pendingDonXinList.isEmpty)
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
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _pendingDonXinList.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
        itemBuilder: (context, index) {
          final don = _pendingDonXinList[index];
          final maNV = don.userId ?? '-';
          final hoTen = don.hoTen ?? 'N/A';
          final loaiDon = don.loaiDon ?? 'Đơn xin';
          final lyDo = don.lyDo ?? '';
          final ngayBatDau = don.ngayBatDau ?? '-';
          final ngayKetThuc = don.ngayKetThuc ?? '-';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.2),
              child: const Icon(Icons.assignment, color: Colors.green),
            ),
            title: Text(
              hoTen,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '$loaiDon - $ngayBatDau đến $ngayKetThuc',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (lyDo.isNotEmpty)
                  Text(
                    'Lý do: $lyDo',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: ElevatedButton.icon(
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Duyệt', style: TextStyle(fontSize: 12)),
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
      case '/lich_su_cham_cong':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LichSuChamCongQuanLyView(
              maQL: _maQL,
              hoTenQL: _hoTenQL,
            ),
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
