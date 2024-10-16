import 'package:app/utils/helper.dart';

class Atasan {
  int id;
  int penggunaId;
  int atasanId;
  int jabatanId;
  int lokasiId;
  String code;
  String nama;
  String createdAt;
  String updatedAt;
  String deletedAt;

  Atasan({
    required this.id,
    required this.penggunaId,
    required this.atasanId,
    required this.jabatanId,
    required this.lokasiId,
    required this.code,
    required this.nama,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  factory Atasan.fromJson(Map<String, dynamic> json) {
    return getAtasan(json);
  }

  static getAtasan(Map<String, dynamic> json){
    if (json != null && json['id'] != null && json['id'] != null) {
      return Atasan(
        id: Helper().toInt(json['id']),
        penggunaId: Helper().toInt(json['pengguna_id']),
        atasanId: Helper().toInt(json['atasan_id']),
        jabatanId: Helper().toInt(json['jabatan_id']),
        lokasiId: Helper().toInt(json['lokasi_id']),
        code: json['code'] ?? '',
        nama: json['nama'] ?? '',
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
        deletedAt: json['deleted_at'] ?? '',
      );
    }
    return null;
  }

  Map toJson() => {
    'id': id,
    'pengguna_id': penggunaId,
    'atasan_id': atasanId,
    'jabatan_id': jabatanId,
    'lokasi_id': lokasiId,
    'code': code,
    'nama': nama,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
  };
}