import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';

class OfflineAttendanceService {
  static const String _offlineQueueKey = 'offline_attendance_queue';
  final String baseUrl = "http://192.168.0.114:5000";

  Future<bool> hasInternet() async {
    var result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // === 1. LƯU ẢNH + TEXT (KHI NHẬN DIỆN THÀNH CÔNG NHƯNG CHẤM CÔNG FAIL) ===
  Future<void> saveOfflineImageAttendance({
    required List<int> imageBytes,
    required String userId,
    required String role,
    required String shift,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final directory = await getApplicationDocumentsDirectory();
    
    final timestamp = DateTime.now();
    final fileName = 'att_${timestamp.millisecondsSinceEpoch}.jpg';
    final filePath = '${directory.path}/$fileName';
    
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);

    List<String> queue = prefs.getStringList(_offlineQueueKey) ?? [];
    
    final record = jsonEncode({
      'type': 'image_with_text',
      'imagePath': filePath,
      'timestamp': timestamp.toIso8601String(),
      'shift': shift,
      'userId': userId,
      'role': role,
      'location': 'Văn phòng (Offline)',
    });

    queue.add(record);
    await prefs.setStringList(_offlineQueueKey, queue);
    print('[OFFLINE] ✅ Đã lưu cặp ảnh+text: $filePath - User: $userId');
  }

  // === 2. LƯU CHỈ ẢNH (KHI MẤT MẠNG NGAY TỪ LÚC NHẬN DIỆN) ===
  Future<void> saveOfflineImageOnly({
    required List<int> imageBytes,
    required String shift,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final directory = await getApplicationDocumentsDirectory();
    
    final timestamp = DateTime.now();
    final fileName = 'att_${timestamp.millisecondsSinceEpoch}.jpg';
    final filePath = '${directory.path}/$fileName';
    
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);

    List<String> queue = prefs.getStringList(_offlineQueueKey) ?? [];
    
    final record = jsonEncode({
      'type': 'image',
      'imagePath': filePath,
      'timestamp': timestamp.toIso8601String(),
      'shift': shift,
      'location': 'Văn phòng (Offline)',
    });

    queue.add(record);
    await prefs.setStringList(_offlineQueueKey, queue);
    print('[OFFLINE] ✅ Đã lưu ảnh: $filePath (cần nhận diện lại)');
  }

  // === 3. ĐỒNG BỘ DỮ LIỆU ===
  Future<void> syncOfflineData() async {
    if (!await hasInternet()) {
      print('[SYNC] ⚠️ Không có mạng, bỏ qua sync');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    List<String> queue = prefs.getStringList(_offlineQueueKey) ?? [];
    
    if (queue.isEmpty) {
      print('[SYNC] ℹ️ Không có dữ liệu offline cần sync');
      return;
    }

    print('[SYNC] 🔄 Bắt đầu đồng bộ ${queue.length} bản ghi...');
    List<String> failed = [];

    for (String recordStr in queue) {
      try {
        final record = jsonDecode(recordStr);

        // --- A. ĐỒNG BỘ ẢNH + TEXT (ƯU TIÊN - ĐÃ BIẾT USER) ---
        if (record['type'] == 'image_with_text') {
          final String imagePath = record['imagePath'];
          final file = File(imagePath);

          if (!await file.exists()) {
            print('[SYNC] ⚠️ File không tồn tại: $imagePath');
            continue;
          }

          final bytes = await file.readAsBytes();
          final base64Img = base64Encode(bytes);

          print('[SYNC] 📤 Đang sync ảnh+text: $imagePath - User: ${record['userId']}');

          final response = await http.post(
            Uri.parse("$baseUrl/api/sync_offline_attendance"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "type": "image_with_text", // ✅ Thêm type
              "image_base64": base64Img,
              "timestamp": record['timestamp'],
              "MaCa": record['shift'],
              "DiaDiem": record['location'],
              "userId": record['userId'], 
              "role": record['role'],
            }),
          ).timeout(const Duration(seconds: 20));

          if (response.statusCode == 200) {
            print('[SYNC] ✅ Đồng bộ ảnh+text thành công');
            await file.delete(); 
          } else {
            print('[SYNC] ❌ Lỗi sync ảnh+text: ${response.body}');
            failed.add(recordStr);
          }
        }
        
        // --- B. ĐỒNG BỘ CHỈ ẢNH (CẦN NHẬN DIỆN LẠI) ---
        else if (record['type'] == 'image') {
          final String imagePath = record['imagePath'];
          final file = File(imagePath);

          if (!await file.exists()) {
            print('[SYNC] ⚠️ File không tồn tại: $imagePath');
            continue;
          }

          final bytes = await file.readAsBytes();
          final base64Img = base64Encode(bytes);

          print('[SYNC] 📤 Đang sync ảnh (cần nhận diện): $imagePath');

          final response = await http.post(
            Uri.parse("$baseUrl/api/sync_offline_attendance"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "type": "image", // ✅ Thêm type
              "image_base64": base64Img,
              "timestamp": record['timestamp'],
              "MaCa": record['shift'],
              "DiaDiem": record['location']
            }),
          ).timeout(const Duration(seconds: 20));

          if (response.statusCode == 200) {
            print('[SYNC] ✅ Đồng bộ ảnh thành công');
            await file.delete(); 
          } else {
            print('[SYNC] ❌ Lỗi sync ảnh: ${response.body}');
            failed.add(recordStr);
          }
        }

      } catch (e) {
        print('[SYNC] ❌ Lỗi ngoại lệ: $e');
        failed.add(recordStr);
      }
    }

    await prefs.setStringList(_offlineQueueKey, failed);
    
    if (failed.isEmpty) {
      print('[SYNC] ✅ Đồng bộ hoàn tất! Tất cả thành công');
    } else {
      print('[SYNC] ⚠️ Còn ${failed.length} bản ghi chưa sync được');
    }
  }

  Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_offlineQueueKey) ?? []).length;
  }

  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineQueueKey);
    print('[OFFLINE] 🧹 Đã xóa queue offline');
  }
}