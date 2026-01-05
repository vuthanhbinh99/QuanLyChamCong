import os
import traceback
from datetime import datetime
from flask import Blueprint, request, jsonify, send_file
from sqlalchemy import text
from database import SessionLocal
from io import BytesIO
import pandas as pd # type: ignore
from reportlab.lib.pagesizes import landscape, A4 # type: ignore
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer # type: ignore
from reportlab.lib import colors # type: ignore
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle # type: ignore
from reportlab.lib.units import inch # type: ignore
from reportlab.pdfbase import pdfmetrics # type: ignore
from reportlab.pdfbase.ttfonts import TTFont # type: ignore
from reportlab.lib.enums import TA_CENTER # type: ignore
from reportlab.pdfbase.cidfonts import UnicodeCIDFont # type: ignore
def register_vietnamese_fonts():
    font_path = 'Arial.ttf' 
    
    if not os.path.exists(font_path):
        if os.path.exists('C:/Windows/Fonts/arial.ttf'):
            font_path = 'C:/Windows/Fonts/arial.ttf'
        else:
            print("⚠️ CẢNH BÁO: Không tìm thấy file font Arial.ttf. Tiếng Việt sẽ bị lỗi!")
            return 'Helvetica' 

    try:
        pdfmetrics.registerFont(TTFont('ArialVN', font_path))
        return 'ArialVN'
    except Exception as e:
        print(f"Lỗi đăng ký font: {e}")
        return 'Helvetica'

VIETNAMESE_FONT = register_vietnamese_fonts()

baocao_bp = Blueprint('baocao', __name__, url_prefix='/api')

# API JSON BÁO CÁO (RAW SQL – AN TOÀN)
@baocao_bp.route('/baocao', methods=['GET'])
def get_baocao_simple():
    session = SessionLocal()
    try:
        user_id = request.args.get('user_id')
        role = request.args.get('role')
        filter_type = request.args.get('filter_type')
        month = request.args.get('month')
        year = request.args.get('year')

        if not year:
            return jsonify({"success": False, "error": "Thiếu year"}), 400

        year = int(year)

        sql = """
        SELECT 
            cc.MaNV,
            nv.HoTenNV,
            ISNULL(pb.TenPB, '') AS PhongBan,
            COUNT(DISTINCT cc.NgayChamCong) AS TongNgayLam,
            ISNULL(SUM(DATEDIFF(MINUTE, cc.GioVao, cc.GioRa)), 0) AS TongPhutLam
        FROM ChamCong cc
        JOIN NhanVien nv ON cc.MaNV = nv.MaNV
        LEFT JOIN PhongBan pb ON nv.MaPB = pb.MaPB
        WHERE 1=1
        """

        params = {"year": year}

        if filter_type == 'thang':
            if not month:
                return jsonify({"success": False, "error": "Thiếu month"}), 400
            month = int(month)
            sql += " AND DATEPART(year, cc.NgayChamCong) = :year AND DATEPART(month, cc.NgayChamCong) = :month"
            params["month"] = month

        elif filter_type == 'nam':
            sql += " AND DATEPART(year, cc.NgayChamCong) = :year"

        else:
            return jsonify({"success": False, "error": "filter_type phải là thang | nam"}), 400

        if role == 'nhanvien':
            sql += " AND cc.MaNV = :user_id"
            params["user_id"] = user_id

        sql += " GROUP BY cc.MaNV, nv.HoTenNV, pb.TenPB ORDER BY nv.HoTenNV"

        results = session.execute(text(sql), params).fetchall()

        data = []
        for ma_nv, ho_ten, phong_ban, ngay, phut in results:
            data.append({
                "maNV": ma_nv,
                "hoTen": ho_ten,
                "phongBan": phong_ban,
                "tongNgayLam": ngay,
                "soGioLam": round((phut or 0) / 60, 2)
            })

        return jsonify({"success": True, "data": data})

    except Exception as e:
        traceback.print_exc()
        return jsonify({"success": False, "error": str(e)}), 500
    finally:
        session.close()


# EXPORT EXCEL
@baocao_bp.route('/baocao/excel', methods=['GET'])
def export_baocao_excel():
    session = SessionLocal()
    try:
        user_id = request.args.get('user_id')
        role = request.args.get('role')
        filter_type = request.args.get('filter_type')
        month = request.args.get('month')
        year = request.args.get('year')

        if not year:
            return jsonify({"success": False, "error": "Thiếu year"}), 400

        year = int(year)

        sql = """
        SELECT 
            cc.MaNV,
            nv.HoTenNV,
            ISNULL(pb.TenPB, '') AS PhongBan,
            COUNT(DISTINCT cc.NgayChamCong) AS TongNgayLam,
            ISNULL(SUM(DATEDIFF(MINUTE, cc.GioVao, cc.GioRa)), 0) AS TongPhutLam
        FROM ChamCong cc
        JOIN NhanVien nv ON cc.MaNV = nv.MaNV
        LEFT JOIN PhongBan pb ON nv.MaPB = pb.MaPB
        WHERE 1=1
        """

        params = {"year": year}

        if filter_type == 'thang':
            if not month:
                return jsonify({"success": False, "error": "Thiếu month"}), 400
            month = int(month)
            sql += """
                AND DATEPART(year, cc.NgayChamCong) = :year
                AND DATEPART(month, cc.NgayChamCong) = :month
            """
            params["month"] = month

        elif filter_type == 'nam':
            sql += " AND DATEPART(year, cc.NgayChamCong) = :year"
        else:
            return jsonify({"success": False, "error": "filter_type không hợp lệ"}), 400

        if role == 'nhanvien':
            sql += " AND cc.MaNV = :user_id"
            params["user_id"] = user_id

        sql += """
        GROUP BY cc.MaNV, nv.HoTenNV, pb.TenPB
        ORDER BY nv.HoTenNV
        """

        results = session.execute(text(sql), params).fetchall()

        # ========== THIẾT KẾ EXCEL ĐẸP HƠN ==========
        output = BytesIO()
        
        # Tạo DataFrame từ dữ liệu
        df_data = []
        for ma_nv, ho_ten, phong_ban, tong_ngay, tong_phut in results:
            gio = round((tong_phut or 0) / 60, 2)
            df_data.append({
                'Mã NV': ma_nv,
                'Họ Tên': ho_ten,
                'Phòng Ban': phong_ban,
                'Tổng Ngày Làm': tong_ngay,
                'Tổng Giờ Làm': gio
            })
        
        df = pd.DataFrame(df_data)
        
        # Sử dụng ExcelWriter để format đẹp hơn
        with pd.ExcelWriter(output, engine='xlsxwriter') as writer:
            # Ghi tiêu đề
            workbook = writer.book
            worksheet = workbook.add_worksheet('Báo Cáo')
            
            # Format cho tiêu đề chính
            title_format = workbook.add_format({
                'bold': True,
                'font_size': 16,
                'align': 'center',
                'valign': 'vcenter',
                'fg_color': '#4472C4',
                'font_color': 'white'
            })
            
            # Format cho header bảng
            header_format = workbook.add_format({
                'bold': True,
                'font_size': 11,
                'align': 'center',
                'valign': 'vcenter',
                'fg_color': '#D9E1F2',
                'border': 1
            })
            
            # Format cho dữ liệu
            data_format = workbook.add_format({
                'align': 'center',
                'valign': 'vcenter',
                'border': 1
            })
            
            # Tiêu đề chính
            if filter_type == 'thang':
                title = f'BÁO CÁO CHẤM CÔNG THÁNG {month}/{year}'
            else:
                title = f'BÁO CÁO CHẤM CÔNG NĂM {year}'
            
            worksheet.merge_range('A1:E1', title, title_format)
            worksheet.set_row(0, 30)
            
            # Thông tin bổ sung
            info_format = workbook.add_format({'italic': True, 'font_size': 10})
            worksheet.write('A2', f'Ngày xuất: {datetime.now().strftime("%d/%m/%Y %H:%M")}', info_format)
            
            # Header bảng
            headers = ['Mã NV', 'Họ Tên', 'Phòng Ban', 'Tổng Ngày Làm', 'Tổng Giờ Làm']
            for col_num, header in enumerate(headers):
                worksheet.write(3, col_num, header, header_format)
            
            # Dữ liệu
            for row_num, row_data in enumerate(df_data, start=4):
                worksheet.write(row_num, 0, row_data['Mã NV'], data_format)
                worksheet.write(row_num, 1, row_data['Họ Tên'], data_format)
                worksheet.write(row_num, 2, row_data['Phòng Ban'], data_format)
                worksheet.write(row_num, 3, row_data['Tổng Ngày Làm'], data_format)
                worksheet.write(row_num, 4, row_data['Tổng Giờ Làm'], data_format)
            
            # Tổng cộng
            total_row = len(df_data) + 4
            total_format = workbook.add_format({
                'bold': True,
                'font_size': 11,
                'align': 'center',
                'fg_color': '#FFE699',
                'border': 1
            })
            worksheet.merge_range(total_row, 0, total_row, 2, 'TỔNG CỘNG', total_format)
            worksheet.write(total_row, 3, sum([d['Tổng Ngày Làm'] for d in df_data]), total_format)
            worksheet.write(total_row, 4, sum([d['Tổng Giờ Làm'] for d in df_data]), total_format)
            
            # Căn chỉnh cột
            worksheet.set_column('A:A', 12)
            worksheet.set_column('B:B', 25)
            worksheet.set_column('C:C', 20)
            worksheet.set_column('D:D', 18)
            worksheet.set_column('E:E', 18)

        output.seek(0)

        filename = (
            f"BaoCao_Thang{month}_{year}.xlsx"
            if filter_type == "thang"
            else f"BaoCao_Nam{year}.xlsx"
        )

        return send_file(
            output,
            as_attachment=True,
            download_name=filename,
            mimetype="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )

    except Exception as e:
        traceback.print_exc()
        return jsonify({"success": False, "error": str(e)}), 500
    finally:
        session.close()



# ======================================================
# EXPORT PDF
# ======================================================
@baocao_bp.route('/baocao/pdf', methods=['GET'])
def export_pdf():
    session = SessionLocal()
    try:
        # 1. Lấy tham số (Giữ nguyên logic cũ)
        user_id = request.args.get('user_id')
        role = request.args.get('role')
        filter_type = request.args.get('filter_type')
        month = request.args.get('month')
        year = request.args.get('year')

        if not year:
            return jsonify({"success": False, "error": "Thiếu year"}), 400
        year = int(year)

        # 2. Truy vấn SQL (Giữ nguyên)
        sql = """
        SELECT 
            cc.MaNV,
            nv.HoTenNV,
            ISNULL(pb.TenPB, '') AS PhongBan,
            COUNT(DISTINCT cc.NgayChamCong) AS TongNgayLam,
            ISNULL(SUM(DATEDIFF(MINUTE, cc.GioVao, cc.GioRa)), 0) AS TongPhutLam
        FROM ChamCong cc
        JOIN NhanVien nv ON cc.MaNV = nv.MaNV
        LEFT JOIN PhongBan pb ON nv.MaPB = pb.MaPB
        WHERE 1=1
        """
        params = {"year": year}

        if filter_type == 'thang':
            if not month:
                return jsonify({"success": False, "error": "Thiếu month"}), 400
            month = int(month)
            sql += " AND DATEPART(year, cc.NgayChamCong) = :year AND DATEPART(month, cc.NgayChamCong) = :month"
            params["month"] = month
        elif filter_type == 'nam':
            sql += " AND DATEPART(year, cc.NgayChamCong) = :year"
        else:
            return jsonify({"success": False, "error": "filter_type không hợp lệ"}), 400

        if role == 'nhanvien':
            sql += " AND cc.MaNV = :user_id"
            params["user_id"] = user_id

        sql += " GROUP BY cc.MaNV, nv.HoTenNV, pb.TenPB ORDER BY nv.HoTenNV"

        rows = session.execute(text(sql), params).fetchall()

        # ========== 3. TẠO PDF (PHẦN ĐÃ CHỈNH SỬA) ==========
        buffer = BytesIO()
        doc = SimpleDocTemplate(
            buffer, 
            pagesize=landscape(A4),
            rightMargin=20, leftMargin=20, topMargin=30, bottomMargin=30
        )
        
        styles = getSampleStyleSheet()
        
        # Style cho Tiêu đề (Dùng font đã đăng ký)
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=18,
            textColor=colors.HexColor('#1F4788'),
            spaceAfter=20,
            alignment=TA_CENTER,
            fontName=VIETNAMESE_FONT # Dùng font ArialVN
        )
        
        subtitle_style = ParagraphStyle(
            'CustomSubtitle',
            parent=styles['Normal'],
            fontSize=10,
            textColor=colors.grey,
            spaceAfter=15,
            alignment=TA_CENTER,
            fontName=VIETNAMESE_FONT
        )

        elements = []
        
        # Tên file và Tiêu đề
        if filter_type == 'thang':
            title_text = f"BÁO CÁO CHẤM CÔNG THÁNG {month}/{year}"
            filename = f"BaoCao_Thang{month}_{year}.pdf"
        else:
            title_text = f"BÁO CÁO CHẤM CÔNG NĂM {year}"
            filename = f"BaoCao_Nam{year}.pdf"
        
        elements.append(Paragraph(title_text, title_style))
        elements.append(Paragraph(f"Ngày xuất: {datetime.now().strftime('%d/%m/%Y %H:%M')}", subtitle_style))
        elements.append(Spacer(1, 10))

        # --- XỬ LÝ DỮ LIỆU BẢNG ---
        # Header
        table_data = [["Mã NV", "Họ và Tên", "Phòng Ban", "Số Ngày Làm", "Tổng Giờ"]]
        
        total_days = 0
        total_hours = 0
        
        for r in rows:
            hours = round((r[4] or 0) / 60, 2) # Tính giờ
            total_days += r[3]
            total_hours += hours
            
            table_data.append([
                str(r[0]),      # Mã NV
                str(r[1]),      # Họ tên
                str(r[2]),      # Phòng ban
                str(r[3]),      # Ngày làm
                f"{hours:0.2f}" # Giờ làm (format 2 số thập phân)
            ])
        
        # --- DÒNG TỔNG CỘNG (SỬA LẠI ĐỂ HIỆN RÕ HƠN) ---
        # Cấu trúc: [Label Tổng, (trống), (trống), Tổng Ngày, Tổng Giờ]
        # Chúng ta sẽ merge 3 cột đầu tiên lại để hiển thị chữ "TỔNG CỘNG TOÀN BỘ"
        table_data.append([
            "TỔNG", "", "", 
            str(total_days), 
            f"{total_hours:0.2f}"
        ])

        # Kích thước cột (cân chỉnh lại cho vừa giấy A4 ngang)
        col_widths = [1.0*inch, 2.5*inch, 2.0*inch, 1.2*inch, 1.2*inch]

        table = Table(table_data, colWidths=col_widths)
        
        # Style của bảng
        tbl_style = TableStyle([
            # -- HEADER --
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#4472C4')), # Màu xanh header
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('FONTNAME', (0, 0), (-1, 0), VIETNAMESE_FONT),
            ('FONTSIZE', (0, 0), (-1, 0), 11),
            ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
            ('VALIGN', (0, 0), (-1, 0), 'MIDDLE'),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 8),
            ('TOPPADDING', (0, 0), (-1, 0), 8),
            
            # -- DATA ROWS --
            ('FONTNAME', (0, 1), (-1, -2), VIETNAMESE_FONT),
            ('FONTSIZE', (0, 1), (-1, -2), 10),
            ('ALIGN', (0, 1), (2, -2), 'LEFT'),   # Cột Tên, PB canh trái
            ('ALIGN', (3, 1), (-1, -2), 'CENTER'), # Cột số liệu canh giữa
            ('GRID', (0, 0), (-1, -2), 0.5, colors.grey), # Kẻ lưới mờ
            ('ROWBACKGROUNDS', (0, 1), (-1, -2), [colors.white, colors.whitesmoke]), # Màu xen kẽ
            
            # -- TOTAL ROW (DÒNG MÀU VÀNG CUỐI CÙNG) --
            ('BACKGROUND', (0, -1), (-1, -1), colors.HexColor('#FFE699')), # Màu vàng
            ('FONTNAME', (0, -1), (-1, -1), VIETNAMESE_FONT), # Font Việt
            ('TEXTCOLOR', (0, -1), (-1, -1), colors.black),
            ('FONTSIZE', (0, -1), (-1, -1), 11),
            
            # Merge 3 cột đầu tiên (Mã NV, Tên, PB) thành 1 ô để ghi chữ "TỔNG CỘNG"
            ('SPAN', (0, -1), (2, -1)), 
            ('ALIGN', (0, -1), (2, -1), 'CENTER'), # Canh giữa chữ Tổng cộng
            ('ALIGN', (3, -1), (-1, -1), 'CENTER'), # Số liệu canh giữa
            
            ('GRID', (0, -1), (-1, -1), 1, colors.black), # Kẻ khung đậm cho dòng tổng
        ])

        table.setStyle(tbl_style)
        elements.append(table)
        
        # Footer
        elements.append(Spacer(1, 30))
        footer_style = ParagraphStyle(
            'Footer',
            parent=styles['Normal'],
            fontSize=9,
            textColor=colors.grey,
            alignment=TA_CENTER,
            fontName=VIETNAMESE_FONT
        )
        elements.append(Paragraph(f"Báo cáo được xuất từ hệ thống - Tổng số nhân viên: {len(rows)}", footer_style))

        doc.build(elements)
        buffer.seek(0)

        return send_file(
            buffer, 
            as_attachment=True, 
            download_name=filename,
            mimetype='application/pdf'
        )

    except Exception as e:
        traceback.print_exc()
        return jsonify({"success": False, "error": str(e)}), 500
    finally:
        session.close()
