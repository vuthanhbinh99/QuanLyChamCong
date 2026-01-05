from sqlalchemy import Column, String, Time, NVARCHAR
from database import Base
class CaLam(Base):
    __tablename__ = 'CaLam'
    MaCa = Column(String(20), primary_key=True, nullable=False)
    TenCa = Column(NVARCHAR(50), nullable=False)
    GioBatDau = Column(Time, nullable=False)
    GioKetThuc = Column(Time, nullable=False)
    GhiChu = Column(NVARCHAR(255), nullable=True)

    def __str__(self):
        return self.TenCa