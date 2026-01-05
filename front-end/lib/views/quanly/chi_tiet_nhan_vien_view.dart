import 'package:flutter/material.dart';
import '../../models/user.dart';
import 'thong_tin_nhan_vien_edit_view.dart';

class ThongTinNhanVienView extends StatelessWidget {
  final User user;

  const ThongTinNhanVienView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user.hoTen ?? 'Nhân viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ThongTinNhanVienEditView(user: user),
                ),
              );

              if (updated == true) {
                Navigator.pop(context, true);
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã NV: ${user.id}'),
            Text('Email: ${user.email ?? ''}'),
            Text('SĐT: ${user.soDienThoai ?? ''}'),
            Text('Chức vụ: ${user.chucVu ?? ''}'),
            Text('Giới tính: ${user.gioiTinh ?? ''}'),
          ],
        ),
      ),
    );
  }
}
