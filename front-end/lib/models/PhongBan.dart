class PhongBan {
  final String MaPB;
  final String TenPB;

  PhongBan({
    required this.MaPB,
    required this.TenPB
  });

  factory PhongBan.fromJson(Map<String, dynamic> json){
    return PhongBan(
      MaPB: json['MaPB'] ?? '',
      TenPB: json['TenPB'] ?? ''
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'MaPB': MaPB,
      'TenPB': TenPB
    };
  }
}