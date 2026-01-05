from sqlalchemy import Column, String , LargeBinary, DateTime, ForeignKey, NVARCHAR, func
from sqlalchemy.orm import declarative_base, relationship
from database import Base
class LuuTruKhuonMat(Base):
    __tablename__='LuuTruKhuonMat'
    MaLuuTru= Column(String(20), primary_key=True)
    MaNV= Column(String(20), ForeignKey('NhanVien.MaNV'), nullable=True)
    MaQL= Column(String(20), ForeignKey('QuanLy.MaQL'), nullable=True)
    Embedding= Column(LargeBinary, nullable=False)
    NgayTao = Column(DateTime, server_default=func.getdate())
    NgayCapNhat= Column(DateTime, nullable=True)
    GhiChu= Column(NVARCHAR(255), nullable=True)
    nhanvien = relationship("NhanVien", back_populates="luu_tru")