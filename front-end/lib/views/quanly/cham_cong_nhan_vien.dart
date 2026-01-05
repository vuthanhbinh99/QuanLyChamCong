import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../nhanvien/lich_su_cham_cong.dart';

class ChamCongNhanVienView extends StatefulWidget {
  final String maQL; // Mã quản lý

  const ChamCongNhanVienView({super.key, required this.maQL});

  @override
  _ChamCongNhanVienViewState createState() => _ChamCongNhanVienViewState();
}

class _ChamCongNhanVienViewState extends State<ChamCongNhanVienView> {
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> _nhanVienList = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNhanVien();
  }

  Future<void> _loadNhanVien() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final nhanvien = await _apiService.getNhanVienByQuanLy(widget.maQL);
      setState(() {
        _nhanVienList = nhanvien;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredList {
    if (_searchQuery.isEmpty) return _nhanVienList;
    
    return _nhanVienList.where((nv) {
      final hoTen = (nv['hoTen'] ?? '').toString().toLowerCase();
      final maNV = (nv['maNV'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return hoTen.contains(query) || maNV.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chấm công nhân viên'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNhanVien,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm nhân viên...',
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Thống kê
          if (_nhanVienList.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Tổng NV',
                    '${_nhanVienList.length}',
                    Icons.people,
                  ),
                  _buildStatItem(
                    'Đang hiện',
                    '${_filteredList.length}',
                    Icons.visibility,
                  ),
                ],
              ),
            ),

          // Danh sách nhân viên
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green[700], size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Lỗi: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNhanVien,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_nhanVienList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có nhân viên nào trong phòng ban',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final filteredList = _filteredList;

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy nhân viên phù hợp',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final nv = filteredList[index];
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.green[100],
              child: Text(
                _getInitials(nv['hoTen'] ?? 'N/A'),
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              nv['hoTen'] ?? 'N/A',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.badge, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Mã NV: ${nv['maNV']}'),
                  ],
                ),
                if (nv['chucVu'] != null && nv['chucVu'].toString().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.work, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(nv['chucVu']),
                    ],
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.history, color: Colors.green),
              tooltip: 'Xem lịch sử chấm công',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LichSuChamCongView(
                      userId: nv['maNV'],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'N/A';
    
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}