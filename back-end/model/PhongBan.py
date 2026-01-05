from sqlalchemy import Column, String, NVARCHAR
from database import Base
class PhongBan(Base):
    __tablename__ = 'PhongBan'

    MaPB = Column(String(20), primary_key=True)
    TenPB = Column(NVARCHAR(100), name='TENPB')  # tên thuộc tính TenPB ánh xạ cột TENPB
    
    def __str__(self):
        return self.TenPB # Trả về tên phòng ban khi in đối tượng PhongBan
