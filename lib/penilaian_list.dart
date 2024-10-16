import 'dart:convert';
import 'dart:ui';
import 'dart:developer' as developer;

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'entities/akses.dart';
import 'entities/atasan.dart';
import 'entities/jabatan.dart';
import 'entities/pekerjaan.dart';
import 'entities/pengguna.dart';
import 'entities/penilaian.dart';
import 'entities/penilaian_detail.dart';
import 'entities/tunjangan.dart';
import 'menu.dart';
import 'penilaian.dart';
import 'penilaian_input.dart';
import 'penilaian_list_duplicate.dart';
import 'penilaian_verifikasi.dart';
import 'tunjangan_list.dart';
import 'utils/constant.dart';
import 'utils/helper.dart';
import 'utils/rest.dart';
import 'utils/sqlite.dart';

class PenilaianListRoute extends StatelessWidget {
  String message;
  Tunjangan tunjangan;

  PenilaianListRoute(this.message, this.tunjangan);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Detail Pekerjaan",
      home: PenilaianListStatefulWidget(this.message, this.tunjangan),
    );
  }
}

class PenilaianListStatefulWidget extends StatefulWidget {
  String message;
  Tunjangan tunjangan;

  PenilaianListStatefulWidget(this.message, this.tunjangan);

  @override
  CustomPenilaianListStatefulWidget createState() => CustomPenilaianListStatefulWidget(this.message, this.tunjangan);
}

class CustomPenilaianListStatefulWidget extends State<PenilaianListStatefulWidget> {
  String message;
  bool initialData = false;
  bool loading = false;
  bool showVerification = true;
  bool isAtasan = false;
  bool buttonAdd = false;
  bool buttonDelete = false;
  ScrollController controller = new ScrollController();
  Tunjangan tunjangan;
  Pengguna? pengguna;
  List<Atasan> listAtasan = [];
  List<Jabatan> listJabatan = [];
  List<Pengguna> listPengguna = [];
  List<Penilaian> listPenilaian = [];
  List<bool> isChecked = [];
  List<int> isCheckedPengguna = [];
  List<Widget> listPenggunaWidget = [];
  Sqlite sqlite = new Sqlite();

  CustomPenilaianListStatefulWidget(this.message, this.tunjangan);

  @override
  void initState() {
    super.initState();
    controller = new ScrollController()..addListener(_scrollListener);
    sqlite.getPenilaianList(this.tunjangan.id, true).then((value) {
      setState((){
        listPenilaian = value;
      });
    });

    sqlite.getJabatanList({}).then((value) {
      setState((){
        listJabatan = value;
      });
    });

    Helper().getPengguna().then((value) {
      pengguna = Pengguna.fromJson(value);

      if (pengguna != null && pengguna!.listAkses.length > 0){
        for(Akses akses in pengguna!.listAkses){
          if (akses != null && akses.jabatanCode == 'admin'){
            setState((){
              buttonAdd = true;
            });
          }
        }
      }

      Rest().fetchAtasanList(this.tunjangan.penggunaId).then((value) {
        listAtasan = value;
        for(Atasan atasan in listAtasan) {
          print('PenilaianList:atasan: ${atasan.toJson().toString()} = ${pengguna!.id}');
          if (pengguna != null && atasan.penggunaId == pengguna!.id) {
            isAtasan = true;
          }
        }
      });
    });

  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    if (!loading && listPenilaian.length <= 0) {
      setState(() {
        loading = true;
      });
      Rest().fetchPenilaianList(this.tunjangan).then((value) {
        setState((){
          listPenilaian = value;
        });

        for (Penilaian penilaian in listPenilaian) {
          sqlite.insertPenilaian(Map<String, dynamic>.from(penilaian.toJson()));
          if (penilaian.pekerjaan != null) sqlite.insertPekerjaan(Map<String, dynamic>.from(penilaian.pekerjaan!.toJson()));
          if (penilaian.tunjangan != null) sqlite.insertTunjangan(Map<String, dynamic>.from(penilaian.tunjangan!.toJson()));
          if (penilaian.listPenilaianDetail != null) {
            for (PenilaianDetail penilaianDetail in penilaian.listPenilaianDetail){
              sqlite.insertPenilaianDetail(Map<String, dynamic>.from(penilaianDetail.toJson()));
              if (penilaianDetail.file != null) {
                sqlite.insertFile(Map<String, dynamic>.from(penilaianDetail.file!.toJson()));
              }
            }
          }
        }
      });
    }

    return WillPopScope(
        onWillPop: () async {
          String value = await Helper().getSessionString('penilaian_list_page_from');
          if (value == 'tunjangan_list') return _moveToTunjanganList(context);
          else if (value == 'menu') return _moveToMenuList(context);
          return _moveToTunjanganList(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Helper().getSessionString('penilaian_list_page_from').then((value) {
                if (value == 'tunjangan_list') _moveToTunjanganList(context);
                else if (value == 'menu') _moveToMenuList(context);
              });
            },
          ),
          title: Text(tunjangan.pengguna != null ? tunjangan.pengguna!.nama : 'List Pekerjaan'),
          actions: <Widget>[
            PopupMenuButton<int>(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 1,
                  child: Text(
                    "Download PDF",
                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
                  ),
                ),
                PopupMenuItem(
                  value: 2,
                  child: Text(
                    "Download Excel",
                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              icon: Icon(Icons.list),
              offset: Offset(0, 100),
              onCanceled: () {
                print("You have canceled the menu.");

              },
              onSelected: (value) async {
                print("value:$value");
                if (value == 1) {
                  Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/tunjangan/cetak/${tunjangan.id}');
                  launch(uri.toString());
                  // final taskId = await FlutterDownloader.enqueue(
                  //   url: uri.toString(),
                  //   savedDir: 'pdamhss',
                  //   showNotification: true, // show download progress in status bar (for Android)
                  //   openFileFromNotification: true, // click on notification to open downloaded file (for Android)
                  // );
                } else if (value == 2) {
                  Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/tunjangan/excel/${tunjangan.id}');
                  launch(uri.toString());
                  // final taskId = await FlutterDownloader.enqueue(
                  //   url: uri.toString(),
                  //   savedDir: 'pdamhss',
                  //   showNotification: true, // show download progress in status bar (for Android)
                  //   openFileFromNotification: true, // click on notification to open downloaded file (for Android)
                  // );
                }
              },
            ),
          ],
        ),
        body: Container(
          padding: EdgeInsets.only(left: 10, right: 10),
          width: width,
          height: height,
          child: Column(
            children: [
              Container(
                height: 40,
                child: Row(
                  children: [
                    Expanded(
                      child: Text("Tanggal"),
                    ),
                    Text("${Helper().parseTanggal(this.tunjangan.tanggalMulai, false)} - ${Helper().parseTanggal(this.tunjangan.tanggalSelesai, true)}"),
                  ],
                ),
              ),
              Container(
                height: 40,
                child: Row(
                  children: [
                    Expanded(
                      child: Text("Ketercapaian / Bobot"),
                    ),
                    this.tunjangan.bobot > 0 ? Text("${Helper().currency(this.tunjangan.ketercapaian / this.tunjangan.bobot * 100)} / 100%") : Text('0'),
                  ],
                ),
              ),
              Divider(),
              Container(
                height: 40,
                child: Row(
                  children: [
                    Expanded(
                      child: Text("Status"),
                    ),
                    Chip(
                      padding: EdgeInsets.all(0),
                      backgroundColor: Colors.deepPurple,
                      label: Text('Pending', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  controller: controller,
                  itemCount: listPenilaian != null ? listPenilaian.length : 0,
                  itemBuilder: _getListItemTile,
                ),
              ),
              showVerification ? Container() :
              Container(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                height: 100,
                color: Colors.white,
                child: Center(
                  child: Row(
                    children: <Widget>[
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Terima Hasil Kerja'),
                      ),
                      ElevatedButton(
                        child: Text('Tolak'),
                        onPressed: () {
                          _buttonProcessed(true);
                        },
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        child: Text('Terima'),
                        onPressed: () {
                          _buttonProcessed(true);
                        },
                      ),
                      SizedBox(width: 10),
                    ],
                  ),
                ),
              ),
              buttonAdd ? Row (
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: _tambahButton(context)),
                  buttonDelete ? Expanded(child: _hapusButton(context)) : Expanded(child: _duplicateButton(context)),
                ],
              ) : Container()
            ],
          ),
        ),
      ),
    );
  }

  Widget _tambahButton(BuildContext context) {
    return InkWell(
      onTap: (){
        _moveToPenilaianInput(context, tunjangan);
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
          "Tambah",
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }

  Widget _duplicateButton(BuildContext context) {
    return InkWell(
      onTap: (){
        _moveToPenilaianListDuplicate(context, tunjangan);
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
                colors: [Colors.green, Colors.greenAccent]
            )
        ),
        child: Text(
          "Duplikat",
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }

  Widget _hapusButton(BuildContext context) {
    return InkWell(
      onTap: (){

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
                colors: [Colors.red, Colors.redAccent]
            )
        ),
        child: Text(
          "Hapus",
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }

  _moveToTunjanganList(BuildContext context) {
    Route route = MaterialPageRoute(builder: (context) => TunjanganListRoute(""));
    return Navigator.pushReplacement(context, route);
  }

  _moveToMenuList(BuildContext context) {
    Route route = MaterialPageRoute(builder: (context) => MenuRoute(""));
    return Navigator.pushReplacement(context, route);
  }

  _buttonProcessed(value) {
    setState(() {
      showVerification = value;
    });
  }

  showButton(BuildContext context){
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Terima Hasil Kerja'),
                ElevatedButton(
                  child: const Text('Tolak'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text('Terima'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _scrollListener() {
    if (controller.position.extentAfter == 0) {
      setState(() {
        // _parseOrder(this.parent.apartment, this.parent.searchQuery.text);
      });
    }
  }

  Widget _getListItemTile(BuildContext context, int index) {
    if (isChecked.length <= index) isChecked.add(false);
    Penilaian penilaian = listPenilaian[index];
    double ketercapaian = penilaian.ketercapaian;
    double bobot = penilaian.bobot;
    if (ketercapaian == 0 && penilaian.listPenilaianDetail.length > 0){
      for(PenilaianDetail penilaianDetail in penilaian.listPenilaianDetail){
        ketercapaian += penilaianDetail.nilai;
      }
    }
    double percent = penilaian.target > 0 ? penilaian.nilai / penilaian.target : 0;
    if (percent > 1) percent = 1;
    return GestureDetector(
      onTap: (){
        _moveToPenilaian(context, penilaian, tunjangan);
      },
      onLongPress: () {
      },
      child: Padding(
        padding: EdgeInsets.all(1),
        child: Column(
          children: <Widget>[
            Card(
                child: Container(
                  padding: EdgeInsets.all(20),
                  height: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      buttonAdd ? Checkbox(
                        checkColor: Colors.white,
                        fillColor: MaterialStateProperty.resolveWith(Helper().getColor),
                        value: isChecked.length > 0 ? isChecked[index] : false,
                        onChanged: (bool? value) {
                          setState(() {
                            buttonDelete = false;
                            isChecked[index] = value!;
                            for(bool checked in isChecked) {
                              print('PenilaianList:checked: $checked');
                              if (checked) {
                                buttonDelete = true;
                                break;
                              }
                            }
                          });
                        },
                      ): Container(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              penilaian.nama,
                              textAlign: TextAlign.start,
                              style: TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              maxLines: 1,
                            ),
                            LinearPercentIndicator(
                              lineHeight: 14,
                              percent: percent,
                              backgroundColor: Colors.grey,
                              progressColor: Colors.blue,
                              center: _parsePencentage(penilaian, ketercapaian, bobot),
                              animation: true,
                              animationDuration: 1000,
                            ),
                          ],
                        ),
                      ),
                      isAtasan ? IconButton(
                        alignment: Alignment.center,
                        icon: Icon(Icons.fact_check),
                        iconSize: 32,
                        onPressed: () {
                          _moveToPenilaianVerifikasi(context, tunjangan,penilaian);
                        },
                      ) : Container(),
                      IconButton(
                        alignment: Alignment.center,
                        icon: Icon(Icons.calendar_today_outlined),
                        iconSize: 32,
                        onPressed: () {
                          _moveToPenilaian(context, penilaian, tunjangan);
                        },
                      ),
                    ],
                  ),
                )
            ),
            // ListTile(
            //   title: Text(order.name, style: TextStyle(fontSize: 18)),
            //   subtitle: Text(order.address ?? (order.handphone ?? (order.email ?? '')), style: TextStyle(fontSize: 16)),
            // ),
            // Widget to display the list of project
          ],
        ),
      ),
    );
  }

  _moveToPenilaian(BuildContext context, Penilaian penilaian, Tunjangan tunjangan) {
    Route route = MaterialPageRoute(builder: (context) => PenilaianRoute("", penilaian, tunjangan));
    Navigator.pushReplacement(context, route);
  }

  _moveToPenilaianInput(BuildContext context, Tunjangan tunjangan) {
    Route route = MaterialPageRoute(builder: (context) => PenilaianInputRoute("", 0, tunjangan));
    Navigator.pushReplacement(context, route);
  }

  _moveToPenilaianListDuplicate(BuildContext context, Tunjangan tunjangan) {
    Route route = MaterialPageRoute(builder: (context) => PenilaianListDuplicateRoute("", tunjangan));
    Navigator.pushReplacement(context, route);
  }

  List<Widget> parsePenggunaWidget(BuildContext context) {
    List<Widget> list = [];

    for (Pengguna pengguna in listPengguna){
      int index = listPengguna.indexOf(pengguna);
      if (isCheckedPengguna.length <= index) {
        isCheckedPengguna.add(0);
      }
      list.add(Container(
        child: Row(
          children: [
            Checkbox(
              checkColor: Colors.white,
              fillColor: MaterialStateProperty.resolveWith(Helper().getColorGreen),
              value: isCheckedPengguna[index] > 0 ? true: false,
              onChanged: (bool? value) {
                setState(() {
                });
                if (value == true) isCheckedPengguna[index] = pengguna.id;
                else isCheckedPengguna[index] = 0;
              },
            ),
            Text(pengguna.nama)
          ]
        )
      ));
    }

    return list;
  }

  _parsePencentage(Penilaian penilaian, ketercapaian, bobot) {
    return Text("${Helper().removeDecimalZeroFormat(penilaian.nilai)} / ${Helper().removeDecimalZeroFormat(penilaian.target)}");
    if (penilaian.tipe == 'nominal') return Text("${Helper().removeDecimalZeroFormat(penilaian.nilai)} / ${Helper().removeDecimalZeroFormat(penilaian.target)}");
    return Text("${Helper().removeDecimalZeroFormat(ketercapaian)} / ${Helper().removeDecimalZeroFormat(bobot)}");
  }

  _moveToPenilaianVerifikasi(BuildContext context, Tunjangan tunjangan, Penilaian penilaian) {
    Route route = MaterialPageRoute(builder: (context) => PenilaianVerifikasiRoute("", tunjangan, penilaian));
    Navigator.pushReplacement(context, route);
  }
}