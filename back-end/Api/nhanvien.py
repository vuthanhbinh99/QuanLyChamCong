# Api/nhanvien.py
from flask import Blueprint, request, jsonify
from sqlalchemy.orm import Session
from database import SessionLocal
from model import NhanVien
from datetime import datetime

nhanvien_bp = Blueprint('nhanvien', __name__)

@nhanvien_bp.route('/nhanvien/<ma_nv>', methods=['PUT'])
def update_nhan_vien(ma_nv):
    db: Session = SessionLocal()
    data = request.json

    nv = db.query(NhanVien).filter(NhanVien.MaNV == ma_nv).first()
    if not nv:
        return jsonify({'message': 'Nhân viên không tồn tại'}), 404

    nv.HoTenNV = data.get('ho_ten', nv.HoTenNV)
    nv.Email = data.get('email', nv.Email)
    nv.SoDienThoai = data.get('so_dien_thoai', nv.SoDienThoai)
    nv.MaPB = data.get('ma_phong_ban', nv.MaPB)
    nv.ChucVu = data.get('chuc_vu', nv.ChucVu)
    nv.GioiTinh = data.get('gioi_tinh', nv.GioiTinh)

    if data.get('ngay_bat_dau_lam'):
        nv.NgayBatDauLam = datetime.strptime(
            data['ngay_bat_dau_lam'], '%Y-%m-%d'
        )

    db.commit()
    db.close()

    return jsonify({
        'message': 'Cập nhật thông tin nhân viên thành công'
    })
@nhanvien_bp.route('/nhanvien/<ma_nv>/khoa', methods=['PUT'])
def khoa_nhan_vien(ma_nv):
    db = SessionLocal()
    nv = db.query(NhanVien).filter(NhanVien.MaNV == ma_nv).first()

    if not nv:
        return jsonify({'message': 'Không tồn tại'}), 404

    nv.TrangThai = 0   # ❗ 0 = khóa
    db.commit()
    db.close()

    return jsonify({'message': 'Đã khóa nhân viên'})



@nhanvien_bp.route('/nhanvien/<ma_nv>/mo-khoa', methods=['PUT'])
def mo_khoa_nhan_vien(ma_nv):
    db = SessionLocal()
    nv = db.query(NhanVien).filter(NhanVien.MaNV == ma_nv).first()

    if not nv:
        return jsonify({'message': 'Không tồn tại'}), 404

    nv.TrangThai = 1   # ❗ 1 = hoạt động
    db.commit()
    db.close()

    return jsonify({'message': 'Đã mở khóa nhân viên'})

    