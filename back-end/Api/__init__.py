"""
API Package - Đăng ký tất cả blueprints
"""
from flask import Flask
from .auth import auth_bp
from .chamcong import chamcong_bp
from .face import face_bp
from .donxin import donxin_bp
from .quanly import quanly_bp
from .calam import calam_bp
from .baocao import baocao_bp
from .nhanvien import nhanvien_bp

def register_blueprints(app: Flask):
    """Đăng ký tất cả blueprints vào Flask app"""
    app.register_blueprint(auth_bp, url_prefix='/api')
    app.register_blueprint(face_bp, url_prefix='/api')
    app.register_blueprint(chamcong_bp, url_prefix = '/api')
    app.register_blueprint(donxin_bp, url_prefix='/api')
    app.register_blueprint(quanly_bp, url_prefix='/api')
    app.register_blueprint(calam_bp, url_prefix='/api')
    app.register_blueprint(baocao_bp, url_prefix='/api')
    app.register_blueprint(nhanvien_bp, url_prefix='/api')
    print("[INFO] All blueprints registered successfully")