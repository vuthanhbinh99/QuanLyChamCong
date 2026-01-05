
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../controllers/CameraController.dart';

class DangKyGuongMatView extends StatefulWidget {
  final String userId;
  
  const DangKyGuongMatView({super.key, required this.userId});

  @override
  State<DangKyGuongMatView> createState() => _DangKyGuongMatViewState();
}

class _DangKyGuongMatViewState extends State<DangKyGuongMatView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _hasFace = false;
  DateTime? _ngayTao;
  DateTime? _ngayCapNhat;

  @override
  void initState() {
    super.initState();
    _checkFaceStatus();
  }

  Future<void> _checkFaceStatus() async {
    setState(() => _isLoading = true);

    try {
      final result = await _apiService.checkFaceStatus(widget.userId);
      
      if (result != null && mounted) {
        setState(() {
          _hasFace = result['has_face'] ?? false;
          
          // Parse ngày tạo nếu có
          if (result['ngay_tao'] != null) {
            _ngayTao = DateTime.parse(result['ngay_tao']);
          }
          
          // Parse ngày cập nhật nếu có
          if (result['ngay_cap_nhat'] != null) {
            _ngayCapNhat = DateTime.parse(result['ngay_cap_nhat']);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kiểm tra trạng thái: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToRegisterCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterCamera(
          id_user: widget.userId,
          autoCapture: true,
        ),
      ),
    );

    // Nếu đăng ký thành công, reload trạng thái
    if (result == true && mounted) {
      _checkFaceStatus();
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý khuôn mặt'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card hiển thị trạng thái
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            _hasFace ? Icons.check_circle : Icons.face,
                            size: 80,
                            color: _hasFace ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _hasFace 
                                ? 'Đã đăng ký khuôn mặt' 
                                : 'Chưa đăng ký khuôn mặt',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _hasFace ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Thông tin ngày tạo
                          if (_hasFace && _ngayTao != null) ...[
                            _buildInfoRow(
                              icon: Icons.calendar_today,
                              label: 'Ngày đăng ký:',
                              value: _formatDateTime(_ngayTao),
                            ),
                            const SizedBox(height: 12),
                          ],
                          
                          // Thông tin ngày cập nhật
                          if (_hasFace && _ngayCapNhat != null) ...[
                            _buildInfoRow(
                              icon: Icons.update,
                              label: 'Cập nhật lần cuối:',
                              value: _formatDateTime(_ngayCapNhat),
                            ),
                            const SizedBox(height: 12),
                          ],
                          
                          // Thông báo nếu chưa cập nhật
                          if (_hasFace && _ngayCapNhat == null) ...[
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Chưa có lần cập nhật nào',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Nút đăng ký hoặc cập nhật
                  ElevatedButton.icon(
                    onPressed: _navigateToRegisterCamera,
                    icon: Icon(_hasFace ? Icons.update : Icons.camera_alt),
                    label: Text(
                      _hasFace ? 'Cập nhật khuôn mặt' : 'Đăng ký khuôn mặt',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: _hasFace ? Colors.orange : Colors.blue,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Hướng dẫn
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Hướng dẫn',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildGuideItem('Hệ thống sẽ tự động chụp 3 ảnh'),
                          _buildGuideItem('Giữ khuôn mặt ổn định khi chụp'),
                          _buildGuideItem('Thực hiện các tư thế theo hướng dẫn'),
                          if (_hasFace)
                            _buildGuideItem(
                              'Cập nhật sẽ thay thế dữ liệu cũ',
                              color: Colors.orange[700],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildGuideItem(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: color ?? Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: color ?? Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}