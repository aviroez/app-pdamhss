import 'dart:io';

import 'package:app/entities/akses.dart';
import 'package:app/entities/file.dart';
import 'package:app/entities/jabatan.dart';
import 'package:app/entities/libur.dart';
import 'package:app/entities/lokasi.dart';
import 'package:app/entities/pekerjaan.dart';
import 'package:app/entities/pengguna.dart';
import 'package:app/entities/penilaian_detail.dart';
import 'package:app/entities/tunjangan.dart';
import 'package:app/entities/verifikasi.dart';
import 'package:app/utils/sqlite.dart';
import 'package:intl/intl.dart';

import 'helper.dart';
import 'rest.dart';

class Sync {
  Sqlite sqlite = new Sqlite();
  List<Tunjangan> listTunjangan = [];
  List<Lokasi> listLokasi = [];
  List<Jabatan> listJabatan = [];
  List<Libur> listLibur = [];

  Future<List<Tunjangan>> synchronizeTunjangan() async {
    Map<String, dynamic> p = await Helper().getPengguna();
    Pengguna pengguna = Pengguna.fromJson(p);
    Tunjangan? tunjangan = await sqlite.getLastTunjangan();

    Map<String, String> body = Map<String, String>();
    if (pengguna != null) body['pengguna_id'] = pengguna.id.toString();
    if (tunjangan != null) {
      print('Sync:synchronizeTunjangan: ${tunjangan.toJson().toString()}');
      var createdAt = DateFormat('dd-MM-yyyy').parse(tunjangan.createdAt);
      var updatedAt = DateFormat('dd-MM-yyyy').parse(tunjangan.updatedAt);
      body['date_from'] = tunjangan.createdAt;
      if (updatedAt.isAfter(createdAt)) body['date_from'] = tunjangan.updatedAt;
      else {
        if (tunjangan.deletedAt != null && tunjangan.deletedAt != '') {
          var deletedAt = DateFormat('dd-MM-yyyy').parse(tunjangan.deletedAt);
          if (deletedAt.isAfter(createdAt)) body['date_from'] = tunjangan.deletedAt;
        }
      }
    }
    listTunjangan = await Rest().fetchTunjanganList(body);
    print('Sync:synchronizeTunjangan:listTunjangan: ${listTunjangan.length.toString()}');
    return listTunjangan;
  }

  synchronizePenilaian(String ids) {
    if (ids != '') {
      sqlite.getLastPenilaian().then((penilaian) {
        Map<String, String> body = Map<String, String>();
        if (penilaian != null) {
          var createdAt = DateFormat('dd-MM-yyyy').parse(penilaian.createdAt);
          var updatedAt = DateFormat('dd-MM-yyyy').parse(penilaian.updatedAt);
          body['date_from'] = penilaian.createdAt;
          if (updatedAt.isAfter(createdAt)) body['date_from'] = penilaian.updatedAt;
          else {
            if (penilaian.deletedAt != null && penilaian.deletedAt != '') {
              var deletedAt = DateFormat('dd-MM-yyyy').parse(penilaian.deletedAt);
              if (deletedAt.isAfter(createdAt)) body['date_from'] = penilaian.deletedAt;
            }
          }
        }
        body['tunjangan_id'] = ids;
        Rest().syncPenilaian(body).then((value) {
          Map<String, dynamic> map = value;
          if (map.containsKey('data')) {
            for(var i=0; i < map['data'].length; i++){
              sqlite.insertPenilaian(Map<String, dynamic>.from(map['data'][i]));
            }
          }
        });
      });
      sqlite.getLastFile(0).then((file) {
        Map<String, String> body = Map<String, String>();
        if (file != null) {
          var createdAt = DateFormat('dd-MM-yyyy').parse(file.createdAt);
          var updatedAt = DateFormat('dd-MM-yyyy').parse(file.updatedAt);
          body['date_from'] = file.createdAt;
          if (updatedAt.isAfter(createdAt)) body['date_from'] = file.updatedAt;
          else {
            if (file.deletedAt != null && file.deletedAt != '') {
              var deletedAt = DateFormat('dd-MM-yyyy').parse(file.deletedAt);
              if (deletedAt.isAfter(createdAt)) body['date_from'] = file.deletedAt;
            }
          }
        }
        body['tunjangan_id'] = ids;
        Rest().syncFile(body).then((value) {
          Map<String, dynamic> map = value;
          if (map.containsKey('data')) {
            for(var i=0; i < map['data'].length; i++){
              sqlite.insertFile(Map<String, dynamic>.from(map['data'][i]));
            }
          }
        });
      });
      sqlite.getLastPenilaianDetail().then((penilaianDetail) {
        Map<String, String> body = Map<String, String>();
        if (penilaianDetail != null) {
          var createdAt = DateFormat('dd-MM-yyyy').parse(penilaianDetail.createdAt);
          var updatedAt = DateFormat('dd-MM-yyyy').parse(penilaianDetail.updatedAt);
          body['date_from'] = penilaianDetail.createdAt;
          if (updatedAt.isAfter(createdAt)) body['date_from'] = penilaianDetail.updatedAt;
          else {
            if (penilaianDetail.deletedAt != null && penilaianDetail.deletedAt != '') {
              var deletedAt = DateFormat('dd-MM-yyyy').parse(penilaianDetail.deletedAt);
              if (deletedAt.isAfter(createdAt)) body['date_from'] = penilaianDetail.deletedAt;
            }
          }
        }
        body['tunjangan_id'] = ids;
        Rest().syncPenilaianDetail(body).then((value) {
          Map<String, dynamic> map = value;
          if (map.containsKey('data')) {
            for(var i=0; i < map['data'].length; i++){
              sqlite.insertPenilaianDetail(Map<String, dynamic>.from(map['data'][i]));
            }
          }
        });
      });
      sqlite.getLastVerifikasi().then((verifikasi) {
        Map<String, String> body = Map<String, String>();
        if (verifikasi != null) {
          var createdAt = DateFormat('dd-MM-yyyy').parse(verifikasi.createdAt);
          var updatedAt = DateFormat('dd-MM-yyyy').parse(verifikasi.updatedAt);
          body['date_from'] = verifikasi.createdAt;
          if (updatedAt.isAfter(createdAt)) body['date_from'] = verifikasi.updatedAt;
          else {
            if (verifikasi.deletedAt != null && verifikasi.deletedAt != '') {
              var deletedAt = DateFormat('dd-MM-yyyy').parse(verifikasi.deletedAt);
              if (deletedAt.isAfter(createdAt)) body['date_from'] = verifikasi.deletedAt;
            }
          }
        }
        body['tunjangan_id'] = ids;
        Rest().syncVerifikasi(body).then((value) {
          Map<String, dynamic> map = value;
          if (map.containsKey('data')) {
            for(var i=0; i < map['data'].length; i++){
              sqlite.insertVerifikasi(Map<String, dynamic>.from(map['data'][i]));
            }
          }
        });
      });
    }
  }

  synchronizeMaster() async {
    List<Lokasi> listLokasi = await sqlite.getLokasiList({});
    if (listLokasi.length <= 0) {
      Rest().fetchLokasiList().then((value) {
        listLokasi = value;

        for (Lokasi lokasi in listLokasi) {
          sqlite.insertLokasi(Map<String, dynamic>.from(lokasi.toJson()));
        }
      });
    }

    List<Jabatan> listJabatan = await sqlite.getJabatanList({});
    if (listJabatan.length <= 0) {
      Rest().fetchJabatanList().then((value) {
        listJabatan = value;

        for (Jabatan jabatan in listJabatan) {
          sqlite.insertJabatan(Map<String, dynamic>.from(jabatan.toJson()));
        }
      });
    }

    List<Libur> listLibur = await sqlite.getLiburList({});
    if (listLibur.length <= 0) {
      Rest().fetchLiburList({}).then((value) {
        listLibur = value;

        for (Libur libur in listLibur) {
          sqlite.insertLibur(Map<String, dynamic>.from(libur.toJson()));
        }
      });
    }

    List<Pekerjaan> listPekerjaan = await sqlite.getPekerjaanList({});
    if (listPekerjaan.length <= 0) {
      Rest().fetchPekerjaanList().then((value) {
        listPekerjaan = value;

        for (Pekerjaan pekerjaan in listPekerjaan) {
          sqlite.insertPekerjaan(Map<String, dynamic>.from(pekerjaan.toJson()));
        }
      });
    }
  }

  synchronizeFile(){
    sqlite.getAllFileInput().then((value) {
      List<FileModel> listFile = value;

      for(FileModel file in listFile) {

      }
    });
  }

  synchronizePenilaianDetail(){
    sqlite.getAllPenilaianDetailInput().then((value) {
      List<PenilaianDetail> listPenilaianDetail = value;

      for(PenilaianDetail penilaianDetail in listPenilaianDetail) {

      }
    });
  }

  Future<bool> synchronizePenilaianDetailFile() async {
    List<PenilaianDetail> listPenilaianDetail = await sqlite.getAllPenilaianDetailInput();
    List<FileModel> listFile = await sqlite.getAllFileInput();

    for (PenilaianDetail penilaianDetail in listPenilaianDetail) {
      Map<String, dynamic> body = new Map<String, dynamic>();
      bool fileAvailable = false;
      for (FileModel fileModel in listFile) {
        if (fileModel.penilaianId == penilaianDetail.penilaianId && penilaianDetail.tanggal == fileModel.tanggal) {
          body['penilaian_id'] = penilaianDetail.penilaianId;
          body['tanggal'] = penilaianDetail.tanggal;
          body['nilai'] = penilaianDetail.nilai;
          body['status'] = penilaianDetail.status;
          body['latitude'] = penilaianDetail.latitude;
          body['longitude'] = penilaianDetail.longitude;
          body['alamat'] = penilaianDetail.alamat;

          body['nama'] = fileModel.nama;
          body['tipe'] = fileModel.tipe;
          fileAvailable = true;
          File file = new File(fileModel.nama);

          // Rest().savePenilaianDetailFile(file, body).then((value) {
            // sqlite.deletePenilaianDetailInput(penilaianDetail.id);
            // sqlite.deleteFileInput(fileModel.id);
          // });
          file.exists().then((value) {
            if (value) {
              Rest().savePenilaianDetailFile(file, body).then((value) {
                sqlite.deletePenilaianDetailInput(penilaianDetail.id);
                sqlite.deleteFileInput(fileModel.id);
              });
            } else {
              sqlite.deletePenilaianDetailInput(penilaianDetail.id);
              sqlite.deleteFileInput(fileModel.id);
            }
          });
        }
      }

      if (!fileAvailable) {
        // sqlite.deletePenilaianDetailInput(penilaianDetail.id);
      }
    }

    return true;
  }

  synchronizeVerifikasi(){
    sqlite.getAllVerifikasiInput().then((value) {
      List<Verifikasi> listVerifikasi = value;

      for(Verifikasi verifikasi in listVerifikasi) {

      }
    });
  }
}