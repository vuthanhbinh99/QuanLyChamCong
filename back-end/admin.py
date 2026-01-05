from datetime import datetime
from flask import render_template
from flask_admin import Admin, AdminIndexView, expose # type: ignore
from flask_admin.contrib.sqla import ModelView # type: ignore
from database import SessionLocal, engine
from sqlalchemy.orm import scoped_session, sessionmaker
from model import NhanVien, ChamCong, CaLam, QuanLy, PhongBan, TaiKhoan
from Services.generate_id import get_new_employee_id, get_new_account_id, get_new_QuanLy_id
from wtforms.validators import Regexp, Email, DataRequired # type: ignore
from wtforms import StringField,ValidationError # type: ignore
from flask_admin.contrib.sqla.filters import FilterLike # type: ignore

# Tạo phiên làm việc với cơ sở dữ liệu
db_session = scoped_session(sessionmaker(autocommit=False, autoflush=False, bind=engine))

class SecureModelView(ModelView):
    page_size = 50  # Hiển thị 50 dòng mỗi trang
    can_export = True  # Cho phép xuất dữ liệu
    def is_accessible(self):
        return True
    
    def inaccessible_callback(self, name, **kwargs):
        return "Bạn không có quyền truy cập trang này!"
    
class NhanVienView(SecureModelView):
    column_list = ('MaNV', 'HoTenNV', 'Email','PhongBan', 'ChucVu','GioiTinh', 'SoDienThoai','NgayBatDauLam', 'TrangThai')
    column_searchable_list = ['HoTenNV', 'MaNV']
    column_filters = ['ChucVu', 'GioiTinh','HoTenNV', 'MaNV']
    form_excluded_columns = ['luu_tru'] 
    column_labels = {
        'HoTenNV': 'Họ và Tên',
        'MaNV': 'Mã Nhân Viên',
        'PhongBan': 'Phòng Ban',
        'ChucVu': 'Chức Vụ',
        'GioiTinh': 'Giới Tính',
        'SoDienThoai': 'SĐT',
        'NgayBatDauLam': 'Ngày Bắt Đầu Làm',
        'TrangThai': 'Trạng Thái',
        'Email': 'Email'
    }
    form_args = {
        'SoDienThoai': {
            'label': 'Số Điện Thoại',
            'validators': [
                DataRequired(), 
                Regexp(r'^\d+$', message="Số điện thoại chỉ được chứa các ký tự số (0-9)."),
                Regexp(r'^\d{10}$', message="Số điện thoại phải có 10.") 
            ]
        },
        'Email': {
            'label': 'Email (Gmail)',
            'validators': [
                DataRequired(),
                Email(message="Địa chỉ email không hợp lệ."),
                Regexp(r'.+@gmail\.com$', message="Email phải có đuôi @gmail.com")
            ]
        }
    }
    def on_model_change(self, form, model, is_created):
        if is_created:
            phong_ban_obj = model.PhongBan
            # Tạo mã nhân viên mới khi thêm nhân viên
            if phong_ban_obj is None:
                # Nếu model.MaPB cũng rỗng nốt thì báo lỗi bắt buộc chọn
                if not model.MaPB:
                    raise ValueError(" LỖI: Bạn chưa chọn Phòng Ban! Vui lòng chọn từ danh sách.")
                else:
                    # Trường hợp hiếm: MaPB có nhưng Object chưa load
                    ma_pb_chuan = model.MaPB
            else:
                ma_pb_chuan = phong_ban_obj.MaPB
            ngay_bat_dau = model.NgayBatDauLam if model.NgayBatDauLam else datetime.now()
            ma_nv_moi = get_new_employee_id(db_session, ma_pb_chuan, ngay_bat_dau)
            model.MaNV = ma_nv_moi
            model.MaPB = ma_pb_chuan
        if not model.TrangThai:
            model.TrangThai = True
            
    def after_model_change(self, form, model, is_created):
        if is_created:
            session = self.session
            new_tk_id = get_new_account_id(session)
            tai_khoan = TaiKhoan(
                MaTK=new_tk_id,
                TenDangNhap=model.MaNV,
                MatKhau='123456',  # Mật khẩu mặc định
                VaiTro='nhân viên',
                MaNV=model.MaNV,
                TrangThai=1
            )
            session.add(tai_khoan)
            session.commit()
class QuanLyView(SecureModelView):
    column_list = ('MaQL', 'HoTenQL', 'PhongBan','GioiTinh', 'SoDienThoai', 'Email', 'TrangThai', 'NgayBatDauLam')
    column_searchable_list = ['HoTenQL', 'MaQL']
    column_filters = ['GioiTinh','MaQL', 'HoTenQL']
    column_labels = {
        'HoTenQL': 'Họ và Tên',
        'MaQL': 'Mã Quản Lý',
        'PhongBan': 'Phòng Ban',
        'GioiTinh': 'Giới Tính',
        'SoDienThoai': 'SĐT',
        'Email': 'Email',
        'TrangThai': 'Trạng Thái',
        'TenPB': 'Tên Phòng Ban',
        'NgayBatDauLam': 'Ngày Bắt Đầu Làm'
    }
    form_args ={
        'SoDienThoai': {
            'label': 'Số Điện Thoại',
            'validators': [
                DataRequired(), 
                Regexp(r'^\d+$', message="Số điện thoại chỉ được chứa các ký tự số (0-9)."),
                Regexp(r'^\d{10}$', message="Số điện thoại phải có 10.") 
            ]
        },
        'Email': {
            'label': 'Email (Gmail)',
            'validators': [
                DataRequired(),
                Email(message="Địa chỉ email không hợp lệ."),
                Regexp(r'.+@gmail\.com$', message="Email phải có đuôi @gmail.com")
            ]
        }
    }
    def on_model_change(self, form, model, is_created):
        if is_created:
            phong_ban_obj = model.PhongBan
            # Tạo mã quản lý mới khi thêm quản lý
            if phong_ban_obj is None:
                # Nếu model.MaPB cũng rỗng nốt thì báo lỗi bắt buộc chọn
                if not model.MaPB:
                    raise ValueError(" LỖI: Bạn chưa chọn Phòng Ban! Vui lòng chọn từ danh sách.")
                else:
                    # Trường hợp hiếm: MaPB có nhưng Object chưa load
                    ma_pb_chuan = model.MaPB
            else:
                ma_pb_chuan = phong_ban_obj.MaPB
            ngay_bat_dau = model.NgayBatDauLam if model.NgayBatDauLam else datetime.now()
            ma_ql_moi = get_new_QuanLy_id(db_session, ma_pb_chuan, ngay_bat_dau)
            model.MaQL = ma_ql_moi
            model.MaPB = ma_pb_chuan
        if not model.TrangThai:
            model.TrangThai = True
    def after_model_change(self, form, model, is_created):
        if is_created:
            session = self.session
            new_tk_id = get_new_account_id(session)
            tai_khoan = TaiKhoan(
                MaTK=new_tk_id,
                TenDangNhap=model.MaQL,
                MatKhau='123456',  # Mật khẩu mặc định
                VaiTro='quản lý',
                MaQL=model.MaQL,
                TrangThai=1
            )
            session.add(tai_khoan)
            session.commit()
class PhongBanView(SecureModelView):
    column_list = ('MaPB', 'TenPB')
    column_searchable_list = ['TenPB', 'MaPB']
    column_labels = {
        'MaPB': 'Mã Phòng Ban',
        'TenPB': 'Tên Phòng Ban'
    }
    form_columns = ('MaPB', 'TenPB')
    form_args = {
        'MaPB': {
            'label': 'Mã Phòng Ban',
            'validators': [DataRequired()] 
        }
    }
    def validate_form(self, form):
        if not super(PhongBanView, self).validate_form(form):
            return False
        if form.MaPB.data:
            exist = self.session.query(PhongBan).filter_by(MaPB=form.MaPB.data).first()
            if exist:
                form.MaPB.errors.append(' Mã phòng ban này đã tồn tại! Vui lòng chọn mã khác.')
                return False
            return True
    def create_form(self, obj=None):
        form = super(PhongBanView, self).create_form(obj)
        
        # Lấy danh sách tất cả mã phòng ban hiện có trong DB
        danh_sach_pb = self.session.query(PhongBan.MaPB, PhongBan.TenPB).all()
        
        # Chuyển thành chuỗi: "IT, HR, KD..."
        # item[0] vì query trả về tuple ('IT',)
        ds_hien_thi = [f"{item.MaPB} ({item.TenPB})" for item in danh_sach_pb]
        chuoi_thong_bao = ", ".join(ds_hien_thi)
        
        # Gán vào dòng chú thích (Description) của ô nhập liệu
        if hasattr(form, 'MaPB'):
            form.MaPB.description = f"Danh sách đã có: {chuoi_thong_bao}"
        
        return form
class TaiKhoanView(SecureModelView):
    column_list = ('MaTK', 'TenDangNhap', 'MatKhau', 'VaiTro', 'MaNV', 'MaQL', 'MaQTV', 'TrangThai', 'NgayTao')
    column_searchable_list = ['TenDangNhap', 'MaTK', 'VaiTro', 'MaNV', 'MaQL', 'MaQTV']
    column_labels = {
        'MaTK': 'Mã Tài Khoản',
        'TenDangNhap': 'Tên Đăng Nhập',
        'MatKhau': 'Mật Khẩu',
        'VaiTro': 'Vai Trò',
        'MaNV': 'Mã Nhân Viên',
        'MaQL': 'Mã Quản Lý',
        'MaQTV': 'Mã Quản Trị Viên',
        'TrangThai': 'Trạng Thái',
        'NgayTao': 'Ngày Tạo'
    }
class ChamCongView(SecureModelView):
    column_list = ('MaChamCong', 'NhanVien','QuanLy.HoTenQL', 'NgayChamCong','GioVao','GioRa', 'CaLam', 'TrangThai','DiaDiemChamCong')
    column_searchable_list = ['MaChamCong', 'NhanVien.HoTenNV','QuanLy.HoTenQL', 'CaLam.TenCa']
    column_filters = ['NgayChamCong', 'MaChamCong', FilterLike(NhanVien.HoTenNV, name='Tên Nhân Viên')]
    column_labels = {
        'MaChamCong': 'Mã Chấm Công',
        'NhanVien': 'Nhân Viên',
        'NgayChamCong': 'Ngày Chấm Công',
        'CaLam': 'Ca Làm',
        'TrangThai': 'Trạng Thái',
        'DiaDiemChamCong': 'Địa Điểm Chấm Công',
        'QuanLy.HoTenQL': 'Quản Lý',
        'GioVao': 'Giờ Vào',
        'GioRa': 'Giờ Ra',
        'NhanVien.HoTenNV': 'Tên nhân viên',
        'QuanLy.HoTenQL': 'Tên quản lý',
        'CaLam.TenCa': 'Tên ca'
    }
class CaLamView(SecureModelView):
    column_list = ('MaCa', 'TenCa', 'GioBatDau', 'GioKetThuc', 'GhiChu')
    column_searchable_list = ['MaCa', 'TenCa']
    column_labels = {
        'MaCa': 'Mã Ca',
        'TenCa': 'Tên Ca',
        'GioBatDau': 'Giờ Bắt Đầu',
        'GioKetThuc': 'Giờ Kết Thúc',
        'GhiChu': 'Ghi Chú'
    }
    form_columns = ('MaCa', 'TenCa','GhiChu')
    form_args = {
        'MaCa': {
            'label': 'Mã Ca',
            'validators': [DataRequired()] 
        }
    }
    def validate_form(self, form):
        if not super(CaLamView, self).validate_form(form):
            return False
        if form.MaCa.data:
            exist = self.session.query(CaLam).filter_by(MaCa=form.MaCa.data).first()
            if exist:
                form.MaCa.errors.append(' Mã Ca này đã tồn tại! Vui lòng nhập mã khác.')
                return False
            return True
    def create_form(self, obj=None):
        form = super(CaLamView, self).create_form(obj)
        
        # Lấy danh sách tất cả mã phòng ban hiện có trong DB
        danh_sach_calam = self.session.query(CaLam.MaCa, CaLam.TenCa).all()
        
        ds_hien_thi = [f"{item.MaCa} ({item.TenCa})" for item in danh_sach_calam]
        chuoi_thong_bao = ", ".join(ds_hien_thi)
        
        # Gán vào dòng chú thích (Description) của ô nhập liệu
        if hasattr(form, 'MaCa'):
            form.MaCa.description = f"Danh sách đã có: {chuoi_thong_bao}"
        
        return form
class DashboardView(AdminIndexView):
    @expose('/')
    def index(self):
        # 1. Chuẩn bị dữ liệu (Logic giữ nguyên)
        today = datetime.now().date()
        
        # Dữ liệu thống kê
        stats = {
            "nv": db_session.query(NhanVien).count(),
            "pb": db_session.query(PhongBan).count(),
            "cham_cong": db_session.query(ChamCong).filter(ChamCong.NgayChamCong == today).count(),
            "di_muon": db_session.query(ChamCong).filter(
                ChamCong.NgayChamCong == today, 
                ChamCong.TrangThai.like('%Muộn%')
            ).count()
        }
        
        # Dữ liệu bảng mới nhất
        recent_query = db_session.query(ChamCong).filter(
            ChamCong.NgayChamCong == today
        ).order_by(ChamCong.GioVao.desc()).limit(10).all()
        
        recent_data = []
        for cc in recent_query:
            recent_data.append({
                "ten": cc.NhanVien.HoTenNV if cc.NhanVien else "N/A",
                "gio_vao": cc.GioVao.strftime('%H:%M:%S') if cc.GioVao else "",
                "trang_thai": cc.TrangThai or ""
            })

        # 2. Render file HTML (Flask tự tìm trong thư mục templates/admin/dashboard.html)
        # Không cần json.dumps ở đây vì ta dùng filter | tojson của Jinja2 trong HTML rồi
        return self.render('admin/dashboard.html', 
                           data_stats=stats, 
                           data_recent=recent_data)
def setup_admin(app):
        admin = Admin(app, name='Hệ Thống Chấm Công', index_view=DashboardView(name='Dashboard', url='/admin'))
        admin.add_view(NhanVienView(NhanVien, db_session, name="Nhân Viên", category="Nhân Sự", endpoint="admin_nhanvien" )) # type: ignore
        admin.add_view(QuanLyView(QuanLy, db_session, name="Quản Lý", category="Nhân Sự", endpoint="admin_quanly" )) # type: ignore
        admin.add_view(PhongBanView(PhongBan, db_session, name="Phòng Ban", category="Phòng Ban", endpoint="admin_phongban" )) # type: ignore

        admin.add_view(ChamCongView(ChamCong, db_session, name="Dữ Liệu Chấm Công", category="Hoạt Động", endpoint="admin_chamcong" )) # type: ignore
        admin.add_view(CaLamView(CaLam, db_session, name="Ca Làm Việc", category="Cấu Hình", endpoint="admin_calam")) # type: ignore
        admin.add_view(TaiKhoanView(TaiKhoan, db_session, name="Tài Khoản", category="Cấu Hình", endpoint="admin_taikhoan")) # type: ignore
        print("[INFO] Flask-Admin setup completed!")
