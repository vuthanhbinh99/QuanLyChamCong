class BaoCao {
  final String maNV;
  final String hoTen;
  final String phongBan;
  final int tongNgayLam;
  final double soGioLam;

  BaoCao({
    required this.maNV,
    required this.hoTen,
    required this.phongBan,
    required this.tongNgayLam,
    required this.soGioLam,
  });

  factory BaoCao.fromJson(Map<String, dynamic> json) {
    return BaoCao(
      maNV: json['maNV'] ?? '',
      hoTen: json['hoTen'] ?? '',
      phongBan: json['phongBan'] ?? '',
      tongNgayLam: json['tongNgayLam'] ?? 0,
      soGioLam: (json['soGioLam'] ?? 0).toDouble(),
    );
  }
}
