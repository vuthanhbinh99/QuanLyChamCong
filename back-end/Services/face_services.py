import cv2, io
import base64
from PIL import Image
import numpy as np
from datetime import datetime, time as time_class
import time
from model import LuuTruKhuonMat, NhanVien, QuanLy
from insightface.app import FaceAnalysis

# Cache known faces trong 60 giây
_face_app = None
_known_faces_cache = None
_cache_time = 0
CACHE_DURATION = 60  # seconds

def init_face_app():
    """Khởi tạo InsightFace model"""
    global _face_app
    
    if _face_app is not None:
        return _face_app
    
    try:
        _face_app = FaceAnalysis(
            name='buffalo_s',
            providers=['CPUExecutionProvider']
        )
        _face_app.prepare(ctx_id=0, det_size=(320, 320))
        print("[INFO] InsightFace initialized successfully")
        return _face_app
    except Exception as e:
        print(f"[ERROR] Failed to initialize InsightFace: {e}")
        return None

def get_face_app():
    """Lấy instance của face_app"""
    global _face_app
    if _face_app is None:
        _face_app = init_face_app()
    return _face_app

# ====== HÀM DECODE ẢNH TỐI ƯU ======
def decode_base64_image_optimized(img_base64):
    """Decode base64 nhanh hơn"""
    try:
        # Bỏ phần header nếu có
        if ',' in img_base64:
            img_base64 = img_base64.split(',')[1]
        
        # Decode
        img_bytes = base64.b64decode(img_base64)
        
        # Dùng PIL để decode nhanh hơn
        img = Image.open(io.BytesIO(img_bytes))
        
        # Resize về kích thước phù hợp (640x480) để xử lý nhanh
        if img.width > 640 or img.height > 480:
            img.thumbnail((640, 480), Image.Resampling.LANCZOS)
        
        # Convert sang numpy array BGR
        img_array = np.array(img.convert('RGB'))
        return cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)
    
    except Exception as e:
        print(f"[ERROR] Decode ảnh thất bại: {e}")
        return None
    

def load_known_faces_cached(session):
    """Load known faces với cache"""
    global _known_faces_cache, _cache_time
    
    current_time = time.time()
    
    # Nếu cache còn hiệu lực
    if _known_faces_cache and (current_time - _cache_time) < CACHE_DURATION:
        print("[CACHE] Sử dụng cached known faces")
        return _known_faces_cache
    
    # Load lại từ DB
    print("[DB] Load known faces từ database...")
    result = load_known_faces(session)
    
    # Lưu cache
    _known_faces_cache = result
    _cache_time = current_time
    
    return result

def load_known_faces_cached(session):
    """Load known faces với cơ chế Cache"""
    global _known_faces_cache, _cache_time
    
    current_time = time.time()
    
    # Nếu cache còn dữ liệu và chưa hết hạn
    if _known_faces_cache is not None and (current_time - _cache_time) < CACHE_DURATION:
        # print("[CACHE] Sử dụng cached known faces")
        return _known_faces_cache
    
    # Nếu không có cache hoặc hết hạn -> Load lại từ DB
    print("[DB] 🔄 Đang tải dữ liệu khuôn mặt từ database...")
    result = load_known_faces(session)
    
    # Cập nhật cache
    _known_faces_cache = result
    _cache_time = current_time
    
    return result

def load_known_faces(session):
    """
    Query DB để lấy embedding của cả Nhân Viên và Quản Lý
    """
    known_embeddings = []
    known_names = []
    known_id = []
    known_roles = []

    try:
        # 1. Lấy dữ liệu NHÂN VIÊN
        # Join bảng LuuTruKhuonMat với NhanVien qua MaNV
        data_nv = session.query(
            LuuTruKhuonMat.Embedding, 
            NhanVien.HoTenNV, 
            NhanVien.MaNV
        ).join(
            NhanVien, LuuTruKhuonMat.MaNV == NhanVien.MaNV
        ).all()
        
        for embedding_blob, name, id_user in data_nv:
            if embedding_blob:
                # Convert bytes sang numpy array float32
                emb_array = np.frombuffer(embedding_blob, dtype=np.float32)
                known_embeddings.append(emb_array)
                known_names.append(name)
                known_id.append(id_user)
                known_roles.append("NhanVien")

        # 2. Lấy dữ liệu QUẢN LÝ
        # Join bảng LuuTruKhuonMat với QuanLy qua MaQL
        data_ql = session.query(
            LuuTruKhuonMat.Embedding, 
            QuanLy.HoTenQL, 
            QuanLy.MaQL
        ).join(
            QuanLy, LuuTruKhuonMat.MaQL == QuanLy.MaQL
        ).all()
        
        for embedding_blob, name, id_user in data_ql:
            if embedding_blob:
                emb_array = np.frombuffer(embedding_blob, dtype=np.float32)
                known_embeddings.append(emb_array)
                known_names.append(name)
                known_id.append(id_user)
                known_roles.append("QuanLy")

        print(f"[INFO] Đã tải {len(known_embeddings)} khuôn mặt (NV: {len(data_nv)}, QL: {len(data_ql)})")
        
    except Exception as e:
        print(f"[ERROR] Lỗi khi load khuôn mặt từ DB: {e}")
        # Trả về list rỗng để không crash app
        return [], [], [], []

    return known_embeddings, known_names, known_id, known_roles
def clear_known_faces_cache():
    global _known_faces_cache, _cache_time
    
    # Reset biến cache về None
    _known_faces_cache = None
    _cache_time = 0
    print("[FACE SERVICE] 🧹 Cache đã được dọn dẹp (Reset).")