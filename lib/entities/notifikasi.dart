import 'package:app/utils/helper.dart';

class Notifikasi {
  int id;
  int penggunaId;
  int tunjanganId;
  int penilaianId;
  int penilaianDetailId;
  String playerId = '';
  String judul = '';
  String pesan = '';
  String result = '';
  String status = '';
  String web = '';
  final String createdAt;
  final String updatedAt;
  final String deletedAt;

  Notifikasi({
    required this.id,
    required this.penggunaId,
    required this.tunjanganId,
    required this.penilaianId,
    required this.penilaianDetailId,
    required this.playerId,
    required this.judul,
    required this.pesan,
    required this.result,
    required this.status,
    required this.web,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  factory Notifikasi.fromJson(Map<String, dynamic> json) {
    return Notifikasi(
      id: Helper().toInt(json['id']),
      penggunaId: Helper().toInt(json['pengguna_id']),
      tunjanganId: Helper().toInt(json['tunjangan_id']),
      penilaianId: Helper().toInt(json['penilaian_id']),
      penilaianDetailId: Helper().toInt(json['penilaian_detail_id']),
      playerId: json['player_id'],
      judul: json['judul'],
      pesan: json['pesan'],
      result: json['result'],
      status: json['status'],
      web: json['web'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'] ?? '',
    );
  }

  Map toJson() => {
    'id': id,
    'pengguna_id': penggunaId,
    'tunjangan_id': tunjanganId,
    'penilaian_id': penilaianId,
    'penilaian_detail_id': penilaianDetailId,
    'player_id': playerId,
    'judul': judul,
    'pesan': pesan,
    'result': result,
    'status': status,
    'web': web,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
  };
}