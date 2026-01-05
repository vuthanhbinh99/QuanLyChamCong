from sqlalchemy import String , NVARCHAR, Column, ForeignKey, Boolean, Date
from sqlalchemy.orm import declarative_base, relationship
from database import Base
class QuanLy(Base):
    __tablename__ = "QuanLy"
    MaQL = Column(NVARCHAR(20), primary_key=True, nullable=False)
    HoTenQL = Column(NVARCHAR(100), nullable=False)
    MaPB = Column(NVARCHAR(20), ForeignKey("PhongBan.MaPB"), nullable=False)
    PhongBan = relationship("PhongBan")
    SoDienThoai = Column(String(20))
    Email = Column(String(100))
    GioiTinh = Column(NVARCHAR(3), nullable=False)
    TrangThai = Column(Boolean, nullable=False)
    NgayBatDauLam = Column(Date)
    def __str__(self):
        return self.HoTenQL