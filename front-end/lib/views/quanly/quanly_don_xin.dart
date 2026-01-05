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
    final now = DateTime.now();
    selectedMonth = now.month;
    selectedYear = now.year;
    _futureDonXin = fetchDonXinByUser(widget.userId);
  }

  Future<List<DonXin>> fetchDonXinByUser(String userId) async {
    final url = Uri.parse('$baseUrl/api/don-xin-nghi/quan-ly/$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      List<DonXin> allDon = data.map((json) => DonXin.fromJson(json)).toList();

      List<DonXin> filteredDon = allDon.where((don) {
        DateTime ngayBatDau = DateTime.tryParse(don.ngayBatDau) ?? DateTime(2000);

        bool matchMonthYear = (selectedMonth == null || ngayBatDau.month == selectedMonth) &&
                              (selectedYear == null || ngayBatDau.year == selectedYear);

        bool matchMaDon = searchMaDon.isEmpty || don.maDon.toLowerCase().contains(searchMaDon.toLowerCase());

        return matchMonthYear && matchMaDon;
      }).toList();

      return filteredDon;
    } else {
      throw Exception('Lỗi tải danh sách đơn xin nghỉ của user');
    }
  }

  void filterByDate(int month, int year) {
    setState(() {
      selectedMonth = month;
      selectedYear = year;
      _futureDonXin = fetchDonXinByUser(widget.userId);
    });
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã đơn: ${don.maDon}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Loại đơn: ${don.loaiDon}'),
            Text('Lý do: ${don.lyDo}'),
            Text('Ngày bắt đầu: ${don.ngayBatDau}'),
            Text('Ngày kết thúc: ${don.ngayKetThuc}'),
            Text('Trạng thái: ${don.trangThai}'),
            if (don.ngayGui != null) Text('Ngày gửi: ${don.ngayGui}'),
            if (don.maQL != null) Text('Quản lý duyệt: ${don.maQL}'),
            if (don.ngayDuyet != null) Text('Ngày duyệt: ${don.ngayDuyet}'),
            if (don.ghiChu != null) Text('Ghi chú: ${don.ghiChu}'),

            if (don.trangThai == 'Chờ duyệt' || don.trangThai == 'Chờ phê duyệt') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () async {
                        bool success = await duyetTuChoiDon(don.maDon, 'Đã duyệt', 'Đơn đã được duyệt');
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duyệt đơn thành công')));
                          setState(() {
                            _futureDonXin = fetchDonXinByUser(widget.userId);
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duyệt đơn thất bại')));
                        }
                      },
                      child: const Text('Duyệt'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        bool success = await duyetTuChoiDon(don.maDon, 'Từ chối', 'Đơn bị từ chối');
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Từ chối đơn thành công')));
                          setState(() {
                            _futureDonXin = fetchDonXinByUser(widget.userId);
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Từ chối đơn thất bại')));
                        }
                      },
                      child: const Text('Từ chối'),
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
        title: Text('Đơn xin nghỉ của: ${widget.userId}'),
      ),
      body: Column(
        children: [
          // TextField tìm kiếm mã đơn
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Tìm kiếm mã đơn',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: onSearchMaDonChanged,
            ),
          ),

          // Dropdown chọn tháng và năm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                DropdownButton<int>(
                  value: selectedMonth,
                  items: List.generate(12, (index) => index + 1)
                      .map((month) => DropdownMenuItem(
                            value: month,
                            child: Text('Tháng $month'),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) filterByDate(val, selectedYear ?? DateTime.now().year);
                  },
                ),
                const SizedBox(width: 20),
                DropdownButton<int>(
                  value: selectedYear,
                  items: List.generate(10, (index) => DateTime.now().year - index)
                      .map((year) => DropdownMenuItem(
                            value: year,
                            child: Text('Năm $year'),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) filterByDate(selectedMonth ?? DateTime.now().month, val);
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<DonXin>>(
              future: _futureDonXin,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Chưa có đơn xin nghỉ nào.'));
                }

                final donXinList = snapshot.data!;
                return ListView.builder(
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
