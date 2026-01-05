import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../nhanvien/sua_thong_tin_nhan_vien_view.dart';

class ThongTinCaNhanView extends StatelessWidget {
  final User user;

  const ThongTinCaNhanView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),

        //  NÚT SỬA 
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Sửa thông tin',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SuaThongTinNhanVienView(user: user),
                ),
              );

              // Nếu sửa xong và backend OK
              if (result == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng đăng nhập lại để cập nhật dữ liệu')),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: const Text('Mã nhân viên'),
                subtitle: Text(user.id),
              ),
              ListTile(
                title: const Text('Họ và tên'),
                subtitle: Text(user.hoTen ?? ''),
              ),
              ListTile(
                title: const Text('Chức vụ'),
                subtitle: Text(user.chucVu ?? ''),
              ),
              ListTile(
                title: const Text('Email'),
                subtitle: Text(user.email ?? ''),
              ),
              ListTile(
                title: const Text('Số điện thoại'),
                subtitle: Text(user.soDienThoai ?? ''),
              ),
              ListTile(
                title: const Text('Phòng ban'),
                subtitle: Text(user.tenPhongBan ?? user.phongBan ?? ''),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
