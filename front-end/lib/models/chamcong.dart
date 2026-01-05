class ChamCong {
  final String id;          // MaChamCong
  final String userId;      // MaNV
  final String? maQL;       // MaQL
  final String maCa;       // MaCa
  final DateTime ngayChamCong;
  final String gioVao;
  final String gioRa;
  final String trangThai;
  final String diaDiemChamCong;

  ChamCong({
    required this.id,
    required this.userId,
    this.maQL,
    required this.maCa,
    required this.ngayChamCong,
    required this.gioVao,
    required this.gioRa,
    required this.trangThai,
    required this.diaDiemChamCong,
  });

  factory ChamCong.fromJson(Map<String, dynamic> json) {
    return ChamCong(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      maQL: json['maQL'],
      maCa: json['maCa']?.toString() ?? '',
      ngayChamCong: DateTime.parse(json['ngayChamCong']),
      gioVao: json['gioVao'],
      gioRa: json['gioRa'],
      trangThai: json['trangThai'] ?? '',
      diaDiemChamCong: json['diaDiemChamCong'] ?? '',
    );
  }
}
