class User {
  final String id;
  final String role;
  final String? hoTen;
  final String? email;
  final String? phongBan;
  final String? tenPhongBan;
  final String? soDienThoai;
  final String? chucVu;
  final String? gioiTinh;

  User({
    required this.id,
    required this.role,
    this.hoTen,
    this.email,
    this.phongBan,
    this.tenPhongBan,
    this.soDienThoai,
    this.chucVu,
    this.gioiTinh,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final userInfo = json['user_info'] ?? {};

    return User(
      id: json['id']?.toString() 
          ?? json['user_id']?.toString() 
          ?? '',

      role: json['role']?.toString() 
          ?? json['user_role']?.toString() 
          ?? '',

      hoTen: userInfo['ho_ten']?.toString(),
      email: userInfo['email']?.toString(),
      phongBan: userInfo['phong_ban']?.toString(),
      tenPhongBan: userInfo['ten_phong_ban']?.toString(),
      soDienThoai: userInfo['so_dien_thoai']?.toString(),
      chucVu: userInfo['chuc_vu']?.toString(),
      gioiTinh: userInfo['gioi_tinh']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'user_info': {
        'ho_ten': hoTen,
        'email': email,
        'phong_ban': phongBan,
         'ten_phong_ban': tenPhongBan,
        'so_dien_thoai': soDienThoai,
        'chuc_vu': chucVu,
        'gioi_tinh': gioiTinh,
      }
    };
  }

  bool get isNhanVien => role.toLowerCase().contains('nhanvien');
  bool get isQuanLy => role.toLowerCase().contains('quanly');
  bool get isQuanTriVien => role.toLowerCase().contains('quantrivien');

  @override
  String toString() => 'User(id: $id, role: $role, hoTen: $hoTen)';
}
