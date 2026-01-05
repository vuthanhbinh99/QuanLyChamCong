import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user.dart';
import 'chi_tiet_nhan_vien_view.dart';

class DanhSachNhanVienView extends StatefulWidget {
  const DanhSachNhanVienView({super.key});

  @override
  State<DanhSachNhanVienView> createState() => _DanhSachNhanVienViewState();
}

class _DanhSachNhanVienViewState extends State<DanhSachNhanVienView> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _nhanVienList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNhanVien();
  }

  Future<void> _loadNhanVien() async {
    final maQL = context.read<AuthController>().currentUserId;
    final data = await _apiService.getNhanVienByQuanLy(maQL!);
    setState(() {
      _nhanVienList = data;
      _isLoading = false;
    });
  }

  Future<void> _khoaNhanVien(String maNV) async {
    await _apiService.khoaNhanVien(maNV);
    _loadNhanVien();
  }

  Future<void> _moKhoaNhanVien(String maNV) async {
    await _apiService.moKhoaNhanVien(maNV);
    _loadNhanVien();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách nhân viên')),
      body: ListView.builder(
        itemCount: _nhanVienList.length,
        itemBuilder: (context, index) {
          final nv = _nhanVienList[index];

          final int trangThai = int.tryParse(nv['trangThai'].toString()) ?? 1;

          final user = User(
            id: nv['maNV'],
            role: 'NhanVien',
            hoTen: nv['hoTen'],
            email: nv['email'],
            soDienThoai: nv['soDienThoai'],
            chucVu: nv['chucVu'],
            phongBan: nv['maPB'],
            tenPhongBan: nv['tenPhongBan'],
            gioiTinh: nv['gioiTinh'],
          );

          return ListTile(
            title: Text(user.hoTen ?? ''),
            subtitle: Text('Mã NV: ${user.id}'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'lock') {
                  _khoaNhanVien(user.id!);
                } else if (value == 'unlock') {
                  _moKhoaNhanVien(user.id!);
                }
              },
              itemBuilder: (context) {
                final int trangThai =
                    int.tryParse(nv['trangThai'].toString()) ?? 1;

                return [
                  if (trangThai == 1)
                    const PopupMenuItem(
                      value: 'lock',
                      child: Text('Khóa nhân viên'),
                    ),
                  if (trangThai == 0)
                    const PopupMenuItem(
                      value: 'unlock',
                      child: Text('Hủy khóa nhân viên'),
                    ),
                ];
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ThongTinNhanVienView(user: user),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
