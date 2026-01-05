import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/baocao.dart';
import 'package:open_file/open_file.dart';

class BaoCaoView extends StatefulWidget {
  final String userId;
  final String userRole;

  const BaoCaoView({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<BaoCaoView> createState() => _BaoCaoViewState();
}

class _BaoCaoViewState extends State<BaoCaoView> {
  final ApiService api = ApiService();

  String filterType = 'thang';
  final TextEditingController monthCtrl = TextEditingController();
  final TextEditingController yearCtrl = TextEditingController();

  late Future<List<BaoCao>> _futureBaoCao;

  @override
  void initState() {
    super.initState();
    monthCtrl.text = DateTime.now().month.toString();
    yearCtrl.text = DateTime.now().year.toString();
    _loadBaoCao();
  }

  void _loadBaoCao() {
    setState(() {
      _futureBaoCao = api.getBaoCao(
        userId: widget.userId,
        role: widget.userRole,
        filterType: filterType,
        month: monthCtrl.text,
        year: yearCtrl.text,
      );
    });
  }

  // === HÀM XỬ LÝ XÓA FILE (MỚI) ===
  void _confirmDeleteFiles() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa file tạm?'),
        content: const Text(
            'Hành động này sẽ xóa tất cả các file PDF và Excel đã tải về trong máy để giải phóng bộ nhớ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Đóng hộp thoại
              
              // Gọi API xóa
              int count = await api.deleteAllReports();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa sạch $count file báo cáo cũ!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Xóa ngay', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo chấm công'),
        actions: [
          // Nút xóa file
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            tooltip: 'Xóa file cũ',
            onPressed: _confirmDeleteFiles,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPDF,
          ),
          IconButton(
            icon: const Icon(Icons.table_view),
            onPressed: _exportExcel,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilter(),
          Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  // ... Giữ nguyên các Widget _buildFilter, _buildTable, _exportExcel, _exportPDF như cũ ...
  
  Widget _buildFilter() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          DropdownButton<String>(
            value: filterType,
            items: const [
              DropdownMenuItem(value: 'thang', child: Text('Theo tháng')),
              DropdownMenuItem(value: 'nam', child: Text('Theo năm')),
            ],
            onChanged: (v) {
              filterType = v!;
              _loadBaoCao();
            },
          ),
          const SizedBox(width: 10),
          if (filterType == 'thang')
            SizedBox(
              width: 70,
              child: TextField(
                controller: monthCtrl,
                decoration: const InputDecoration(labelText: 'Tháng'),
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _loadBaoCao(),
              ),
            ),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: TextField(
              controller: yearCtrl,
              decoration: const InputDecoration(labelText: 'Năm'),
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _loadBaoCao(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return FutureBuilder<List<BaoCao>>(
      future: _futureBaoCao,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final list = snapshot.data ?? [];

        if (list.isEmpty) {
          return const Center(child: Text('Không có dữ liệu'));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Mã NV')),
              DataColumn(label: Text('Họ tên')),
              DataColumn(label: Text('Phòng ban')),
              DataColumn(label: Text('Ngày làm')),
              DataColumn(label: Text('Giờ làm')),
            ],
            rows: list.map((bc) => DataRow(cells: [
                  DataCell(Text(bc.maNV)),
                  DataCell(Text(bc.hoTen)),
                  DataCell(Text(bc.phongBan)),
                  DataCell(Text(bc.tongNgayLam.toString())),
                  DataCell(Text(bc.soGioLam.toString())),
                ])).toList(),
          ),
        );
      },
    );
  }

  void _exportExcel() async {
    try {
      final file = await api.downloadBaoCaoExcel(
        userId: widget.userId,
        role: widget.userRole,
        filterType: filterType,
        month: monthCtrl.text,
        year: yearCtrl.text,
      );
      if (file != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tải Excel thành công tại: ${file.path}')),
          );
        }
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải Excel: $e')),
        );
      }
    }
  }

  void _exportPDF() async {
    try {
      final file = await api.downloadBaoCaoPDF(
        userId: widget.userId,
        role: widget.userRole,
        filterType: filterType,
        month: monthCtrl.text,
        year: yearCtrl.text,
      );
      if (file != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tải PDF thành công tại: ${file.path}')),
          );
        }
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải PDF: $e')),
        );
      }
    }
  }
}
