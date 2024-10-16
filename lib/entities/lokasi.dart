import '/utils/helper.dart';

class Lokasi {
  int id;
  String nama = '';
  final String createdAt;
  final String updatedAt;
  final String deletedAt;

  Lokasi({
    required this.id,
    required this.nama,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  factory Lokasi.fromJson(Map<String, dynamic> json) {
    return Lokasi(
      id: Helper().toInt(json['id']),
      nama: json['nama'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'] ?? '',
    );
  }

  Map toJson() => {
    'id': id,
    'nama': nama,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
  };
}