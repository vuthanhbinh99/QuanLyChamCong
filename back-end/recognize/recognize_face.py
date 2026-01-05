import sys, os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import cv2
import numpy as np
from datetime import datetime, time
from insightface.app import FaceAnalysis
from PIL import ImageFont, ImageDraw, Image
from database import SessionLocal
from sqlalchemy.orm import Session
from model import LuuTruKhuonMat, NhanVien, ChamCong, QuanLy

# --- Hàm vẽ chữ tiếng Việt ---
def draw_vietnamese_text(frame, text, position, font_path="C:/Windows/Fonts/arial.ttf", font_size=24, color=(255, 255, 0)):
    img_pil = Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
    draw = ImageDraw.Draw(img_pil)
    font = ImageFont.truetype(font_path, font_size)
    draw.text(position, text, font=font, fill=color[::-1])
    return cv2.cvtColor(np.array(img_pil), cv2.COLOR_RGB2BGR)

# --- Mở camera ---
def open_camera():
    print("[INFO] Đang mở camera...")
    for i in range(5):
        cap = cv2.VideoCapture(i)
        if cap.isOpened():
            print(f"[INFO] Mở camera thành công (index={i})")
            cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
            cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
            cap.set(cv2.CAP_PROP_FPS, 15)
            return cap
        cap.release()
    raise RuntimeError("Không thể mở camera nào!")

# --- Xác định ca làm ---
def xac_dinh_ca_lam(): 
    now = datetime.now().time()
    if time(8,0) <= now <= time(12,0):
        return "CA001"
    elif time(13,0) <= now <= time(17,30):
        return "CA002"
    elif now >= time(19,0)  or now < time(0,0,0):
        return "CA003"
    else:
        return None

# --- Load danh sách khuôn mặt đã đăng ký ---
def load_known_faces():
    session: Session = SessionLocal()
    known_embeddings, known_names, known_id, known_roles = [], [], [], []

    data_nv = session.query(LuuTruKhuonMat, NhanVien.HoTenNV, NhanVien.MaNV)\
                      .join(NhanVien, LuuTruKhuonMat.MaNV==NhanVien.MaNV).all()
    for luu_tru, hoten, manv in data_nv:
        if luu_tru.Embedding:
            known_embeddings.append(np.frombuffer(luu_tru.Embedding, dtype=np.float32))
            known_names.append(hoten)
            known_id.append(manv)
            known_roles.append("NhanVien") 


    data_ql = session.query(LuuTruKhuonMat, QuanLy.HoTenQL, QuanLy.MaQL)\
                      .join(QuanLy, LuuTruKhuonMat.MaQL==QuanLy.MaQL).all()
    for luu_tru, hoten, maq in data_ql:
        if luu_tru.Embedding:
            known_embeddings.append(np.frombuffer(luu_tru.Embedding, dtype=np.float32))
            known_names.append(hoten)
            known_id.append(maq)
            known_roles.append("QuanLy") 

    # Quản lý
    data_ql = session.query(LuuTruKhuonMat, QuanLy.HoTenQL, QuanLy.MaQL)\
                     .join(QuanLy, LuuTruKhuonMat.MaQL==QuanLy.MaQL).all()
    for luu_tru, hoten, maq in data_ql:
        if luu_tru.Embedding:
            known_embeddings.append(np.frombuffer(luu_tru.Embedding, dtype=np.float32))
            known_names.append(hoten)
            known_id.append(maq)
            known_roles.append("QuanLy")

    session.close()
    return known_embeddings, known_names, known_id, known_roles

known_embeddings, known_names, known_id, known_roles = load_known_faces()
print(f"[INFO] Đã tải {len(known_embeddings)} khuôn mặt đã đăng ký.")

# --- Khởi tạo InsightFace ---
app = FaceAnalysis(name='buffalo_s', providers=['CPUExecutionProvider'])
app.prepare(ctx_id=0, det_size=(640,640))
print("[INFO] InsightFace sẵn sàng.")

# --- Nhận diện trên 1 frame ---
def recognize_frame(frame):
    now = datetime.now()
    ca_lam = xac_dinh_ca_lam()
    
    # Nếu không thuộc ca nào thì gán tạm hoặc bỏ qua (tùy logic của bạn)
    if not ca_lam: ca_lam = "CA001" 

    session: Session = SessionLocal()
    results = []

    try:
        faces = app.get(frame)
        for face in faces:
            # ... (Phần vẽ khung, check kích thước giữ nguyên) ...
            x1, y1, x2, y2 = face.bbox.astype(int)
            # (Code vẽ khung cắt ảnh giữ nguyên của bạn...)

            # So sánh embedding
            embedding_test = face.normed_embedding
            scores = [np.dot(embedding_test, emb) for emb in known_embeddings]
            
            if not scores: continue 

            best_idx = np.argmax(scores)
            best_score = scores[best_idx]

            if best_score > 0.6: 
                name = known_names[best_idx]
                user_id = known_id[best_idx]
                role = known_roles[best_idx] # <--- LẤY VAI TRÒ (QuanLy hay NhanVien)
                
                # Vẽ tên lên màn hình
                time_str = now.strftime("%H:%M:%S")
                cv2.rectangle(frame,(x1,y1),(x2,y2),(0,255,0),2)
                frame = draw_vietnamese_text(frame, f"{name} ({role})", (x1,y1-30))

                # =========================================================
                # LOGIC CHẤM CÔNG PHÂN BIỆT NV VÀ QL
                # =========================================================
                
                # 1. Tạo query tìm bản ghi trong ngày
                query = session.query(ChamCong).filter(
                    ChamCong.NgayChamCong == now.date(),
                    ChamCong.MaCa == ca_lam
                )
                
                # Filter theo đúng cột dựa trên Role
                if role == "NhanVien":
                    query = query.filter(ChamCong.MaNV == user_id)
                else: # QuanLy
                    query = query.filter(ChamCong.MaQL == user_id)
                
                exists = query.first()

                if not exists:
                    # --- CHẤM VÀO ---
                    print(f"[CHECK-IN] {role}: {name} - {user_id}")
                    
                    chamcong = ChamCong(
                        MaChamCong=f"CC_{int(now.timestamp())}_{user_id}",
                        
                        # LOGIC QUAN TRỌNG Ở ĐÂY:
                        MaNV = user_id if role == "NhanVien" else None,
                        MaQL = user_id if role == "QuanLy" else None,
                        
                        MaCa=ca_lam,
                        NgayChamCong=now.date(),
                        GioVao=now.time().replace(microsecond=0),
                        GioRa=None,
                        TrangThai="Đã chấm công vào",
                        DiaDiemChamCong="Camera AI"
                    )
                    session.add(chamcong)
                    session.commit()
                else:
                    # --- CHẤM RA ---
                    if exists.GioRa is None:
                        # (Tùy chọn: Thêm logic kiểm tra thời gian > 1 phút mới cho ra)
                        exists.GioRa = now.time().replace(microsecond=0)
                        exists.TrangThai = "Đã chấm công ra"
                        session.commit()
                        print(f"[CHECK-OUT] {role}: {name}")

                results.append({"name": name, "id": user_id, "score": best_score})
            else:
                # Người lạ
                cv2.rectangle(frame,(x1,y1),(x2,y2),(0,255,255),2)
                frame = draw_vietnamese_text(frame, "Người lạ", (x1,y1-30))

    except Exception as e:
        print(f"[ERROR] {e}")
        # import traceback
        # traceback.print_exc()
    finally:
        session.close()
        
    return frame, results

# --- Main ---
if __name__ == "__main__":
    cap = open_camera()
    print("[INFO] Bắt đầu nhận diện khuôn mặt từ camera...")

    while True:
        ret, frame = cap.read()
        if not ret:
            print("[ERROR] Không đọc được frame!")
            break

        frame, results = recognize_frame(frame)
        cv2.imshow("Face Recognition", frame)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()
    print("[INFO] Đã tắt camera và kết thúc chương trình.")
