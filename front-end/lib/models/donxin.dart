class DonXin {
  final String maDon;
  final String userId; // Server trả về key là "userId"
  final String loaiDon;
  final String lyDo;
  final String ngayBatDau;
  final String ngayKetThuc;
  final String trangThai;
  final String? hoTen; // Tên nhân viên
  final String? maQL;
  final String? ngayGui;
  final String? ngayDuyet;
  final String? ghiChu;

  DonXin({
    required this.maDon,
    required this.userId,
    required this.loaiDon,
    required this.lyDo,
    required this.ngayBatDau,
    required this.ngayKetThuc,
    required this.trangThai,
    this.hoTen,
    this.maQL,
    this.ngayGui,
    this.ngayDuyet,
    this.ghiChu,
  });
factory DonXin.fromJson(Map<String, dynamic> json) {
  return DonXin(
    maDon: json['MaDon'] ?? '',
    userId: json['MaNV'] ?? '',
    loaiDon: json['LoaiDon'] ?? '',
    lyDo: json['LyDo'] ?? '',
    ngayBatDau: json['NgayBatDau'] ?? '',
    ngayKetThuc: json['NgayKetThuc'] ?? '',
    trangThai: json['TrangThai'] ?? '',
    hoTen: json['HoTen'],
    maQL: json['MaQL'],
    ngayGui: json['NgayGui'],
    ngayDuyet: json['NgayDuyet'],
    ghiChu: json['GhiChu'],
  );
}



  Map<String, dynamic> toJson() {
    return {
      'maDon': maDon,
      'userId': userId,
      'loaiDon': loaiDon,
      'lyDo': lyDo,
      'ngayBatDau': ngayBatDau,
      'ngayKetThuc': ngayKetThuc,
      'trangThai': trangThai,
      'maQL': maQL,
      'ngayGui': ngayGui,
      'ngayDuyet': ngayDuyet,
      'ghiChu': ghiChu,
    };
  }
}