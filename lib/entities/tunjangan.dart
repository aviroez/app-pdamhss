import 'package:app/utils/helper.dart';

import 'pengguna.dart';

class Tunjangan {
  final int id;
  final int jabatanId;
  final int penggunaId;
  final String nama;
  final String periode;
  final double bobot;
  final double ketercapaian;
  final double tunjangan;
  final double diterima;
  final String deskripsi;
  final String tanggalMulai;
  final String tanggalSelesai;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String deletedAt;
  Pengguna? pengguna;

  Tunjangan({
    required this.id,
    required this.jabatanId,
    required this.penggunaId,
    required this.nama,
    required this.periode,
    required this.bobot,
    required this.ketercapaian,
    required this.tunjangan,
    required this.diterima,
    required this.deskripsi,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    this.pengguna,
  });

  factory Tunjangan.fromJson(Map<String, dynamic> json) {
    return getTunjangan(json);
  }

  factory Tunjangan.fromMap(Map<String, dynamic> json) {
    return getTunjangan(json);
  }

  static getTunjangan(Map<String, dynamic> json){
    if (json != null && json['id'] != null) {
      return Tunjangan(
        id: Helper().toInt(json['id']),
        jabatanId: Helper().toInt(json['jabatan_id']),
        penggunaId: Helper().toInt(json['pengguna_id']),
        nama: json['nama'],
        periode: json['periode'],
        bobot: Helper().toDouble(json['bobot']),
        ketercapaian: Helper().toDouble(json['ketercapaian']),
        tunjangan: Helper().toDouble(json['tunjangan']),
        diterima: Helper().toDouble(json['diterima']),
        deskripsi: json['deskripsi'] ?? "",
        tanggalMulai: json['tanggal_mulai'],
        tanggalSelesai: json['tanggal_selesai'],
        status: json['status'],
        pengguna: json['pengguna'] != null ? Pengguna.fromJson(json['pengguna']) : null,
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
        deletedAt: json['deleted_at'] ?? '',
      );
    }
    return null;
  }

  Map toJson() => {
    'id': id,
    'jabatan_id': jabatanId,
    'pengguna_id': penggunaId,
    'nama': nama,
    'periode': periode,
    'bobot': bobot,
    'ketercapaian': ketercapaian,
    'tunjangan': tunjangan,
    'diterima': diterima,
    'deskripsi': deskripsi,
    'tanggal_mulai': tanggalMulai,
    'tanggal_selesai': tanggalSelesai,
    'status': status,
    'pengguna': pengguna,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
  };
}
