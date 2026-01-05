from model import NhanVien, TaiKhoan
from datetime import datetime
from database import SessionLocal
import re

def get_new_employee_id(session, ma_phong_ban: str, ngay_bat_dau: datetime):
    session = SessionLocal()
    so_phong_ban = re.sub(r'[^0-9]', '', ma_phong_ban)
    so_phong_ban = str(int(so_phong_ban))  # Bỏ số 0 đứng đầu
    
    year_2_digits = str(ngay_bat_dau.year)[-2:]
    
    # Tìm nhân viên cuối cùng có cùng mã phòng ban và năm
    last_nv = (
        session.query(NhanVien)
        .filter(NhanVien.MaNV.like(f"NV{so_phong_ban}{year_2_digits}%"))
        .order_by(NhanVien.MaNV.desc())
        .first()
    )
    
    if last_nv:
        # Lấy 4 số cuối và tăng lên 1
        last_number = int(last_nv.MaNV[-4:])
        next_number = last_number + 1
    else:
        next_number = 1
    
    # Format số thứ tự thành 4 chữ số
    number_str = f"{next_number:04d}"
    
    new_ma_nv = f"NV{so_phong_ban}{year_2_digits}{number_str}"
    return new_ma_nv
def get_new_account_id(session):
    try:
        # Lấy tất cả các mã TK hiện có
        all_ids = session.query(TaiKhoan.MaTK).all()
        existing_ids = {id_[0] for id_ in all_ids}
        
        next_number = 1
        while True:
            number_str = f"TK{next_number:04d}"
            if number_str not in existing_ids:
                return number_str
            next_number += 1

    except Exception as e:
        import traceback
        tb = traceback.format_exc()
        print(f"[ERROR] Lỗi tạo mã tài khoản: {str(e)}\n{tb}")
        raise
