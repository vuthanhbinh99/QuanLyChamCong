from io import BytesIO
import sys, os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import cv2
import numpy as np
from PIL import ImageFont, ImageDraw, Image
import time
import base64
from insightface.app import FaceAnalysis
from sqlalchemy.orm import Session
from model import TaiKhoan, LuuTruKhuonMat, NhanVien
from insightface.app import FaceAnalysis
from datetime import datetime
from database import SessionLocal
from Services.generate_id import get_new_employee_id
import uuid

# Khởi tạo FaceAnalysis
face_app = FaceAnalysis(name='buffalo_s', providers=['CPUExecutionProvider'])
face_app.prepare(ctx_id=0, det_size=(320, 320))

# --- Cấu hình ---
STABLE_TIME_SECONDS = 2.0
MOVEMENT_THRESHOLD_PX = 5.0
CENTER_WINDOW = 20

# --- Hàm vẽ tiếng Việt ---
def draw_vietnamese_text(frame, text, position, font_path="C:/Windows/Fonts/arial.ttf", font_size=24, color=(255, 255, 0)):
    """Vẽ chữ tiếng Việt có dấu lên frame."""
    img_pil = Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
    draw = ImageDraw.Draw(img_pil)
    font = ImageFont.truetype(font_path, font_size)
    draw.text(position, text, font=font, fill=color[::-1])
    return cv2.cvtColor(np.array(img_pil), cv2.COLOR_RGB2BGR)

# --- Hàm tiện ích ---
# def open_camera():
#     print("[INFO] Đang mở camera...")
#     for i in range(5):
#         cap = cv2.VideoCapture(i)
#         if cap.isOpened():
#             print(f"[INFO] Mở camera thành công (index={i})")
#             cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
#             cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
#             cap.set(cv2.CAP_PROP_FPS, 15)
#             return cap
#         cap.release()
#     raise RuntimeError("Không thể mở camera nào! Hãy kiểm tra thiết bị.")

def get_current_user():
    session: Session = SessionLocal()
    try:
        taikhoan = session.query(TaiKhoan).filter(TaiKhoan.TrangThai == False).first()
        if not taikhoan:
            raise ValueError("Không tìm thấy tài khoản .")
        if taikhoan.VaiTro =="Nhân Viên":
            return {
                "VaiTro": "Nhân Viên",
                "MaNV": taikhoan.MaNV,
                "MaQL": None
            }
        elif taikhoan.VaiTro =="Quản Lý":
            return {
                "VaiTro": "Quản Lý",
                "MaNV": None,
                "MaQL": taikhoan.MaQL
            }
        else:
            raise ValueError("Vai trò người dùng không hợp lệ.")
    finally:
        session.close()
def get_face_center_and_kps(face):
    bbox = face.bbox.astype(int)
    x1, y1, x2, y2 = bbox
    center = ((x1 + x2) / 2.0, (y1 + y2) / 2.0)
    keypoints = getattr(face, 'keypoints', None)
    return center, keypoints

def is_stable(centers_window, threshold_px=MOVEMENT_THRESHOLD_PX):
    if len(centers_window) < 2:
        return False
    pts = np.array(centers_window)
    dx = pts[:, 0].max() - pts[:, 0].min()
    dy = pts[:, 1].max() - pts[:, 1].min()
    return np.sqrt(dx * dx + dy * dy) <= threshold_px

# --- Chụp khung ổn định ---
# def capture_stable_frame(cap, app, prompt_text, stable_time=STABLE_TIME_SECONDS):
#     print(f"\n---- {prompt_text} ----")
#     print(f"Vui lòng giữ yên trong {stable_time} giây...")

#     centers = []
#     stable_start = None
#     stable_frames = []
#     last_face = None

#     window_name = "Đăng ký khuôn mặt"
#     cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)
#     cv2.resizeWindow(window_name, 640, 480)

#     while True:
#         ret, frame = cap.read()
#         if not ret:
#             raise RuntimeError("Không thể đọc từ camera.")
        
#         display_frame = frame.copy()
#         faces = app.get(frame)

#         if faces and len(faces) > 0:
#             face = faces[0]
#             center, _ = get_face_center_and_kps(face)
#             last_face = face
#             centers.append(center)
#             if len(centers) > CENTER_WINDOW:
#                 centers.pop(0)
#             bbox = face.bbox.astype(int)
#             cv2.rectangle(display_frame, (bbox[0], bbox[1]), (bbox[2], bbox[3]), (0, 255, 0), 2)
#         else:
#             centers.clear()
#             stable_start = None
#             stable_frames.clear()
#             display_frame = draw_vietnamese_text(display_frame, "Không tìm thấy khuôn mặt - di chuyển gần hơn", (20, 30), font_size=22, color=(0, 0, 255))

#         # Hiển thị hướng dẫn
#         display_frame = draw_vietnamese_text(display_frame, prompt_text, (20, 60), font_size=22, color=(255, 255, 0))

#         if is_stable(centers):
#             if stable_start is None:
#                 stable_start = time.time()
#                 stable_frames = []
#             elapsed = time.time() - stable_start
#             stable_frames.append(frame.copy())
#             remaining = max(0, stable_time - elapsed)
#             display_frame = draw_vietnamese_text(display_frame, f"Đang giữ yên: {remaining:.1f} giây", (20, 90), font_size=22, color=(0, 255, 0))
#             display_frame = draw_vietnamese_text(display_frame, "Giữ yên vị trí để chụp", (20, 120), font_size=22, color=(0, 140, 255))
#             if elapsed >= stable_time:
#                 idx = len(stable_frames) // 2
#                 chosen = stable_frames[idx]
#                 cv2.imshow(window_name, display_frame)
#                 cv2.waitKey(500)
#                 return chosen, last_face
#         else:
#             stable_start = None
#             stable_frames.clear()
#             if faces:
#                 display_frame = draw_vietnamese_text(display_frame, "Di chuyển để đặt đúng hướng và vị trí", (20, 90), font_size=22, color=(0, 140, 255))

#         cv2.imshow(window_name, display_frame)
#         if cv2.waitKey(1) & 0xFF == ord('q'):
#             return None

def register_face_from_base64(user: dict, img_base64: list, app):
    """
    ✅ CHỈ TRÍCH XUẤT EMBEDDINGS, KHÔNG LƯU VÀO DB
    
    Args:
        user: Dict chứa thông tin user (MaNV hoặc MaQL)
        img_base64: List các ảnh base64
        app: FaceAnalysis instance
    
    Returns:
        List các embeddings (bytes) hoặc None nếu thất bại
    """
    embeddings_list = []
    
    try:
        for i, img_b64 in enumerate(img_base64, start=1):
            try:
                # Decode ảnh từ base64
                img_data = base64.b64decode(img_b64)
                image = Image.open(BytesIO(img_data)).convert('RGB')
                frame = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
                
                # Detect faces
                faces = app.get(frame)
                if not faces:
                    print(f"[WARNING] Không thể trích xuất khuôn mặt từ ảnh {i}.")
                    continue
                
                # Lấy embedding từ face đầu tiên
                face = faces[0]
                embedding = face.normed_embedding
                
                # Convert sang bytes để lưu vào DB
                emb_bytes = embedding.astype(np.float32).tobytes()
                
                embeddings_list.append(emb_bytes)
                print(f"[DEBUG] ✅ Đã trích xuất embedding cho tư thế {i}")
                
            except Exception as e:
                print(f"[ERROR] Lỗi xử lý ảnh {i}: {e}")
                continue
        
        if len(embeddings_list) == 0:
            print("[ERROR] Không trích xuất được embedding nào!")
            return None
        
        print(f"[SUCCESS] Đăng ký hoàn tất cho {user.get('MaNV') or user.get('MaQL')} với {len(embeddings_list)} tư thế.")
        
        # ✅ CHỈ TRẢ VỀ LIST EMBEDDINGS, KHÔNG LƯU DB
        return embeddings_list
        
    except Exception as e:
        print(f"[ERROR] register_face_from_base64: {e}")
        return None
            
            
# --- Chuỗi đăng ký khuôn mặt ---
# def register_face_sequence(user:dict):
#     session: Session = SessionLocal()
#     cap = open_camera()
#     try:
#         if user["VaiTro"] == "Nhân Viên":
#             ma_pb = session.query(NhanVien.MaPB).filter(NhanVien.MaNV==user["MaNV"]).scalar()
#             ngay_db = session.query(NhanVien.NgayBatDauLam).filter(NhanVien.MaNV==user["MaNV"]).scalar()
#             ma_nv = get_new_employee_id(session, ma_pb, ngay_db)
#             ma_ql=None
#         elif user["VaiTro"] == "Quản Lý":
#             ma_nv = None
#             ma_ql = user["MaQL"]
#         else:
#             raise ValueError("Vai trò người dùng không hợp lệ.")

#         print("[INFO] Đang khởi tạo InsightFace (CPU)...")
#         app = FaceAnalysis(name='buffalo_l', providers=['CPUExecutionProvider'])
#         print("[INFO] Đang load model, vui lòng chờ...")
#         app.prepare(ctx_id=0, det_size=(320, 320))
#         print("[INFO] InsightFace đã sẵn sàng.")

#         poses = [
#             "Nhìn chính diện (giữ yên)",
#             "Quay sang trái (giữ yên)",
#             "Quay sang phải  (giữ yên)"
#         ]

#         saved_count = 0
#         for i, prompt in enumerate(poses, start=1):
#             result = capture_stable_frame(cap, app, prompt)
#             if result is None:
#                 print("[WARN] Đã hủy quá trình đăng ký.")
#                 return False
#             chosen_frame, face_obj = result

#             try:
#                 embedding = face_obj.normed_embedding
#             except Exception:
#                 faces2 = app.get(chosen_frame)
#                 if not faces2:
#                     print("[ERROR] Không thể trích xuất khuôn mặt.")
#                     return False
                
#             embedding = faces2[0].normed_embedding
#             emb_bytes = embedding.astype(np.float32).tobytes()
#             ma_luutru = f"LT_{ma_nv}_{int(time.time()% 1000000)}_{i}"

#             luu = LuuTruKhuonMat(
#                 MaLuuTru=ma_luutru,
#                 MaNV=ma_nv,
#                 Embedding=emb_bytes,
#                 NgayTao=datetime.now(),
#                 GhiChu=f"Tư thế {i}"
#             )
#             session.add(luu)
#             saved_count += 1
#             print(f"[INFO] Đã lưu tư thế {i} cho {user['VaiTro']} (ma_nv or ma_ql).")

#         session.commit()
#         if ma_nv:
#             session.query(TaiKhoan).filter(TaiKhoan.MaNV == ma_nv).update({"TrangThai": True})
#             session.commit()
#         else:
#             session.query(TaiKhoan).filter(TaiKhoan.MaQL == ma_ql).update({"TrangThai": True})
#             session.commit()

#         print(f"[SUCCESS] Đăng ký hoàn tất cho {ma_nv} với {saved_count} tư thế.")
#         return True

#     except Exception as e:
#         session.rollback()
#         print("[ERROR]", e)
#         return False

#     finally:
#         cap.release()
#         cv2.destroyAllWindows()
#         session.close()

if __name__ == "__main__":
    current_user = get_current_user()
    test_img_base64 = [
        "base64_string_1",
        "base64_string_2",
        "base64_string_3"
    ]
    register_face_from_base64(current_user, test_img_base64, face_app)
