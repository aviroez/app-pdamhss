import 'package:app/entities/penilaian_detail.dart';

import '/utils/helper.dart';
import 'pekerjaan.dart';
import 'tunjangan.dart';

class Penilaian {
  final int id;
  final int tunjanganId;
  final int pekerjaanId;
  final String nama;
  final String tipe;
  final double bobot;
  final double ketercapaian;
  final double nilai;
  final double target;
  final bool lebih;
  final String deskripsi;
  final String tanggalMulai;
  final String tanggalSelesai;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String deletedAt;
  Pekerjaan? pekerjaan;
  Tunjangan? tunjangan;
  List<PenilaianDetail> listPenilaianDetail = [];

  Penilaian({
    required this.id,
    required this.tunjanganId,
    required this.pekerjaanId,
    required this.nama,
    required this.tipe,
    required this.bobot,
    required this.ketercapaian,
    required this.nilai,
    required this.target,
    required this.lebih,
    required this.deskripsi,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    this.pekerjaan,
    this.tunjangan,
    required this.listPenilaianDetail,
  });

  factory Penilaian.fromJson(Map<String, dynamic> json) {
    return getPenilaian(json);
  }

  factory Penilaian.fromMap(Map<String, dynamic> json) {
    return getPenilaian(json);
  }

  static getPenilaian(Map<String, dynamic> json){
    if (json != null && json['id'] != null) {
      return Penilaian(
          id: Helper().toInt(json['id']),
          tunjanganId: Helper().toInt(json['tunjangan_id']),
          pekerjaanId: Helper().toInt(json['pekerjaan_id']),
          nama: json['nama'] ?? '',
          tipe: json['tipe'] ?? '',
          bobot: Helper().toDouble(json['bobot']),
          ketercapaian: Helper().toDouble(json['ketercapaian']),
          nilai: Helper().toDouble(json['nilai']),
          target: Helper().toDouble(json['target']),
          lebih: Helper().toInt(json['lebih']) == 1,
          deskripsi: json['deskripsi'] ?? '',
          tanggalMulai: json['tanggal_mulai'] ?? '',
          tanggalSelesai: json['tanggal_selesai'] ?? '',
          status: json['status'] ?? '',
          createdAt: json['created_at'] ?? '',
          updatedAt: json['updated_at'] ?? '',
          deletedAt: json['deleted_at'] ?? '',
          pekerjaan: json['pekerjaan'] != null ? Pekerjaan.fromMap(json['pekerjaan']) : null,
          tunjangan: json['tunjangan'] != null ? Tunjangan.fromMap(json['tunjangan']) : null,
          listPenilaianDetail: json['penilaian_detail_list'] != null ? json['penilaian_detail_list'].map<PenilaianDetail>((tagJson) {
            return PenilaianDetail.fromJson(tagJson);
          }).toList() : [],
      );
    }
    return null;
  }

  Map toJson() => {
    'id': id,
    'tunjangan_id': tunjanganId,
    'pekerjaan_id': pekerjaanId,
    'nama': nama,
    'tipe': tipe,
    'bobot': bobot,
    'ketercapaian': ketercapaian,
    'nilai': nilai,
    'target': target,
    'lebih': lebih,
    'deskripsi': deskripsi,
    'tanggal_mulai': tanggalMulai,
    'tanggal_selesai': tanggalSelesai,
    'status': status,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
    'pekerjaan': pekerjaan,
    'tunjangan': tunjangan,
    'penilaian_detail_list': listPenilaianDetail,
  };
}
