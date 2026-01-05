from sqlalchemy import Column, String, Date, Integer, Float, ForeignKey, NVARCHAR
from database import Base

class BaoCao(Base):
    __tablename__ = 'BaoCao'

    MaBC = Column(String(20), primary_key=True)
    NgayTao = Column(Date)
    LoaiBaoCao = Column(NVARCHAR(100))
    MaNV = Column(String(20), ForeignKey('NhanVien.MaNV'))
    SoGioLam = Column(Float)
    TongNgayLam = Column(Integer)
