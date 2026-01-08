from flask import Blueprint, request, jsonify
from model import DonXin, NhanVien, QuanLy
from datetime import datetime
from database import SessionLocal
from .chamcong import safe_strftime

donxin_bp = Blueprint('donxin', __name__)

def generate_ma_don(session):
    max_ma_don = session.query(DonXin.MaDon)\
        .filter(DonXin.MaDon.like('DN%'))\
        .order_by(DonXin.MaDon.desc()).first()

    if max_ma_don is None or max_ma_don[0] is None:
        return 'DN001'
    else:
        last_num = int(max_ma_don[0][2:])
        new_num = last_num + 1
        return f'DN{new_num:03d}'
    
@donxin_bp.route('/don-xin-nghi', methods=['POST'])
def create_don_xin_nghi():
    data = request.json
    print("Received data:", data)
    
    user_id = data.get('userId')
    ly_do = data.get('lyDo')
    loai_don = data.get('loaiDon', 'Nghỉ phép')  # mặc định
    ngay_bat_dau_str = data.get('ngayBatDau')
    ngay_ket_thuc_str = data.get('ngayKetThuc')

    if not all([user_id, ly_do, ngay_bat_dau_str, ngay_ket_thuc_str]):
        return jsonify({"error": "Thiếu dữ liệu bắt buộc"}), 400

    # Parse ngày theo nhiều định dạng ISO8601 phổ biến
    try:
        ngay_bat_dau = datetime.strptime(ngay_bat_dau_str, "%Y-%m-%dT%H:%M:%S.%fZ")
        ngay_ket_thuc = datetime.strptime(ngay_ket_thuc_str, "%Y-%m-%dT%H:%M:%S.%fZ")
    except ValueError:
        try:
            ngay_bat_dau = datetime.strptime(ngay_bat_dau_str, "%Y-%m-%dT%H:%M:%S.%f")
            ngay_ket_thuc = datetime.strptime(ngay_ket_thuc_str, "%Y-%m-%dT%H:%M:%S.%f")
        except Exception:
            try:
                ngay_bat_dau = datetime.strptime(ngay_bat_dau_str, "%Y-%m-%dT%H:%M:%S")
                ngay_ket_thuc = datetime.strptime(ngay_ket_thuc_str, "%Y-%m-%dT%H:%M:%S")
            except Exception:
                return jsonify({"error": "Định dạng ngày không hợp lệ, cần ISO8601"}), 400

    if ngay_ket_thuc < ngay_bat_dau:
        return jsonify({"error": "Ngày kết thúc phải sau hoặc bằng ngày bắt đầu"}), 400

    session = SessionLocal()
    try:
        # Tạo mã đơn mới, truyền session vào hàm
        ma_don = generate_ma_don(session)

        don_xin = DonXin(
            MaDon=ma_don,
            MaNV=user_id,
            LoaiDon=loai_don,
            LyDo=ly_do,
            NgayBatDau=ngay_bat_dau.date(),
            NgayKetThuc=ngay_ket_thuc.date(),
            TrangThai="Chờ duyệt",
            NgayGui=datetime.utcnow().date()
        )

        session.add(don_xin)
        session.commit()

        return jsonify({
            "success": True,
            "message": "Tạo đơn xin nghỉ thành công",
            "maDon": ma_don
        })
    except Exception as e:
        session.rollback()
        return jsonify({"error": f"Lỗi hệ thống: {str(e)}"}), 500
    finally:
        session.close()

@donxin_bp.route('/don-xin-nghi/<string:user_id>', methods=['GET'])
def get_don_xin_nghi_by_user(user_id):
    session = SessionLocal()
    try:
        ds_don = session.query(DonXin).filter(DonXin.MaNV == user_id).order_by(DonXin.NgayBatDau.desc()).all()
        result = []
        for don in ds_don:
            result.append({
                "MaDon": don.MaDon,
                "MaNV": don.MaNV,
                "LoaiDon": don.LoaiDon,     
                "LyDo": don.LyDo,
                "NgayBatDau": safe_strftime(don.NgayBatDau),
                "NgayKetThuc": safe_strftime(don.NgayKetThuc),
                "TrangThai": don.TrangThai,
                "GhiChu": don.GhiChu,
                "MaQL": don.MaQL,
                "NgayGui": safe_strftime(don.NgayGui),
                "NgayDuyet": safe_strftime(don.NgayDuyet)
            })
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": f"Lỗi lấy dữ liệu: {str(e)}"}), 500
    finally:
        session.close()
        
@donxin_bp.route('/don-xin-nghi/quan-ly/<ma_quan_ly>', methods=['GET'])
def get_don_xin_cho_quan_ly(ma_quan_ly):
    session = SessionLocal()
    try:
        # Lấy phòng ban quản lý đang quản lý
        phong_ban = session.query(QuanLy.MaPB).filter(QuanLy.MaQL == ma_quan_ly).first()
        if phong_ban is None:
            return jsonify({"error": "Không tìm thấy quản lý hoặc phòng ban"}), 404
        ma_pb = phong_ban[0]

        # Lấy danh sách mã nhân viên thuộc phòng ban đó
        nhanvien_ids = session.query(NhanVien.MaNV).filter(NhanVien.MaPB == ma_pb).all()
        nhanvien_ids = [nv[0] for nv in nhanvien_ids]

        # Lấy danh sách đơn xin nghỉ của các nhân viên này kèm thông tin nhân viên
        don_xin_list = session.query(DonXin, NhanVien.HoTenNV).join(
            NhanVien, DonXin.MaNV == NhanVien.MaNV
        ).filter(DonXin.MaNV.in_(nhanvien_ids)).all()

        result = []
        for don, ho_ten in don_xin_list:
            don_dict = don.to_dict()
            don_dict['HoTen'] = ho_ten  # Thêm tên nhân viên
            result.append(don_dict)
        
        return jsonify(result)
    except Exception as e:
        import traceback
        traceback.print_exc()  # In lỗi ra console
        return jsonify({"error": f"Lỗi hệ thống: {str(e)}"}), 500
    finally:
        session.close()
        
@donxin_bp.route ('/don-xin-nghi/duyet-tu-choi/<ma_don>', methods=['POST'])
def duyet_tu_choi_don(ma_don):
    data = request.json
    trang_thai_moi = data.get('trangThai')  # 'Đã duyệt' hoặc 'Từ chối'
    ghi_chu = data.get('ghiChu', '')
    ma_quan_ly = data.get('maQL')  # Bắt buộc frontend gửi mã quản lý kèm theo

    session = SessionLocal()
    try:
        don = session.query(DonXin).filter(DonXin.MaDon == ma_don).first()
        if not don:
            return jsonify({'error': 'Không tìm thấy đơn'}), 404

        don.TrangThai = trang_thai_moi
        don.GhiChu = ghi_chu
        don.NgayDuyet = datetime.now()

        # CẬP NHẬT MÃ QUẢN LÝ DUYỆT ĐƠN
        don.MaQL = ma_quan_ly

        session.commit()
        return jsonify({'message': 'Cập nhật trạng thái thành công'})
    except Exception as e:
        session.rollback()
        return jsonify({'error': f'Lỗi hệ thống: {str(e)}'}), 500
    finally:
        session.close()
