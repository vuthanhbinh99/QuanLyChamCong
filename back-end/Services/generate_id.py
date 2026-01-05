from sqlalchemy.orm import Session
from model import NhanVien, TaiKhoan, QuanLy
from datetime import datetime
def get_new_employee_id(db: Session, ma_phong_ban: str, ngay_bat_dau: datetime):
   ma_pb_so = ma_phong_ban
   if ma_phong_ban and ma_phong_ban.startswith("PB"):
        try:
            ma_pb_so = str(int(ma_phong_ban[2:])) 
        except ValueError:
            pass 
   if not ma_phong_ban:
      raise ValueError("Mã phòng ban bị rỗng, không thể sinh mã nhân viên!")
   year_2_digits = str(ngay_bat_dau.year)[-2:]
   prefix_code = f"NV{ma_pb_so}{year_2_digits}"

   last_nv=(
       db.query(NhanVien)
       .filter(NhanVien.MaNV.like(f"{prefix_code}%")) 
       .order_by(NhanVien.MaNV.desc())
       .first())  
   
   if last_nv:
      try:
         last_number = int(last_nv.MaNV[-4:])
         next_number = last_number + 1
      except ValueError:
         next_number = 1
   else:
      next_number = 1
    
   number_str = f"{next_number:04d}"
    
   new_ma_nv = f"{prefix_code}{number_str}"
   return new_ma_nv

def get_new_QuanLy_id(db: Session, ma_phong_ban: str, ngay_bat_dau: datetime):
   ma_pb_so = ma_phong_ban
   if ma_phong_ban and ma_phong_ban.startswith("PB"):
        try:
            ma_pb_so = str(int(ma_phong_ban[2:])) 
        except ValueError:
            pass 
   if not ma_phong_ban:
      raise ValueError("Mã phòng ban bị rỗng, không thể sinh mã quản lý!")
   year_2_digits = str(ngay_bat_dau.year)[-2:]
   prefix_code = f"QL{ma_pb_so}{year_2_digits}"
   last_ql = (
         db.query(QuanLy)
         .filter(QuanLy.MaQL.like(f"{prefix_code}%")) 
         .order_by(QuanLy.MaQL.desc())
         .first())
   if last_ql:
      try:
         last_number = int(last_ql.MaQL[-4:])
         next_number = last_number + 1
      except ValueError:
         next_number = 1
   else:
      next_number = 1
   number_str = f"{next_number:04d}"
   new_ma_ql = f"{prefix_code}{number_str}"
   return new_ma_ql
def get_new_account_id(db: Session):
   last_account=(
      db.query(TaiKhoan).order_by(TaiKhoan.MaTK.desc()).first())
   if last_account and last_account.MaTK:
         try:
            numeric_part = last_account.MaTK[2:]
            last_number = int(numeric_part)
            next_number = last_number + 1
         except ValueError:
            next_number = 1
   else:
      next_number = 1
   number_str = f"{next_number:03d}"
   new_ma_taikhoan = f"TK{number_str}"
   return new_ma_taikhoan