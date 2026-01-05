from sqlalchemy import Column, String, NVARCHAR
from database import Base
class QuanTriVien(Base):
    __tablename__ = 'QuanTriVien'
    MaQTV = Column(String(20), primary_key=True)
    HoTenQTV = Column(NVARCHAR(100), nullable=False)
    Email = Column(String(100), nullable=False, unique=True)
    SoDienThoai = Column(String(15), nullable=False)