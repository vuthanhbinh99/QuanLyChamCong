import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GuiDonXinNghiView extends StatefulWidget {
  final String userId;
 
  const GuiDonXinNghiView({super.key, required this.userId});

  @override
  State<GuiDonXinNghiView> createState() => _GuiDonXinNghiViewState();
}

class _GuiDonXinNghiViewState extends State<GuiDonXinNghiView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _lyDoController = TextEditingController();
  DateTime? _ngayBatDau;
  DateTime? _ngayKetThuc;
  bool _isSending = false;
  final baseUrl = "http://192.168.0.114:5000";
  // final baseUrl = 'http://10.0.2.2:5000';

  String? _selectedLoaiDon;
  final List<String> _loaiDonOptions = [
    'Nghỉ phép',
    'Nghỉ ốm',
    'Nghỉ việc riêng',
    'Khác',
  ];

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final initialDate = isStart ? (_ngayBatDau ?? now) : (_ngayKetThuc ?? now);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          _ngayBatDau = pickedDate;
          if (_ngayKetThuc != null && _ngayKetThuc!.isBefore(pickedDate)) {
            _ngayKetThuc = pickedDate;
          }
        } else {
          _ngayKetThuc = pickedDate;
          if (_ngayBatDau != null && _ngayBatDau!.isAfter(pickedDate)) {
            _ngayBatDau = pickedDate;
          }
        }
      });
    }
  }

  Future<void> _sendDonXinNghi() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ngayBatDau == null || _ngayKetThuc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày bắt đầu và ngày kết thúc')),
      );
      return;
    }

    if (_selectedLoaiDon == null || _selectedLoaiDon!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn loại đơn')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/don-xin-nghi"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'lyDo': _lyDoController.text.trim(),
          'loaiDon': _selectedLoaiDon!.trim(),
          'ngayBatDau': '${_ngayBatDau!.toIso8601String()}Z',
          'ngayKetThuc': '${_ngayKetThuc!.toIso8601String()}Z',
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gửi đơn xin nghỉ thành công!')),
        );
        _lyDoController.clear();
        setState(() {
          _ngayBatDau = null;
          _ngayKetThuc = null;
          _selectedLoaiDon = null;
        });
      } else {
        final respBody = response.body;
        String msg = 'Lỗi gửi đơn: ${response.statusCode}';
        try {
          final jsonData = jsonDecode(respBody);
          if (jsonData['error'] != null) {
            msg = jsonData['error'];
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi đơn: $e')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  void dispose() {
    _lyDoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gửi đơn xin nghỉ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _lyDoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Lý do xin nghỉ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập lý do';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Loại đơn',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedLoaiDon,
                items: _loaiDonOptions.map((loai) {
                  return DropdownMenuItem(
                    value: loai,
                    child: Text(loai),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLoaiDon = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng chọn loại đơn';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày bắt đầu',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _ngayBatDau != null
                              ? "${_ngayBatDau!.day}/${_ngayBatDau!.month}/${_ngayBatDau!.year}"
                              : 'Chọn ngày',
                          style: TextStyle(
                              color: _ngayBatDau != null ? Colors.black : Colors.grey[600]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày kết thúc',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _ngayKetThuc != null
                              ? "${_ngayKetThuc!.day}/${_ngayKetThuc!.month}/${_ngayKetThuc!.year}"
                              : 'Chọn ngày',
                          style: TextStyle(
                              color: _ngayKetThuc != null ? Colors.black : Colors.grey[600]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendDonXinNghi,
                  child: _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Gửi đơn'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
