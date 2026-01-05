from flask import Blueprint, jsonify
from model import CaLam
from database import SessionLocal

calam_bp = Blueprint('calam',__name__)

@calam_bp.route('/calam', methods=['GET'])
def get_all_ca_lam():
    session = SessionLocal()
    try:
        CaLamList = session.query(CaLam).all()
        result =[]
        for calam in  CaLamList:
            result.append({
                "maCa": calam.MaCa,
                "tenCa": calam.TenCa,
                "gioBatDau": calam.GioBatDau.strftime("%H:%M") if calam.GioBatDau else "",
                "gioKetThuc": calam.GioKetThuc.strftime("%H:%M") if calam.GioKetThuc else "",
                "ghiChu": calam.GhiChu or ""
            })
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": f"Lỗi lấy danh sách ca làm: {str(e)}"}), 500
    finally:
        session.close()

@calam_bp.route('/calam/<string:ma_ca>', methods=['GET'])
def get_ca_lam_by_id(ma_ca):
    session = SessionLocal()
    try:
        ca = session.query(CaLam).filter(CaLam.MaCa == ma_ca).first()
        
        if not ca:
            return jsonify({"error": "không tìm thấy ca làm" }), 404
        
        result = {
            "maCa": ca.MaCa,
            "tenCa": ca.TenCa,
            "gioBatDau": ca.GioBatDau.strftime("%H:%M") if ca.GioBatDau else "",
            "gioKetThuc": ca.GioKetThuc.strftime("%H:%M") if ca.GioKetThuc else "",
            "ghiChu": ca.GhiChu or ""
        }
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": f"Lỗi lấy thông tin ca làm: {str(e)}"}), 500
    finally:
        session.close()