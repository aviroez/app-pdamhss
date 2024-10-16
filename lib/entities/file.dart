import 'package:app/utils/helper.dart';

class FileModel {
  final int id;
  final int penilaianId;
  final int penilaianDetailId;
  final int penggunaId;
  final String nama;
  final String tipe;
  final String tanggal;
  final String createdAt;
  final String updatedAt;
  final String deletedAt;

  FileModel({
    required this.id,
    required this.penilaianId,
    required this.penilaianDetailId,
    required this.penggunaId,
    required this.nama,
    required this.tipe,
    required this.tanggal,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return getFile(json);
  }

  factory FileModel.fromMap(Map<String, dynamic> json) {
    return getFile(json);
  }

  static getFile(Map<String, dynamic> json){
    if (json != null && json['id'] != null) {
      return FileModel(
          id: Helper().toInt(json['id']),
          penilaianId: Helper().toInt(json['penilaian_id']),
          penilaianDetailId: Helper().toInt(json['penilaian_detail_id']),
          penggunaId: Helper().toInt(json['pengguna_id']),
          nama: json['nama'] ?? '',
          tipe: json['tipe'] ?? '',
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
    'penilaian_id': penilaianId,
    'penilaian_detail_id': penilaianDetailId,
    'pengguna_id': penggunaId,
    'nama': nama,
    'tipe': tipe,
    'tanggal': tanggal,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
  };
}
