import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/donxin.dart';

class DanhSachDonXinView extends StatefulWidget {
  final String userId;

  const DanhSachDonXinView({super.key, required this.userId});

  @override
  State<DanhSachDonXinView> createState() => _DanhSachDonXinViewState();
}

class _DanhSachDonXinViewState extends State<DanhSachDonXinView> {
  final ApiService _apiService = ApiService();
  late Future<List<DonXin>> _futureDonXin;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureDonXin = _apiService.getDonXinNghiByUser(widget.userId);
    });
  }

  Color _getStatusColor(String status) {
    if (status == 'Đã duyệt') return Colors.green;
    if (status == 'Từ chối') return Colors.red;
    return Colors.orange;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _deleteDon(String maDon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa đơn này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiService.deleteDonXin(maDon);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa đơn thành công')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn xin đã gửi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      body: FutureBuilder<List<DonXin>>(
        future: _futureDonXin,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return const Center(child: Text('Chưa có đơn xin nghỉ'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final don = list[index];
              final statusColor = _getStatusColor(don.trangThai);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#${don.maDon}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              don.trangThai,
                              style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      Text('Loại đơn: ${don.loaiDon}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                        'Thời gian: ${_formatDate(don.ngayBatDau)} - ${_formatDate(don.ngayKetThuc)}',
                      ),
                      const SizedBox(height: 8),

                      /// LÝ DO
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Lý do: ${don.lyDo}'),
                      ),

                      /// GHI CHÚ
                      if (don.ghiChu != null &&
                          don.ghiChu!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Phản hồi: ${don.ghiChu}',
                          style: TextStyle(
                            color: don.trangThai == 'Đã duyệt'
                                ? Colors.green
                                : Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],

                      /// NÚT XÓA
                      if (don.trangThai == 'Chờ duyệt') ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _deleteDon(don.maDon),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text(
                              'Xóa',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
