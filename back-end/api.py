from flask import Flask
from Api import register_blueprints
from insightface.app import FaceAnalysis
from admin import setup_admin
app = Flask(__name__)
app.config['SECRET_KEY'] = 'chuoi-bi-mat-sieu-kho-doan-123456'
# Khởi tạo InsightFace
try:
    face_app = FaceAnalysis(name='buffalo_s', providers=['CPUExecutionProvider'])
    face_app.prepare(ctx_id=0, det_size=(320, 320))
    print("[INFO] InsightFace sẵn sàng")
except Exception as e:
    print(f"[ERROR] Không thể khởi tạo InsightFace: {e}")

# Đăng ký tất cả blueprints
register_blueprints(app)
setup_admin(app)
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)