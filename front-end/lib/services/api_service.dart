import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chamcong.dart';
import '../models/donxin.dart';
import '../models/caLam.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/baocao.dart';
class ApiService {
  // static const String baseUrl = 'http://10.0.2.2:5000';
  static const String baseUrl = 'http://192.168.0.114:5000';
  
// === HÀM XÓA FILE BÁO CÁO CŨ ===
  Future<int> deleteAllReports() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      // Dùng await list() để không bị đơ ứng dụng nếu file quá nhiều
      final List<FileSystemEntity> entities = await dir.list().toList();

      int deletedCount = 0;
      for (var entity in entities) {
        if (entity is File) {
          final path = entity.path.toLowerCase();
          // Chỉ xóa file PDF và Excel
          if (path.endsWith('.pdf') || path.endsWith('.xlsx')) {
            await entity.delete();
            print("🗑️ Đã xóa: $path");
            deletedCount++;
          }
        }
      }
      print("✅ Đã dọn dẹp xong $deletedCount file!");
      return deletedCount;
    } catch (e) {
      print("❌ Lỗi xóa file: $e");
      return 0;
    }
  }
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"username": username, "password": password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Lỗi kết nối hệ thống (Mã: ${response.statusCode})');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> generateEmployeeId(String maPB, String ngayBatDau) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate_employee_id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"MaPB": maPB, "NgayBatDauLam": ngayBatDau}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)["MaNV"];
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Lỗi tạo mã nhân viên');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> createEmployee({
    required String maPB,
    required String ngayBatDau,
    String? hoTen,
    String? email,
    String? soDienThoai,
    String? chucVu,
    String? gioiTinh,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/create_employee'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "ma_phong_ban": maPB,
          "ngay_bat_dau": ngayBatDau,
          "ho_ten": hoTen,
          "email": email,
          "so_dien_thoai": soDienThoai,
          "chuc_vu": chucVu,
          "gioi_tinh": gioiTinh,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Lỗi tạo nhân viên');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> registerFace({
    required String idUser,
    required List<String> imagesBase64,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/register_face'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "id_user": idUser,
          "images": imagesBase64,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] == true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Lỗi đăng ký khuôn mặt');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối API: $e');
    }
  }

  Future<bool> updateEmployee({
    required String maNV,
    required String hoTen,
    required String email,
    required String soDienThoai,
    required String gioiTinh,
    String? chucVu,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/update_employee/$maNV'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "HoTenNV": hoTen,
          "Email": email,
          "SoDienThoai": soDienThoai,
          "GioiTinh": gioiTinh,
          "ChucVu": chucVu,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] == true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Lỗi cập nhật thông tin');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updatePassword({
    required String maNV,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/update_account/$maNV'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "MatKhau": newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] == true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Lỗi cập nhật mật khẩu');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
    // ============= CHẤM CÔNG =============
Future<List<ChamCong>> getChamCongByUserId(String userId) async {
  final response = await http.get(Uri.parse('$baseUrl/api/chamcong/$userId'));
  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ChamCong.fromJson(json)).toList();
  } else {
    final errorData = jsonDecode(response.body);
    throw Exception(errorData['error'] ?? 'Lỗi tải lịch sử chấm công');
  }
}
// ============= CA LÀM =============
Future<List<CaLam>> getAllCaLam() async{
  try{
    final response = await http.get(Uri.parse('$baseUrl/api/calam'), headers: {'Content-Type': 'Application/json'});

    if(response.statusCode == 200){
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CaLam.fromJson(json)).toList();
    }
    else{
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Lỗi tải danh sách ca làm');
    }
  }
  catch (e){
    print("API ERROR getAllCaLam: $e");
    rethrow;
  }
}

Future<CaLam?> getCaLamById (String maCa) async {
  try{
    final reponse = await http.get(Uri.parse('$baseUrl/api/calam/$maCa'), headers: {'Content-Type': 'Application/json'});

    if(reponse.statusCode == 200){
      return CaLam.fromJson(jsonDecode(reponse.body));
    }
    else {return null;}
  } catch (e){
    print("API ERROR getCaLamById: $e");
    return null;
  }
}
  // ============= ĐƠN XIN =============
 Future<String?> sendDonXinNghi({
  required String userId,
  required String lyDo,
  required DateTime ngayBatDau,
  required DateTime ngayKetThuc,
  required String loaiDon, 
}) async {
  try {
    final body = jsonEncode({
      'userId': userId,
      'lyDo': lyDo.trim(),
      'loaiDon': loaiDon.trim(),    
      'ngayBatDau': '${ngayBatDau.toIso8601String()}Z',   
      'ngayKetThuc': '${ngayKetThuc.toIso8601String()}Z',
    });
    print('Request body: $body');

    final response = await http.post(
      Uri.parse('$baseUrl/api/don-xin-nghi'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return null; // Thành công
    } else {
      final errorData = jsonDecode(response.body);
      return errorData['error'] ?? 'Lỗi gửi đơn: ${response.statusCode}';
    }
  } catch (e) {
    return 'Lỗi gửi đơn: $e';
  }
}


  // Lấy danh sách đơn xin nghỉ của user (GET)
  Future<List<DonXin>> getDonXinNghiByUser(String userId) async {
    final url = Uri.parse('$baseUrl/api/don-xin-nghi/$userId');
    final response = await http.get(url);

    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => DonXin.fromJson(json)).toList();
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Lỗi tải danh sách đơn xin nghỉ');
    }
  }
  //xoa don xin cua nhan vien
  Future<void> deleteDonXin(String maDon) async {
  final url = Uri.parse('$baseUrl/api/don-xin-nghi/$maDon');
  final response = await http.delete(url);

  if (response.statusCode != 200) {
    final data = jsonDecode(response.body);
    throw Exception(data['error'] ?? 'Xóa đơn thất bại');
  }
}

// Lấy thông tin quản lý theo mã
Future<Map<String, dynamic>?> getQuanLyInfo(String maQL) async {
  try {
    final url = Uri.parse('$baseUrl/api/quanly/$maQL');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  } catch (e) {
    print('Error getting quan ly info: $e');
    return null;
  }
}

// Lấy danh sách đơn xin chờ duyệt của quản lý
Future<List<DonXin>> getPendingDonXinByQuanLy(String maQL) async {
  try {
    final url = Uri.parse('$baseUrl/api/don-xin-nghi/quan-ly/$maQL');
    final response = await http.get(url);

    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // Lọc chỉ những đơn có trạng thái "Chờ duyệt"
      final pendingRequests = data
          .map((json) => DonXin.fromJson(json))
          .where((don) => don.trangThai?.toLowerCase() == 'chờ duyệt')
          .toList();
      return pendingRequests;
    } else {
      throw Exception('Lỗi tải danh sách đơn xin chờ duyệt');
    }
  } catch (e) {
    print('Error getting pending don xin: $e');
    return [];
  }
}

Future<void> duyetTuChoiDon(String maDon, String trangThai, String ghiChu, String maQL) async {
  final url = Uri.parse('$baseUrl/api/don-xin-nghi/duyet-tu-choi/$maDon');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'trangThai': trangThai,
      'ghiChu': ghiChu,
      'maQL': maQL,   // Gửi kèm mã quản lý
    }),
  );

  if (response.statusCode != 200) {
    throw Exception('Lỗi duyệt đơn: ${response.body}');
  }
}

Future<List<Map<String, dynamic>>> getNhanVienByQuanLy(String maql) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/quanly/nhanvien/phong/$maql'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Nếu API không có key 'nhanvien' hoặc null → trả về list rỗng
      final list = data['NhanVien'];
      if (list == null || list is! List) {
        return [];
      }

      // Convert an toàn
      return List<Map<String, dynamic>>.from(
        list.map((e) => {
          "maNV": e["MaNV"],
          "hoTen": e["HoTenNV"],
          "email": e["Email"],
          "soDienThoai": e["SoDienThoai"],
          "chucVu": e["ChucVu"],
          "gioiTinh": e["GioiTinh"],
          "maPB": e["MaPB"],
        })
      );
    } else {
      throw Exception('Lỗi tải danh sách nhân viên');
    }
  } catch (e) {
    // Không cho phép throw null ra ngoài → return list rỗng
    print("API ERROR getNhanVienByQuanLy: $e");
    return [];
  }
}
Future<Map<String, dynamic>?> checkFaceStatus(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/check_face_status/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Nếu lỗi, trả về null hoặc ném lỗi tùy logic
        print("Check status failed: ${response.body}");
        return null; 
      }
    } catch (e) {
      print("API Connection Error: $e");
      return null;
    }
  }

 // ================= GET BÁO CÁO =================
  Future<List<BaoCao>> getBaoCao({
    required String userId,
    required String role,
    required String filterType, // 'thang' hoặc 'nam'
    String? month,              // Optional, bắt buộc nếu filterType='thang'
    required String year,
  }) async {
    try {
      // Validate input
      if (filterType == 'thang' && (month == null || month.isEmpty)) {
        throw Exception('Thiếu tháng khi báo cáo theo tháng');
      }

      // Build query parameters
      final queryParams = {
        'user_id': userId,
        'role': role,
        'filter_type': filterType,
        'year': year,
      };

      // Chỉ thêm month nếu có
      if (month != null && month.isNotEmpty) {
        queryParams['month'] = month;
      }

      final uri = Uri.parse('$baseUrl/api/baocao').replace(
        queryParameters: queryParams,
      );

      print('📊 Fetching report: $uri');

      final res = await http.get(uri);

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final jsonData = json.decode(res.body);
      
      if (jsonData['success'] != true) {
        throw Exception(jsonData['error'] ?? 'Lỗi lấy báo cáo');
      }

      final List<BaoCao> reports = (jsonData['data'] as List)
          .map((e) => BaoCao.fromJson(e))
          .toList();

      print('✅ Loaded ${reports.length} records');
      return reports;

    } catch (e) {
      print('❌ getBaoCao error: $e');
      rethrow;
    }
  }

  // ================= EXCEL =================
 Future<File?> downloadBaoCaoExcel({
    required String userId,
    required String role,
    required String filterType,
    String? month,
    required String year,
  }) async {
    try {
      // Validate
      if (filterType == 'thang' && (month == null || month.isEmpty)) {
        throw Exception('Thiếu tháng khi báo cáo theo tháng');
      }

      // Query parameters
      final queryParams = {
        'user_id': userId,
        'role': role,
        'filter_type': filterType,
        'year': year,
      };

      if (month != null && month.isNotEmpty) {
        queryParams['month'] = month;
      }

      final uri = Uri.parse('$baseUrl/api/baocao/excel').replace(
        queryParameters: queryParams,
      );

      print('📥 Downloading Excel: $uri');

      final res = await http.get(uri);

      if (res.statusCode != 200) {
        print('❌ Excel download failed: ${res.statusCode}');
        return null;
      }

      // Tạo file name động
      final fileName = filterType == 'thang'
          ? 'BaoCao_Thang${month}_$year.xlsx'
          : 'BaoCao_Nam$year.xlsx';

      // Lưu file
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(res.bodyBytes);

      print('✅ Excel saved: ${file.path}');
      return file;

    } catch (e) {
      print('❌ downloadBaoCaoExcel error: $e');
      return null;
    }
  }


  // ================= PDF =================
  Future<File?> downloadBaoCaoPDF({
    required String userId,
    required String role,
    required String filterType,
    String? month,
    required String year,
  }) async {
    try {
      // Validate
      if (filterType == 'thang' && (month == null || month.isEmpty)) {
        throw Exception('Thiếu tháng khi báo cáo theo tháng');
      }

      // Query parameters
      final queryParams = {
        'user_id': userId,
        'role': role,
        'filter_type': filterType,
        'year': year,
      };

      if (month != null && month.isNotEmpty) {
        queryParams['month'] = month;
      }

      final uri = Uri.parse('$baseUrl/api/baocao/pdf').replace(
        queryParameters: queryParams,
      );

      print('📥 Downloading PDF: $uri');

      final res = await http.get(uri);

      if (res.statusCode != 200) {
        print('❌ PDF download failed: ${res.statusCode}');
        return null;
      }

      // Tạo file name động
      final fileName = filterType == 'thang'
          ? 'BaoCao_Thang${month}_$year.pdf'
          : 'BaoCao_Nam$year.pdf';

      // Lưu file
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(res.bodyBytes);

      print('✅ PDF saved: ${file.path}');
      return file;

    } catch (e) {
      print('❌ downloadBaoCaoPDF error: $e');
      return null;
    }
  }
  
//suathongtinnhanvien
  Future<void> updateNhanVien(
    String maNV,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/nhanvien/$maNV'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Cập nhật thất bại: ${response.body}');
    }
  }
  //khoa tai khoan nhan vien
  Future<void> khoaNhanVien(String maNV) async {
  final response = await http.put(
    Uri.parse('$baseUrl/api/nhanvien/$maNV/khoa'),
  );

  if (response.statusCode != 200) {
    throw Exception('Khóa nhân viên thất bại');
  }
}

Future<void> moKhoaNhanVien(String maNV) async {
  final response = await http.put(
    Uri.parse('$baseUrl/api/nhanvien/$maNV/mo-khoa'),
  );

  if (response.statusCode != 200) {
    throw Exception('Mở khóa nhân viên thất bại');
  }
}

}