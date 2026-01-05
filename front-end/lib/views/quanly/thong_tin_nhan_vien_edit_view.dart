import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';

class ThongTinNhanVienEditView extends StatefulWidget {
  final User user;

  const ThongTinNhanVienEditView({super.key, required this.user});

  @override
  State<ThongTinNhanVienEditView> createState() =>
      _ThongTinNhanVienEditViewState();
}

class _ThongTinNhanVienEditViewState
    extends State<ThongTinNhanVienEditView> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late TextEditingController hoTenCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController sdtCtrl;
  late TextEditingController chucVuCtrl;
  late TextEditingController gioiTinhCtrl;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    hoTenCtrl = TextEditingController(text: widget.user.hoTen);
    emailCtrl = TextEditingController(text: widget.user.email);
    sdtCtrl = TextEditingController(text: widget.user.soDienThoai);
    chucVuCtrl = TextEditingController(text: widget.user.chucVu);
    gioiTinhCtrl = TextEditingController(text: widget.user.gioiTinh);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _apiService.updateNhanVien(widget.user.id, {
        'ho_ten': hoTenCtrl.text,
        'email': emailCtrl.text,
        'so_dien_thoai': sdtCtrl.text,
        'chuc_vu': chucVuCtrl.text,
        'gioi_tinh': gioiTinhCtrl.text,
      });

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa thông tin nhân viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _input('Họ tên', hoTenCtrl),
                    _input('Email', emailCtrl),
                    _input('SĐT', sdtCtrl),
                    _input('Chức vụ', chucVuCtrl),
                    _input('Giới tính', gioiTinhCtrl),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _input(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) =>
            v == null || v.isEmpty ? 'Không được bỏ trống' : null,
      ),
    );
  }
}
