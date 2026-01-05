from sqlalchemy import Column, String, Date, ForeignKey, NVARCHAR
from sqlalchemy.dialects.mssql import TIME
from sqlalchemy.orm import declarative_base, relationship
from database import Base

class ChamCong(Base):
    __tablename__= 'ChamCong'
    MaChamCong = Column(String(30), primary_key=True)
    MaNV = Column(String(20), ForeignKey('NhanVien.MaNV'), nullable=True)
    NhanVien = relationship("NhanVien")
    MaQL = Column(String(20), ForeignKey('QuanLy.MaQL'), nullable=True)
    QuanLy = relationship("QuanLy")
    MaCa = Column(String(20), ForeignKey('CaLam.MaCa'), nullable=True)
    CaLam = relationship("CaLam")
    NgayChamCong = Column(Date, nullable=False)
    GioVao = Column(TIME(precision=0), nullable=True)
    GioRa = Column(TIME(precision=0), nullable=True)
    TrangThai = Column(NVARCHAR(50), nullable=False)
    DiaDiemChamCong = Column(NVARCHAR(255), nullable=True) 
