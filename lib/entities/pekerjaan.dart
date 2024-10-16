import '/utils/helper.dart';

class Pekerjaan {
  final int id;
  final String nama;
  final double bobot;
  final String tipe;
  final double nilai;
  final bool lebih;
  final String deskripsi;
  final String createdAt;
  final String updatedAt;
  final String deletedAt;

  Pekerjaan({
    required this.id,
    required this.nama,
    required this.bobot,
    required this.tipe,
    required this.nilai,
    required this.lebih,
    required this.deskripsi,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  factory Pekerjaan.fromJson(Map<String, dynamic> json) {
    return getPekerjaan(json);
  }

  factory Pekerjaan.fromMap(Map<String, dynamic> json) {
    return getPekerjaan(json);
  }

  static getPekerjaan(Map<String, dynamic> json){
    if (json != null && json['id'] != null) {
      return Pekerjaan(
          id: Helper().toInt(json['id']),
          nama: json['nama'] ?? '',
          bobot: Helper().toDouble(json['bobot']),
          tipe: json['tipe'] ?? '',
          nilai: Helper().toDouble(json['nilai']),
          lebih: Helper().toInt(json['lebih']) == 1,
          deskripsi: json['deskripsi'] ?? '',
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
    'bobot': bobot,
    'tipe': tipe,
    'nilai': nilai,
    'lebih': lebih,
    'deskripsi': deskripsi,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
  };
}
