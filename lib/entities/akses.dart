import 'package:app/utils/helper.dart';

class Akses {
  int penggunaId;
  int jabatanId;
  int lokasiId;
  String jabatanCode = '';
  String jabatanNama = '';
  String lokasiNama = '';

  Akses({
    required this.penggunaId,
    required this.jabatanId,
    required this.lokasiId,
    required this.jabatanCode,
    required this.jabatanNama,
    required this.lokasiNama,
  });

  factory Akses.fromJson(Map<String, dynamic> json) {
    return getAkses(json);
  }

  static getAkses(Map<String, dynamic> json){
    if (json != null && json['pengguna_id'] != null) {
      return Akses(
        penggunaId: Helper().toInt(json['pengguna_id']),
        jabatanId: Helper().toInt(json['jabatan_id']),
        lokasiId: Helper().toInt(json['lokasi_id']),
        jabatanCode: json['jabatan_code'] ?? '',
        jabatanNama: json['jabatan_nama'] ?? '',
        lokasiNama: json['lokasi_nama'] != null ? json['lokasi_nama'] : '',
      );
    }
    return null;
  }

  Map toJson() => {
    'pengguna_id': penggunaId,
    'jabatan_id': jabatanId,
    'lokasi_id': lokasiId,
    'jabatan_code': jabatanCode,
    'jabatan_nama': jabatanNama,
    'lokasi_nama': lokasiNama,
  };
}