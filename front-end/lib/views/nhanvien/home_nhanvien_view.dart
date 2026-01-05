import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../nhanvien/gui_don_xin_nghi.dart';
import '../nhanvien/thong_tin_nhan_vien.dart';
import '../nhanvien/lich_su_cham_cong.dart';
import '../dang_ky_guong_mat_view.dart'; 
import '../nhanvien/danh_sach_don_xin.dart';
import 'package:quanlychamcong/controllers/auth_controller.dart';
import 'package:quanlychamcong/models/user.dart';

import 'package:quanlychamcong/services/api_service.dart';
import 'package:quanlychamcong/views/login_view.dart';
import 'package:quanlychamcong/views/user_guide_view.dart';

class HomeNhanVienView extends StatefulWidget {
  final User currentUser;

  const HomeNhanVienView({super.key, required this.currentUser});

  @override
  State<HomeNhanVienView> createState() => _HomeNhanVienViewState();
}

class _HomeNhanVienViewState extends State<HomeNhanVienView> {
  final ApiService apiService = ApiService();
  
  // Status hôm nay
  String _gioVao = '--:--';
  String _gioRa = '--:--';
  String _trangThai = 'Chưa chấm';
  String _ca = '';
  bool _isLoadingStatus = true;

  final List<MenuItem> menuItems = const [
    MenuItem(title: 'Thông tin cá nhân', icon: Icons.person, route: '/thong_tin_ca_nhan'),
    MenuItem(title: 'Lịch sử chấm công', icon: Icons.history, route: '/lich_su_cham_cong'),
    MenuItem(title: 'Quản lý khuôn mặt', icon: Icons.face, route: '/dang_ky_khuon_mat'), 
    MenuItem(title: 'Gửi đơn xin nghỉ', icon: Icons.note_add, route: '/gui_don_xin_nghi'),
    MenuItem(title: 'Lịch sử đơn từ', icon: Icons.assignment_turned_in, route: '/danh_sach_don_xin'),
  ];

  @override
  void initState() {
    super.initState();
    _loadTodayStatus();
  }

  Future<void> _loadTodayStatus() async {
    setState(() => _isLoadingStatus = true);

    try {
      final chamCongList = await apiService.getChamCongByUserId(widget.currentUser.id);
      
      // Lọc chấm công hôm nay
      final today = DateTime.now();
      final todayChamCong = chamCongList.where((cc) {
        return cc.ngayChamCong.year == today.year &&
               cc.ngayChamCong.month == today.month &&
               cc.ngayChamCong.day == today.day;
      }).toList();

      if (todayChamCong.isNotEmpty) {
        // Lấy record cuối cùng (mới nhất)
        final latest = todayChamCong.last;
        
        setState(() {
          _gioVao = latest.gioVao;
          _gioRa = latest.gioRa ?? '--:--';
          _trangThai = latest.trangThai ?? 'Chưa rõ';
          _ca = _getCaText(latest.maCa);
        });
      } else {
        setState(() {
          _gioVao = '--:--';
          _gioRa = '--:--';
          _trangThai = 'Chưa chấm công';
          _ca = '';
        });
      }
    } catch (e) {
      print('[ERROR] Load today status: $e');
      setState(() => _trangThai = 'Lỗi tải dữ liệu');
    } finally {
      setState(() => _isLoadingStatus = false);
    }
  }

  String _getCaText(String? maCa) {
    switch (maCa) {
      case 'CA001':
        return 'Ca 1 (Sáng)';
      case 'CA002':
        return 'CA 2 (Chiều)';
      case 'CA003':
        return 'Ca 3 (Tối)';
      default:
        return '';
    }
  }

  Color _getStatusColor(String status) {
    if (status.contains('ra')) return Colors.green;
    if (status.contains('vào')) return Colors.orange;
    if (status.contains('Chưa')) return Colors.grey;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Nhân Viên'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Hướng dẫn sử dụng',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UserGuideView(userRole: 'NhanVien'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTodayStatus,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: _loadTodayStatus,
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
            decoration: const BoxDecoration(color: Colors.blue),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 30, color: Colors.blue),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.currentUser.hoTen ?? 'Nhân Viên',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.currentUser.id,
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
                      leading: Icon(item.icon, color: Colors.blue),
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
                        builder: (_) => const UserGuideView(userRole: 'NhanVien'),
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
                    const Icon(Icons.person, size: 40, color: Colors.blue),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào, ${widget.currentUser.hoTen ?? "Nhân Viên"}!',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text('Mã NV: ${widget.currentUser.id}', style: TextStyle(color: Colors.grey[600])),
                          Text(widget.currentUser.chucVu ?? 'Nhân viên', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ✅ Today's Status - REAL-TIME
            _buildTodayStatus(),

            const SizedBox(height: 20),

            // Quick actions
            const Text('Thao tác nhanh:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildQuickAction(
                  context: context,
                  icon: Icons.history,
                  label: 'Lịch sử\nchấm công',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LichSuChamCongView(userId: widget.currentUser.id),
                      ),
                    );
                    _loadTodayStatus();
                  },
                ),
                // ✅ THAY ĐỔI: Dùng DangKyGuongMatView thay vì RegisterCamera
                _buildQuickAction(
                  context: context,
                  icon: Icons.face,
                  label: 'Quản lý\nkhuôn mặt',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DangKyGuongMatView(userId: widget.currentUser.id),
                      ),
                    );
                  },
                ),
                _buildQuickAction(
                  context: context,
                  icon: Icons.note_add,
                  label: 'Gửi đơn\nxin nghỉ',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GuiDonXinNghiView(userId: widget.currentUser.id),
                      ),
                    );
                  },
                ),
                _buildQuickAction(
                  context: context,
                  icon: Icons.assignment_turned_in,
                  label: 'Theo dõi\nđơn từ',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DanhSachDonXinView(userId: widget.currentUser.id),
                      ),
                    );
                  },
                ),
                _buildQuickAction(
                  context: context,
                  icon: Icons.person,
                  label: 'Thông tin\ncá nhân',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ThongTinCaNhanView(user: widget.currentUser),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatus() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Hôm nay:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (_isLoadingStatus) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            
            // ✅ HIỂN THỊ CA LÀM VIỆC
            if (_ca.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue, width: 1),
                  ),
                  child: Text(_ca, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
                ),
              ),
            
            const SizedBox(height: 12),
            
            // ✅ HIỂN THỊ GIỜ VÀO/RA/TRẠNG THÁI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem('Giờ vào', _gioVao, Icons.login, Colors.blue),
                Container(height: 50, width: 1, color: Colors.grey[300]),
                _buildStatusItem('Giờ ra', _gioRa, Icons.logout, Colors.green),
                Container(height: 50, width: 1, color: Colors.grey[300]),
                _buildStatusItem('Trạng thái', _getShortStatus(_trangThai), Icons.info, _getStatusColor(_trangThai)),
              ],
            ),
            
            // ✅ THÔNG BÁO NẾU CHƯA CHẤM CÔNG
            if (_trangThai.contains('Chưa chấm'))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text('Bạn chưa chấm công hôm nay. Vui lòng chấm công!', style: TextStyle(fontSize: 13, color: Colors.orange))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getShortStatus(String status) {
    if (status.contains('ra')) return 'Đã ra';
    if (status.contains('vào')) return 'Đã vào';
    return status;
  }

  Widget _buildQuickAction({required BuildContext context, required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  void _onMenuItemTap(BuildContext context, MenuItem item) {
    Navigator.pop(context);
    switch (item.route) {
      // ✅ THAY ĐỔI: Dùng DangKyGuongMatView
      case '/dang_ky_khuon_mat':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DangKyGuongMatView(userId: widget.currentUser.id),
          ),
        );
        break;
      
      case '/thong_tin_ca_nhan':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ThongTinCaNhanView(user: widget.currentUser),
          ),
        );
        break;
      
      case '/lich_su_cham_cong':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LichSuChamCongView(userId: widget.currentUser.id),
          ),
        ).then((_) => _loadTodayStatus());
        break;
      
      case '/gui_don_xin_nghi':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GuiDonXinNghiView(userId: widget.currentUser.id),
          ),
        );
        break;
      case '/danh_sach_don_xin':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DanhSachDonXinView(userId: widget.currentUser.id),
          ),
        );
        break;
        
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chưa xử lý: ${item.title}')),
        );
    }
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.pop(context);
    final authController = context.read<AuthController>();
    await authController.logout();
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginView()), (route) => false);
  }
}

class MenuItem {
  final String title;
  final IconData icon;
  final String route;
  const MenuItem({required this.title, required this.icon, required this.route});
}