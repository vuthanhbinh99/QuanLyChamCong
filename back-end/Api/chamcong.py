import uuid
from flask import Blueprint, jsonify, request
from sqlalchemy import or_
from model import ChamCong, NhanVien, QuanLy
from datetime import datetime
from database import SessionLocal

chamcong_bp = Blueprint('chamcong',__name__)

def xac_dinh_ca_lam(time_check=None):
    now = time_check if time_check else datetime.now().time()
    
    ca_sang = datetime.strptime("08:00", "%H:%M").time()
    ca_sang_end = datetime.strptime("12:00", "%H:%M").time()
    ca_chieu = datetime.strptime("13:30", "%H:%M").time()
    ca_chieu_end = datetime.strptime("17:30", "%H:%M").time()
    ca_toi = datetime.strptime("18:00", "%H:%M").time()
    ca_toi_end = datetime.strptime("07:30", "%H:%M").time()
    
    if ca_sang <= now <= ca_sang_end:
        return "CA001"
    elif ca_chieu <= now <= ca_chieu_end:
        return "CA002"
    elif now >= ca_toi or now <= ca_toi_end:
        return "CA003"
    else:
        return None 
    
def safe_strftime(dt, fmt="%Y-%m-%d"):
    return dt.strftime(fmt) if dt else ""

def process_attendance_logic(user_id, role, ca_lam, timestamp_input=None):
    session = SessionLocal()
    try:
        # Ưu tiên timestamp input (cho sync offline)
        current_dt = timestamp_input if timestamp_input else datetime.now()
        
        # Khử timezone
        if current_dt.tzinfo is not None:
            current_dt = current_dt.replace(tzinfo=None)
            
        today = current_dt.date()
        current_time = current_dt.time().replace(microsecond=0)
        
        ma_nv = user_id if role == "NhanVien" else None
        ma_ql = user_id if role == "QuanLy" else None

        # Nếu ca_lam là None (do sync gửi lên UNKNOWN và tính lại vẫn None), gán đại CA003 hoặc xử lý riêng
        if not ca_lam:
             # Ở đây ta trả về False để báo lỗi
             return (False, f"Thời gian {current_time} không thuộc ca làm việc nào.", "Ngoài giờ")

        # Kiểm tra bản ghi
        exists = session.query(ChamCong).filter(
            or_(ChamCong.MaNV == user_id, ChamCong.MaQL == user_id),
            ChamCong.NgayChamCong == today,
            ChamCong.MaCa == ca_lam
        ).first()

        if not exists:
            # --- CHẤM VÀO ---
            new_cc = ChamCong(
                MaChamCong=f"CC_{int(current_dt.timestamp())}_{uuid.uuid4().hex[:6]}",
                MaNV=ma_nv,
                MaQL=ma_ql,
                MaCa=ca_lam,
                NgayChamCong=today,
                GioVao=current_time,
                TrangThai="Đã chấm công vào (Offline Sync)" if timestamp_input else "Đã chấm công vào",
                DiaDiemChamCong="Văn phòng"
            )
            session.add(new_cc)
            session.commit()
            print(f"[ATTENDANCE] ✅ Chấm công VÀO: {user_id} lúc {current_time}")
            return (True, f"Chấm công VÀO thành công lúc {current_time}", "Chấm công vào")
        else:
            # --- CHẤM RA ---
            if exists.GioRa is None:
                dt_vao = datetime.combine(today, exists.GioVao)
                time_diff = (current_dt - dt_vao).total_seconds()
                
                if time_diff > 300:  # 5 phút
                    exists.GioRa = current_time
                    exists.TrangThai = "Đã chấm công ra (Offline Sync)" if timestamp_input else "Đã chấm công ra"
                    session.commit()
                    print(f"[ATTENDANCE] ✅ Chấm công RA: {user_id} lúc {current_time}")
                    return (True, f"Chấm công RA thành công lúc {current_time}", "Chấm công ra")
                else:
                    minutes_left = int((300 - time_diff) / 60) + 1
                    print(f"[ATTENDANCE] ⚠️ Chấm RA quá sớm: {user_id}")
                    return (False, f"Chưa đủ 5 phút! Vui lòng đợi thêm {minutes_left} phút.", "Chấm RA quá sớm")
            else:
                print(f"[ATTENDANCE] ⚠️ Đã chấm công đủ ca: {user_id}")
                return (False, f"Đã chấm công đủ ca (Vào: {exists.GioVao}, Ra: {exists.GioRa})", "Đã chấm đủ ca")           
    except Exception as e:
        print(f"[ATTENDANCE ERROR] {e}")
        session.rollback()
        return (False, f"Lỗi hệ thống: {str(e)}", "Error")
    finally:
        session.close()
        
@chamcong_bp.route('/chamcong', methods=['POST'])
def cham_cong():
    data = request.json
    
    user_input = data.get('userId') or data.get('MaNV') or data.get('MaQL')
    maca = data.get('MaCa')
    diadiem = data.get('DiaDiemChamCong', 'Văn phòng')

    if not user_input:
        return jsonify({"error": "Thiếu ID người dùng"}), 400
    
    if not maca:
        maca = xac_dinh_ca_lam() 
        
    if maca is None:
        return jsonify({
            "message": "Đang là giờ nghỉ trưa hoặc ngoài giờ làm việc. Vui lòng quay lại chấm công sau!", 
            "code": "BREAK_TIME",
            "action": "Ngoài giờ làm"
        }), 400
        
    session = SessionLocal()
    now = datetime.now()
    today = now.date()
    
    try:
        ma_nv_to_save = None
        ma_ql_to_save = None
        
        nv = session.query(NhanVien).filter(NhanVien.MaNV == user_input).first()
        if nv:
            ma_nv_to_save = user_input 
        else:
            ql = session.query(QuanLy).filter(QuanLy.MaQL == user_input).first()
            if ql:
                ma_ql_to_save = user_input 
            else:
                return jsonify({"error": f"ID {user_input} không tồn tại trong hệ thống"}), 404

        # Kiểm tra đã chấm công chưa
        exists = session.query(ChamCong).filter(
            or_(ChamCong.MaNV == user_input, ChamCong.MaQL == user_input),
            ChamCong.NgayChamCong == today,
            ChamCong.MaCa == maca
        ).first()

        if not exists:
            # --- CHẤM VÀO ---
            new_cc = ChamCong(
                MaChamCong=f"CC_{int(datetime.now().timestamp())}_{uuid.uuid4().hex[:6]}",
                MaNV=ma_nv_to_save, 
                MaQL=ma_ql_to_save,
                MaCa=maca,
                NgayChamCong=today,
                GioVao=now.time().replace(microsecond=0),
                GioRa=None,
                TrangThai="Đã chấm công vào",
                DiaDiemChamCong=diadiem,
            )
            session.add(new_cc)
            session.commit()
            return jsonify({
                "message": "Chấm công vào thành công", 
                "GioVao": str(new_cc.GioVao),
                "action": "Chấm công vào"
            }), 201
        else:
            # --- CHẤM RA ---
            if exists.GioRa is None:
                dt_vao = datetime.combine(today, exists.GioVao)
                time_diff = (now - dt_vao).total_seconds()
                
                if time_diff > 300:  # 5 phút
                    exists.GioRa = now.time().replace(microsecond=0)
                    exists.TrangThai = "Đã chấm công ra"
                    session.commit()
                    return jsonify({
                        "message": "Chấm công ra thành công", 
                        "GioRa": str(exists.GioRa),
                        "action": "Chấm công ra"
                    }), 200
                else:
                    minutes_left = int((300 - time_diff) / 60) + 1
                    return jsonify({
                        "message": f"Chưa đủ 5 phút! Vui lòng đợi thêm {minutes_left} phút nữa.",
                        "action": "Chấm RA quá sớm",
                        "seconds_left": int(300 - time_diff)
                    }), 400
            else:
                return jsonify({
                    "message": f"Đã chấm công đủ ca này rồi (Vào: {exists.GioVao}, Ra: {exists.GioRa})",
                    "action": "Đã chấm đủ ca"
                }), 400

    except Exception as e:
        session.rollback()
        print(f"Error: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        session.close()
        
@chamcong_bp.route('/chamcong/<string:user_id>', methods=['GET'])
def get_cham_cong_by_user(user_id):
    session = SessionLocal()
    try:
        chamcong_list = session.query(ChamCong)\
            .filter(or_(ChamCong.MaNV == user_id, ChamCong.MaQL == user_id))\
            .order_by(ChamCong.NgayChamCong.desc())\
            .all()

        result = []
        for cc in chamcong_list:
            real_id = cc.MaNV if cc.MaNV else cc.MaQL
            
            result.append({
                "id": cc.MaChamCong,
                "userId": real_id,
                "ngayChamCong": safe_strftime(cc.NgayChamCong, "%Y-%m-%d"),
                "gioVao": safe_strftime(cc.GioVao, "%H:%M:%S"),
                "gioRa": safe_strftime(cc.GioRa, "%H:%M:%S"),
                "trangThai": cc.TrangThai,
                "diaDiemChamCong": cc.DiaDiemChamCong or "",
                "maCa": cc.MaCa
            })

        return jsonify(result), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        session.close()
        
        