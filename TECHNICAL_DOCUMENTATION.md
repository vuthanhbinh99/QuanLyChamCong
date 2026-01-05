# 📚 Tài Liệu Hệ Thống Quản Lý Chấm Công

## 📖 Mục Lục

1. [Tổng Quan Hệ Thống](#tổng-quan-hệ-thống)
2. [Cấu Trúc Dự Án](#cấu-trúc-dự-án)
3. [Kiến Trúc Ứng Dụng](#kiến-trúc-ứng-dụng)
4. [Hướng Dẫn Sử Dụng](#hướng-dẫn-sử-dụng)
5. [Hướng Dẫn Phát Triển](#hướng-dẫn-phát-triển)

---

## 🎯 Tổng Quan Hệ Thống

### Mục Đích
Ứng dụng quản lý chấm công nhân viên với tính năng nhận diện khuôn mặt, quản lý đơn xin, và báo cáo chi tiết.

### Các Tính Năng Chính
- ✅ Chấm công bằng khuôn mặt
- ✅ Quản lý nhân viên và phòng ban
- ✅ Duyệt đơn xin nghỉ
- ✅ Báo cáo chấm công
- ✅ Quản lý tài khoản & quyền hạn
- ✅ Hệ thống logs & kiểm tra

### Công Nghệ Sử Dụng
- **Frontend**: Flutter (Dart)
- **Backend**: Python (Flask)
- **Database**: SQL Server
- **Face Recognition**: OpenCV, TensorFlow
- **Deployment**: Docker (tùy chọn)

---

## 📁 Cấu Trúc Dự Án

### Backend (Python/Flask)

```
back-end/
├── admin.py                 # File quản trị
├── api.py                   # Entry point Flask
├── database.py              # Kết nối database
├── requirements.txt         # Dependencies Python
│
├── Api/                     # REST API endpoints
│   ├── auth.py             # Đăng nhập/xác thực
│   ├── quanly.py           # API quản lý
│   ├── nhanvien.py         # API nhân viên
│   ├── chamcong.py         # API chấm công
│   ├── donxin.py           # API đơn xin nghỉ
│   ├── baocao.py           # API báo cáo
│   ├── face.py             # API nhận diện khuôn mặt
│   ├── calam.py            # API ca làm việc
│   └── generate_id.py      # Tạo ID tự động
│
├── model/                  # Database models
│   ├── TaiKhoan.py        # Tài khoản đăng nhập
│   ├── NhanVien.py        # Nhân viên
│   ├── QuanLy.py          # Quản lý
│   ├── QuanTriVien.py     # Quản trị viên
│   ├── ChamCong.py        # Chấm công
│   ├── DonXin.py          # Đơn xin nghỉ
│   ├── CaLam.py           # Ca làm việc
│   ├── BaoCao.py          # Báo cáo
│   ├── PhongBan.py        # Phòng ban
│   ├── LuuTruKhuonMat.py  # Lưu trữ khuôn mặt
│   └── __init__.py
│
├── recognize/             # Face recognition module
│   ├── recognize_face.py  # Nhận diện khuôn mặt
│   ├── register_face.py   # Đăng ký khuôn mặt
│   
│
├── Services/              # Business logic
│   ├── face_services.py   # Face processing
│   └── generate_id.py     # ID generation
│
└── templates/             # HTML templates
    └── admin/
        └── dashboard.html
```

### Frontend (Flutter/Dart)

```
front-end/
├── lib/
│   ├── main.dart                      # Entry point
│   ├── controllers/
│   │   ├── auth_controller.dart      # Quản lý auth
│   │   └── ...
│   │
│   ├── models/
│   │   ├── user.dart
│   │   ├── chamcong.dart
│   │   ├── donxin.dart
│   │   └── ...
│   │
│   ├── services/
│   │   ├── api_service.dart          # API calls
│   │   └── ...
│   │
│   └── views/
│       ├── login_view.dart
│       ├── user_guide_view.dart      # 🆕 Hướng dẫn
│       │
│       ├── nhanvien/
│       │   ├── home_nhanvien_view.dart
│       │   ├── lich_su_cham_cong.dart
│       │   ├── gui_don_xin_nghi.dart
│       │   ├── danh_sach_don_xin.dart
│       │   └── ...
│       │
│       ├── quanly/
│       │   ├── home_quanly_view.dart
│       │   ├── danh_sach_nhan_vien_view.dart
│       │   ├── them_nhan_vien_view.dart
│       │   ├── quanly_don_xin.dart
│       │   ├── cham_cong_nhan_vien.dart
│       │   ├── bao_cao_view.dart
│       │   └── ...
│       
│       
│
├── pubspec.yaml                       # Dependencies Dart
└── ...
```

---

## 🏗️ Kiến Trúc Ứng Dụng

### 1. Mô Hình MVC (Backend)

```
Request → API Controller → Service/Model → Database
                   ↓
                Response (JSON)
```

### 2. Quy Trình Xác Thực (Auth Flow)

```
┌─────────────────┐
│  LoginView      │
└────────┬────────┘
         │ Input: username, password
         ↓
┌─────────────────────────────┐
│  AuthController             │
│  - Gọi API login()          │
└────────┬────────────────────┘
         │
         ↓
┌─────────────────────────────┐
│  Backend: /login            │
│  - Kiểm tra username/pwd    │
│  - Lấy role từ TaiKhoan     │
│  - Trả về token + user info │
└────────┬────────────────────┘
         │
         ↓
┌─────────────────────────────┐
│  _buildHomeByRole()         │
│  - NhanVien → HomeNhanVien  │
│  - QuanLy → HomeQuanLy      │
│  - QuanTriVien → HomeQTV    │
└─────────────────────────────┘
```

### 3. Luồng Chấm Công

```
┌──────────────────────┐
│  Nhân viên nhấn      │
│  "CHẤM CÔNG"         │
└──────────┬───────────┘
           │
           ↓
┌──────────────────────────────────┐
│  Camera mở                       │
│  - Quét khuôn mặt                │
│  - So sánh với database          │
└──────────┬───────────────────────┘
           │ Nhận diện thành công
           ↓
┌──────────────────────────────────┐
│  Tạo record ChamCong            │
│  - user_id                       │
│  - thời gian                     │
│  - ca làm việc                   │
└──────────┬───────────────────────┘
           │
           ↓
┌──────────────────────────────────┐
│  Lưu vào Database               │
│  - TrangThai = "Vào"/"Ra"       │
└──────────────────────────────────┘
```

### 4. Phân Quyền (Authorization)

```
┌──────────────────────────────────────────────┐
│              QUẢN TRỊ VIÊN (Admin)           │
│  - Toàn quyền tất cả chức năng               │
│  - Quản lý nhân viên, tài khoản, phòng ban   │
└──────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│          QUẢN LÝ (Manager)                   │
│  - Quản lý nhân viên phòng ban của mình      │
│  - Duyệt đơn xin nghỉ                        │
│  - Xem báo cáo phòng ban                     │
└──────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│       NHÂN VIÊN (Employee)                   │
│  - Chấm công                                 │
│  - Xem lịch sử chấm công                     │
│  - Gửi đơn xin nghỉ                          │
│  - Quản lý khuôn mặt                         │
└──────────────────────────────────────────────┘
```

---

## 👥 Hướng Dẫn Sử Dụng

### Mở Hướng Dẫn Trong App

Tất cả 3 role có thể mở hướng dẫn bằng cách:

1. **Nhân Viên**: Menu → Hướng Dẫn Sử Dụng
2. **Quản Lý**: Menu → Hướng Dẫn Sử Dụng
3. **Quản Trị Viên**: Menu → Hướng Dẫn Sử Dụng

### Xem Hướng Dẫn Bằng File Markdown

Chi tiết xem file: **HUONG_DAN_SU_DUNG.md**

---

## 🛠️ Hướng Dẫn Phát Triển

### Cài Đặt Backend

```bash
# 1. Di chuyển vào thư mục backend
cd back-end

# 2. Tạo virtual environment
python -m venv venv

# 3. Kích hoạt virtual environment
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# 4. Cài đặt dependencies
pip install -r requirements.txt

# 5. Cấu hình database (trong database.py)
# Chỉnh sửa connection string SQL Server

# 6. Chạy server
python api.py
```

### Cài Đặt Frontend

```bash
# 1. Di chuyển vào thư mục frontend
cd front-end

# 2. Lấy dependencies
flutter pub get

# 3. Chạy ứng dụng
flutter run

# 4. Build APK (Android)
flutter build apk

# 5. Build iOS
flutter build ios
```

### Cấu Hình API Endpoint

**File**: `lib/services/api_service.dart`

```dart
class ApiService {
  final String baseUrl = 'http://YOUR_SERVER_IP:5000';
  
  // Các endpoint API
  final String loginEndpoint = '$baseUrl/login';
  final String chamCongEndpoint = '$baseUrl/cham-cong';
  // ...
}
```

### Tạo Migration Database

```python
# Tạo bảng mới
from database import Base, engine
from model import YourModel  # Import model mới

# Tạo các bảng
Base.metadata.create_all(bind=engine)
```

### Thêm API Endpoint Mới

**File**: `Api/your_api.py`

```python
from flask import Blueprint, jsonify, request
from database import SessionLocal
from model import YourModel

your_bp = Blueprint('your', __name__)

@your_bp.route('/your-endpoint', methods=['GET'])
def your_function():
    session = SessionLocal()
    try:
        # Logic của bạn
        data = session.query(YourModel).all()
        return jsonify({'success': True, 'data': data}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        session.close()
```

Sau đó đăng ký blueprint trong `api.py`:

```python
from Api.your_api import your_bp
app.register_blueprint(your_bp)
```

### Thêm UI View Mới (Flutter)

**File**: `lib/views/your_view.dart`

```dart
import 'package:flutter/material.dart';

class YourView extends StatefulWidget {
  const YourView({super.key});

  @override
  State<YourView> createState() => _YourViewState();
}

class _YourViewState extends State<YourView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Title')),
      body: const Center(child: Text('Your Content')),
    );
  }
}
```

---

## 📊 Database Schema

### Bảng Chính

#### TaiKhoan
```sql
MaTK (PK) | TenDangNhap | MatKhau | VaiTro | MaNV | MaQL | MaQTV | TrangThai | NgayTao
```

#### NhanVien
```sql
MaNV (PK) | HoTenNV | Email | SoDienThoai | MaPB | ChucVu | NgayBatDauLam | GioiTinh | TrangThai
```

#### QuanLy
```sql
MaQL (PK) | HoTenQL | Email | SoDienThoai | MaPB | GioiTinh | TrangThai
```

#### QuanTriVien
```sql
MaQTV (PK) | HoTenQTV | Email | SoDienThoai
```

#### ChamCong
```sql
MaCC (PK) | MaNV | NgayChamCong | GioVao | GioRa | MaCa | TrangThai
```

#### DonXin
```sql
MaDon (PK) | MaNV | LoaiDon | NgayBatDau | NgayKetThuc | TrangThai | LyDo | MaQL | NgayDuyet
```

#### PhongBan
```sql
MaPB (PK) | TenPB | MoTa | TrangThai
```

#### CaLam
```sql
MaCa (PK) | TenCa | GioBatDau | GioKetThuc
```

---

## 🔐 Bảo Mật

### Best Practices

1. **Mật khẩu**:
   - Mã hóa trước khi lưu
   - Tối thiểu 8 ký tự
   - Chứa chữ hoa, chữ thường, số, ký tự đặc biệt

2. **API**:
   - Sử dụng HTTPS
   - Implement JWT tokens
   - Validate input đầu vào
   - Rate limiting

3. **Database**:
   - Backup định kỳ
   - Encrypted passwords
   - Giới hạn quyền truy cập

4. **Frontend**:
   - Không lưu password trong local storage
   - Xóa sensitive data khi logout
   - Validate dữ liệu trước gửi

---

## 📝 Quy Ước Code

### Backend (Python)
```python
# Tên hàm: snake_case
def get_employee_by_id(employee_id):
    pass

# Tên biến: snake_case
max_attempts = 3

# Tên class: PascalCase
class EmployeeService:
    pass
```

### Frontend (Dart)
```dart
// Tên class: PascalCase
class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

// Tên hàm & biến: camelCase
void loadUserData() { }
int totalEmployees = 0;

// Widget mềm: _leading_uppercase
Widget _buildDrawer() { }
```

---

## 🐛 Debug & Troubleshooting

### Backend Issues

**Lỗi Database Connection**
```
Error: pyodbc.InterfaceError
Giải pháp: Kiểm tra connection string, cài ODBC driver
```

**Lỗi Import Module**
```
Error: ModuleNotFoundError: No module named 'model'
Giải pháp: Cài pip install -r requirements.txt
```

### Frontend Issues

**Lỗi API Connection**
```
Error: Connection refused
Giải pháp: Kiểm tra IP server, port 5000 đang chạy
```

**Lỗi Face Recognition**
```
Error: No face detected
Giải pháp: Kiểm tra camera, ánh sáng, chất lượng ảnh
```

---

## 📚 Tài Liệu Tham Khảo

- [Flutter Documentation](https://flutter.dev/docs)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [SQLAlchemy ORM](https://docs.sqlalchemy.org/)
- [OpenCV Face Detection](https://docs.opencv.org/master/d0/daX/tutorial_traincascade.html)

---

## 📞 Liên Hệ & Hỗ Trợ

- **Email**: support@quanlychamcong.vn
- **Phone**: 1900-1234
- **Chat**: help.quanlychamcong.vn
- **Issues**: GitHub Issues

---

**Document Version**: 1.0  
**Last Updated**: 2025-01-05  
**Author**: Development Team


