import 'package:app/utils/helper.dart';

class Jabatan {
  int id;
  String code = '';
  String nama = '';
  String createdAt;
  String updatedAt;
  String deletedAt;

  Jabatan({
    required this.id,
    required this.code,
    required this.nama,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  factory Jabatan.fromJson(Map<String, dynamic> json) {
    return getJabatan(json);
  }

  static getJabatan(Map<String, dynamic> json){
    if (json != null && json['id'] != null) {
      return Jabatan(
        id: Helper().toInt(json['id']),
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
    'code': code,
    'nama': nama,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
  };
}