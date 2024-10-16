import 'package:app/utils/helper.dart';

import 'akses.dart';
import 'token.dart';

class Pengguna {
  int id;
  String nipp = '';
  String nama = '';
  String noHp = '';
  String password = '';
  String email = '';
  String pangkatGolongan = '';
  String tempatLahir = '';
  String tanggalLahir = '';
  String pendidikan = '';
  String jenisKelamin = '';
  String bidang = '';
  final String createdAt;
  final String updatedAt;
  final String deletedAt;
  Token? token;
  List<Akses> listAkses = [];

  Pengguna({
    required this.id,
    required this.nipp,
    required this.nama,
    required this.noHp,
    required this.password,
    required this.email,
    required this.pangkatGolongan,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.pendidikan,
    required this.jenisKelamin,
    required this.bidang,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.token,
    required this.listAkses,
  });

  factory Pengguna.fromJson(Map<String, dynamic> json) {
    return getPengguna(json);
  }

  static getPengguna(Map<String, dynamic> json){
    if (json != null && json['id'] != null) {
      List<Akses> listAkses = [];
      if (json['akses_list'] != null) {
        listAkses = (json['akses_list'] as List).map((i) =>
            Akses.fromJson(i)
        ).toList();
      }
      return Pengguna(
          id: Helper().toInt(json['id']),
          nipp: json['nipp'] ?? '',
          nama: json['nama'] ?? '',
          noHp: json['no_hp'] ?? '',
          password: json['password'] ?? '',
          email: json['email'] ?? '',
          pangkatGolongan: json['pangkat_golongan'] ?? '',
          tempatLahir: json['tempat_lahir'] ?? '',
          tanggalLahir: json['tanggal_lahir'] ?? '',
          pendidikan: json['pendidikan'] ?? '',
          jenisKelamin: json['jenis_kelamin'] ?? '',
          bidang: json['bidang'] ?? '',
          createdAt: json['created_at'] ?? '',
          updatedAt: json['updated_at'] ?? '',
          deletedAt: json['deleted_at'] ?? '',
          token: json['token'] != null ? Token.fromJson(json['token']) : null,
          listAkses: listAkses,
      );
    }
    return null;
  }

  Map toJson() => {
    'id': id,
    'nipp': nipp,
    'nama': nama,
    'no_hp': noHp,
    'password': password,
    'email': email,
    'pangkat_golongan': pangkatGolongan,
    'tempat_lahir': tempatLahir,
    'tanggal_lahir': tanggalLahir,
    'pendidikan': pendidikan,
    'jenis_kelamin': jenisKelamin,
    'bidang': bidang,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
    'token': token,
    'akses_list': listAkses,
  };
}