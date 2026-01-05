# model/TaiKhoan.py
from sqlalchemy import Column, String, DateTime, ForeignKey, NVARCHAR, func, Boolean
from database import Base  # Giờ sẽ import được

class TaiKhoan(Base):
    __tablename__ = 'TaiKhoan'
    MaTK = Column(String(20), primary_key=True)
    TenDangNhap = Column(NVARCHAR(50), nullable=False, unique=True)
    MatKhau = Column(NVARCHAR(255), nullable=False)
    VaiTro = Column(NVARCHAR(50), nullable=False)
    MaNV = Column(String(20), ForeignKey('NhanVien.MaNV'))
    MaQL = Column(String(20), ForeignKey('QuanLy.MaQL'))
    MaQTV = Column(String(20), ForeignKey('QuanTriVien.MaQTV'))
    TrangThai = Column(Boolean, default=True)
    NgayTao = Column(DateTime, server_default=func.getdate())