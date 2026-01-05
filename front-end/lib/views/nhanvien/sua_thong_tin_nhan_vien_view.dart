import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';

class SuaThongTinNhanVienView extends StatefulWidget {
  final User user;

  const SuaThongTinNhanVienView({
    super.key,
    required this.user,
  });

  @override
  State<SuaThongTinNhanVienView> createState() =>
      _SuaThongTinNhanVienViewState();
}

class _SuaThongTinNhanVienViewState
    extends State<SuaThongTinNhanVienView> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late TextEditingController _hoTenCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _sdtCtrl;
  late TextEditingController _gioiTinhCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _hoTenCtrl = TextEditingController(text: widget.user.hoTen ?? '');
    _emailCtrl = TextEditingController(text: widget.user.email ?? '');
    _sdtCtrl = TextEditingController(text: widget.user.soDienThoai ?? '');
    _gioiTinhCtrl = TextEditingController(text: widget.user.gioiTinh ?? '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _apiService.updateNhanVien(
        widget.user.id,
        {
          'ho_ten': _hoTenCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'so_dien_thoai': _sdtCtrl.text.trim(),
          'gioi_tinh': _gioiTinhCtrl.text.trim(),
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thông tin thành công')),
      );

      Navigator.pop(context, true); // báo màn trước reload
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Không được để trống' : null,
      ),
    );
  }

  @override
  void dispose() {
    _hoTenCtrl.dispose();
    _emailCtrl.dispose();
    _sdtCtrl.dispose();
    _gioiTinhCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa thông tin cá nhân'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _input('Họ và tên', _hoTenCtrl),
              _input('Email', _emailCtrl,
                  keyboardType: TextInputType.emailAddress),
              _input('Số điện thoại', _sdtCtrl,
                  keyboardType: TextInputType.phone),
              _input('Giới tính', _gioiTinhCtrl),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
