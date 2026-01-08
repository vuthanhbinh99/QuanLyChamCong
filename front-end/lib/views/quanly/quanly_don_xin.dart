import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quanlychamcong/models/donxin.dart';

class QuanLyDonXinTheoUserView extends StatefulWidget {
  final String userId;
  final String currentManagerId;
  const QuanLyDonXinTheoUserView({super.key, required this.userId, required this.currentManagerId});

  @override
  State<QuanLyDonXinTheoUserView> createState() => _QuanLyDonXinTheoUserViewState();
}

class _QuanLyDonXinTheoUserViewState extends State<QuanLyDonXinTheoUserView> {
  late Future<List<DonXin>> _futureDonXin;

  int? selectedMonth;
  int? selectedYear;
  String searchMaDon = '';

  final baseUrl = 'http://192.168.0.114:5000';

  @override
  void initState() {
    super.initState();
    _futureDonXin = fetchDonXinByUser(widget.userId);
  }

  Future<List<DonXin>> fetchDonXinByUser(String userId) async {
    final url = Uri.parse('$baseUrl/api/don-xin-nghi/quan-ly/$userId');
    
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isEmpty) {
          return [];
        }
        
        List<DonXin> allDon = data.map((json) => DonXin.fromJson(json)).toList();

        List<DonXin> filteredDon = allDon.where((don) {
          try {
            // Chỉ hiển thị đơn chờ duyệt
            if (don.trangThai != 'Chờ duyệt' && don.trangThai != 'Chờ phê duyệt') {
              return false;
            }
            
            DateTime ngayBatDau = DateTime.tryParse(don.ngayBatDau) ?? DateTime(2000);

            bool matchMonthYear = (selectedMonth == null || ngayBatDau.month == selectedMonth) &&
                                  (selectedYear == null || ngayBatDau.year == selectedYear);

            bool matchMaDon = searchMaDon.isEmpty || don.maDon.toLowerCase().contains(searchMaDon.toLowerCase());

            return matchMonthYear && matchMaDon;
          } catch (e) {
            print('Error filtering don xin: $e');
            return false;
          }
        }).toList();

        return filteredDon;
      } else {
        throw Exception('Lỗi tải danh sách đơn xin (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  void onSearchMaDonChanged(String value) {
    setState(() {
      searchMaDon = value.trim();
      _futureDonXin = fetchDonXinByUser(widget.userId);
    });
  }

  Future<bool> duyetTuChoiDon(String maDon, String trangThai, String ghiChu) async {
    final url = Uri.parse('$baseUrl/api/don-xin-nghi/duyet-tu-choi/$maDon');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'trangThai': trangThai,
          'ghiChu': ghiChu,
          'maQL': widget.currentManagerId, 
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Lỗi từ Server: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Lỗi kết nối: $e');
      return false;
    }
  }

  Widget buildDonXinCard(DonXin don) {
    final hoTen = don.hoTen ?? 'N/A';
    final loaiDon = don.loaiDon ?? 'Không xác định';
    final lyDo = don.lyDo ?? '-';
    final ngayBatDau = don.ngayBatDau ?? '-';
    final ngayKetThuc = don.ngayKetThuc ?? '-';
    final trangThai = don.trangThai ?? 'Không xác định';
    
    Color statusColor = Colors.orange;
    if (trangThai == 'Đã duyệt') statusColor = Colors.green;
    if (trangThai == 'Từ chối') statusColor = Colors.red;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Mã đơn & Trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${don.maDon}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hoTen,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    trangThai,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            
            // Nội dung đơn
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Loại: $loaiDon',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Từ: $ngayBatDau đến $ngayKetThuc',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Lý do
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lý do:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lyDo,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            
            // Ghi chú từ quản lý
            if (don.ghiChu != null && don.ghiChu!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: trangThai == 'Đã duyệt' 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: trangThai == 'Đã duyệt' 
                      ? Colors.green.withOpacity(0.5)
                      : Colors.red.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phản hồi:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: trangThai == 'Đã duyệt' 
                          ? Colors.green
                          : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      don.ghiChu!,
                      style: TextStyle(
                        fontSize: 13,
                        color: trangThai == 'Đã duyệt' 
                          ? Colors.green[700]
                          : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Nút duyệt/từ chối
            if (trangThai == 'Chờ duyệt' || trangThai == 'Chờ phê duyệt') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        bool success = await duyetTuChoiDon(don.maDon, 'Đã duyệt', 'Đơn đã được duyệt');
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Duyệt đơn thành công'), backgroundColor: Colors.green),
                          );
                          setState(() {
                            _futureDonXin = fetchDonXinByUser(widget.userId);
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Duyệt đơn thất bại'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Duyệt'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        bool success = await duyetTuChoiDon(don.maDon, 'Từ chối', 'Đơn bị từ chối');
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Từ chối đơn thành công'), backgroundColor: Colors.green),
                          );
                          setState(() {
                            _futureDonXin = fetchDonXinByUser(widget.userId);
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Từ chối đơn thất bại'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Từ chối'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyệt đơn xin'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Tìm kiếm mã đơn',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: onSearchMaDonChanged,
            ),
          ),

          // Filter by date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<int?>(
                    isExpanded: true,
                    value: selectedMonth,
                    hint: const Text('Chọn tháng'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Tất cả tháng'),
                      ),
                      ...List.generate(12, (index) => index + 1)
                          .map((month) => DropdownMenuItem<int?>(
                                value: month,
                                child: Text('Tháng $month'),
                              ))
                          .toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedMonth = value;
                        _futureDonXin = fetchDonXinByUser(widget.userId);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<int?>(
                    isExpanded: true,
                    value: selectedYear,
                    hint: const Text('Chọn năm'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Tất cả năm'),
                      ),
                      ...List.generate(5, (index) => DateTime.now().year - 2 + index)
                          .map((year) => DropdownMenuItem<int?>(
                                value: year,
                                child: Text('Năm $year'),
                              ))
                          .toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedYear = value;
                        _futureDonXin = fetchDonXinByUser(widget.userId);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<DonXin>>(
              future: _futureDonXin,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Lỗi: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có đơn xin nghỉ nào.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                final donXinList = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: donXinList.length,
                  itemBuilder: (context, index) {
                    final don = donXinList[index];
                    return buildDonXinCard(don);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
