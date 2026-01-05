from sqlalchemy import Column, String, Date, Boolean, ForeignKey, NVARCHAR
from sqlalchemy.orm import declarative_base, relationship
from database import Base
class NhanVien(Base):
    __tablename__='NhanVien'
    MaNV= Column(String(20), primary_key=True)
    HoTenNV= Column(NVARCHAR(100), nullable=False)
    Email =Column(NVARCHAR(100))
    SoDienThoai= Column(NVARCHAR(20))
    MaPB = Column(String(20), ForeignKey('PhongBan.MaPB'))
    PhongBan = relationship("PhongBan")
    ChucVu= Column(NVARCHAR(50))
    NgayBatDauLam= Column(Date)
    TrangThai = Column(Boolean, default=True)
    GioiTinh = Column(NVARCHAR(3), nullable=False)
    luu_tru = relationship("LuuTruKhuonMat", back_populates="nhanvien")
    
    def __str__(self):
        return self.HoTenNV
    
    