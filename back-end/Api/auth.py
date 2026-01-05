from flask import Blueprint, jsonify, request
from database import SessionLocal
from model import TaiKhoan, NhanVien, QuanLy, QuanTriVien, PhongBan
from datetime import datetime
from Services.face_services import(init_face_app)
auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/login', methods=['POST'])
def login():
    session = SessionLocal()
    data = request.json
    username = data.get('username')
    password = data.get('password')

    try:
        user = session.query(TaiKhoan).filter(TaiKhoan.TenDangNhap == username).first()
        if not user:
            print("❌ User not found")
            return jsonify({
                "success": False,
                "error": "Tài khoản nhân viên chưa được đăng ký trong hệ thống chấm công."
            }), 400

        if password != user.MatKhau:
            print("❌ Wrong password")
            return jsonify({
                    "success": False,
                    "error": "Mật khẩu không chính xác. Vui lòng kiểm tra lại."
                }), 401

        role = user.VaiTro
        id_user = None
        
        print(f"👤 User found: role='{role}', MaNV='{user.MaNV}', MaQL='{user.MaQL}', MaQTV='{user.MaQTV}'")

        # CHUẨN HÓA ROLE - So sánh không phân biệt hoa thường
        role_lower = role.lower() if role else ""
        
        if 'nhanvien' in role_lower or 'nhân viên' in role_lower:
            id_user = user.MaNV
            role_type = 'NhanVien'
        elif 'quanly' in role_lower or 'quản lý' in role_lower:
            id_user = user.MaQL
            role_type = 'QuanLy'
        elif 'quantrivien' in role_lower or 'quản trị viên' in role_lower:
            id_user = user.MaQTV
            role_type = 'QuanTriVien'
        else:
            # Fallback: thử lấy ID từ bất kỳ trường nào có giá trị
            if user.MaNV:
                id_user = user.MaNV
                role_type = 'NhanVien'
            elif user.MaQL:
                id_user = user.MaQL
                role_type = 'QuanLy'
            elif user.MaQTV:
                id_user = user.MaQTV
                role_type = 'QuanTriVien'

        print(f"🆔 User ID determined: {id_user}, Role type: {role_type}")

        if id_user is None:
            return jsonify({
                 "error": "Tài khoản chưa được phân quyền chấm công hoặc quản lý."
             }), 400
        # Lấy thông tin chi tiết
        user_info = {}
        if role_type == 'NhanVien':
            nv_result = session.query(NhanVien, PhongBan.TenPB).outerjoin(
                PhongBan, NhanVien.MaPB == PhongBan.MaPB
            ).filter(NhanVien.MaNV == id_user).first()
            if nv_result:
                nv_info, ten_phong_ban = nv_result
                user_info = {
                    "ho_ten": nv_info.HoTenNV or "",
                    "email": nv_info.Email or "",
                    "phong_ban": nv_info.MaPB or "",
                    "ten_phong_ban": ten_phong_ban or "",  # Thêm tên phòng ban
                    "so_dien_thoai": nv_info.SoDienThoai or "",
                    "chuc_vu": nv_info.ChucVu or "",
                    "gioi_tinh": nv_info.GioiTinh or ""
                }
        elif role_type == 'QuanLy':
            ql_result = session.query(QuanLy, PhongBan.TenPB).outerjoin(
                PhongBan, QuanLy.MaPB == PhongBan.MaPB
            ).filter(QuanLy.MaQL == id_user).first()
            if ql_result:
                ql_info, ten_phong_ban = ql_result
                user_info = {
                    "ho_ten": ql_info.HoTenQL or "",
                    "email": ql_info.Email or "",
                    "phong_ban": ql_info.MaPB or "",
                    "ten_phong_ban": ten_phong_ban or "",  # Thêm tên phòng ban
                    "so_dien_thoai": ql_info.SoDienThoai or "",
                    "gioi_tinh": ql_info.GioiTinh or ""
                }
        elif role_type == 'QuanTriVien':
            qtv_info = session.query(QuanTriVien).filter(QuanTriVien.MaQTV == id_user).first()
            if qtv_info:
                user_info = {
                    "ho_ten": qtv_info.HoTenQTV or "",
                    "email": qtv_info.Email or "",
                    "so_dien_thoai": qtv_info.SoDienThoai or ""
                }

        response_data = {
            "success": True,
            "message": "Đăng nhập thành công",
            "role": role_type,  # Sử dụng role đã chuẩn hóa
            "id": id_user,
            "user_info": user_info
        }

        print(f"✅ Login successful: {response_data}")
        return jsonify(response_data)

    except Exception as e:
        print(f"🚨 Login error: {str(e)}")
        return jsonify({
                "error": "Máy chủ chấm công gặp sự cố kỹ thuật. Vui lòng liên hệ IT."
        }), 500
    finally:
        session.close()
        
@auth_bp.route('health', methods=['GET'])
def health_check():
    status = {
        "status": "healthy",
        "face_recognition_ready": init_face_app() is not None,
        "timestamp": datetime.now().isoformat()
    }
    return jsonify(status)