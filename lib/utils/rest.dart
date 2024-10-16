import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app/entities/atasan.dart';
import 'package:app/entities/lokasi.dart';
import 'package:app/entities/pekerjaan.dart';
import 'package:async/async.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

import '/entities/file.dart';
import '/entities/libur.dart';
import '/entities/notifikasi.dart';
import '/entities/penilaian.dart';
import '/entities/penilaian_detail.dart';
import '/entities/token.dart';
import '/entities/tunjangan.dart';
import '/entities/jabatan.dart';
import '/entities/pengguna.dart';
import 'constant.dart';
import 'helper.dart';

class Rest {

  Future<Map<String, String>> getHeaders() async {
    String token = await Helper().getSessionString('token');
    return {
        HttpHeaders.authorizationHeader: 'Basic $token'
    };
  }

  Future<List<Jabatan>> fetchJabatanList() async {
    List<Jabatan> listJabatan = [];
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/jabatan');
      var response = await client.get(uri, headers: await getHeaders());
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      for (var t in decodedResponse['data']) {
        listJabatan.add(Jabatan.fromJson(t));
      }
    } finally {
      client.close();
    }
    return listJabatan;
  }

  Future<List<Pengguna>> fetchPenggunaList(jabatanId, exceptId) async {
    List<Pengguna> listPengguna = [];
    Map<String, String> param = {};
    if (jabatanId > 0) param = {'jabatan_id': jabatanId.toString()};
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/pengguna', param);
      var response = await client.get(uri, headers: await getHeaders());
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      for (var t in decodedResponse['data']) {
        Pengguna pengguna = Pengguna.fromJson(t);
        if (pengguna.id != exceptId) {
          listPengguna.add(pengguna);
        }
      }
    } finally {
      client.close();
    }
    return listPengguna;
  }

  Future<List<Atasan>> fetchAtasanList(penggunaId) async {
    List<Atasan> listAtasan = [];
    Map<String, String> param = {};
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/pengguna/atasan/$penggunaId');
      print('Rest:fetchAtasanList: ${uri.toString()}');
      var response = await client.get(uri, headers: await getHeaders());
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      for (var t in decodedResponse['atasan_list']) {
        listAtasan.add(Atasan.fromJson(t));
      }
    } finally {
      client.close();
    }
    return listAtasan;
  }

  Future<List<String>> fetchPeriodeList() async {
    List<String> list = [];
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/tunjangan/periode');
      var response = await client.get(uri, headers: await getHeaders());
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      for (var t in decodedResponse['data']) {
        list.add(t);
      }
    } finally {
      client.close();
    }
    return list;
  }

  Future<List<Tunjangan>> fetchTunjanganList(Map<String, String> body) async {
    List<Tunjangan> listTunjangan = [];
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/tunjangan', body);
      print('Rest:fetchTunjanganList: ${uri.toString()}');
      print('Rest:fetchTunjanganList:body ${body.toString()}');
      var response = await client.get(uri, headers: await getHeaders());
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      for (var t in decodedResponse['data']) {
        listTunjangan.add(Tunjangan.fromJson(t));
      }
    } finally {
      client.close();
    }
    return listTunjangan;
  }

  Future<Tunjangan> fetchTunjangan(id) async {
    Tunjangan? tunjangan;
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/tunjangan/tampil/$id');
      var response = await client.get(uri, headers: await getHeaders());
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      tunjangan = Tunjangan.fromMap(decodedResponse['data']);
    } finally {
      client.close();
    }
    return tunjangan;
  }

  Future<List<Tunjangan>> pushTunjanganDuplicate(id, List<int> penggunaIds, String? periode) async {
    List<Tunjangan> list = [];
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/tunjangan/duplikasi/$id');
      var body = {'pengguna_id': penggunaIds.join(','), 'periode': periode};
      var response = await client.post(uri, headers: await getHeaders(), body: body);
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      for (var t in decodedResponse['data']) {
        list.add(Tunjangan.fromMap(t));
      }
    } finally {
      client.close();
    }
    return list;
  }

  Future<List<Lokasi>> fetchLokasiList() async {
    List<Lokasi> listLokasi = [];
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/lokasi');
      var response = await client.get(uri, headers: await getHeaders());
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      for (var t in decodedResponse['data']) {
        listLokasi.add(Lokasi.fromJson(t));
      }
    } finally {
      client.close();
    }
    return listLokasi;
  }

  Future<List<Pekerjaan>> fetchPekerjaanList() async {
    List<Pekerjaan> listPekerjaan = [];
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/pekerjaan');
      var response = await client.get(uri, headers: await getHeaders());
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      for (var t in decodedResponse['data']) {
        listPekerjaan.add(Pekerjaan.fromJson(t));
      }
    } finally {
      client.close();
    }
    return listPekerjaan;
  }

  Future<List<Penilaian>> fetchPenilaianList(Tunjangan tunjangan) async {
    List<Penilaian> listPenilaian = [];
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/penilaian', {'tunjangan_id': tunjangan.id.toString(), 'detail': '1'});
      var response = await client.get(uri, headers: await getHeaders());
      print('Penilaian:uri ${uri.toString()}');
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      for (var t in decodedResponse['data']) {
        listPenilaian.add(Penilaian.fromJson(t));
      }
    } finally {
      client.close();
    }
    return listPenilaian;
  }

  Future<List<PenilaianDetail>> fetchPenilaianDetailList(
      Penilaian penilaian) async {
    List<PenilaianDetail> listPenilaianDetail = [];
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/penilaianDetail',
          {'penilaian_id': penilaian.id.toString()});
      var response = await client.get(uri, headers: await getHeaders());
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      for (var t in decodedResponse['data']) {
        listPenilaianDetail.add(PenilaianDetail.fromJson(t));
      }
    } finally {
      client.close();
    }
    return listPenilaianDetail;
  }

  Future<PenilaianDetail> savePenilaianDetail(Map<String, String> body) async {
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/penilaianDetail/simpan');
      var response = await client.post(uri, headers: await getHeaders(), body: body);
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      return PenilaianDetail.fromJson(decodedResponse['data']);
    } finally {
      client.close();
    }
  }

  Future<List<Libur>> fetchLiburList(Map<String, String> body) async {
    List<Libur> listLibur = [];
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/libur', body);
      var response = await client.get(uri, headers: await getHeaders());
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      for (var t in decodedResponse['data']) {
        listLibur.add(Libur.fromJson(t));
      }
    } finally {
      client.close();
    }
    return listLibur;
  }

  Future<Map> fetchHoliday(id) async {
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/libur/tunjangan/$id');
      var response = await client.get(uri, headers: await getHeaders());
      print('Rest:fetchHoliday:uri: ${uri.toString()}');
      print('Rest:fetchHoliday:body: ${response.body}');
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      if (decodedResponse != null) return decodedResponse['data'];
    } finally {
    //   client.close();
    }
    return {};
  }

  Future<Map<String, dynamic>> fetchToken(token) async {
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/pengguna/token/$token');
      var response = await client.post(uri);
      print('Rest:fetchToken:uri: ${uri.toString()}');
      print('Rest:fetchToken:body: ${response.body}');
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } finally {
      client.close();
    }
    return Map<String, dynamic>();
  }

  Future<Token> updateToken(id, Map<String, String> body) async {
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/token/update/$id');
      var response = await client.post(uri, headers: await getHeaders(), body: body);
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      return Token.fromJson(decodedResponse['data']);
    } finally {
      client.close();
    }
  }

  Future<List<Notifikasi>> fetchAllNotifikasiOneSignal(Map<String, String>? body) async {
    List<Notifikasi> listNotifikasi = [];
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/notifikasi/onesignal', body);
      var response = await client.get(uri, headers: await getHeaders());
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      for (var t in decodedResponse['data']) {
        listNotifikasi.add(Notifikasi.fromJson(t));
      }
    } finally {
      client.close();
    }
    return listNotifikasi;
  }

  Future<FileModel?> saveFile(File file, penilaianDetailId) async {
    var client = http.Client();
    var body = {};
    FileModel? fileModel;
    try {
      var stream = new http.ByteStream(DelegatingStream.typed(file.openRead()));
      // get file length
      var length = await file.length();
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/file/simpan');

      var multipartFileSign = new http.MultipartFile('file', stream, length,
          filename: basename(file.path)
      );
      var request = new http.MultipartRequest("POST", uri);
      request.files.add(multipartFileSign);
      request.fields['penilaian_detail_id'] = penilaianDetailId.toString();

      // send
      var response = await request.send();
    } finally {
      client.close();
    }
    return fileModel;
  }

  Future<Map<String, dynamic>> syncFile(Map<String, String>? body) async {
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/file/sync', body);
      print('Rest:syncFile ${uri.toString()}');
      print('Rest:syncFile:body ${body.toString()}');
      var response = await client.get(uri, headers: await getHeaders());
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } finally {
      client.close();
    }
    return Map<String, dynamic>();
  }

  Future<Map<String, dynamic>> syncPenilaian(Map<String, String>? body) async {
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/penilaian/sync', body);
      print('Rest:syncPenilaian ${uri.toString()}');
      print('Rest:syncPenilaian:body ${body.toString()}');
      var response = await client.get(uri, headers: await getHeaders());
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } finally {
      client.close();
    }
    return Map<String, dynamic>();
  }

  Future<Map<String, dynamic>> syncPenilaianDetail(Map<String, String>? body) async {
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/penilaianDetail/sync', body);
      print('Rest:syncPenilaianDetail ${uri.toString()}');
      print('Rest:syncPenilaianDetail:body ${body.toString()}');
      var response = await client.get(uri, headers: await getHeaders());
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } finally {
      client.close();
    }
    return Map<String, dynamic>();
  }

  Future<Map<String, dynamic>> syncVerifikasi(Map<String, String>? body) async {
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/verifikasi/sync', body);
      print('Rest:syncVerifikasi ${uri.toString()}');
      print('Rest:syncVerifikasi:body ${body.toString()}');
      var response = await client.get(uri, headers: await getHeaders());
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } finally {
      client.close();
    }
    return Map<String, dynamic>();
  }

  Future<Map<String, dynamic>> savePenilaianDetailFile(File file, Map<String, dynamic> body) async {
    var client = http.Client();
    try {
      var stream = new http.ByteStream(DelegatingStream.typed(file.openRead()));
      var length = await file.length();
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/penilaianDetail/file');

      var multipartFileSign = new http.MultipartFile('file', stream, length,
          filename: basename(file.path)
      );
      var request = new http.MultipartRequest("POST", uri);
      request.files.add(multipartFileSign);
      body.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // var response = await client.post(uri, headers: {}, body: body);
      http.StreamedResponse response = await request.send();
      String responseString = await response.stream.bytesToString();
      print('Rest:savePenilaianDetailFile: $responseString');
      // return jsonDecode(responseString) as Map<String, dynamic>;
    } finally {
      client.close();
    }
    return Map<String, dynamic>();
  }
}