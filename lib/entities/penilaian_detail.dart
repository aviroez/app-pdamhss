import '/utils/helper.dart';
import 'file.dart';
import 'verifikasi.dart';

class PenilaianDetail {
  int id;
  int penilaianId;
  double nilai;
  String status;
  String tanggal;
  String catatan;
  double latitude;
  double longitude;
  String alamat;
  final String createdAt;
  final String updatedAt;
  final String deletedAt;
  FileModel? file;
  Verifikasi? verifikasi;

  PenilaianDetail({
    required this.id,
    required this.penilaianId,
    required this.nilai,
    required this.status,
    required this.tanggal,
    required this.catatan,
    required this.latitude,
    required this.longitude,
    required this.alamat,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.file,
    required this.verifikasi,
  });

  factory PenilaianDetail.fromJson(Map<String, dynamic> json) {
    return PenilaianDetail(
      id: Helper().toInt(json['id']),
      penilaianId: Helper().toInt(json['penilaian_id']),
      nilai: Helper().toDouble(json['nilai']),
      status: json['status'] ?? '',
      tanggal: json['tanggal'] ?? '',
      catatan: json['catatan'] ?? '',
      latitude: Helper().toDouble(json['latitude']),
      longitude: Helper().toDouble(json['longitude']),
      alamat: json['alamat'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'] ?? '',
      file: json['file'] != null ? FileModel.fromMap(json['file']) : null,
      verifikasi: json['verifikasi'] != null ? Verifikasi.fromJson(json['verifikasi']) : null,
    );
  }

  Map toJson() => {
    'id': id,
    'penilaian_id': penilaianId,
    'nilai': nilai,
    'status': status,
    'tanggal': tanggal,
    'catatan': catatan,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
    'file': file,
    'verifikasi': verifikasi,
  };
}
