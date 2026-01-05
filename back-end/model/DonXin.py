from sqlalchemy import NVARCHAR, Column, String, Date, Time, ForeignKey
from database import Base

class DonXin(Base):
    __tablename__ = 'DonXin'
    MaDon = Column(String(20), primary_key=True)
    MaNV = Column(String(20), ForeignKey('NhanVien.MaNV'))
    LoaiDon = Column(NVARCHAR(50))
    NgayBatDau = Column(Date)
    NgayKetThuc = Column(Date)
    LyDo = Column(NVARCHAR(255))
    TrangThai = Column(NVARCHAR(50))
    MaQL = Column(String(20), ForeignKey('QuanLy.MaQL'), nullable=True)
    NgayGui = Column(Date)
    NgayDuyet = Column(Date)
    GhiChu = Column(NVARCHAR(255))

    def to_dict(self):
        return {
            "MaDon": self.MaDon,
            "MaNV": self.MaNV,
            "LoaiDon": self.LoaiDon,
            "NgayBatDau": self.NgayBatDau.isoformat() if self.NgayBatDau else None,
            "NgayKetThuc": self.NgayKetThuc.isoformat() if self.NgayKetThuc else None,
            "LyDo": self.LyDo,
            "TrangThai": self.TrangThai,
            "MaQL": self.MaQL,
            "NgayGui": self.NgayGui.isoformat() if self.NgayGui else None,
            "NgayDuyet": self.NgayDuyet.isoformat() if self.NgayDuyet else None,
            "GhiChu": self.GhiChu,
        }
