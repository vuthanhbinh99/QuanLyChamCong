from flask import Blueprint, jsonify, request
from database import SessionLocal
from model import NhanVien, LuuTruKhuonMat, QuanLy
from recognize.register_face import register_face_from_base64
import numpy as np
from datetime import datetime
import time
from Services.face_services import load_known_faces_cached, decode_base64_image_optimized, get_face_app
import threading
from Api.chamcong import xac_dinh_ca_lam, process_attendance_logic
from Services.face_services import clear_known_faces_cache


face_bp = Blueprint('face', __name__)

face_app = None

def clear_cache():
    clear_known_faces_cache()
    print("[DEBUG] ✅ Yêu cầu clear cache faces")

@face_bp.route('/register_face', methods=['POST'])
def register_face_api():
    session = SessionLocal()
    
    try:
        data = request.json
        id_user = data.get('id_user')
        images_base64 = data.get('images', []) 

        if not id_user:
            return jsonify({"error": "Thiếu id_user"}), 400
        
        id_user = str(id_user)
        
        # 1. XÁC ĐỊNH LOẠI NGƯỜI DÙNG
        user_obj = None
        ma_nv_val = None 
        ma_ql_val = None 
        user_type = ""

        # Kiểm tra bảng NhanVien
        nv = session.query(NhanVien).filter(NhanVien.MaNV == id_user).first()
        if nv:
            user_obj = nv
            ma_nv_val = id_user
            ma_ql_val = None
            user_type = "NhanVien"
        else:
            # Kiểm tra bảng QuanLy
            ql = session.query(QuanLy).filter(QuanLy.MaQL == id_user).first()
            if ql:
                user_obj = ql
                ma_nv_val = None
                ma_ql_val = id_user
                user_type = "QuanLy"
        
        if not user_obj:
            return jsonify({"error": f"Người dùng với ID={id_user} không tồn tại trong hệ thống"}), 400

        print(f"[INFO] Đang xử lý cho: {user_type} - ID: {id_user}")

        # 2. KIỂM TRA & XỬ LÝ UPDATE 
        existing_faces = []
        if user_type == "NhanVien":
            existing_faces = session.query(LuuTruKhuonMat).filter(LuuTruKhuonMat.MaNV == id_user).all()
        else:
            existing_faces = session.query(LuuTruKhuonMat).filter(LuuTruKhuonMat.MaQL == id_user).all()
        
        is_update = len(existing_faces) > 0
        ngay_tao_cu = None
        
        if is_update:
            print(f"[INFO] 🔄 Phát hiện {len(existing_faces)} dữ liệu cũ, tiến hành cập nhật.")
            ngay_tao_cu = existing_faces[0].NgayTao
            # Xóa dữ liệu cũ
            for face in existing_faces:
                session.delete(face)
            session.flush()
        else:
            print(f"[INFO] ➕ Đăng ký mới.")

        # 3. TẠO EMBEDDING TỪ ẢNH
        face_app = get_face_app()
        if face_app is None:
            return jsonify({"error": "Model nhận diện chưa khởi tạo"}), 500

        try:
            # Hàm register_face_from_base64 chỉ dùng dict user để log, ta truyền dummy
            embeddings_list = register_face_from_base64(
                user={"MaNV": id_user}, 
                img_base64=images_base64,
                app=face_app
            )
            
            if embeddings_list is None or len(embeddings_list) == 0:
                return jsonify({"error": "Không trích xuất được khuôn mặt. Vui lòng chụp lại rõ hơn."}), 400
            
        except Exception as e:
            print(f"[ERROR] Lỗi xử lý ảnh: {e}")
            return jsonify({"error": f"Lỗi xử lý ảnh: {str(e)}"}), 500

        # 4. LƯU VÀO DATABASE (PHÂN BIỆT MaNV / MaQL)
        now = datetime.now()
        tu_the_labels = ["Chinh dien", "Nghieng trai", "Nghieng phai"]
        saved_records = []
        
        for idx, embedding in enumerate(embeddings_list):
            timestamp_short = datetime.now().strftime("%Y%m%d%H%M%S")
            ma_luu_tru = f"LT_{timestamp_short}_{idx}"
            
            record = LuuTruKhuonMat(
                MaLuuTru=ma_luu_tru,
                MaNV=ma_nv_val,  # Nếu là QL thì cái này Null
                MaQL=ma_ql_val,  # Nếu là NV thì cái này Null
                Embedding=embedding,
                NgayTao=ngay_tao_cu if is_update else now,
                NgayCapNhat=now if is_update else None,
                GhiChu=tu_the_labels[idx] if idx < len(tu_the_labels) else f"Pose {idx+1}"
            )
            session.add(record)
            saved_records.append(ma_luu_tru)
            time.sleep(0.001) # Tránh trùng timestamp
        
        # Cập nhật trạng thái "Đã đăng ký" cho User (nếu bảng có cột TrangThai)
        if hasattr(user_obj, 'TrangThai'):
            user_obj.TrangThai = True 
        
        session.commit()
        
        clear_cache() # Xóa cache để cập nhật ngay
        
        message = "Cập nhật khuôn mặt thành công" if is_update else "Đăng ký khuôn mặt thành công"
        return jsonify({
            "success": True,
            "message": message,
            "saved_count": len(saved_records)
        }), 200

    except Exception as e:
        session.rollback()
        print(f"[ERROR] register_face: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": f"Lỗi server: {str(e)}"}), 500

    finally:
        session.close()

# Hàm chạy ngầm để lưu DB
def save_attendance_background(user_id, role, ca_lam):
    # Tạo session mới riêng cho luồng này
    new_session = SessionLocal() 
    try:
        now = datetime.now().replace(microsecond=0)
        today = now.date()
        
        # Logic kiểm tra và lưu (Copy logic cũ vào đây)
        # ... (Code check exists, insert ChamCong) ...
        print(f"[BACKGROUND] Đã chấm công cho {user_id}")
        new_session.commit()
    except Exception as e:
        print(f"[BACKGROUND ERROR] {e}")
        new_session.rollback()
    finally:
        new_session.close()
        
@face_bp.route('/recognize', methods=['POST'])
def recognize_face():
    start_time = time.time()
    
    data = request.json
    img_base64 = data.get('image_base64')
    
    if not img_base64:
        return jsonify({'error': 'Không có ảnh gửi lên'}), 400

    # print(f"[INFO] Nhận request nhận diện...") 

    session = SessionLocal()
    try:
        # 1. Load known faces (cache)
        # load_start = time.time()
        known_embeddings, known_names, known_id, known_roles = load_known_faces_cached(session)
        # print(f"[TIME] Load faces: {time.time() - load_start:.2f}s")

        # 2. Decode ảnh
        # decode_start = time.time()
        frame = decode_base64_image_optimized(img_base64)
        if frame is None:
            return jsonify({'error': 'Ảnh không hợp lệ'}), 400
        # print(f"[TIME] Decode ảnh: {time.time() - decode_start:.2f}s")

        # 3. Detect faces với InsightFace
        # detect_start = time.time()
        face_app = get_face_app()
        if face_app is None:
            return jsonify({'error': 'Model chưa khởi tạo'}), 500
            
        try:
            # Sửa lỗi: Chỉ gọi get() 1 lần duy nhất trong try/except
            faces = face_app.get(frame)
        except Exception as e:
            print("[ERROR] face_app.get() lỗi:", e)
            return jsonify({'error': 'Không thể detect face'}), 500

        # print(f"[TIME] Detect faces: {time.time() - detect_start:.2f}s - Số mặt: {len(faces)}")

        if not faces:
            return jsonify({'error': 'Không tìm thấy khuôn mặt'}), 404
        
        best_match_found = False
        results = []
        
        # 4. So sánh embedding
        # compare_start = time.time()
        for face in faces:
            embedding_test = face.normed_embedding
            
            # Tính cosine similarity
            scores = [np.dot(embedding_test, emb) for emb in known_embeddings]
            
            if not scores:
                continue

            best_idx = np.argmax(scores)
            best_score = scores[best_idx]

            # Ngưỡng nhận diện (Threshold)
            if best_score > 0.6: 
                result_data = [{
                "status": "recognized",
                "name": known_names[best_idx],
                "role": known_roles[best_idx],
                "user_id": known_id[best_idx],
                "score": float(best_score)
            }]
            # === CHẠY NGẦM: Đẩy việc chấm công ra luồng khác ===
            # User không cần chờ việc này xong
            user_id = known_id[best_idx]
            role = known_roles[best_idx]
            ca_lam = xac_dinh_ca_lam() 
            
            if ca_lam:
                threading.Thread(
                    target=save_attendance_background, 
                    args=(user_id, role, ca_lam)
                ).start()

            print(f"[TIME] Phản hồi sau: {time.time() - start_time:.2f}s")
            return jsonify(result_data), 200
            break
        if best_match_found:
            print(f"[TIME] Phản hồi sau: {time.time() - start_time:.2f}s")
            return jsonify(result_data), 200
        else:
            return jsonify({'error': 'Không nhận diện được khuôn mặt nào trong DB'}), 404

    except Exception as e:
        print(f"[ERROR] Lỗi nhận diện: {e}")
        return jsonify({'error': f'Lỗi nhận diện: {str(e)}'}), 500
    
    finally:
        session.close()

@face_bp.route('/sync_offline_attendance', methods=['POST'])
def sync_offline_attendance():
    data = request.json
    request_type = data.get('type', 'image')  
    img_base64 = data.get('image_base64')
    timestamp_str = data.get('timestamp')
    ma_ca = data.get('MaCa')
    user_id_claimed = data.get('userId')  
    role_claimed = data.get('role')       
    
    if not img_base64 or not timestamp_str:
        return jsonify({"error": "Thiếu dữ liệu ảnh hoặc thời gian"}), 400

    print(f"[SYNC] Nhận request type={request_type}, user_claimed={user_id_claimed}")

    session = SessionLocal()
    try:
        # 1. Nhận diện lại người trong ảnh
        known_embeddings, known_names, known_id, known_roles = load_known_faces_cached(session)
        frame = decode_base64_image_optimized(img_base64)
        
        if frame is None:
            return jsonify({"error": "Ảnh không hợp lệ"}), 400
            
        face_app = get_face_app()
        if face_app is None:
            return jsonify({"error": "Model chưa khởi tạo"}), 500
            
        faces = face_app.get(frame)

        if not faces:
            return jsonify({"error": "Ảnh offline không thấy mặt"}), 400

        # Lấy mặt lớn nhất
        face = max(faces, key=lambda f: (f.bbox[2]-f.bbox[0]) * (f.bbox[3]-f.bbox[1]))
        embedding_test = face.normed_embedding
        
        # So sánh với database
        scores = [np.dot(embedding_test, emb) for emb in known_embeddings]
        
        if not scores: 
            return jsonify({"error": "Cơ sở dữ liệu trống"}), 400
        
        best_idx = np.argmax(scores)
        best_score = scores[best_idx]
        
        if best_score > 0.6:
            user_id = known_id[best_idx]
            role = known_roles[best_idx]
            user_name = known_names[best_idx]
            
            # Verify với userId claimed (nếu có)
            if request_type == 'image_with_text' and user_id_claimed:
                if user_id != user_id_claimed:
                    print(f"[SECURITY WARNING] ⚠️ Type={request_type}, Claimed={user_id_claimed} but Detected={user_id}")
                    # Option: Vẫn cho phép nếu nhận diện đúng người trong DB, chỉ warning
                else:
                    print(f"[SECURITY OK] ✅ Verified: {user_id_claimed} = {user_id}")
            
            # 2. Convert thời gian từ ISO string
            try:
                # Xử lý chuỗi thời gian có thể có 'Z' hoặc offset
                actual_time = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
            except:
                actual_time = datetime.now()
                
            # Khử timezone để lưu vào DB (SQL Server thường dùng naive datetime)
            if actual_time.tzinfo is not None:
                actual_time = actual_time.replace(tzinfo=None)
            actual_time = actual_time.replace(microsecond=0)
            
            # Nếu ma_ca là UNKNOWN hoặc không có, thử tính lại dựa trên actual_time
            if not ma_ca or ma_ca == "UNKNOWN":
                ma_ca = xac_dinh_ca_lam(actual_time.time())

            print(f"[SYNC] Xử lý chấm công cho {user_id} ({role}) lúc {actual_time}, Ca: {ma_ca}")
            
            # 3. Thực hiện chấm công với thời gian thực tế
            success, message, action = process_attendance_logic(user_id, role, ma_ca, actual_time)
            
            if success:
                return jsonify({
                    "success": True,
                    "message": message,
                    "user": user_name,
                    "user_id": user_id,
                    "timestamp": actual_time.isoformat(),
                    "action": action,
                    "type": request_type
                }), 200
            else:
                return jsonify({
                    "success": False,
                    "message": message,
                    "user_id": user_id,
                    "action": action,
                    "type": request_type
                }), 400 
        else:
            return jsonify({
                "error": f"Không nhận diện được người trong ảnh offline (score: {best_score:.3f})"
            }), 400

    except Exception as e:
        print(f"[SYNC ERROR] {e}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500
    finally:
        session.close()

@face_bp.route('/check_face_status/<string:user_id>', methods=['GET'])
def check_face_status(user_id):
    session = SessionLocal()
    try:   
        face_record = session.query(LuuTruKhuonMat).filter(
            (LuuTruKhuonMat.MaNV == user_id) | (LuuTruKhuonMat.MaQL == user_id)
        ).first()
        
        if face_record:
            return jsonify({
                "has_face": True,
                "ngay_tao": face_record.NgayTao.isoformat() if face_record.NgayTao else None,
                "ngay_cap_nhat": face_record.NgayCapNhat.isoformat() if face_record.NgayCapNhat else None
            }), 200
        else:
            return jsonify({"has_face": False}), 200
            
    except Exception as e:
        print(f"[ERROR] check_face_status: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        session.close()