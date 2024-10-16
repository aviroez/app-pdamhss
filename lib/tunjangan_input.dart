import 'dart:convert';

import 'package:app/components/text_subtitle.dart';
import 'package:app/utils/sqlite.dart';
import 'dart:developer' as developer;
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

import 'components/background.dart';
import 'entities/jabatan.dart';
import 'entities/pengguna.dart';
import 'entities/tunjangan.dart';
import 'menu.dart';
import 'tunjangan_list.dart';
import 'utils/constant.dart';
import 'utils/helper.dart';
import 'utils/rest.dart';

class TunjanganInputRoute extends StatelessWidget {
  String message;
  int _tunjanganId = 0;

  TunjanganInputRoute(this.message, this._tunjanganId);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Input Pekerjaan",
      home: TunjanganInputStatefulWidget(this.message, this._tunjanganId),
    );
  }
}

class TunjanganInputStatefulWidget extends StatefulWidget {
  String message;
  int _tunjanganId = 0;

  TunjanganInputStatefulWidget(this.message, this._tunjanganId);

  @override
  CustomTunjanganInputStatefulWidget createState() => CustomTunjanganInputStatefulWidget(this.message, this._tunjanganId);
}

class CustomTunjanganInputStatefulWidget extends State<TunjanganInputStatefulWidget> {
  String message;
  final textTanggalMulaiController = TextEditingController();
  final textTanggalSelesaiController = TextEditingController();
  final textTunjanganController = TextEditingController();
  final textDeskripsiController = TextEditingController();
  bool tanggalMulaiFocus = false;
  bool tanggalSelesaiFocus = false;
  bool tunjanganFocus = false;
  bool loading = false;
  bool firstLoad = true;
  bool initJabatanLoaded = false;
  bool initPenggunaLoaded = false;
  int _tunjanganId = 0;
  String _periode = '';
  Jabatan? _jabatan;
  Pengguna? _pengguna;
  Tunjangan? _tunjangan;
  List<Jabatan> listJabatan = [];
  List<Pengguna> listPengguna = [];
  List<String> listPeriode = [];
  Sqlite sqlite = new Sqlite();

  CustomTunjanganInputStatefulWidget(this.message, this._tunjanganId);

  @override
  void initState() {
    super.initState();
    var now = DateTime.now();
    listPeriode.add(DateFormat('yMM').format(now));
    var nextMonth = Jiffy();
    for (var i = 1; i <= 5; i++) {
      nextMonth = nextMonth.add(months: 1);
      // var nextMonth = new DateTime(now.year, now.month + i, now.day);
      listPeriode.add(DateFormat('yMM').format(nextMonth.dateTime));
      print('listPeriode:now: ${now.year}-${now.month}-${now.day}');
      print('listPeriode:nextMonth: ${nextMonth.year}-${nextMonth.month}-${nextMonth.day}');
    }

    if (this._tunjanganId <= 0) {
      initJabatanLoaded = true;
      initPenggunaLoaded = true;
    }

    sqlite.getJabatanList({}).then((value) {
      setState((){
        listJabatan = value;
      });
      if (listJabatan.isEmpty) {
        Rest().fetchJabatanList().then((value) {
          setState((){
            listJabatan = value;
          });
          for(Jabatan jabatan in listJabatan) {
            sqlite.insertJabatan(Map<String, dynamic>.from(jabatan.toJson()));
          }
          _parseJabatan(_tunjangan, listJabatan);
          if (_tunjangan != null) _parsePenggunaSelected(_tunjangan!.jabatanId, true);
        });
      } else {
        _parseJabatan(_tunjangan, listJabatan);
        if (_tunjangan != null) _parsePenggunaSelected(_tunjangan!.jabatanId, true);
      }
    });

    if (_tunjanganId > 0){
      Rest().fetchTunjangan(_tunjanganId).then((value){
        setState((){
          _tunjangan = value;
          if (_tunjangan != null) {
            sqlite.insertTunjangan(Map<String, dynamic>.from(_tunjangan!.toJson()));
            textTanggalMulaiController.text = _tunjangan!.tanggalMulai;
            textTanggalSelesaiController.text = _tunjangan!.tanggalMulai;
            textTunjanganController.text = Helper().removeDecimalZeroFormat(_tunjangan!.tunjangan);
            textDeskripsiController.text = _tunjangan!.deskripsi;
            _periode = _tunjangan!.periode;
          }

          _parseJabatan(_tunjangan!, listJabatan);
          _parsePenggunaSelected(_tunjangan!.jabatanId, true);
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
          return _moveToTunjanganList(context);
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                _moveToTunjanganList(context);
              },
            ),
            title: _tunjanganId > 0 ? Text('Ubah Pekerjaan') : Text('Input Pekerjaan'),
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
                          SizedBox(height: 10),
                          DropdownSearch<Jabatan>(
                            autoFocusSearchBox: true,
                            selectedItem: _jabatan,
                            label: 'Jabatan',
                            onFind: (String filter) async {
                              return this.listJabatan;
                            },
                            itemAsString: (Jabatan jabatan) {
                              return jabatan.nama != null ? jabatan.nama : 'Pilih Jabatan';
                            },
                            onChanged: (data) {
                              setState(() {
                                _jabatan = data!;
                                _parsePenggunaSelected(data.id, false);
                              });
                            },
                            validator: (data){
                              if (data!.id <= 0) return 'Pilih Jabatan';
                              return null;
                            },
                          ),
                          SizedBox(height: 10),
                          DropdownSearch<Pengguna>(
                            autoFocusSearchBox: true,
                            selectedItem: _pengguna,
                            label: 'Karyawan',
                            onFind: (String filter) async {
                              return this.listPengguna;
                            },
                            itemAsString: (Pengguna pengguna) {
                              return pengguna.nama != null ? pengguna.nama : 'Pilih Karyawan';
                            },
                            onChanged: (data) {
                              setState(() {
                                _pengguna = data!;
                                // _getEvents(data);
                              });
                            },
                            validator: (data){
                              if (data!.id <= 0) return 'Pilih Karyawan';
                              return null;
                            },
                          ),
                          SizedBox(height: 10),
                          DropdownSearch<String>(
                            autoFocusSearchBox: true,
                            selectedItem: _periode,
                            label: 'Periode',
                            onFind: (String filter) async {
                              return this.listPeriode;
                            },
                            itemAsString: (String string) {
                              return string != '' ? Helper().parsePeriode(string) : 'Pilih Periode';
                            },
                            onChanged: (data) {
                              _onchangePeriode(data);
                            },
                            validator: (data){
                              if (data == '') return 'Pilih Periode';
                              return null;
                            },
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            autofocus: tanggalMulaiFocus,
                            controller: textTanggalMulaiController,
                            // initialValue: isUraian ? 'Uraian' : 'Email',
                            decoration: InputDecoration(
                              labelText: "Tanggal Mulai",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            autofocus: tanggalSelesaiFocus,
                            controller: textTanggalSelesaiController,
                            // initialValue: isUraian ? 'Uraian' : 'Email',
                            decoration: InputDecoration(
                              labelText: "Tanggal Selesai",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          // SizedBox(height: 10),
                          // TextField(
                          //   autofocus: tunjanganFocus,
                          //   controller: textTunjanganController,
                          //   decoration: InputDecoration(
                          //     labelText: "Tunjangan",
                          //     border: OutlineInputBorder(
                          //       borderSide: BorderSide(color: Colors.blueAccent, width: 1),
                          //     ),
                          //   ),
                          // ),
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
        )
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
    if (_jabatan == null || _jabatan!.id <= 0) {
      return _showSnackBar(context, 'Jabatan Harus diisi');
    } else if (_pengguna == null || _pengguna!.id <= 0) {
      return _showSnackBar(context, 'Pengguna Harus diisi');
    } else if (_periode == '') {
      return _showSnackBar(context, 'Periode Harus diisi');
    // } else if (textTunjanganController.text == '') {
    //   _setFocus('tunjangan');
    //   return _showSnackBar(context, 'Tunjangan Harus diisi');
    } else if (textTanggalMulaiController.text == '') {
      _setFocus('tanggal_mulai');
      return _showSnackBar(context, 'Tanggal Mulai Harus diisi');
    } else if (textTanggalSelesaiController.text == '') {
      _setFocus('tanggal_selesai');
      return _showSnackBar(context, 'Tanggal Selesai Harus diisi');
    }
    setState(() {
      loading = true;
    });
    double bobot = 0;
    if (_tunjangan != null) bobot = _tunjangan!.bobot;
    _saveTunjangan(_jabatan!.id, _pengguna!.id, '', _periode, bobot, textTunjanganController.text, textDeskripsiController.text,
        textTanggalMulaiController.text, textTanggalSelesaiController.text, 'draft').then((value) {
        setState(() {
          loading = false;
          _moveToMenuList(context);
        });
    });
  }

  Future<Tunjangan> _saveTunjangan(int jabatanId, int penggunaId, String nama,
      String periode, double bobot, String tunjangan, String deskripsi, String tanggalMulai, String tanggalSelesai,
      String status) async {
    var client = http.Client();
    var body = {
      'jabatan_id': jabatanId.toString(), 'pengguna_id': penggunaId.toString(),
      'nama': nama, 'periode': periode, 'bobot': bobot.toString(), 'tunjangan': tunjangan, 'deskripsi': deskripsi,
      'tanggal_mulai': tanggalMulai, 'tanggal_selesai': tanggalSelesai, 'status': status
    };
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/tunjangan/simpan');
      var response = await client.post(uri, headers: {}, body: body);
      print('TunjanganInput:_saveTunjangan: ${uri.toString()}');
      print('TunjanganInput:_saveTunjangan:body: ${response.body}');
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      return Tunjangan.fromJson(decodedResponse['data']);
    } finally {
      client.close();
    }
  }

  _moveToMenuList(BuildContext context) {
    Route route = MaterialPageRoute(builder: (context) => MenuRoute(""));
    return Navigator.pushReplacement(context, route);
  }

  _moveToTunjanganList(BuildContext context) {
    Route route = MaterialPageRoute(builder: (context) => TunjanganListRoute(""));
    return Navigator.pushReplacement(context, route);
  }

  _setFocus(focusCode) {
    setState((){
      tanggalMulaiFocus = false;
      tanggalSelesaiFocus = false;
      tunjanganFocus = false;

      if (focusCode == 'tanggal_mulai') tanggalMulaiFocus = true;
      if (focusCode == 'tanggal_selesai') tanggalSelesaiFocus = true;
      if (focusCode == 'tunjangan') tunjanganFocus = true;
    });

    return true;
  }

  void _onchangePeriode(String? data) {
    setState(() {
      _periode = data!;
      var tahun = Helper().toInt(_periode.substring(0, 4));
      var bulan = Helper().toInt(_periode.substring(4, 6));

      var tahunSebelumnya = tahun;
      var bulanSebelumnya = bulan;
      if (bulan > 1) {
        bulanSebelumnya = bulan-1;
        if (bulanSebelumnya < 10) bulanSebelumnya = '0${bulanSebelumnya}';
      } else {
        bulanSebelumnya = '12';
        tahunSebelumnya = tahun - 1;
      }
      if (bulan < 10) bulan = '0${bulan}';
      textTanggalMulaiController.text = '${tahunSebelumnya}-${bulanSebelumnya}-26';
      textTanggalSelesaiController.text = '${tahun}-${bulan}-25';
    });
  }

  _parseJabatan(Tunjangan? tunjangan, List<Jabatan> listJabatan) {
    print('TunjanganInput:_parseJabatan: ${initJabatanLoaded}');
    if (initJabatanLoaded == false) {
      for (Jabatan jabatan in listJabatan) {
        if (tunjangan != null && jabatan != null && tunjangan.jabatanId == jabatan.id) {
          sqlite.insertJabatan(Map<String, dynamic>.from(jabatan.toJson()));
          setState((){
            _jabatan = jabatan ;
            initJabatanLoaded = true;
          });
        }
      }
    }
  }

  _parsePengguna(Tunjangan tunjangan, List<Pengguna> listPengguna) {
    print('TunjanganInput:_parsePengguna: ${initJabatanLoaded}');
    if (initPenggunaLoaded == false) {
      for (Pengguna pengguna in listPengguna) {
        if (pengguna != null && tunjangan != null && tunjangan.penggunaId == pengguna.id) {
          sqlite.insertJabatan(Map<String, dynamic>.from(pengguna.toJson()));
          setState((){
            _pengguna = pengguna;
            initPenggunaLoaded = true;
          });
        }
      }
    }
  }

  _showSnackBar(BuildContext context, message) {
    if (message != '') {
      SnackBar snackBar = SnackBar(content: Text(message));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  _parsePenggunaSelected(jabatanId, init){
    Rest().fetchPenggunaList(jabatanId, null).then((value) {
      listPengguna = value;
      if (init) _parsePengguna(_tunjangan!, listPengguna);
    });
  }
}