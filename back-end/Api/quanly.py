import traceback
from flask import Blueprint, jsonify, request
from model import NhanVien, QuanLy, PhongBan, TaiKhoan, ChamCong
from datetime import datetime
from database import SessionLocal
from Api.generate_id import get_new_employee_id, get_new_account_id

quanly_bp = Blueprint('quanly', __name__)

@quanly_bp.route('/quanly/nhanvien/phong/<string:ma_ql>', methods=['GET'])
def get_nhanvien_by_quanly(ma_ql):
    session = SessionLocal()
    try:
        quanly = session.query(QuanLy).filter(QuanLy.MaQL == ma_ql).first()
        if not quanly:
            return jsonify({"ERROR": "Không tìm thấy quản lý"}), 404
        ma_phong_ban = quanly.MaPB
        nhanvienList = session.query(NhanVien).filter(NhanVien.MaPB == ma_phong_ban).order_by(NhanVien.HoTenNV).all()
        result = []
        for nv in nhanvienList:
            result.append({
                "MaNV": nv.MaNV,
                "HoTenNV": nv.HoTenNV,
                "Email": nv.Email or "",
                "SoDienThoai": nv.SoDienThoai,
                "ChucVu": nv.ChucVu,
                "GioiTinh": nv.GioiTinh,
                "MaPB": nv.MaPB
            })
        return jsonify({
            "success": True,
            "PhongBan": ma_phong_ban,
            "NhanVien": result
        }), 200
    except Exception as e:
        tb = traceback.format_exc()
        return jsonify({"ERROR": f"Lỗi: {str(e)}", "traceback": tb}), 500
    finally:
        session.close()

@quanly_bp.route('/quanly/them-nhan-vien', methods=['POST'])
def them_nhan_vien():
    session = SessionLocal()
    try:
        data = request.get_json()
        required_fields = ['ho_ten', 'ma_phong_ban', 'ngay_bat_dau', 'gioi_tinh', 'mat_khau']
        for field in required_fields:
            if field not in data:
                return jsonify({
                    'success': False,
                    'message': f'Thiếu trường bắt buộc: {field}'
                }), 400
                
        phong_ban = session.query(PhongBan).filter(PhongBan.MaPB == data['ma_phong_ban']).first()
        if not phong_ban:
            return jsonify({
                'success': False,
                'message': 'Mã phòng ban không tồn tại'
            }), 404
        
        ngay_bat_dau = datetime.strptime(data['ngay_bat_dau'], '%Y-%m-%d')
        
        ma_nv = get_new_employee_id(session, data['ma_phong_ban'], ngay_bat_dau)
        ma_tk = get_new_account_id(session)
        vai_tro = data.get('vai_tro', 'NhanVien')
        
        nhan_vien = NhanVien(
            MaNV=ma_nv,
            HoTenNV=data['ho_ten'],
            Email=data.get('email'),
            SoDienThoai=data.get('sdt'),
            MaPB=data['ma_phong_ban'],
            ChucVu=data.get('chuc_vu', 'Nhân viên'),
            NgayBatDauLam=ngay_bat_dau,
            GioiTinh=data['gioi_tinh'],
            TrangThai=1
        )
        session.add(nhan_vien)
        session.flush()
        
        tai_khoan = TaiKhoan(
            MaTK=ma_tk,
            TenDangNhap=ma_nv,
            MatKhau=data['mat_khau'],
            VaiTro=vai_tro,
            MaNV=ma_nv,
            MaQL=None,
            MaQTV=None,
            TrangThai=1
        )
        session.add(tai_khoan)
        session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Thêm nhân viên và tài khoản thành công',
            'data': {
                'ma_nv': ma_nv,
                'ma_tk': ma_tk,
                'ten_dang_nhap': ma_nv,   # Tên đăng nhập chính là mã nhân viên
                'mat_khau': data['mat_khau'],  # Mật khẩu gốc từ request
                'ho_ten': data['ho_ten'],
                'vai_tro': vai_tro,
                'phong_ban': phong_ban.TenPB if hasattr(phong_ban, 'TenPB') else data['ma_phong_ban']
            }
        }), 201

        
    except ValueError as e:
        session.rollback()
        tb = traceback.format_exc()
        return jsonify({
            'success': False,
            'message': f'Lỗi định dạng dữ liệu: {str(e)}',
            'traceback': tb
        }), 400
    except Exception as e:
        session.rollback()
        tb = traceback.format_exc()
        # In lỗi ra console để bạn dễ theo dõi
        print("[ERROR]", str(e))
        print(tb)
        return jsonify({
            'success': False,
            'message': f'Lỗi server: {str(e)}',
            'traceback': tb
        }), 500

    finally:
        session.close()

@quanly_bp.route('/quanly/cham-cong-ngay/<string:ma_ql>', methods=['GET'])
def cham_cong_ngay_by_quanly(ma_ql):
    """Lấy danh sách chấm công hôm nay của nhân viên trong phòng ban quản lý"""
    session = SessionLocal()
    try:
        # Lấy thông tin quản lý
        quanly = session.query(QuanLy).filter(QuanLy.MaQL == ma_ql).first()
        if not quanly:
            return jsonify({"error": "Không tìm thấy quản lý"}), 404
        
        ma_phong_ban = quanly.MaPB
        today = datetime.now().date()
        
        # Lấy danh sách chấm công hôm nay của phòng ban
        cham_cong_list = session.query(ChamCong, NhanVien.HoTenNV).join(
            NhanVien, ChamCong.MaNV == NhanVien.MaNV
        ).filter(
            NhanVien.MaPB == ma_phong_ban,
            ChamCong.NgayChamCong == today
        ).order_by(ChamCong.NgayChamCong.desc()).all()
        
        result = []
        for cc, ten_nv in cham_cong_list:
            result.append({
                'ma_nv': cc.MaNV,
                'ten_nv': ten_nv,
                'gio_vao': cc.GioVao,
                'gio_ra': cc.GioRa or '--:--',
                'trang_thai': cc.TrangThai or 'Chưa xác định',
                'ma_ca': cc.MaCa,
                'ngay_cham_cong': cc.NgayChamCong.strftime('%Y-%m-%d') if cc.NgayChamCong else None
            })
        
        return jsonify({
            'success': True,
            'data': result,
            'total': len(result)
        }), 200
        
    except Exception as e:
        tb = traceback.format_exc()
        return jsonify({
            'success': False,
            'message': f'Lỗi server: {str(e)}',
            'traceback': tb
        }), 500
    finally:
        session.close()

@quanly_bp.route('/quanly/danh-sach-nhan-vien', methods=['GET'])
def danh_sach_nhan_vien():
    session = SessionLocal()
    try:
        query = session.query(NhanVien)
        ma_pb = request.args.get('ma_phong_ban')
        if ma_pb:
            query = query.filter(NhanVien.MaPB == ma_pb)
        
        trang_thai = request.args.get('trang_thai')
        if trang_thai is not None:
            query = query.filter(NhanVien.TrangThai == (trang_thai.lower() == 'true'))
        
        nhan_viens = query.all()
        
        result = []
        for nv in nhan_viens:
            result.append({
                'ma_nv': nv.MaNV,
                'ho_ten': nv.HoTenNV,
                'email': nv.Email,
                'sdt': nv.SoDienThoai,
                'ma_phong_ban': nv.MaPB,
                'chuc_vu': nv.ChucVu,
                'ngay_bat_dau': nv.NgayBatDauLam.strftime('%Y-%m-%d') if nv.NgayBatDauLam else None,
                'gioi_tinh': nv.GioiTinh,
                'trang_thai': nv.TrangThai
            })
        
        return jsonify({
            'success': True,
            'data': result,
            'total': len(result)
        }), 200
        
    except Exception as e:
        tb = traceback.format_exc()
        return jsonify({
            'success': False,
            'message': f'Lỗi server: {str(e)}',
            'traceback': tb
        }), 500
    finally:
        session.close()
