import 'dart:io';
import 'dart:typed_data';

import 'package:app/entities/akses.dart';
import 'package:app/entities/file.dart';
import 'package:app/entities/jabatan.dart';
import 'package:app/entities/libur.dart';
import 'package:app/entities/lokasi.dart';
import 'package:app/entities/notifikasi.dart';
import 'package:app/entities/pekerjaan.dart';
import 'package:app/entities/pengguna.dart';
import 'package:app/entities/penilaian.dart';
import 'package:app/entities/penilaian_detail.dart';
import 'package:app/entities/token.dart';
import 'package:app/entities/tunjangan.dart';
import 'package:app/entities/verifikasi.dart';
import 'package:app/utils/constant.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'helper.dart';

class Sqlite {
  Database? db;

  Sqlite() {
    Sqflite.devSetDebugModeOn(true);

    if (db == null) {
      initDatabase(Constant.DB_NAME).then((value) {
        db = value;
      });
    }
  }

  Future<Database> initDatabase(dbName) async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, dbName);

    var exists = await databaseExists(path);

    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      ByteData data = await rootBundle.load(join("assets", dbName));
      List<int> bytes =
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      await File(path).writeAsBytes(bytes, flush: true);
    }
    return await openDatabase(path);
  }

  Future<void> deleteDatabaseFile() async{
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, Constant.DB_NAME);

    var exists = await databaseExists(path);

    if (!exists) await Directory(dirname(path)).delete(recursive: true);

    return await deleteDatabase(path);
  }

  Future<FileModel?> insertFile(Map<String, dynamic> values) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);

    Map<String, dynamic> params = new Map<String, dynamic>();
    values.forEach((key, value) {
      if (!['nama'].contains(key)) {
        params[key] = value;
      }
    });
    int id = Helper().toInt(values['id']);
    FileModel? fileModel = await getFile(id, false);
    if (fileModel != null) {
      id = fileModel.id;
      await db!.update('file', values, where: 'id = ?',whereArgs: [fileModel.id]);
    } else {
      id = await db!.insert('file', values);
    }
    return await getFile(id, false);
  }

  Future<FileModel?> getFile(id, bool deletedAt) async {
    if (id <= 0) return null;
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('file',
      where: deletedAt ? "id = ? AND (deleted_at = '' OR deleted_at IS NULL) " : 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.length > 0) {
      return FileModel.fromMap(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<FileModel?> getLastFile(int id) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = [];
    if (id > 0) {
      maps = await db!.query('file',
          where: "penilaian_detail_id = ? AND (deleted_at = '' OR deleted_at IS NULL)",
          whereArgs: [id],
          limit: 1,
          orderBy: 'id DESC'
      );
    } else {
      maps = await db!.query('file',
        orderBy: 'created_at DESC, updated_at DESC, deleted_at DESC',
        limit: 1,
      );
    }
    if (maps.length > 0) {
      return FileModel.fromMap(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<int> deleteFile(int id) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    if (id > 0) return await db!.delete('file', where: 'id = ?', whereArgs: [id]);
    else return await db!.delete('file');
  }

  Future<FileModel?> insertFileInput(Map<String, dynamic> values) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    var id = await db!.insert('file_input', values);
    return await getFileInput(id);
  }

  Future<int> getFileInputId() async {
    int id = 1;
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.rawQuery('SELECT MAX(id)+1 as id FROM penilaian_detail_input');
    if (maps.length > 0) {
      return Helper().toInt(maps.first['id']);
    }
    return id;
  }

  Future<FileModel?> getFileInput(id) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('file_input',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.length > 0) {
      return FileModel.fromMap(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<FileModel>> getAllFileInput() async {
    List<FileModel> list = [];
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('file_input');
    for (Map map in maps) {
      list.add(FileModel.fromMap(map as Map<String, dynamic>));
    }
    return list;
  }

  Future<FileModel?> getLastFileInput(id) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('file_input',
        where: "penilaian_detail_id = ? AND (deleted_at = '' OR deleted_at IS NULL)",
        whereArgs: [id],
        limit: 1,
        orderBy: 'id DESC'
    );
    if (maps.length > 0) {
      return FileModel.fromMap(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<int> deleteFileInput(int id) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    if (id > 0) return await db!.delete('file_input', where: 'id = ?', whereArgs: [id]);
    else return await db!.delete('file');
  }

  Future<Notifikasi?> insertNotifikasi(Map<String, dynamic> values) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    var id = await db!.insert('notifikasi', values);
    return await getNotifikasi(id, false);
  }

  Future<Notifikasi?> getNotifikasi(id, bool deletedAt) async {
    if (id <= 0) return null;
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('notifikasi',
      where: deletedAt ? "id = ? AND (deleted_at = '' OR deleted_at IS NULL) " : 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.length > 0) {
      return Notifikasi.fromJson(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<int> deleteNotifikasi(int id) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    if (id > 0) return await db!.delete('notifikasi', where: 'id = ?', whereArgs: [id]);
    else return await db!.delete('notifikasi');
  }

  Future<Pekerjaan?> insertPekerjaan(Map<String, dynamic> values) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    int id = Helper().toInt(values['id']);
    Pekerjaan? pekerjaan = await getPekerjaan(id, false);
    if (pekerjaan != null) {
      id = pekerjaan.id;
      await db!.update('pekerjaan', values, where: 'id = ?',whereArgs: [pekerjaan.id]);
    } else {
      id = await db!.insert('pekerjaan', values);
    }
    return await getPekerjaan(id, false);
  }

  Future<Pekerjaan?> getPekerjaan(id, bool deletedAt) async {
    if (id <= 0) return null;
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('pekerjaan',
      where: deletedAt ? "id = ? AND (deleted_at = '' OR deleted_at IS NULL) " : 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.length > 0) {
      return Pekerjaan.fromJson(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<Pekerjaan>> getPekerjaanList(Map<String, dynamic> values) async {
    List<Pekerjaan> list = [];
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('pekerjaan');
    for(Map map in maps) {
      list.add(Pekerjaan.fromJson(map as Map<String, dynamic>)) ;
    }
    return list;
  }

  Future<int> deletePekerjaan(int id) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    if (id > 0) return await db!.delete('pekerjaan', where: 'id = ?', whereArgs: [id]);
    else return await db!.delete('pekerjaan');
  }

  Future<Penilaian?> insertPenilaian(Map<String, dynamic> values) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);

    Map<String, dynamic> params = new Map<String, dynamic>();
    values.forEach((key, value) {
      if (!['pekerjaan','tunjangan'].contains(key)) {
        params[key] = value;
      }
    });

    int id = Helper().toInt(values['id']);
    Penilaian? penilaian = await getPenilaian(id, false);
    if (penilaian != null) {
      id = penilaian.id;
      await db!.update('penilaian', params, where: 'id = ?',whereArgs: [penilaian.id]);
    } else {
      id = await db!.insert('penilaian', params);
    }
    return await getPenilaian(id, false);
  }

  Future<Penilaian?> getPenilaian(id, bool deletedAt) async {
    if (id <= 0) return null;
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('penilaian',
        where: deletedAt ? "id = ? AND (deleted_at = '' OR deleted_at IS NULL) " : 'id = ?',
        whereArgs: [id],
        limit: 1,
    );
    if (maps.length > 0) {
      return Penilaian.fromMap(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<Penilaian>> getPenilaianList(int tunjanganId, bool withDetail) async {
    List<Penilaian> list = [];
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('penilaian',
      where: "tunjangan_id = ? AND (deleted_at = '' OR deleted_at IS NULL)",
      whereArgs: [tunjanganId]
    );
    if (maps.length > 0) {
      for(Map map in maps) {
        Penilaian penilaian = Penilaian.fromMap(map as Map<String, dynamic>);

        if (penilaian.pekerjaanId > 0) {
          penilaian.pekerjaan = await getPekerjaan(penilaian.pekerjaanId, false);
        }
        if (penilaian.tunjanganId > 0) {
          penilaian.tunjangan = await getTunjangan(penilaian.tunjanganId, false);
        }
        if (withDetail) {
          penilaian.listPenilaianDetail = await getAllPenilaianDetail(penilaian.id);
        }
        if (penilaian.listPenilaianDetail.length > 0) {
          for (PenilaianDetail penilaianDetail in penilaian.listPenilaianDetail) {
            penilaianDetail.file = await getLastFile(penilaianDetail.id);
          }
        }
        list.add(penilaian);
      }
    }
    return list;
  }

  Future<Penilaian?> getLastPenilaian() async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('penilaian',
      orderBy: 'created_at DESC, updated_at DESC, deleted_at DESC',
      limit: 1,
    );
    if (maps.length > 0) {
      return Penilaian.fromMap(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<int> deletePenilaian(int id) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    if (id > 0) return await db!.delete('penilaian', where: 'id = ?', whereArgs: [id]);
    else return await db!.delete('penilaian');
  }

  Future<PenilaianDetail?> insertPenilaianDetail(Map<String, dynamic> values) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    int id = Helper().toInt(values['id']);

    Map<String, dynamic> params = new Map<String, dynamic>();
    values.forEach((key, value) {
      if (!['file','verifikasi'].contains(key)) {
        params[key] = value;
      }
    });
    PenilaianDetail? penilaianDetail = await getPenilaianDetail(id, false);
    if (penilaianDetail != null) {
      await db!.update('penilaian_detail', params, where: 'id = ?',whereArgs: [penilaianDetail.id]);
    } else {
      id = await db!.insert('penilaian_detail', params);
    }
    return await getPenilaianDetail(id, false);
  }

  Future<PenilaianDetail?> getPenilaianDetail(id, bool deletedAt) async {
    if (id <= 0) return null;
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('penilaian_detail',
      where: deletedAt ? "id = ? AND (deleted_at = '' OR deleted_at IS NULL) " : 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.length > 0) {
      return PenilaianDetail.fromJson(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<PenilaianDetail>> getAllPenilaianDetail(penilaianId) async {
    List<PenilaianDetail> list = [];
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('penilaian_detail',
      where: "penilaian_id = ? AND (deleted_at = '' OR deleted_at IS NULL)",
      whereArgs: [penilaianId],
      orderBy: 'tanggal',
    );
    for (Map map in maps) {
      PenilaianDetail penilaianDetail = PenilaianDetail.fromJson(map as Map<String, dynamic>);
      list.add(penilaianDetail);
    }
    return list;
  }

  Future<int> deletePenilaianDetail(int id) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    if (id > 0) return await db!.delete('penilaian_detail', where: 'id = ?', whereArgs: [id]);
    else return await db!.delete('penilaian_detail');
  }

  Future<PenilaianDetail?> getLastPenilaianDetail() async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('penilaian_detail',
      orderBy: 'created_at DESC, updated_at DESC, deleted_at DESC',
      limit: 1,
    );
    if (maps.length > 0) {
      return PenilaianDetail.fromJson(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<PenilaianDetail?> insertPenilaianDetailInput(Map<String, dynamic> values) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    Map<String, dynamic> params = new Map<String, dynamic>();
    int penilaianId = Helper().toInt(values['penilaian_id']);
    int id = 1;
    String tanggal = '';
    values.forEach((key, value) {
      if (!['id', 'file', 'pengguna_id'].contains(key)) {
        params[key] = value;
      }
    });
    PenilaianDetail? penilaianDetail = await getPenilaianDetailInputBy(penilaianId, tanggal);
    if (penilaianDetail != null) {
      id = penilaianDetail.id;
      await db!.update('penilaian_detail_input', params, where: 'id = ?',whereArgs: [penilaianDetail.id]);
    } else {
      List<Map> maps = await db!.rawQuery('SELECT MAX(id)+1 as id FROM penilaian_detail_input');
      if (maps.length > 0 && Helper().toInt(maps.first['id']) > 0) id = Helper().toInt(maps.first['id']);
      params['id'] = id;
      id = await db!.insert('penilaian_detail_input', params);
    }
    return await getPenilaianDetailInput(id);
  }

  Future<PenilaianDetail?> getPenilaianDetailInput(id) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('penilaian_detail_input',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.length > 0) {
      return PenilaianDetail.fromJson(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<PenilaianDetail>> getAllPenilaianDetailInput() async {
    List<PenilaianDetail> list = [];
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('penilaian_detail_input');
    for (Map map in maps) {
      list.add(PenilaianDetail.fromJson(maps.first as Map<String, dynamic>)) ;
    }
    return list;
  }

  Future<PenilaianDetail?> getPenilaianDetailInputBy(penilaianId, tanggal) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('penilaian_detail_input',
      where: "penilaian_id = ? AND tanggal = ? AND (deleted_at = '' OR deleted_at IS NULL)",
      whereArgs: [penilaianId, tanggal],
      limit: 1,
    );
    if (maps.length > 0) {
      return PenilaianDetail.fromJson(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<int> deletePenilaianDetailInput(int id) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    if (id > 0) return await db!.delete('penilaian_detail_input', where: 'id = ?', whereArgs: [id]);
    else return await db!.delete('penilaian_detail_input');
  }

  Future<Tunjangan?> insertTunjangan(Map<String, dynamic> values) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    int id = Helper().toInt(values['id']);
    Tunjangan? tunjangan = await getTunjangan(id, false);
    Map<String, dynamic> params = Map<String, dynamic>();
    values.forEach((key, value) {
      if (!['pengguna'].contains(key)) {
        params[key] = value;
      }
    });
    if (tunjangan != null) await db!.update('tunjangan', params, where: 'id = ?',whereArgs: [id]);
    else await db!.insert('tunjangan', params);
    return await getTunjangan(id, false);
  }

  Future<List<Tunjangan>> getTunjanganList(Map<String, dynamic> body) async {
    List<Tunjangan> list = [];
    String query = "SELECT * FROM tunjangan WHERE (deleted_at = '' OR deleted_at IS NULL)";
    int penggunaId = 0;
    if (body.containsKey('pengguna_id')) {
      query += " AND pengguna_id='${body['pengguna_id']}'";
      penggunaId = Helper().toInt(body['pengguna_id']);
    }
    if (body.containsKey('periode')) {
      var periodeList = body['periode'].split(',');
      String periode = periodeList[0];
      if (periodeList.length > 1) {
        print('tanggalMulai:periode $periode');
        var tanggalMulai = periode.substring(0, 4) + '-' + periode.substring(3, 5) + '-01';
        print('tanggalMulaitanggalMulai: $tanggalMulai');
        query += " AND tanggal_mulai ${periodeList[1]} '$tanggalMulai'";
      } else {
        query += " AND periode='$periode'";
      }
    }
    query += " GROUP BY id";
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.rawQuery(query);
    for(Map map in maps) {
      Tunjangan tunjangan = Tunjangan.fromMap(map as Map<String, dynamic>);
      if (tunjangan.penggunaId > 0) {
        tunjangan.pengguna = await getPengguna(tunjangan.penggunaId, false);
        tunjangan.pengguna!.listAkses = await getAksesList(tunjangan.penggunaId);
      }
      list.add(tunjangan);
    }
    return list;
  }

  Future<String> getAllTunjanganId() async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.rawQuery("SELECT GROUP_CONCAT(id) AS id FROM tunjangan WHERE (deleted_at = '' OR deleted_at IS NULL)");
    if (maps.length > 0) {
      print('Sqlite:listTunjangan: ${maps.first['id']}');
      return maps.first['id'].toString();
    }
    return '';
  }

  Future<List<String>> getPeriodeList() async {
    List<String> list = [];
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('tunjangan', columns: ['periode'], groupBy: 'periode', orderBy: 'periode');
    for(Map map in maps) {
      list.add(map['periode']);
    }
    return list;
  }

  Future<Tunjangan?> getTunjangan(id, bool deletedAt) async {
    if (id <= 0) return null;
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('tunjangan',
      where: deletedAt ? "id = ? AND (deleted_at = '' OR deleted_at IS NULL) " : 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.length > 0) {
      return Tunjangan.fromMap(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<Tunjangan?> getLastTunjangan() async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('tunjangan',
      orderBy: 'created_at DESC, updated_at DESC, deleted_at DESC',
      limit: 1,
    );
    if (maps.length > 0) {
      return Tunjangan.fromMap(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<int> deleteTunjangan(int id) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    if (id > 0) return await db!.delete('tunjangan', where: 'id = ?', whereArgs: [id]);
    else return await db!.delete('tunjangan');
  }

  Future<Pengguna?> insertPengguna(Map<String, dynamic> values) async {
    int id = Helper().toInt(values['id']);
    Pengguna? pengguna = await getPengguna(id, false);
    Map<String, dynamic> params = Map<String, dynamic>();
    values.forEach((key, value) {
      if (!['token', 'akses_list'].contains(key)) {
        params[key] = value;
      }
    });
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    if (pengguna != null) await db!.update('pengguna', params, where: 'id = ?',whereArgs: [id]);
    else await db!.insert('pengguna', params);
    return await getPengguna(id, false);
  }

  Future<Pengguna?> getPengguna(id, bool deletedAt) async {
    if (id <= 0) return null;
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('pengguna',
      where: deletedAt ? "id = ? AND (deleted_at = '' OR deleted_at IS NULL) " : 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.length > 0) {
      return Pengguna.fromJson(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<Pengguna>> getPenggunaList() async {
    List<Pengguna> list = [];
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('pengguna',
      where: "deleted_at = '' OR deleted_at IS NULL",
    );
    if (maps.length > 0) {
      for (Map map in maps){
        list.add(Pengguna.fromJson(map as Map<String, dynamic>));
      }
    }
    return list;
  }

  Future<int> deletePengguna(int id) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    if (id > 0) return await db!.delete('pengguna', where: 'id = ?', whereArgs: [id]);
    else return await db!.delete('pengguna');
  }

  Future<Token?> insertToken(Map<String, dynamic> values) async {
    int id = Helper().toInt(values['id']);
    Token? token = await getToken(id, false);
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    if (token != null) await db!.update('token', values, where: 'id = ?',whereArgs: [id]);
    else await db!.insert('token', values);
    return await getToken(id, false);
  }

  Future<Token?> getToken(id, bool deletedAt) async {
    if (id <= 0) return null;
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('token',
      where: deletedAt ? "id = ? AND (deleted_at = '' OR deleted_at IS NULL) " : 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.length > 0) {
      return Token.fromJson(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<int> deleteToken(int id) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    if (id > 0) return await db!.delete('token', where: 'id = ?', whereArgs: [id]);
    else return await db!.delete('token');
  }

  Future<Akses?> insertAkses(Map<String, dynamic> values) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    Map<String, Object> params = Map<String, Object>();
    params['pengguna_id'] = values['pengguna_id'];
    params['jabatan_id'] = values['jabatan_id'];
    params['lokasi_id'] = values['lokasi_id'];
    await db!.insert('akses', params);
    return Akses.fromJson(values);
  }

  Future<List<Akses>?> getAkses(penggunaId) async {
    List<Akses> list = [];
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('token',
      where: 'pengguna_id = ?',
      whereArgs: [penggunaId],
      limit: 1,
    );
    if (maps.length > 0) {
      for (Map map in maps) {
        list.add(Akses.fromJson(map as Map<String, dynamic>));
      }
    }
    return list;
  }

  Future<List<Akses>> getAksesList(penggunaId) async {
    List<Akses> list = [];
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    String query = "SELECT akses.*, jabatan.code as jabatan_code, jabatan.nama as jabatan_nama, " +
      " lokasi.nama as lokasi_nama FROM akses" +
      " JOIN jabatan ON akses.jabatan_id=jabatan.id AND (jabatan.deleted_at = '' OR jabatan.deleted_at IS NULL) " +
      " LEFT JOIN lokasi ON akses.lokasi_id=lokasi.id AND (lokasi.deleted_at = '' OR lokasi.deleted_at IS NULL) " +
      " WHERE akses.pengguna_id = '$penggunaId'";
    List<Map> maps = await db!.rawQuery(query);
    if (maps.length > 0) {
      for (Map map in maps) {
        list.add(Akses.fromJson(map as Map<String, dynamic>));
      }
    }
    return list;
  }

  Future<int?> deleteAkses(int penggunaId) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    return await db!.delete('akses', where: 'pengguna_id = ?', whereArgs: [penggunaId]);
  }

  Future<Lokasi?> insertLokasi(Map<String, dynamic> values) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    int id = Helper().toInt(values['lokasi_id'] ?? values['id']);
    if (id <= 0) return null;
    Lokasi? lokasi = await getLokasi(id, false);
    Map<String, Object> params = Map<String, Object>();
    params['id'] = id;
    params['nama'] = values['lokasi_nama'] ?? values['nama'];
    if (lokasi != null) await db!.update('lokasi', params, where: 'id = ?',whereArgs: [id]);
    else await db!.insert('lokasi', params);
    return await getLokasi(id, false);
  }

  Future<Lokasi?> getLokasi(id, bool deletedAt) async {
    if (id <= 0) return null;
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('lokasi',
      where: deletedAt ? "id = ? AND (deleted_at = '' OR deleted_at IS NULL) " : 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.length > 0) {
      return Lokasi.fromJson(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<Lokasi>> getLokasiList(Map<String, dynamic> values) async {
    List<Lokasi> list = [];
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('lokasi');
    for(Map map in maps) {
      list.add(Lokasi.fromJson(map as Map<String, dynamic>));
    }
    return list;
  }

  Future<int> deleteLokasi(int id) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    if (id > 0) return await db!.delete('lokasi', where: 'id = ?', whereArgs: [id]);
    else return await db!.delete('lokasi');
  }

  Future<Jabatan?> insertJabatan(Map<String, dynamic> values) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    int id = Helper().toInt(values['jabatan_id'] ?? values['id']);
    Jabatan? jabatan = await getJabatan(id, false);
    Map<String, Object> params = Map<String, Object>();
    params['id'] = id;
    params['code'] = values['jabatan_code'] ?? values['code'];
    params['nama'] = values['jabatan_nama'] ?? values['nama'];
    if (jabatan != null) await db!.update('jabatan', params, where: 'id = ?',whereArgs: [id]);
    else await db!.insert('jabatan', params);
    return await getJabatan(id, false);
  }

  Future<Jabatan?> getJabatan(id, bool deletedAt) async {
    if (id <= 0) return null;
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('jabatan',
      where: deletedAt ? "id = ? AND (deleted_at = '' OR deleted_at IS NULL) " : 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.length > 0) {
      return Jabatan.fromJson(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<Jabatan>> getJabatanList(Map<String, dynamic> values) async {
    List<Jabatan> list = [];
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('jabatan');
    for(Map map in maps) {
      list.add(Jabatan.fromJson(map as Map<String, dynamic>)) ;
    }
    return list;
  }

  Future<int> deleteJabatan(int id) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    if (id > 0) return await db!.delete('jabatan', where: 'id = ?', whereArgs: [id]);
    else return await db!.delete('jabatan');
  }

  Future<Libur?> insertLibur(Map<String, dynamic> values) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    var id = Helper().toInt(values['id']);
    Libur? libur = await getLibur(id, false);
    if (libur != null) await db!.update('libur', values, where: 'id = ?',whereArgs: [id]);
    else await db!.insert('libur', values);
    return await getLibur(id, false);
  }

  Future<Libur?> getLibur(id, bool deletedAt) async {
    if (id <= 0) return null;
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('libur',
      where: deletedAt ? "id = ? AND (deleted_at = '' OR deleted_at IS NULL) " : 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.length > 0) {
      return Libur.fromJson(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<Libur>> getLiburList(Map<String, dynamic> values) async {
    List<Libur> list = [];
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('libur');
    for(Map map in maps) {
      list.add(Libur.fromJson(map as Map<String, dynamic>)) ;
    }
    return list;
  }

  Future<int> deleteLibur(int id) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    if (id > 0) return await db!.delete('libur', where: 'id = ?', whereArgs: [id]);
    else return await db!.delete('libur');
  }

  Future<Verifikasi?> insertVerifikasi(Map<String, dynamic> values) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    var id = Helper().toInt(values['id']);
    Verifikasi? verifikasi = await getVerifikasi(id, false);
    if (verifikasi != null) await db!.update('verifikasi', values, where: 'id = ?',whereArgs: [id]);
    else await db!.insert('verifikasi', values);
    return await getVerifikasi(id, false);
  }

  Future<Verifikasi?> getVerifikasi(id, bool deletedAt) async {
    if (id <= 0) return null;
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('verifikasi',
      where: deletedAt ? "id = ? AND (deleted_at = '' OR deleted_at IS NULL) " : 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.length > 0) {
      return Verifikasi.fromJson(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<int> deleteVerifikasi(int id) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    if (id > 0) return await db!.delete('verifikasi', where: 'id = ?', whereArgs: [id]);
    else return await db!.delete('verifikasi');
  }

  Future<Verifikasi?> getLastVerifikasi() async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('verifikasi',
      orderBy: 'created_at DESC, updated_at DESC, deleted_at DESC',
      limit: 1,
    );
    if (maps.length > 0) {
      return Verifikasi.fromJson(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<Verifikasi?> insertVerifikasiInput(Map<String, dynamic> values) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    var id = await db!.insert('verifikasi_input', values);
    return await getVerifikasiInput(id);
  }

  Future<Verifikasi?> getVerifikasiInput(id) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('verifikasi_input',
      where: 'id = ? AND deleted_at',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.length > 0) {
      return Verifikasi.fromJson(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<Verifikasi>> getAllVerifikasiInput() async {
    List<Verifikasi> list = [];
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    List<Map> maps = await db!.query('verifikasi_input');
    for (Map map in maps) {
      list.add(Verifikasi.fromJson(maps.first as Map<String, dynamic>));
    }
    return list;
  }

  Future<int> deleteVerifikasiInput(int id) async {
    if (db == null) db = await initDatabase(Constant.DB_NAME);
    if (id > 0) return await db!.delete('verifikasi_input', where: 'id = ?', whereArgs: [id]);
    else return await db!.delete('verifikasi_input');
  }

  // deleteAll() async {
  //   await deleteAkses(0);
  //   await deleteFile(0);
  //   await deleteJabatan(0);
  //   await deleteLibur(0);
  //   await deleteLokasi(0);
  //   await deleteNotifikasi(0);
  //   await deletePekerjaan(0);
  //   await deletePengguna(0);
  //   await deletePenilaian(0);
  //   await deletePenilaianDetail(0);
  //   await deleteToken(0);
  //   await deleteTunjangan(0);
  //   await deleteVerifikasi(0);
  // }
}