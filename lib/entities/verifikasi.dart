import '/utils/helper.dart';
import 'file.dart';

class Verifikasi {
  int id;
  int penggunaId;
  int jabatanId;
  int penilaianId;
  int penilaianDetailId;
  String status;
  String pesan;
  String createdAt;
  String updatedAt;
  String deletedAt;

  Verifikasi({
    required this.id,
    required this.penggunaId,
    required this.jabatanId,
    required this.penilaianId,
    required this.penilaianDetailId,
    required this.status,
    required this.pesan,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  factory Verifikasi.fromJson(Map<String, dynamic> json) {
    return Verifikasi(
      id: Helper().toInt(json['id']),
      penggunaId: Helper().toInt(json['pengguna_id']),
      jabatanId: Helper().toInt(json['jabatan_id']),
      penilaianId: Helper().toInt(json['penilaian_id']),
      penilaianDetailId: Helper().toInt(json['penilaian_detail_id']),
      status: json['status'] ?? '',
      pesan: json['pesan'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'] ?? '',
    );
  }

  Map toJson() => {
    'id': id,
    'pengguna_id': penggunaId,
    'jabatan_id': jabatanId,
    'penilaian_id': penilaianId,
    'penilaian_detail_id': penilaianDetailId,
    'status': status,
    'pesan': pesan,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
  };
}
