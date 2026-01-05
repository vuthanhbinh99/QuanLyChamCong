import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import '../services/offline_service.dart';

class ChamCongView extends StatefulWidget {
  const ChamCongView({super.key});

  @override
  State<ChamCongView> createState() => _ChamCongViewState();
}

class _ChamCongViewState extends State<ChamCongView> {
  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  bool _cameraReady = false;
  bool _isProcessing = false;
  bool _isSendingToServer = false;
  Size? _imageSize;
  String? _guideMessage;
  Color _guideColor = Colors.white;
  final OfflineAttendanceService _offlineService = OfflineAttendanceService();
  DateTime? _lastOfflineSaveTime; // Lưu thời điểm cuối cùng lưu offline
  final Duration _offlineSaveCooldown = const Duration(seconds: 30); // Quy định 30s

  List<Face> _faces = [];
  int _faceStableCount = 0;
  final int _stableThreshold = 5;

  String? _userMessage; 
  String? _lastRecognizedUserId;
  DateTime? _lastRecognitionTime;
  final Duration _recognitionCooldown = const Duration(seconds: 5);

  final baseUrl = "http://192.168.0.114:5000";

  int _frameSkipCounter = 0;
  final int _frameSkipRate = 3;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _initFaceDetector();
    _initCamera();
    _updatePendingCount(); 
    _checkAndSync();
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        Future.delayed(const Duration(seconds: 2), () {
          _checkAndSync();
        });
      }
    });
  }

// HÀM MỚI: Cập nhật số lượng pending lên UI
  Future<void> _updatePendingCount() async {
    final count = await _offlineService.getPendingCount();
    if (mounted) {
      setState(() {
        _pendingCount = count;
      });
    }
  }

  void _initFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableContours: false,
        enableClassification: false,
        enableLandmarks: false,
        minFaceSize: 0.1,
      ),
    );
    debugPrint("[DEBUG] tìm kiếm khuôn mặt bắt đầu (accurate mode, minSize: 0.1)");
  }

 Future<void> _checkAndSync() async {
    final count = await _offlineService.getPendingCount();
    if (mounted) setState(() => _pendingCount = count);

    if (count > 0 && await _offlineService.hasInternet()) {
      _showUserMessage('Đang đồng bộ dữ liệu...', Colors.blue);
      
      await _offlineService.syncOfflineData();
      
      await _updatePendingCount(); 

      final remainingCount = await _offlineService.getPendingCount();
      
      // Kiểm tra lại xem còn sót không để thông báo
      if (mounted) {
        if (remainingCount == 0) {
          //  Tất cả đã sync xong
          setState(() => _pendingCount = 0);
          _showUserMessage(' Đồng bộ hoàn tất!', Colors.green);
        } else {
          // ⚠️ Còn một số bản ghi chưa sync được
          setState(() => _pendingCount = remainingCount);
          _showUserMessage(' Còn $remainingCount bản ghi chưa đồng bộ được', Colors.orange);
        }
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      debugPrint("[DEBUG] Camera: ${front.name}, lens: ${front.lensDirection}");

      _cameraController = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.nv21 
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      await _cameraController!.lockCaptureOrientation();
      if (!mounted) return;

      debugPrint("[DEBUG] khởi tạo camera: ${_cameraController!.value.previewSize}");

      setState(() => _cameraReady = true);

      await Future.delayed(const Duration(milliseconds: 500));
      _cameraController!.startImageStream(_processFrame);
      
      debugPrint("[DEBUG] Camera stream started");
    } catch (e) {
      debugPrint("[ERROR] khởi tạo camera thất bại: $e");
      if (mounted) {
        _showUserMessage("Không thể mở camera. Vui lòng kiểm tra quyền truy cập.", Colors.red);
      }
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    _frameSkipCounter++;

    if (_frameSkipCounter < _frameSkipRate) return;
    _frameSkipCounter = 0;

    if (_isProcessing || _isSendingToServer) return;

    // Kiểm tra cooldown
    if (_lastRecognitionTime != null) {
      final timeSinceLastRecognition = DateTime.now().difference(_lastRecognitionTime!);
      if (timeSinceLastRecognition < _recognitionCooldown) {
        return;
      }
    }

    _isProcessing = true;

    try {
      final input = _convertToInputImage(image);
      final faces = await _faceDetector.processImage(input);

      // DEBUG LOG - Không hiện cho user
      if (faces.isNotEmpty) {
        debugPrint("[DEBUG] Detected ${faces.length} face(s)");
        _faceStableCount++;
      } else {
        _faceStableCount = 0;
        if (_frameSkipCounter % 30 == 0) {
          debugPrint("[DEBUG] Không tìm thấy khuôn mặt - Kiểm tra ánh sáng và góc máy");
        }
      }

      if (mounted) {
        setState(() {
          _faces = faces;
          // Cập nhật size ảnh từ camera
          _imageSize = Size(
            image.width.toDouble(),
            image.height.toDouble(),
          );
          // LOGIC HƯỚNG DẪN MỚI (DỄ HƠN)
          if (faces.isEmpty) {
            _guideMessage = "Không tìm thấy khuôn mặt";
            _guideColor = Colors.red;
            _faceStableCount = 0;
          } else {
            final face = faces.reduce((a, b) => 
                (a.boundingBox.width * a.boundingBox.height) > 
                (b.boundingBox.width * b.boundingBox.height) ? a : b);
            
            // Tính diện tích tương đối (đã xoay)
            // Image gốc 480x640. Face 200x200.
            final double faceArea = face.boundingBox.width * face.boundingBox.height;
            final double imageArea = image.width * image.height.toDouble();
            final double ratio = faceArea / imageArea;

            // Tính độ lệch tâm
            // InputImageRotation.rotation270deg đã xoay tọa độ face về hệ toạ độ chuẩn (0,0 ở góc trên trái khi dựng đứng)
            // Nên ta so sánh với tâm của ảnh đã xoay (tức là image.height x image.width)
            
            // Do sự phức tạp của việc xoay, ta dùng cách đơn giản hơn:
            // Chỉ cần mặt không quá nhỏ là được.
            
            if (ratio < 0.03) { // Giảm ngưỡng từ 0.05 xuống 0.03 (xa hơn vẫn nhận)
               _guideMessage = "Vui lòng lại gần hơn";
               _guideColor = Colors.orange;
               // _faceStableCount = 0; // Tạm bỏ reset để test dễ hơn
            } else {
               // BỎ CHECK CĂN GIỮA (CENTER) ĐỂ TRÁNH LỖI LỆCH TỌA ĐỘ
               // Chỉ cần mặt đủ to là chụp
               _guideMessage = "Giữ nguyên...";
               _guideColor = Colors.green;
               _faceStableCount++;
            }
          }
        });
      }

      if (_faceStableCount >= _stableThreshold && !_isSendingToServer) {
        debugPrint("[DEBUG] Khuôn mặt ổn định! Bắt đầu nhận dạng...");
        _faceStableCount = 0;
        await _captureAndRecognize();
      }
    } catch (e) {
      debugPrint("[ERROR] tiến trình frame thất bại: $e");
    } finally {
      _isProcessing = false;
    }
  }

  InputImage _convertToInputImage(CameraImage image) {
    final allBytes = _concatenatePlanes(image.planes);

    debugPrint("[DEBUG] Image size: ${image.width}x${image.height}, format: ${image.format.group}");

    InputImageRotation rotation = InputImageRotation.rotation0deg;
    
    if (_cameraController!.description.lensDirection == CameraLensDirection.front) {
      rotation = InputImageRotation.rotation270deg;
    } else {
      rotation = InputImageRotation.rotation90deg;
    }

    return InputImage.fromBytes(
      bytes: allBytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.yuv420,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    int totalSize = 0;
    for (final plane in planes) {
      totalSize += plane.bytes.length;
    }

    final bytes = Uint8List(totalSize);
    int offset = 0;

    for (final plane in planes) {
      bytes.setRange(offset, offset + plane.bytes.length, plane.bytes);
      offset += plane.bytes.length;
    }

    return bytes;
  }

  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth:  480,
        minHeight: 480,
        quality: 60,
      );
      
      debugPrint("[DEBUG] Compress: ${imageBytes.length} bytes → ${result.length} bytes (reduced ${((1 - result.length / imageBytes.length) * 100).toStringAsFixed(1)}%)");
      
      return result;
    } catch (e) {
      debugPrint("[ERROR] Quá trình nén ảnh thất bại: $e");
      return imageBytes;
    }
  }

  Future<void> _captureAndRecognize() async {
    if (_isSendingToServer) return;
    _isSendingToServer = true;
    
    Uint8List? compressedBytes;
    
    try {
      await _cameraController!.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 100));

      final file = await _cameraController!.takePicture();
      final imageBytes = await file.readAsBytes();

      compressedBytes = await _compressImage(imageBytes);
      final base64Img = base64Encode(compressedBytes);

      debugPrint("[DEBUG] Gửi ảnh: ${imageBytes.length} bytes → ${compressedBytes.length} bytes");

      if (mounted) {
        _showUserMessage("Đang nhận diện...", Colors.blue);
      }

      final response = await http
          .post(
            Uri.parse("$baseUrl/api/recognize"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"image_base64": base64Img}),
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint("[ERROR] Request timeout after 5s");
              throw TimeoutException('Request timeout');
            },
          );

      debugPrint("[DEBUG] Trạng thái phản hồi: ${response.statusCode}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          final Map<String, dynamic> faceData = data[0] as Map<String, dynamic>;

          if (faceData["status"] == "recognized") {
            final name = (faceData["name"] ?? "Unknown").toString();
            final userId = (faceData["user_id"] ?? "").toString();
            final role = (faceData["role"] ?? "").toString();

            debugPrint("[DEBUG] ✅ Nhận diện: $name ($userId)");

            // Kiểm tra cooldown
            if (_lastRecognizedUserId == userId &&
                _lastRecognitionTime != null &&
                DateTime.now().difference(_lastRecognitionTime!) < _recognitionCooldown) {
              _showUserMessage("Vui lòng đợi ${_recognitionCooldown.inSeconds} giây", Colors.orange);
              return;
            }

            _showUserMessage("Đang chấm công cho $name...", Colors.blue);
            
            //  Thử chấm công online trước
            final int result = await _chamCong(userId, role);

            if (result == 1) {
              _showUserMessage(" Chấm công vào thành công!\nXin chào $name", Colors.green);
              _lastRecognizedUserId = userId;
              _lastRecognitionTime = DateTime.now();
            } else if (result == 2){
              // ❌ Chấm công FAIL → LƯU CẢ ẢNH + TEXT OFFLINE
              debugPrint("[DEBUG] Server từ chối chấm công (Logic error). Không lưu offline.");

              _lastRecognizedUserId = userId;
              _lastRecognitionTime = DateTime.now();
            }
            else{
              debugPrint("[DEBUG] ⚠️ Mất kết nối, bắt đầu lưu offline...");
               // Lưu bản ghi offline với đầy đủ thông tin
              await _offlineService.saveOfflineImageAttendance(
                imageBytes: compressedBytes,
                userId: userId,
                role: role,
                shift: _xacDinhCa() ?? "UNKNOWN",
              );
              await _updatePendingCount();
              _showUserMessage(" Lưu offline thành công!\n$name sẽ được chấm công khi có mạng", Colors.orange);
            }
          } else {
            _showUserMessage(" Không nhận diện được khuôn mặt", Colors.red);
          }
        } else {
          _showUserMessage(" Không tìm thấy khuôn mặt trong ảnh", Colors.orange);
        }
      } else {
        debugPrint("[ERROR] Server error: ${response.statusCode}");
        _showUserMessage("❌ Lỗi kết nối. Vui lòng thử lại.", Colors.red);
      }

    } catch (e) {
      debugPrint("[ERROR] ❌ Recognition failed: $e");
      
      // → LƯU ẢNH OFFLINE ĐỂ NHẬN DIỆN + CHẤM CÔNG SAU
      if (e is TimeoutException || 
          e is SocketException || 
          e.toString().contains('SocketException') || 
          e.toString().contains('ClientException') ||
          e.toString().contains('Connection') ||
          e.toString().contains('Failed host lookup')) {
        
        debugPrint("[DEBUG] ⚠️ Mất kết nối mạng, lưu ảnh offline");

        if (_lastOfflineSaveTime != null) {
          final difference = DateTime.now().difference(_lastOfflineSaveTime!);
          if (difference < _offlineSaveCooldown) {
            debugPrint("[OFFLINE] ⏳ Đang chờ 30s (còn lại ${30 - difference.inSeconds}s), bỏ qua lưu.");
            
            // Thông báo nhẹ để người dùng biết
            if (mounted) {
               _showUserMessage(" Vui lòng đợi ${30 - difference.inSeconds}s để quét tiếp", Colors.orange);
            }
            return; 
          }
        }
       try {
          // Lưu ảnh đã chụp
          if (compressedBytes != null) {
            await _offlineService.saveOfflineImageOnly(
              imageBytes: compressedBytes,
              shift: _xacDinhCa() ?? "UNKNOWN",
            );
            await _updatePendingCount();
            _lastOfflineSaveTime = DateTime.now();
            // ✅ THÔNG BÁO THÂN THIỆN CHO OFFLINE
            if (mounted) {
              _showUserMessage(
                "📵 Mất mạng! Đã lưu dữ liệu.\n Sẽ tự động cập nhật khi có kết nối.", 
                Colors.orange
              );
            }
          }
        } catch (saveError) {
          debugPrint("[ERROR] lỗi khi lưu offline: $saveError");
          if (mounted) {
            _showUserMessage(" Lỗi lưu dữ liệu offline", Colors.red);
          }
        }
      } else {
        // Lỗi khác (không phải lỗi mạng)
        if (mounted) {
          _showUserMessage(" Lỗi hệ thống. Vui lòng thử lại.", Colors.red);
        }
      }

    } finally {
      _isSendingToServer = false;

      await Future.delayed(const Duration(milliseconds: 200));
      if (_cameraController != null &&
          _cameraController!.value.isInitialized &&
          mounted) {
        _cameraController!.startImageStream(_processFrame);
      }
    }
}

  Future<int> _chamCong(String userId, String role) async {
  String? caHienTai = _xacDinhCa();
  try {
    final body = {
      "userId": userId, 
      "DiaDiemChamCong": "Văn phòng",
    };
    if (caHienTai != null) {
      body["MaCa"] = caHienTai;
    }

    if (role == "NhanVien") {
      body["MaNV"] = userId;
    } else if (role == "QuanLy") {
      body["MaQL"] = userId;
    } else {
      body["MaNV"] = userId;
    }

    debugPrint("[DEBUG] 🌐 Đang gửi yêu cầu chấm công cho $userId");

    final response = await http
        .post(
          Uri.parse("$baseUrl/api/chamcong"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final action = data['action'] ?? '';
      final message = data['message'] ?? 'Chấm công thành công';
      
      debugPrint("[DEBUG] ✅ Chấm công online thành công: $action");
      
      // Hiển thị message tùy theo action
      if (action == 'Chấm công vào') {
        _showUserMessage("✅ $message\nXin chào $userId", Colors.green);
      } else if (action == 'Chấm công ra') {
        _showUserMessage("👋 $message\nTạm biệt $userId", Colors.blue);
      } else {
        _showUserMessage("✅ $message", Colors.green);
      }
      
      return 1;
    } else {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      final action = errorData['action'] ?? '';
      String errorMsg = errorData['message'] ?? errorData['error'] ?? "Lỗi không xác định";
      
      debugPrint("[ERROR] ❌ Chấm công thất bại: $errorMsg (action: $action)");
      
      // Xử lý các trường hợp lỗi cụ thể
      if (action == 'Chấm RA quá sớm') {
        _showUserMessage("⏰ $errorMsg", Colors.orange);
      } else if (action == 'Đã chấm đủ ca') {
        _showUserMessage(" $errorMsg", Colors.blue);
      } else if (response.statusCode == 400) {
        _showUserMessage("⚠️ $errorMsg", Colors.orange);
      } else {
        _showUserMessage("❌ $errorMsg", Colors.red);
      }
      
      return 2; 
    }
  } on SocketException catch (e) {
    debugPrint("[ERROR] ⚠️ Lỗi kết nối mạng: $e");
    return 0;
  } on TimeoutException catch (e) {
    debugPrint("[ERROR] ⚠️ Timeout khi chấm công: $e");
    return 0;
  } catch (e) {
    debugPrint("[ERROR] ⚠️ Lỗi không xác định: $e");
    return 0;
  }
}


  String? _xacDinhCa() {
    final now = TimeOfDay.now();
    final totalMinutes = now.hour * 60 + now.minute;

    // 1. Ca Sáng: 08:00 (480) -> 12:00 (720)
    if (totalMinutes >= 480 && totalMinutes <= 720) {
      return "CA001";
    } 
    
    // 2. Ca Chiều: 13:30 (810) -> 17:00 (1020)
    else if (totalMinutes >= 810 && totalMinutes <= 1020) {
      return "CA002";
    }
    
    // 3. Ca Tối (Qua đêm): Từ 18:00 (1080) đến nửa đêm (1439) 
    //                     HOẶC Từ sáng sớm (0) đến 07:30 (450)
    else if (totalMinutes >= 1080 || totalMinutes <= 450) {
      return "CA003";
    }
    
    // 4. Các giờ nghỉ (Trưa, Giao ca chiều-tối, Giao ca sáng) -> Trả về null
    return null; 
  }

  void _showUserMessage(String msg, Color color) {
    if (!mounted) return;

    setState(() => _userMessage = msg);

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _userMessage = null);
      }
    });
  }

  @override
  void dispose() {
    _faceDetector.close();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraReady) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                "Đang khởi động camera...",
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chấm công tự động"),
        backgroundColor: Colors.blue,
        actions: [
          if (_pendingCount > 0)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                avatar: const Icon(Icons.cloud_off, size: 16, color: Colors.white),
                label: Text('$_pendingCount chưa Đồng bộ', style: const TextStyle(fontSize: 11, color: Colors.white)),
                backgroundColor: Colors.orange,
              ),
            ),
          
          if (_lastRecognizedUserId != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                avatar: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                label: Text(
                  _lastRecognizedUserId!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),
          // Face Bounding Boxes
          if (_faces.isNotEmpty && _imageSize != null)
           Positioned.fill(
              child: CustomPaint(
                painter: FacePainter(
                  faces: _faces,
                  imageSize: _imageSize!,
                  widgetSize: size,
                  cameraLensDirection: _cameraController!.description.lensDirection,
                  borderColor: _guideColor, 
                ),
              ),
            ),
            if (_guideMessage != null)
              Positioned(
                top: 50, // Cách đỉnh màn hình
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _guideMessage!,
                      style: TextStyle(
                        color: _guideColor, // Màu chữ đổi theo trạng thái (Đỏ/Cam/Xanh)
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          // Status Indicator
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _faces.isEmpty
                          ? "Vui lòng đưa mặt vào khung hình"
                          : "Đang xác định khuôn mặt...",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_lastRecognitionTime != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "Chấm công lúc: ${_lastRecognitionTime!.hour}:${_lastRecognitionTime!.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (_isSendingToServer)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "Đang xử lý...",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),

          // User Message
          if (_userMessage != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getMessageColor(_userMessage!),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _userMessage!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getMessageColor(String message) {
    if (message.contains("thành công") || message.contains("Xin chào")) {
      return Colors.green;
    } else if (message.contains("Tăng Ca")) {
      return Colors.purple; // Màu riêng cho tăng ca
    } else if (message.contains("thất bại") || message.contains("Lỗi")) {
      return Colors.red;
    } else if (message.contains("Đang")) {
      return Colors.blue;
    } else {
      return Colors.orange; // Màu cho cảnh báo (nghỉ trưa, ngoài giờ)
    }
  }
}
// === CLASS VẼ KHUNG ===
class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final Size widgetSize;
  final CameraLensDirection cameraLensDirection;
  final Color borderColor; 

  FacePainter({
    required this.faces,
    required this.imageSize,
    required this.widgetSize,
    required this.cameraLensDirection,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (faces.isEmpty) return;

    // 1. Lấy khuôn mặt lớn nhất
    final Face face = faces.reduce((curr, next) =>
        (curr.boundingBox.width * curr.boundingBox.height) >
                (next.boundingBox.width * next.boundingBox.height)
            ? curr
            : next);

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = borderColor; 

    // 2. TÍNH TOÁN TỶ LỆ SCALE (QUAN TRỌNG)
    // Camera Image (imageSize) thường là 640x480 (ngang)
    // Màn hình (widgetSize) là dọc (ví dụ 360x700)
    // ML Kit đã xoay tọa độ Face theo rotation ta cài đặt, nên ta so sánh chiều rộng với chiều rộng
    
    // Tuy nhiên, để vẽ đè lên CameraPreview (BoxFit.cover), ta cần tính scale dựa trên chiều nào bị zoom nhiều hơn
    // Giả sử ảnh gốc xoay 90 độ để thành dọc:
    double rotatedImageWidth = imageSize.height;
    double rotatedImageHeight = imageSize.width;

    // ignore: deprecated_member_use
    if (ui.window.devicePixelRatio > 0) {
       // Đôi khi cần fix tỉ lệ pixel, nhưng thường logic dưới là đủ
    }

    double scaleX = widgetSize.width / rotatedImageWidth;
    double scaleY = widgetSize.height / rotatedImageHeight;
    
    // Chọn scale lớn hơn để cover toàn màn hình
    double scale = scaleX > scaleY ? scaleX : scaleY;

    // Tính phần thừa bị cắt đi (offset) để căn giữa
    double offsetX = (widgetSize.width - rotatedImageWidth * scale) / 2;
    double offsetY = (widgetSize.height - rotatedImageHeight * scale) / 2;

    final rect = face.boundingBox;

    // 3. CHUYỂN ĐỔI TỌA ĐỘ
    // Lưu ý: rect từ ML Kit đã được xoay nếu ta set rotation đúng trong InputImage
    // Ta chỉ cần scale và translate
    
    double left = rect.left * scale + offsetX;
    double top = rect.top * scale + offsetY;
    double right = rect.right * scale + offsetX;
    double bottom = rect.bottom * scale + offsetY;
    double faceHeight = bottom - top;
    top -= faceHeight * 0.25;
    bottom += faceHeight * 0.075;

    // Xử lý Mirror (Lật ngược) cho camera trước
    if (cameraLensDirection == CameraLensDirection.front) {
      double centerX = widgetSize.width / 2;
      left = centerX + (centerX - left);
      right = centerX + (centerX - right);
      // Sau khi lật, left > right nên cần swap
      double temp = left; left = right; right = temp;
    }

    final Rect uiRect = Rect.fromLTRB(left, top, right, bottom);

    // Vẽ 4 góc
    _drawCorners(canvas, uiRect, paint);
    
    // Vẽ khung mờ bao quanh (Option)
    canvas.drawRect(
      uiRect, 
      // ignore: deprecated_member_use
      Paint()..style = PaintingStyle.stroke ..strokeWidth = 1 ..color = borderColor.withOpacity(0.3)
    );
  }

  void _drawCorners(Canvas canvas, Rect rect, Paint paint) {
    double len = 50.0; // Độ dài góc dài hơn chút cho đẹp
    // Góc trên trái
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(len, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, len), paint);
    // Góc trên phải
    canvas.drawLine(rect.topRight, rect.topRight - Offset(len, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, len), paint);
    // Góc dưới trái
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(len, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft - Offset(0, len), paint);
    // Góc dưới phải
    canvas.drawLine(rect.bottomRight, rect.bottomRight - Offset(len, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight - Offset(0, len), paint);
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) => true;
}
