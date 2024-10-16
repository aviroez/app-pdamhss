import 'dart:convert';

import 'package:app/components/text_subtitle.dart';
import 'package:app/utils/sqlite.dart';
import 'dart:developer' as developer;
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'components/background.dart';
import 'entities/pekerjaan.dart';
import 'entities/tunjangan.dart';
import 'entities/pengguna.dart';
import 'entities/penilaian.dart';
import 'menu.dart';
import 'penilaian.dart';
import 'penilaian_list.dart';
import 'utils/constant.dart';
import 'utils/helper.dart';
import 'utils/rest.dart';

class PenilaianInputRoute extends StatelessWidget {
  String message;
  int _penilaianId = 0;
  Tunjangan? _tunjangan;

  PenilaianInputRoute(this.message, this._penilaianId, this._tunjangan);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Input Pekerjaan",
      home: PenilaianInputStatefulWidget(this.message, this._penilaianId, this._tunjangan!),
    );
  }
}

class PenilaianInputStatefulWidget extends StatefulWidget {
  String message;
  int _penilaianId = 0;
  Tunjangan? _tunjangan;

  PenilaianInputStatefulWidget(this.message, this._penilaianId, this._tunjangan);

  @override
  CustomPenilaianInputStatefulWidget createState() => CustomPenilaianInputStatefulWidget(this.message, this._penilaianId, this._tunjangan!);
}

class CustomPenilaianInputStatefulWidget extends State<PenilaianInputStatefulWidget> {
  String message;
  final textTanggalMulaiController = TextEditingController();
  final textTanggalSelesaiController = TextEditingController();
  final textBobotController = TextEditingController();
  final textTargetController = TextEditingController();
  final textDeskripsiController = TextEditingController();
  bool tanggalMulaiFocus = false;
  bool tanggalSelesaiFocus = false;
  bool bobotFocus = false;
  bool targetFocus = false;
  bool loading = false;
  bool firstLoad = true;
  bool initTunjanganLoaded = false;
  bool initPenggunaLoaded = false;
  bool isCheckedLebih = false;
  int _penilaianId = 0;
  int totalDays = 31;
  String _periode = '';
  String _tipe = '';
  Tunjangan? _tunjangan;
  Pengguna? _pengguna;
  Penilaian? _penilaian;
  Pekerjaan? _pekerjaan;
  List<Tunjangan> listTunjangan = [];
  List<Pekerjaan> listPekerjaan = [];
  List<String> listTipe = ['harian', 'jumlah', 'nominal', 'persen'];
  Sqlite sqlite = new Sqlite();

  CustomPenilaianInputStatefulWidget(this.message, this._penilaianId, this._tunjangan);

  @override
  void initState() {
    super.initState();
    var now = DateTime.now();

    if (this._penilaianId <= 0) {
      initTunjanganLoaded = true;
      initPenggunaLoaded = true;
    }
    textTanggalMulaiController.text = _tunjangan!.tanggalMulai;
    textTanggalSelesaiController.text = _tunjangan!.tanggalSelesai;

    _fetchTunjanganList().then((value) {
      setState((){
        listTunjangan = value;
      });
    });

    Rest().fetchPekerjaanList().then((value) {
      setState((){
        listPekerjaan = value;
      });
    });
    _periode = _tunjangan!.periode;

    Rest().fetchHoliday(_tunjangan!.id).then((value) {
      if (value != null && value['total'] != null) {
        setState((){
          totalDays = value['total'];
          print('PenilaianInput:totalDays: $totalDays');
        });
      }
    });

    if (_penilaianId > 0){
      _fetchPenilaian(_penilaianId).then((value){
        setState((){
          _penilaian = value;
          if (_penilaian != null) {
            textTanggalMulaiController.text = _penilaian!.tanggalMulai;
            textTanggalSelesaiController.text = _penilaian!.tanggalSelesai;
            textBobotController.text = Helper().removeDecimalZeroFormat(_penilaian!.bobot);
            textTargetController.text = Helper().removeDecimalZeroFormat(_penilaian!.target);
            // textPenilaianController.text = Helper().removeDecimalZeroFormat(_penilaian.penilaian);
            textDeskripsiController.text = _penilaian!.deskripsi;
            isCheckedLebih = _penilaian!.lebih;
            _tipe = _penilaian!.tipe;
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    if (mounted && firstLoad) {
      firstLoad = false;
    }

    return WillPopScope(
        onWillPop: () {
        return _moveToPenilaianList(context, _tunjangan);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              _moveToPenilaianList(context, _tunjangan);
            },
          ),
          title: _penilaianId > 0 ? Text('Ubah Pekerjaan') : Text('Input Pekerjaan'),
        ),
        body: Container(
          width: width,
          height: height,
          child: Stack(
            children: <Widget>[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      primaryColor: Colors.blueAccent,
                      primaryColorDark: Colors.blue,
                      accentColor: Colors.lightBlueAccent,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        TextFormField(
                          enabled: false,
                          autofocus: false,
                          initialValue: Helper().parsePeriode(_periode),
                          decoration: InputDecoration(
                            labelText: "Periode",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        DropdownSearch<Pekerjaan>(
                          autoFocusSearchBox: true,
                          selectedItem: _pekerjaan,
                          label: 'Pekerjaan',
                          onFind: (String filter) async {
                            return this.listPekerjaan;
                          },
                          itemAsString: (Pekerjaan pekerjaan) {
                            return pekerjaan.nama != null ? pekerjaan.nama : 'Pilih Pekerjaan';
                          },
                          onChanged: (data) {
                            _parsePekerjaan(data);
                          },
                          validator: (data){
                            if (data!.id <= 0) return 'Pilih Pekerjaan';
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                        DropdownSearch<String>(
                          autoFocusSearchBox: true,
                          selectedItem: _tipe,
                          items: this.listTipe,
                          label: 'Tipe',
                          itemAsString: (String string) {
                            return string != '' ? string.toUpperCase() : 'Pilih Tipe';
                          },
                          onChanged: (data) {
                            // _onchangePeriode(data);
                            setState(() {
                              if (data == 'harian') {
                                textTargetController.text = totalDays.toString();
                              } else if (data == 'jumlah') {
                                textTargetController.text = '1';
                              } else if (data == 'nominal') {
                                textTargetController.text = '1';
                              } else if (data == 'persen') {
                                textTargetController.text = '100';
                              }
                            });
                          },
                          validator: (data){
                            if (data == '') return 'Pilih Tipe';
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                        TextField(
                          autofocus: targetFocus,
                          controller: textTargetController,
                          decoration: InputDecoration(
                            labelText: "Target",
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blueAccent, width: 1),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Checkbox(
                              checkColor: Colors.white,
                              fillColor: MaterialStateProperty.resolveWith(Helper().getColor),
                              value: isCheckedLebih,
                              onChanged: (bool? value) {
                                setState(() {
                                  isCheckedLebih = value!;
                                });
                              },
                            ),
                            Text('Bisa Melebihi Target')
                          ],
                        ),
                        SizedBox(height: 10),
                        // TextFormField(
                        //   autofocus: false,
                        //   controller: textTanggalMulaiController,
                        //   // initialValue: isUraian ? 'Uraian' : 'Email',
                        //   decoration: InputDecoration(
                        //     labelText: "Tanggal Mulai",
                        //     border: OutlineInputBorder(),
                        //   ),
                        // ),
                        // SizedBox(height: 10),
                        // TextFormField(
                        //   autofocus: false,
                        //   controller: textTanggalSelesaiController,
                        //   // initialValue: isUraian ? 'Uraian' : 'Email',
                        //   decoration: InputDecoration(
                        //     labelText: "Tanggal Selesai",
                        //     border: OutlineInputBorder(),
                        //   ),
                        // ),
                        // SizedBox(height: 10),
                        TextField(
                          autofocus: bobotFocus,
                          controller: textBobotController,
                          decoration: InputDecoration(
                            labelText: "Bobot",
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blueAccent, width: 1),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: textDeskripsiController,
                          decoration: InputDecoration(
                            labelText: "Deskripsi",
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blueAccent, width: 1),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        _submitButton(context),
                        SizedBox(height: 5)
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _submitButton(BuildContext context) {
    return InkWell(
      onTap: (){
        _submitProcess(context);
      },
      onLongPress: (){
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                  color: Colors.grey.shade200,
                  offset: Offset(2, 4),
                  blurRadius: 5,
                  spreadRadius: 2
              )
            ],
            gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.blue, Colors.blueAccent]
            )
        ),
        child: Text(
          "Ajukan",
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }

  _submitProcess(BuildContext context) {
    if (textBobotController.text == '') {
      _setFocus('bobot');
      return _showSnackBar(context, 'Bobot Harus diisi');
    } else if (textTargetController.text == '') {
      _setFocus('target');
      return _showSnackBar(context, 'Target Harus diisi');
    }
    // else if (textTanggalMulaiController.text == '') {
    //   _setFocus('tanggal_mulai');
    //   return _showSnackBar(context, 'Tanggal Mulai Harus diisi');
    // } else if (textTanggalSelesaiController.text == '') {
    //   _setFocus('tanggal_selesai');
    //   return _showSnackBar(context, 'Tanggal Selesai Harus diisi');
    // }
    setState(() {
      loading = true;
    });
    _savePenilaian(_tunjangan!.id, _pekerjaan!.id, _pekerjaan!.nama, _tipe, textBobotController.text,
        textTargetController.text, textDeskripsiController.text,
        textTanggalMulaiController.text, textTanggalSelesaiController.text, 'proses').then((value) {
        setState(() {
          loading = false;
          _penilaian = value;
        });
        _showSnackBar(context, 'Berhasil menyimpan data');
        _moveToPenilaian(context, _tunjangan!);
    });
  }

  Future<Penilaian> _fetchPenilaian(id) async {
    Penilaian? penilaian;
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/penilaian/tampil/$id');
      var response = await client.get(uri);
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      penilaian = Penilaian.fromMap(decodedResponse['data']);
      sqlite.insertPenilaian(Map<String, dynamic>.from(penilaian.toJson()));
    } finally {
      client.close();
    }
    return penilaian;
  }

  Future<List<Tunjangan>> _fetchTunjanganList() async {
    List<Tunjangan> listTunjangan = [];
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/tunjangan');
      var response = await client.get(uri);
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      for (var t in decodedResponse['data']) {
        listTunjangan.add(Tunjangan.fromJson(t));
        sqlite.insertTunjangan(Map<String, dynamic>.from(t));
      }
    } finally {
      client.close();
    }
    return listTunjangan;
  }

  Future<Penilaian> _savePenilaian(int tunjanganId, int pekerjaanId, String nama,
      String tipe, String bobot, String target, String deskripsi,
      String tanggalMulai, String tanggalSelesai, String status) async {
    var client = http.Client();
    var body = {
      'tunjangan_id': tunjanganId.toString(), 'pekerjaan_id': pekerjaanId.toString(), 'nama': nama,
      'tipe': tipe, 'bobot': bobot, 'target': target, 'deskripsi': deskripsi,
      'tanggal_mulai': tanggalMulai, 'tanggal_selesai': tanggalSelesai, 'status': status, 'lebih': isCheckedLebih ? '1' : ''
    };

    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/penilaian/simpan');
      var response = await client.post(uri, headers: {}, body: body);
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      sqlite.insertPenilaian(Map<String, dynamic>.from(decodedResponse['data']));
      return Penilaian.fromJson(decodedResponse['data']);
    } finally {
      client.close();
    }
  }

  _setFocus(focusCode) {
    setState((){
      tanggalMulaiFocus = false;
      tanggalSelesaiFocus = false;
      bobotFocus = false;
      targetFocus = false;

      if (focusCode == 'tanggal_mulai') tanggalMulaiFocus = true;
      if (focusCode == 'tanggal_selesai') tanggalSelesaiFocus = true;
      if (focusCode == 'bobot') bobotFocus = true;
      if (focusCode == 'target') targetFocus = true;
    });

    return true;
  }

  _showSnackBar(BuildContext context, message) {
    if (message != '') {
      SnackBar snackBar = SnackBar(content: Text(message));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _parsePekerjaan(Pekerjaan? data) {
    setState(() {
      _pekerjaan = data!;


      if (_pekerjaan != null) {
        textBobotController.text = Helper().removeDecimalZeroFormat(_pekerjaan!.bobot);
        textTargetController.text = Helper().removeDecimalZeroFormat(_pekerjaan!.nilai);
        // textPenilaianController.text = Helper().removeDecimalZeroFormat(_penilaian.penilaian);
        textDeskripsiController.text = _pekerjaan!.deskripsi;
        isCheckedLebih = _pekerjaan!.lebih;
        _tipe = _pekerjaan!.tipe;
      }
    });
  }

  _moveToPenilaian(BuildContext context, Tunjangan tunjangan) {
    Route route = MaterialPageRoute(builder: (context) => PenilaianListRoute("", tunjangan));
    Navigator.pushReplacement(context, route);
  }

  _moveToPenilaianList(BuildContext context, Tunjangan? tunjangan) {
    Route route = MaterialPageRoute(builder: (context) => PenilaianListRoute("", tunjangan!));
    Navigator.pushReplacement(context, route);
  }
}