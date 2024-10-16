import 'package:app/utils/helper.dart';

class Libur {
  final int id;
  final String nama;
  final String tanggal;
  final String createdAt;
  final String updatedAt;
  final String deletedAt;

  Libur({
    required this.id,
    required this.nama,
    required this.tanggal,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  factory Libur.fromJson(Map<String, dynamic> json) {
    return getLibur(json);
  }

  factory Libur.fromMap(Map<String, dynamic> json) {
    return getLibur(json);
  }

  static getLibur(Map<String, dynamic> json){
    if (json != null && json['id'] != null) {
      return Libur(
          id: Helper().toInt(json['id']),
          nama: json['nama'] ?? '',
          tanggal: json['tanggal'] ?? '',
          createdAt: json['created_at'] ?? '',
          updatedAt: json['updated_at'] ?? '',
          deletedAt: json['deleted_at'] ?? '',
      );
    }
    return null;
  }

  Map toJson() => {
    'id': id,
    'nama': nama,
    'tanggal': tanggal,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
  };
}
