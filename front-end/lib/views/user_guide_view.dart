import 'package:flutter/material.dart';

class UserGuideView extends StatefulWidget {
  final String userRole;

  const UserGuideView({
    super.key,
    required this.userRole,
  });

  @override
  State<UserGuideView> createState() => _UserGuideViewState();
}

class _UserGuideViewState extends State<UserGuideView> {
  late List<GuideSection> _guideSections;

  @override
  void initState() {
    super.initState();
    _initializeGuide();
  }

  void _initializeGuide() {
    if (userRole == 'NhanVien') {
      _guideSections = _getNhanVienGuide();
    } else if (userRole == 'QuanLy') {
      _guideSections = _getQuanLyGuide();
    } else {
      _guideSections = [];
    }
  }

  String get userRole => widget.userRole;

  List<GuideSection> _getNhanVienGuide() {
    return [
      GuideSection(
        title: '👤 Thông tin cá nhân',
        steps: [
          '1. Từ menu, chọn "Thông tin cá nhân"',
          '2. Xem các thông tin: Họ tên, email, số điện thoại',
          '3. Xem phòng ban và chức vụ của bạn',
          '4. Có thể liên hệ quản lý để cập nhật thông tin nếu cần',
        ],
      ),
      GuideSection(
        title: '⏱️ Chấm công',
        steps: [
          '1. Nhấn nút "CHẤM CÔNG" trên trang chính',
          '2. Ứng dụng sẽ quét khuôn mặt của bạn',
          '3. Chấm công vào lúc bắt đầu ca làm việc',
          '4. Chấm công ra vào lúc kết thúc ca làm việc',
          '💡 TIP: Hãy đảm bảo điều kiện ánh sáng tốt khi chấm công',
          '⚠️ Nếu không nhận diện được khuôn mặt, hãy đăng ký khuôn mặt trước',
        ],
      ),
      GuideSection(
        title: '📸 Đăng ký khuôn mặt',
        steps: [
          '1. Từ menu, chọn "Quản lý khuôn mặt"',
          '2. Nhấn "ĐĂNG KÝ KHUÔN MẶT MỚI"',
          '3. Xác định các góc khuôn mặt (trực diện, trái, phải)',
          '4. Hệ thống sẽ tự chụp khuôn mặt',
          '5. Đợi xác nhận từ hệ thống',
          '💡 TIP: Tìm nơi có ánh sáng tốt, tránh bóng đổ',
        ],
      ),
      GuideSection(
        title: '📋 Lịch sử chấm công',
        steps: [
          '1. Từ menu, chọn "Lịch sử chấm công"',
          '2. Xem danh sách tất cả các lần chấm công',
          '3. Xem giờ vào, giờ ra, ca làm việc',
          '4. Dùng bộ lọc để tìm kiếm theo ngày/tháng/năm',
        ],
      ),
      GuideSection(
        title: '📝 Gửi đơn xin nghỉ',
        steps: [
          '1. Từ menu, chọn "Gửi đơn xin nghỉ"',
          '2. Chọn loại đơn: Nghỉ phép, Nghỉ ốm, Nghỉ không lương',
          '3. Chọn ngày bắt đầu và ngày kết thúc',
          '4. Nhập lý do xin nghỉ (nếu cần)',
          '5. Nhấn "GỬI ĐƠN" để gửi cho quản lý',
          'Quản lý của bạn sẽ duyệt đơn trong vòng 24h',
        ],
      ),
      GuideSection(
        title: '📄 Lịch sử đơn từ',
        steps: [
          '1. Từ menu, chọn "Lịch sử đơn từ"',
          '2. Xem trạng thái của các đơn đã gửi',
          '3. Màu xanh = Đã duyệt, Đỏ = Từ chối, Vàng = Đang chờ',
          '4. Xem lý do từ chối nếu có',
        ],
      ),
      GuideSection(
        title: '❓ Cần trợ giúp?',
        steps: [
          '📞 Liên hệ quản lý phòng ban của bạn',
          '📧 Gửi email cho bộ phận IT/Quản trị viên',
          '⏰ Thời gian hỗ trợ: 8:00 - 17:00 (Thứ 2 - Thứ 6)',
        ],
      ),
    ];
  }

  List<GuideSection> _getQuanLyGuide() {
    return [
      GuideSection(
        title: '👥 Danh sách nhân viên',
        steps: [
          '1. Từ menu, chọn "Danh sách nhân viên"',
          '2. Xem tất cả nhân viên trong phòng ban của bạn',
          '3. Tìm kiếm theo tên, mã nhân viên hoặc trạng thái',
          '4. Nhấn vào từng nhân viên để xem chi tiết',
        ],
      ),
      GuideSection(
        title: '➕ Thêm nhân viên mới',
        steps: [
          '⚠️ LƯU Ý: Tính năng này sẽ được chuyển cho Quản trị viên trong phiên bản tới',
          '1. Từ menu, chọn "Thêm nhân viên"',
          '2. Nhập thông tin: Họ tên, email, số điện thoại',
          '3. Chọn phòng ban: Phải là phòng ban của bạn',
          '4. Nhập ngày bắt đầu làm việc',
          '5. Đặt mật khẩu ban đầu',
          '6. Nhấn "LƯU" để tạo tài khoản',
          'Nhân viên sẽ nhận được username = mã nhân viên',
        ],
      ),
      GuideSection(
        title: '✅ Duyệt đơn xin nghỉ',
        steps: [
          '1. Từ menu, chọn "Duyệt đơn xin"',
          '2. Xem danh sách đơn đang chờ duyệt',
          '3. Nhấn vào đơn để xem chi tiết',
          '4. Chọn "DUYỆT" hoặc "TỪ CHỐI"',
          '5. Nếu từ chối, nhập lý do từ chối',
          '6. Nhân viên sẽ nhận được thông báo ngay',
          'Duyệt đơn càng sớm càng tốt để nhân viên biết',
        ],
      ),
      GuideSection(
        title: '📋 Danh sách chấm công nhân viên',
        steps: [
          '1. Từ menu, chọn "Chấm công nhân viên"',
          '2. Xem danh sách chấm công của tất cả nhân viên trong phòng',
          '3. Có thể thay đổi giờ vào/ra nếu cần sửa',
          '4. Áp dụng bộ lọc theo ngày, tháng, năm',
        ],
      ),
      GuideSection(
        title: '📊 Xem báo cáo phòng',
        steps: [
          '1. Từ menu, chọn "Xem báo cáo phòng"',
          '2. Xem thống kê chi tiết về phòng ban:',
          '   - Tổng nhân viên',
          '   - Nhân viên đi làm, nghỉ, trễ',
          '   - Tỷ lệ chấm công',
          '3. Sắp xếp theo tháng/năm',
          '4. Xuất báo cáo thành Excel hoặc PDF',
        ],
      ),
      GuideSection(
        title: '📜 Lịch sử chấm công',
        steps: [
          '1. Từ menu, chọn "Lịch sử chấm công"',
          '2. Xem chi tiết chấm công của bạn',
          '3. Kiểm tra giờ vào/ra của bản thân',
        ],
      ),
      GuideSection(
        title: '📸 Đăng ký khuôn mặt',
        steps: [
          '1. Từ menu, chọn "Đăng ký gương mặt"',
          '2. Quản lý cũng cần đăng ký khuôn mặt',
          '3. Thực hiện như hướng dẫn của nhân viên',
        ],
      ),
      GuideSection(
        title: '⚙️ Những lưu ý quan trọng',
        steps: [
          '✅ NHIỆM VỤ CHÍNH:',
          '  - Quản lý nhân viên trong phòng ban',
          '  - Duyệt đơn xin nghỉ',
          '  - Xem báo cáo phòng ban',
          '',
          '❌ KHÔNG CẦN LÀM:',
          '  - Xóa nhân viên (chức năng của Quản trị viên)',
          '  - Khóa/Mở khóa tài khoản (chức năng của Quản trị viên)',
          '  - Quản lý các phòng ban khác',
        ],
      ),
      GuideSection(
        title: '❓ Cần trợ giúp?',
        steps: [
          '📞 Liên hệ Quản trị viên hệ thống',
          '📧 Gửi email cho bộ phận IT',
          '⏰ Thời gian hỗ trợ: 8:00 - 17:00 (Thứ 2 - Thứ 6)',
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              userRole == 'NhanVien' 
                ? Icons.school 
                : Icons.manage_accounts,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hướng dẫn sử dụng - ${_getRoleLabel()}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        backgroundColor: _getRoleColor(),
        elevation: 0,
      ),
      body: _guideSections.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không có hướng dẫn',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _guideSections.length,
              itemBuilder: (context, index) {
                return _buildSectionCard(_guideSections[index]);
              },
            ),
    );
  }

  String _getRoleLabel() {
    switch (userRole) {
      case 'NhanVien':
        return 'Nhân Viên';
      case 'QuanLy':
        return 'Quản Lý';
      default:
        return 'Người dùng';
    }
  }

  Color _getRoleColor() {
    switch (userRole) {
      case 'NhanVien':
        return Colors.blue;
      case 'QuanLy':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSectionCard(GuideSection section) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                color: _getRoleColor(),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                section.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
        iconColor: _getRoleColor(),
        collapsedIconColor: Colors.grey[600],
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: section.steps.where((step) => step.isNotEmpty).map((step) {
                // Extract first character that is a digit or emoji
                String indicator = _extractStepIndicator(step);
                String stepText = _extractStepText(step);
                bool isSpecialLine = !RegExp(r'^\d').hasMatch(step); // Not starting with number
                
                if (isSpecialLine) {
                  // For lines with emoji or special content, show full text without indicator box
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      stepText,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  );
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Number step indicator
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getRoleColor().withOpacity(0.1),
                          border: Border.all(
                            color: _getRoleColor().withOpacity(0.3),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            indicator,
                            style: TextStyle(
                              color: _getRoleColor(),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            stepText,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _extractStepIndicator(String step) {
    // Extract first digit if step starts with digit
    final match = RegExp(r'^\d').firstMatch(step);
    if (match != null) {
      return match.group(0) ?? '•';
    }
    return '•';
  }

  String _extractStepText(String step) {
    // Remove leading "number. " pattern (e.g., "1. ", "2. ")
    return step.replaceFirst(RegExp(r'^\d+\.\s+'), '').trim();
  }
}

class GuideSection {
  final String title;
  final List<String> steps;

  GuideSection({
    required this.title,
    required this.steps,
  });
}
