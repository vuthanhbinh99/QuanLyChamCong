class CaLam {
  final String maCa;
  final String tenCa;
  final String gioBatDau;
  final String gioKetThuc;
  final String ghiChu;

  CaLam({
    required this.maCa,
    required this.tenCa,
    required this.gioBatDau,
    required this.gioKetThuc,
    required this.ghiChu,
  });

  factory CaLam.fromJson(Map<String, dynamic> json) {
    return CaLam(
      maCa: json['maCa'] ?? '',
      tenCa: json['tenCa'] ?? '',
      gioBatDau: json['gioBatDau'] ?? '',
      gioKetThuc: json['gioKetThuc'] ?? '',
      ghiChu: json['ghiChu'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maCa': maCa,
      'tenCa': tenCa,
      'gioBatDau': gioBatDau,
      'gioKetThuc': gioKetThuc,
      'ghiChu': ghiChu,
    };
  }

  // Lấy thông tin hiển thị
  String get timeRange => '$gioBatDau - $gioKetThuc';
}