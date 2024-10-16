import 'dart:convert';

import 'package:app/entities/pengguna.dart';
import 'package:app/utils/sqlite.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'entities/akses.dart';
import 'entities/jabatan.dart';
import 'entities/tunjangan.dart';
import 'menu.dart';
import 'penilaian_list.dart';
import 'penilaian_verifikasi.dart';
import 'tunjangan_input.dart';
import 'utils/helper.dart';
import 'utils/rest.dart';
import 'utils/sync.dart';

class TunjanganListRoute extends StatelessWidget {
  final String message;

  TunjanganListRoute(this.message);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "List Tunjangan",
      home: TunjanganListStatefulWidget(this.message),
    );
  }
}

class TunjanganListStatefulWidget extends StatefulWidget {
  final String message;

  TunjanganListStatefulWidget(this.message);

  @override
  CustomTunjanganListStatefulWidget createState() => CustomTunjanganListStatefulWidget(this.message);
}

class CustomTunjanganListStatefulWidget extends State<TunjanganListStatefulWidget> {
  int _selectedIndex = 0;
  String message;
  bool rekap = false;
  final textTanggalController = TextEditingController();
  final textUraianController = TextEditingController();
  bool loading = false;
  bool buttonAdd = false;
  bool buttonDelete = false;
  bool submitPenilaian = false;
  bool tunjanganLoad = true;
  bool tunjanganSelesaiLoad = true;
  Pengguna? _pengguna;
  String jabatanCode = '';
  String periode = '';
  int jabatanId = 0;
  int penggunaId = 0;
  int levelPengguna = -1;
  DateTime now = DateTime.now();
  List<Akses> listDirektur = [];
  List<Akses> listKepalaBagian = [];
  List<Akses> listKepalaUnit = [];
  List<Akses> listKepalaSeksi = [];
  List<Tunjangan> listTunjangan = [];
  List<Tunjangan> listTunjanganSelesai = [];
  List<Jabatan> listJabatan = [];
  List<Pengguna> listPengguna = [];
  List<String> listPeriode = [];
  Map<String, String> filter = <String, String>{};
  Sqlite sqlite = new Sqlite();

  CustomTunjanganListStatefulWidget(this.message);

  @override
  initState() {
    super.initState();

    Helper().getPengguna().then((value) {
      _pengguna = Pengguna.fromJson(value);

      if (_pengguna != null && _pengguna!.listAkses.length > 0){
        setState((){
          listDirektur = [];
          listKepalaBagian = [];
          listKepalaUnit = [];
          listKepalaSeksi = [];
          for(Akses akses in _pengguna!.listAkses){
            switch (akses.jabatanCode) {
              case 'admin':
                setState((){
                  buttonAdd = true;
                });
                break;
              case 'direktur': listDirektur.add(akses); break;
              case 'kepala_bagian': listKepalaBagian.add(akses); break;
              case 'kepala_unit': listKepalaUnit.add(akses); break;
              case 'kepala_seksi': listKepalaSeksi.add(akses); break;
              case 'operator': rekap = true; break;
              case 'staff': rekap = true; break;
            }
            jabatanCode = akses.jabatanCode;
            int levelCode = Helper().getLevel(jabatanCode);
            if (levelPengguna < 0 || levelCode > levelPengguna) levelPengguna = levelCode;
          }
        });
      }
    });

    sqlite.getJabatanList({}).then((value) {
      listJabatan = value;
    });

    sqlite.getPenggunaList().then((value) {
      listPengguna = value;
    });

    sqlite.getPeriodeList().then((value) {
      listPeriode = value;
    });

    if (now.day >= 26) {
      // var nextMonth = Helper().addMonths(1, now);
      var nextMonth = DateTime(now.year, now.month + 1, 1);
      periode = DateFormat('yMM').format(nextMonth);
      print('TunjanganList:periode: ${periode}');
      filter['periode'] = periode;
    } else {
      periode = DateFormat('yMM').format(now);
      filter['periode'] = periode;
    }

    Helper().setSession('filter', jsonEncode(filter));

    parseTunjanganList(null);
    parseTunjanganListSelesai(null);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    if (listTunjangan.length <= 0 && tunjanganLoad == false) {
      reloadTunjangan();
    }

    if (listTunjanganSelesai.length <= 0 && tunjanganSelesaiLoad == false) {
      reloadTunjanganSelesai();
    }

    if (!submitPenilaian) {
      setState(() {
        submitPenilaian = true;
      });
      Sync().synchronizePenilaianDetailFile().whenComplete(() {
        setState(() {
          submitPenilaian = false;
        });
      });
    }

    return WillPopScope(
        onWillPop: () async {
          return _moveToMenuList(context);
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                _moveToMenuList(context);
              },
            ),
            title: Text(rekap ? 'Rekap Capaian Pekerjaan' : 'List Pekerjaan Staf'),
            actions: <Widget>[
              // IconButton(
              //   icon: const Icon(Icons.filter_list),
              //   tooltip: 'Setting',
              //   onPressed: () {
              //     _showDialog(context);
              //   },
              // ),
            ],
          ),
          body: Container(
              padding: EdgeInsets.symmetric(horizontal: 5),
              width: width,
              height: height,
              child: (tunjanganLoad == true && tunjanganSelesaiLoad == true) ? Column(
                children: [
                  SizedBox(
                    child: CircularProgressIndicator(),
                    height: 50,
                    width: 50,
                  ),
                  Expanded(child: Container())
                ],
              ) : IndexedStack(
                index: _selectedIndex,
                children: [
                  ListView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount: listTunjangan.length,
                      itemBuilder: (context, index) {
                        Tunjangan tunjangan = listTunjangan.elementAt(index);
                        print('TunjanganList:ListView.builder: ${tunjangan.toJson().toString()}');
                        return parseListView(context, index, tunjangan);
                      }
                  ),
                  ListView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount: listTunjanganSelesai.length,
                      itemBuilder: (context, index) {
                        Tunjangan tunjangan = listTunjanganSelesai.elementAt(index);
                        return parseListView(context, index, tunjangan);
                      }
                  ),
                ],
              ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.access_time),
                label: 'Proses',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.check),
                label: 'Selesai',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.amber[800],
            onTap: _onItemTapped,
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: buttonAdd ? Padding(
            padding: const EdgeInsets.only(top: 0),
            child: FloatingActionButton(
              onPressed: () {
                _moveToTunjanganInput(context, 0);
              },
              child: const Icon(Icons.add),
              backgroundColor: Colors.green,
              elevation: 10,
            ),
          ) : Container(),
        )
    );
  }

  void _onItemTapped(int index) {
    if (mounted) {
      print('TunjanganList:_onItemTapped: $index');
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  _moveToTunjanganInput(BuildContext context, int id) {
    Route route = MaterialPageRoute(builder: (context) => TunjanganInputRoute("", id));
    return Navigator.pushReplacement(context, route);
  }

  _moveToPenilaianList(BuildContext context, Tunjangan tunjangan) {
    Route route = MaterialPageRoute(builder: (context) => PenilaianListRoute("", tunjangan));
    Navigator.pushReplacement(context, route);
  }

  // _moveToPenilaianVerifikasi(BuildContext context, Tunjangan tunjangan) {
  //   Route route = MaterialPageRoute(builder: (context) => PenilaianVerifikasiRoute("", tunjangan));
  //   Navigator.pushReplacement(context, route);
  // }

  _moveToMenuList(BuildContext context) {
    Route route = MaterialPageRoute(builder: (context) => MenuRoute(""));
    return Navigator.pushReplacement(context, route);
  }

  void _onPressedFilter(BuildContext dialogContext, Jabatan jabatan, Pengguna pengguna) {
    if (jabatan != null) filter['jabatan_id'] = jabatan.id.toString();
    if (pengguna != null) filter['pengguna_id'] = pengguna.id.toString();
    if (periode.isNotEmpty) filter['periode'] = periode.toString();
    Helper().setSession('filter', jsonEncode(filter));

    parseTunjanganList(dialogContext);
  }

  parseTunjanganList(BuildContext? dialogContext) async {
    Map<String, String> body = Map<String, String>();
    String filterString = await Helper().getSessionString('filter');
    if (filterString.isNotEmpty) {
      Map<String, dynamic> json = jsonDecode(filterString);
      if (json.isNotEmpty) {
        if (json['periode'] != null) body['periode'] = json['periode'].toString();
      }
    }

    sqlite.getTunjanganList(body).then((value) {
      setState((){
        listTunjangan = value;
        tunjanganLoad = false;
      });
    }).whenComplete(() {
      if (dialogContext != null) Navigator.pop(dialogContext);
    });
  }

  parseTunjanganListSelesai(BuildContext? dialogContext) async {
    Map<String, String> body = Map<String, String>();
    body['periode'] = '$periode,<';
    sqlite.getTunjanganList(body).then((value) {
      setState((){
        listTunjanganSelesai = value;
        tunjanganSelesaiLoad = false;
      });
    }).whenComplete(() {
      if (dialogContext != null) Navigator.pop(dialogContext);
    });
  }

  Widget parseListView(BuildContext context, int index, Tunjangan tunjangan) {
    bool verify = false;
    Pengguna? pengguna = tunjangan.pengguna;
    if (pengguna != null && pengguna.listAkses.isNotEmpty){
      for(Akses akses in pengguna.listAkses) {
        switch (akses.jabatanCode) {
          case 'admin': break;
          case 'direktur':
            break;
          case 'kepala_bagian':
            if (listDirektur.length > 0) verify = true;
            break;
          case 'kepala_unit':
            if (listDirektur.length > 0) verify = true;
            break;
          case 'kepala_seksi':
            if (listKepalaBagian.length > 0) verify = true;
            break;
          case 'operator':
            if (listKepalaUnit.length > 0) verify = true;
            break;
          case 'staff':
            if (listKepalaSeksi.length > 0) verify = true;
            break;
        }
      }
    }
    return GestureDetector(
      onTap: () {
        if (verify) {
          _moveToPenilaianList(context, tunjangan);
        } else {
          Helper().setSession('penilaian_list_page_from', 'tunjangan_list');
          _moveToPenilaianList(context, tunjangan);
        }
      },
      onLongPress: () {
        if (buttonAdd) _moveToTunjanganInput(context, tunjangan.id);
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(5, 5, 5, 0),
        height: 125,
        width: double.maxFinite,
        child: Card(
          elevation: 5,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Padding(
              padding: EdgeInsets.all(7),
              child: Stack(children: <Widget>[
                Align(
                  alignment: Alignment.centerRight,
                  child: Stack(
                    children: <Widget>[
                      Padding(
                          padding: const EdgeInsets.only(left: 10, top: 5),
                          child: Column(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                        pengguna != null ? pengguna.nama : "Periode: ${Helper().parsePeriode(tunjangan.periode)}",
                                        style: TextStyle(fontWeight: FontWeight.bold)
                                    ),
                                  ),
                                ],
                              ),
                              Expanded(
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(Helper().getJabatan(tunjangan.pengguna)),
                                  ),
                              ),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                      child: Container(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            tunjangan.bobot > 0 ? Text("${Helper().removeDecimalZeroFormat(tunjangan.ketercapaian / tunjangan.bobot * 100)} / 100%")
                                                : Text('0/100 %'),
                                            // Text("Rp ${tunjangan.diterima != '' ? Helper().removeDecimalZeroFormat(tunjangan.diterima) : 0}"),
                                          ],
                                        ),
                                      )
                                  ),
                                  Text("${Helper().parseTanggal(tunjangan.tanggalMulai, false)} - ${Helper().parseTanggal(tunjangan.tanggalSelesai, true)}"),
                                  // Chip(
                                  //   padding: EdgeInsets.all(0),
                                  //   backgroundColor: Colors.deepPurple,
                                  //   label: Text(tunjangan.status != '' ? tunjangan.status : 'Proses', style: TextStyle(color: Colors.white)),
                                  // ),
                                ],
                              ),
                            ],
                          )
                      )
                    ],
                  ),
                )
              ]),
            ),
          ),
        ),
      ),
    );
  }

  reloadTunjangan() async {
    Map<String, dynamic> map = await Helper().getPengguna();
    Map<String, String> body = Map<String, String>();
    body['pengguna_id'] = map['id'].toString();
    body['periode'] = periode;
    String filterString = await Helper().getSessionString('filter');
    if (filterString.isNotEmpty) {
      Map<String, dynamic> json = jsonDecode(filterString);
      if (json.isNotEmpty) {
        // if (json['jabatan_id'] != null) body['jabatan_id'] = json['jabatan_id'].toString();
        // if (json['periode'] != null) body['periode'] = json['periode'].toString();
        // if (json['pengguna_id'] != null) body['pengguna_id_only'] = json['pengguna_id'].toString();
      }
    }
    Rest().fetchTunjanganList(body).then((value) async {
      setState((){
        if (value.length > 0) listTunjangan = value;
        tunjanganLoad = true;
      });
      for(Tunjangan tunjangan in listTunjangan) {
        sqlite.insertTunjangan(Map<String, dynamic>.from(tunjangan.toJson()));
        if (tunjangan.pengguna != null) {
          sqlite.insertPengguna(Map<String, dynamic>.from(tunjangan.pengguna!.toJson()));
          if (tunjangan.pengguna!.listAkses != null && tunjangan.pengguna!.listAkses.length > 0) {
            sqlite.deleteAkses(tunjangan.pengguna!.id);
            for (Akses akses in tunjangan.pengguna!.listAkses) {
              sqlite.insertAkses(Map<String, dynamic>.from(akses.toJson()));
            }
          }
        }
      }
    });
  }

  reloadTunjanganSelesai() async {
    Map<String, dynamic> map = await Helper().getPengguna();
    Map<String, String> body = Map<String, String>();
    body['pengguna_id'] = map['id'].toString();
    body['periode'] = '$periode,<';
    Rest().fetchTunjanganList(body).then((value) async {
      setState((){
        if (value.length > 0) listTunjanganSelesai = value;
        tunjanganSelesaiLoad = true;
      });
      for(Tunjangan tunjangan in listTunjanganSelesai) {
        sqlite.insertTunjangan(Map<String, dynamic>.from(tunjangan.toJson()));
        if (tunjangan.pengguna != null) {
          sqlite.insertPengguna(Map<String, dynamic>.from(tunjangan.pengguna!.toJson()));
          if (tunjangan.pengguna!.listAkses != null && tunjangan.pengguna!.listAkses.length > 0) {
            sqlite.deleteAkses(tunjangan.pengguna!.id);
            for (Akses akses in tunjangan.pengguna!.listAkses) {
              sqlite.insertAkses(Map<String, dynamic>.from(akses.toJson()));
            }
          }
        }
      }
    });
  }

}