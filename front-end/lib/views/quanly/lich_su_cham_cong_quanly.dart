import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chamcong.dart';
import '../../models/caLam.dart';
import '../../services/api_service.dart';
import 'package:intl/date_symbol_data_local.dart';

class LichSuChamCongQuanLyView extends StatefulWidget {
  final String maQL;
  final String hoTenQL;

  const LichSuChamCongQuanLyView({
    super.key,
    required this.maQL,
    required this.hoTenQL,
  });

  @override
  _LichSuChamCongQuanLyViewState createState() => _LichSuChamCongQuanLyViewState();
}

class _LichSuChamCongQuanLyViewState extends State<LichSuChamCongQuanLyView> {
  final ApiService apiService = ApiService();
  
  List<ChamCong> _allRecords = [];
  Map<String, List<ChamCong>> _groupedRecords = {};
  Map<String, CaLam> _caLamMap = {}; // Cache thông tin ca làm
  bool _isLoading = true;
  String? _error;

  // Bộ lọc
  String _filterType = 'all';
  DateTime? _selectedDate;
  int? _selectedMonth;
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi_VN', null).then((_) {
      _loadData();
    });
  }

  // Lấy thông tin ca làm (với icon và màu mặc định)
  Map<String, dynamic> _getShiftInfo(String maCa) {
    final caLam = _caLamMap[maCa];
    
    // Màu và icon theo ca
    Color color;
    IconData icon;
    
    if (maCa == 'CA001') {
      color = Colors.orange;
      icon = Icons.wb_sunny;
    } else if (maCa == 'CA002') {
      color = Colors.blue;
      icon = Icons.wb_twilight;
    } else if (maCa == 'CA003') {
      color = Colors.indigo;
      icon = Icons.nightlight;
    } else {
      color = Colors.grey;
      icon = Icons.access_time;
    }
    
    return {
      'name': caLam?.tenCa ?? 'Không xác định',
      'time': caLam?.timeRange ?? '--:-- - --:--',
      'color': color,
      'icon': icon,
    };
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      try {
        final caLamList = await apiService.getAllCaLam();
        _caLamMap = Map.fromEntries(
          caLamList.map((ca) => MapEntry(ca.maCa, ca))
        );
      } catch (e) {
        print('Không thể load ca làm từ API: $e');
        _caLamMap = {
          'CA001': CaLam(
            maCa: 'CA001',
            tenCa: 'Ca Sáng',
            gioBatDau: '08:00',
            gioKetThuc: '12:00',
            ghiChu: 'Ca làm buổi sáng',
          ),
          'CA002': CaLam(
            maCa: 'CA002',
            tenCa: 'Ca Chiều',
            gioBatDau: '13:00',
            gioKetThuc: '17:30',
            ghiChu: 'Ca làm buổi chiều',
          ),
          'CA003': CaLam(
            maCa: 'CA003',
            tenCa: 'Ca Tối',
            gioBatDau: '19:00',
            gioKetThuc: '23:59',
            ghiChu: 'Ca làm buổi tối',
          ),
        };
      }
      
      // Load chấm công
      final records = await apiService.getChamCongByUserId(widget.maQL);
      setState(() {
        _allRecords = records;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    List<ChamCong> filteredRecords = [];

    if (_filterType == 'all') {
      filteredRecords = _allRecords;
    } else if (_filterType == 'day' && _selectedDate != null) {
      filteredRecords = _allRecords.where((record) {
        return record.ngayChamCong.year == _selectedDate!.year &&
               record.ngayChamCong.month == _selectedDate!.month &&
               record.ngayChamCong.day == _selectedDate!.day;
      }).toList();
    } else if (_filterType == 'month' && _selectedMonth != null && _selectedYear != null) {
      filteredRecords = _allRecords.where((record) {
        return record.ngayChamCong.month == _selectedMonth &&
               record.ngayChamCong.year == _selectedYear;
      }).toList();
    } else if (_filterType == 'year' && _selectedYear != null) {
      filteredRecords = _allRecords.where((record) {
        return record.ngayChamCong.year == _selectedYear;
      }).toList();
    }

    // Nhóm theo ngày
    setState(() {
      _groupedRecords = _groupByDate(filteredRecords);
    });
  }

  Map<String, List<ChamCong>> _groupByDate(List<ChamCong> records) {
    Map<String, List<ChamCong>> grouped = {};
    
    for (var record in records) {
      String dateKey = DateFormat('yyyy-MM-dd').format(record.ngayChamCong);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(record);
    }

    // Sắp xếp các ca trong mỗi ngày theo giờ bắt đầu của ca
    grouped.forEach((key, value) {
      value.sort((a, b) {
        final caA = _caLamMap[a.maCa];
        final caB = _caLamMap[b.maCa];
        if (caA != null && caB != null) {
          return caA.gioBatDau.compareTo(caB.gioBatDau);
        }
        // Fallback: sắp xếp theo mã ca
        return a.maCa.compareTo(b.maCa);
      });
    });

    return grouped;
  }

  int _countCompletedShifts() {
    int count = 0;
    _groupedRecords.forEach((date, records) {
      count += records.where((r) => r.gioRa.isNotEmpty && r.gioRa != 'null').length;
    });
    return count;
  }

  int _countTotalShifts() {
    int count = 0;
    _groupedRecords.forEach((date, records) {
      count += records.length;
    });
    return count;
  }

  Map<String, int> _getShiftStatistics() {
    Map<String, int> stats = {};
    
    // Khởi tạo cho tất cả ca trong _caLamMap
    for (var maCa in _caLamMap.keys) {
      stats[maCa] = 0;
    }
    
    _groupedRecords.forEach((date, records) {
      for (var record in records) {
        if (stats.containsKey(record.maCa)) {
          stats[record.maCa] = stats[record.maCa]! + 1;
        } else {
          stats[record.maCa] = 1;
        }
      }
    });
    
    return stats;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _filterType = 'day';
      });
      _applyFilter();
    }
  }

  Future<void> _selectMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear ?? now.year, _selectedMonth ?? now.month),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = picked.month;
        _selectedYear = picked.year;
        _filterType = 'month';
      });
      _applyFilter();
    }
  }

  Future<void> _selectYear() async {
    final now = DateTime.now();
    final picked = await showDialog<int>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Chọn năm'),
          children: List.generate(10, (index) {
            final year = now.year - index;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, year),
              child: Text(
                year.toString(),
                style: TextStyle(
                  fontWeight: year == _selectedYear ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedYear = picked;
        _filterType = 'year';
      });
      _applyFilter();
    }
  }

  void _resetFilter() {
    setState(() {
      _filterType = 'all';
      _selectedDate = null;
      _selectedMonth = null;
      _selectedYear = null;
    });
    _applyFilter();
  }

  String _getFilterLabel() {
    if (_filterType == 'all') return 'Tất cả';
    if (_filterType == 'day' && _selectedDate != null) {
      return 'Ngày ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}';
    }
    if (_filterType == 'month' && _selectedMonth != null && _selectedYear != null) {
      return 'Tháng $_selectedMonth/$_selectedYear';
    }
    if (_filterType == 'year' && _selectedYear != null) {
      return 'Năm $_selectedYear';
    }
    return 'Chưa chọn';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử chấm công'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header hiển thị thông tin quản lý
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border(
                bottom: BorderSide(color: Colors.green[200]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hoTenQL,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mã: ${widget.maQL}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Bộ lọc
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_list, size: 20, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'Lọc theo:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    Chip(
                      label: Text(_getFilterLabel()),
                      deleteIcon: _filterType != 'all' ? const Icon(Icons.close, size: 18) : null,
                      onDeleted: _filterType != 'all' ? _resetFilter : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('Ngày'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _filterType == 'day' ? Colors.green : Colors.grey[300],
                          foregroundColor: _filterType == 'day' ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectMonth,
                        icon: const Icon(Icons.calendar_month, size: 18),
                        label: const Text('Tháng'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _filterType == 'month' ? Colors.green : Colors.grey[300],
                          foregroundColor: _filterType == 'month' ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectYear,
                        icon: const Icon(Icons.date_range, size: 18),
                        label: const Text('Năm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _filterType == 'year' ? Colors.green : Colors.grey[300],
                          foregroundColor: _filterType == 'year' ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Thống kê tổng quan
          if (_groupedRecords.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Tổng ngày', '${_groupedRecords.length}', Icons.event_note),
                      _buildStatItem('Tổng ca', '${_countTotalShifts()}', Icons.access_time),
                      _buildStatItem('Ca đầy đủ', '${_countCompletedShifts()}', Icons.check_circle),
                      _buildStatItem(
                        'Ca thiếu',
                        '${_countTotalShifts() - _countCompletedShifts()}',
                        Icons.warning,
                      ),
                    ],
                  ),
                  if (_caLamMap.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Thống kê theo ca - động từ database
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _getShiftStatistics().entries.map((entry) {
                        final shiftInfo = _getShiftInfo(entry.key);
                        return _buildShiftStat(
                          shiftInfo['name'] as String,
                          entry.value.toString(),
                          shiftInfo['icon'] as IconData,
                          shiftInfo['color'] as Color,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

          // Danh sách
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
        Icon(icon, color: Colors.green[700], size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildShiftStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Lỗi: $_error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_groupedRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _filterType == 'all' 
                  ? 'Chưa có dữ liệu chấm công'
                  : 'Không có dữ liệu cho bộ lọc này',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_filterType != 'all') ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: _resetFilter,
                child: const Text('Xóa bộ lọc'),
              ),
            ],
          ],
        ),
      );
    }

    final sortedDates = _groupedRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final records = _groupedRecords[dateKey]!;
        final date = records.first.ngayChamCong;

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - Ngày
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${records.length} ca',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Danh sách các ca
              ...records.map((cc) {
                final hasGioRa = cc.gioRa.isNotEmpty && cc.gioRa != 'null';
                final shiftInfo = _getShiftInfo(cc.maCa);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[200]!,
                        width: cc != records.last ? 1 : 0,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon ca
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: (shiftInfo['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          shiftInfo['icon'] as IconData,
                          color: shiftInfo['color'] as Color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Thông tin ca
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  shiftInfo['name'] as String,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: shiftInfo['color'] as Color,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: hasGioRa ? Colors.green[50] : Colors.orange[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: hasGioRa ? Colors.green[300]! : Colors.orange[300]!,
                                    ),
                                  ),
                                  child: Text(
                                    hasGioRa ? 'Đủ' : 'Thiếu',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: hasGioRa ? Colors.green[700] : Colors.orange[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              shiftInfo['time'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.login, size: 16, color: Colors.green[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Vào: ${cc.gioVao}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.logout, size: 16, color: Colors.red[600]),
                                const SizedBox(width: 4),
                                Text(
                                  hasGioRa ? 'Ra: ${cc.gioRa}' : 'Ra: Chưa chấm công',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: hasGioRa ? Colors.black87 : Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                            if (cc.diaDiemChamCong.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 16, color: Colors.green[600]),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      cc.diaDiemChamCong,
                                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
