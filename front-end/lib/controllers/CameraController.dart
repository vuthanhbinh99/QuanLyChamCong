import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';

class RegisterCamera extends StatefulWidget {
  final String id_user;
  final bool autoCapture;
  const RegisterCamera({super.key, required this.id_user, this.autoCapture = true});

  @override
  State<RegisterCamera> createState() => _RegisterCameraState();
}

class _RegisterCameraState extends State<RegisterCamera> {
  CameraController? cameraController;
  bool isCameraInitialized = false;
  List<String> imageBase64 = [];
  int currentStep = 0;
  bool isProcessing = false;
  List<Face> detectedFaces = [];
  int _frameCounter = 0;

  final ApiService apiService = ApiService();

  final List<String> stepsText = [
    "Nhìn chính diện",
    "Quay mặt sang trái",
    "Quay mặt sang phải",
  ];

  final faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  // Tính ổn định
  List faceCenters = [];
  final int stableThreshold = 5;
  final double threshold = 5.0;

  @override
  void initState() {
    super.initState();
    requestPermissionAndInitialize();
  }

  Future<void> requestPermissionAndInitialize() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cần cấp quyền camera để sử dụng chức năng này')),
          );
        }
        return;
      }
    }
    await initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('Không tìm thấy camera');
      final frontCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first);

      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.nv21 
            : ImageFormatGroup.bgra8888,
      );

      await cameraController!.initialize();
      if (!mounted) return;
      setState(() => isCameraInitialized = true);

      Future.delayed(const Duration(milliseconds: 500), () async {
        await cameraController!.startImageStream(processCameraImage);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể khởi động camera: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    int totalSize = 0;
    for (final plane in planes) {
      totalSize += plane.bytes.length;
    }
    final allBytes = Uint8List(totalSize);
    int offset = 0;
    for (final plane in planes) {
      allBytes.setRange(offset, offset + plane.bytes.length, plane.bytes);
      offset += plane.bytes.length;
    }
    return allBytes;
  }

  Future<void> processCameraImage(CameraImage image) async {
    _frameCounter++;
    if (_frameCounter % 3 != 0) return;
    if (!widget.autoCapture ||
        currentStep >= stepsText.length ||
        isProcessing ||
        !mounted) {
      return;
    }

    try {
      final bytes = await _concatenatePlanes(image.planes);
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: InputImageFormat.yuv420,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;

        final center = Offset(
          face.boundingBox.left + face.boundingBox.width / 2,
          face.boundingBox.top + face.boundingBox.height / 2,
        );

        faceCenters.add(center);
        if (faceCenters.length > stableThreshold) faceCenters.removeAt(0);

        if (isStable() && !isProcessing) {
          isProcessing = true;
          await captureImage();
        }
      }
    } catch (e) {
      print("Lỗi MLKit: $e");
    }
  }

  bool isStable() {
    if (faceCenters.length < stableThreshold) return false;
    final dx = faceCenters.map((e) => e.dx).reduce((a, b) => a > b ? a : b) -
        faceCenters.map((e) => e.dx).reduce((a, b) => a < b ? a : b);
    final dy = faceCenters.map((e) => e.dy).reduce((a, b) => a > b ? a : b) -
        faceCenters.map((e) => e.dy).reduce((a, b) => a < b ? a : b);
    return dx < threshold && dy < threshold;
  }

  Future<void> captureImage() async {
    if (!mounted || cameraController == null) {
      isProcessing = false;
      return;
    }

    try {
      final XFile file = await cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);

      setState(() {
        imageBase64.add(b64);
      });

      // Đợi 2–3 giây rồi mới chuyển pose
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        currentStep++;
      });

      faceCenters.clear();

      if (currentStep >= stepsText.length) {
        await cameraController?.stopImageStream();
        await sendToServer();
      }
    } catch (e) {
      print("Lỗi chụp ảnh: $e");
    } finally {
      isProcessing = false;
    }
  }

  Future<void> sendToServer() async {
    try {
      // Hiển thị loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      bool success = await apiService.registerFace(
        idUser: widget.id_user,
        imagesBase64: imageBase64,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Đóng loading dialog

      // ✅ Hiển thị dialog kết quả với nút OK để quay về
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.red,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(success ? "Thành công" : "Lỗi"),
            ],
          ),
          content: Text(
            success
                ? "Đăng ký khuôn mặt thành công!\nBạn có thể sử dụng tính năng nhận diện khuôn mặt."
                : "Đăng ký thất bại. Vui lòng thử lại.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
                // ✅ Quay về màn hình trước (DangKyGuongMatView) và trả về true
                Navigator.of(context).pop(success);
              },
              child: const Text(
                "OK",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      // Nếu thất bại, reset để người dùng có thể thử lại
      if (!success && mounted) {
        setState(() {
          imageBase64.clear();
          currentStep = 0;
        });
      }
    } catch (e) {
      print("Lỗi gửi server: $e");
      if (!mounted) return;
      Navigator.of(context).pop(); // Đóng loading
      
      // Hiển thị dialog lỗi
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 32),
              SizedBox(width: 12),
              Text("Lỗi kết nối"),
            ],
          ),
          content: Text("Không thể kết nối đến server.\nLỗi: $e"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(false); // Quay về với kết quả thất bại
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );

      setState(() {
        imageBase64.clear();
        currentStep = 0;
      });
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraInitialized || cameraController == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Đăng ký khuôn mặt")),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký khuôn mặt")),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                CameraPreview(cameraController!),
                
                // Hiện text tư thế
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currentStep < stepsText.length
                          ? 'Tư thế: ${stepsText[currentStep]}'
                          : 'Đang gửi dữ liệu...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Overlay khi đang xử lý
                if (isProcessing)
                  Container(
                    color: Colors.black38,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Đang xử lý...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Progress bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: currentStep / stepsText.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 8),
                Text('$currentStep/${stepsText.length} ảnh đã chụp'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FaceDetectionCamera extends StatefulWidget {
  const FaceDetectionCamera({super.key});

  @override
  State<FaceDetectionCamera> createState() => _FaceDetectionCameraState();
}

class _FaceDetectionCameraState extends State<FaceDetectionCamera> {
  CameraController? _cameraController;
  late FaceDetector _faceDetector;

  bool _isBusy = false;
  List<Face> _faces = [];
  Size? _inputImageSize;

  @override
  void initState() {
    super.initState();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableContours: false,
      ),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    final front = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
    );

    _cameraController = CameraController(
      front,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    await _cameraController!.startImageStream(_processImage);

    setState(() {});
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isBusy) return;
    _isBusy = true;

    try {
      final InputImage inputImage = _convertToInputImage(image);

      final faces = await _faceDetector.processImage(inputImage);

      setState(() {
        _faces = faces;
        _inputImageSize = Size(
          image.width.toDouble(),
          image.height.toDouble(),
        );
      });
    } catch (e) {
      debugPrint("ERROR detecting face: $e");
    }

    _isBusy = false;
  }

  InputImage _convertToInputImage(CameraImage image) {
    final WriteBuffer buffer = WriteBuffer();

    for (final plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }

    final Uint8List bytes = buffer.done().buffer.asUint8List();

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: InputImageRotation.rotation270deg,
      format: InputImageFormat.yuv420,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text("Face Detection")),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          if (_faces.isNotEmpty && _inputImageSize != null)
            CustomPaint(
              painter: FacePainter(
                faces: _faces,
                imageSize: _inputImageSize!,
                screenSize: screenSize,
              ),
            ),
        ],
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final Size screenSize;

  FacePainter({
    required this.faces,
    required this.imageSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final double scaleX = screenSize.width / imageSize.height;
    final double scaleY = screenSize.height / imageSize.width;

    for (var face in faces) {
      final rect = Rect.fromLTRB(
        screenSize.width - (face.boundingBox.bottom * scaleX),
        face.boundingBox.left * scaleY,
        screenSize.width - (face.boundingBox.top * scaleX),
        face.boundingBox.right * scaleY,
      );

      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FacePainter oldDelegate) =>
      oldDelegate.faces != faces;
}