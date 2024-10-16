import 'dart:convert';
import 'dart:ui';

import 'package:app/utils/sqlite.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

import 'entities/akses.dart';
import 'entities/notifikasi.dart';
import 'entities/pengguna.dart';
import 'entities/penilaian.dart';
import 'entities/penilaian_detail.dart';
import 'entities/tunjangan.dart';
import 'penilaian_input.dart';
import 'penilaian_list.dart';
import 'tunjangan_list.dart';
import 'utils/constant.dart';
import 'utils/helper.dart';
import 'utils/rest.dart';
import 'utils/string_extension.dart';

class PenilaianVerifikasiRoute extends StatelessWidget {
  String message;
  Tunjangan tunjangan;
  Penilaian penilaian;

  PenilaianVerifikasiRoute(this.message, this.tunjangan, this.penilaian);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Detail Pekerjaan",
      home: PenilaianVerifikasiStatefulWidget(this.message, this.tunjangan, this.penilaian),
    );
  }
}

class PenilaianVerifikasiStatefulWidget extends StatefulWidget {
  String message;
  Tunjangan tunjangan;
  Penilaian penilaian;

  PenilaianVerifikasiStatefulWidget(this.message, this.tunjangan, this.penilaian);

  @override
  CustomPenilaianVerifikasiStatefulWidget createState() => CustomPenilaianVerifikasiStatefulWidget(this.message, this.tunjangan, this.penilaian);
}

class CustomPenilaianVerifikasiStatefulWidget extends State<PenilaianVerifikasiStatefulWidget> {
  String message;
  final textCatatanController = TextEditingController();
  bool initialData = false;
  bool loading = false;
  bool showVerification = false;
  bool buttonAdd = false;
  bool buttonDelete = false;
  bool showMessage = false;
  String _imageValue = '';
  ScrollController controller = new ScrollController();
  Tunjangan tunjangan;
  Penilaian penilaian;
  Pengguna? pengguna;
  List<Notifikasi> listNotifikasi = [];
  List<Penilaian> listPenilaian = [];
  List<PenilaianDetail> listPenilaianDetail = [];
  int isChecked = 0;
  Map<int, bool> isCheckedDetail = <int, bool>{};
  Sqlite sqlite = new Sqlite();

  CustomPenilaianVerifikasiStatefulWidget(this.message, this.tunjangan, this.penilaian);

  @override
  void initState() {
    super.initState();
    controller = new ScrollController()..addListener(_scrollListener);
    sqlite.getPenilaianList(this.tunjangan.id, true).then((value) {
      setState((){
        listPenilaian = value;
      });
    });
    sqlite.getAllPenilaianDetail(this.penilaian.id).then((value) {
      setState((){
        listPenilaianDetail = value;
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    if (mounted && !loading) {
      setState((){
        loading = true;
      });
      Rest().fetchPenilaianDetailList(penilaian).then((value) {
        setState((){
          listPenilaianDetail = value;
        });
        for(PenilaianDetail penilaianDetail in listPenilaianDetail) {
          sqlite.insertPenilaianDetail(Map<String, dynamic>.from(penilaianDetail.toJson()));
          if (penilaianDetail.file != null) {
            sqlite.insertFile(Map<String, dynamic>.from(penilaianDetail.file!.toJson()));
          }
          if (penilaianDetail.verifikasi != null) {
            sqlite.insertVerifikasi(Map<String, dynamic>.from(penilaianDetail.verifikasi!.toJson()));
          }
        }
      });
    }

    return WillPopScope(
      onWillPop: () {
          return _moveToPekerjaanList(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              _moveToPenilaianList(context, tunjangan);
            },
          ),
          title: const Text('Verifikasi Pekerjaan'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.view_headline),
              tooltip: 'Setting',
              onPressed: () {

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
                    this.penilaian.bobot > 0 ? Text("${Helper().currency(this.penilaian.ketercapaian / this.penilaian.bobot * 100)} / 100%") : Text('0'),
                  ],
                ),
              ),
              // Container(
              //   height: 40,
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: Text("Tunjangan Diterima"),
              //       ),
              //       Text("Rp ${Helper().currency(this.tunjangan.diterima)}"),
              //     ],
              //   ),
              // ),
              Divider(),
              Container(
                height: 40,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(penilaian.nama),
                    ),
                    // Chip(
                    //   padding: EdgeInsets.all(0),
                    //   backgroundColor: Colors.deepPurple,
                    //   label: Text(penilaian.status, style: TextStyle(color: Colors.white)),
                    // ),
                  ],
                ),
              ),
              listPenilaianDetail != null && listPenilaianDetail.length > 0 ?
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  controller: controller,
                  itemCount: listPenilaianDetail != null ? listPenilaianDetail.length : 0,
                  itemBuilder: _getListItemTile,
                ),
              ) : Container(
                padding: EdgeInsets.only(top: 10),
                child: Text('Belum Ada Penambahan Pekerjaan', style: TextStyle(color: Colors.redAccent),),
              ),
              showVerification ? Container(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                height: showMessage ? 150 : 100,
                color: Colors.white,
                child: Center(
                  child: Column(
                      children: [
                        Row(
                          children: <Widget>[
                            SizedBox(width: 10),
                            Expanded(
                              child: Text('Terima Hasil Kerja', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: Colors.red,
                              ),
                              child: Text('Tolak'),
                              onPressed: () {
                                setState((){
                                  showMessage = true;
                                });
                                if (textCatatanController.text.isEmpty) Helper().showSnackBar(context, 'Catatan harus diisi');
                                else _buttonProcessed(context, 0, false);
                              },
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              child: Text('Terima'),
                              onPressed: () {
                                setState((){
                                  showMessage = false;
                                });
                                _buttonProcessed(context, 1, true);
                              },
                            ),
                            SizedBox(width: 10),
                          ],
                        ),
                        showMessage ? TextField(
                          controller: textCatatanController,
                          decoration: InputDecoration(
                            labelText: "Catatan",
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blueAccent, width: 1),
                            ),
                          ),
                        ) : Container(),
                      ]
                  ),
                ),
              ) : Container(),
              buttonAdd ? Row (
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: _tambahButton(context)),
                  buttonDelete ? Expanded(child: _hapusButton(context)) : Container(),
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

  _scrollListener() {
    if (controller.position.extentAfter == 0) {
      setState(() {
        // _parseOrder(this.parent.apartment, this.parent.searchQuery.text);
      });
    }
  }

  Widget _getListItemTile(BuildContext context, int index) {
    PenilaianDetail penilaianDetail = listPenilaianDetail[index];
    if (penilaianDetail.file != null) {
      print('penilaianDetail.file ${penilaianDetail.file!.toJson().toString()}');
    }
    double ketercapaian = penilaian.ketercapaian;
    double bobot = penilaian.bobot;
    String imageUrl = _imageValueUrl(penilaianDetail);
    if (ketercapaian == 0 && penilaian.listPenilaianDetail.length > 0){
      for(PenilaianDetail penilaianDetail in penilaian.listPenilaianDetail){
        ketercapaian += penilaianDetail.nilai;
      }
    }
    String tanggal = DateFormat('dd MMM yyyy hh:mm').format(DateTime.parse(penilaianDetail.createdAt));
    return GestureDetector(
      onTap: (){
      },
      onLongPress: () {
      },
      child: Padding(
        padding: EdgeInsets.all(1),
        child: Card(
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(5),
                  // height: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      penilaianDetail.status != 'terima' ?
                      Checkbox(
                        checkColor: Colors.white,
                        fillColor: MaterialStateProperty.resolveWith(Helper().getColor),
                        value: isCheckedDetail[penilaianDetail.id] == true,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) isCheckedDetail[penilaianDetail.id] = true;
                            else isCheckedDetail[penilaianDetail.id] = false;
                          });
                          _checkVerification();
                        },
                      ) : Container(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tanggal,
                              textAlign: TextAlign.start,
                              style: TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: InkWell(
                            onTap: () {
                              _showDialog(context, tanggal, imageUrl);
                            },
                            child: Container(
                                width: 25,
                                height: 50,
                                child: Image.network(imageUrl, loadingBuilder: _loadingBuilder)
                            ),
                          ),
                        ),
                      ),
                      Chip(
                        padding: EdgeInsets.all(0),
                        backgroundColor: penilaianDetail.status=='terima' ? Colors.green : (penilaianDetail.status=='tolak'?Colors.red:Colors.deepPurple),
                        label: Text(penilaianDetail.status != '' ? penilaianDetail.status.capitalize() : 'Pending', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                penilaianDetail.alamat != '' ? Container(
                    padding: EdgeInsets.only(bottom:5, left:5, right:5),
                    child: Text(penilaianDetail.alamat))
                    : Container()
              ],
            ),
        ),
      ),
    );
  }

  _imageValueUrl(PenilaianDetail penilaianDetail) {
    Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/file/last/image',
        {'penilaian_detail_id': penilaianDetail.id.toString()});
    return uri.toString();
  }

  _moveToPenilaianInput(BuildContext context, Tunjangan tunjangan) {
    Route route = MaterialPageRoute(builder: (context) => PenilaianInputRoute("", 0, tunjangan));
    Navigator.pushReplacement(context, route);
  }

  _moveToPekerjaanList(BuildContext context) {
    Route route = MaterialPageRoute(builder: (context) => TunjanganListRoute(""));
    return Navigator.pushReplacement(context, route);
  }

  _buttonProcessed(BuildContext context, int terima, value) async {

    String penilaianDetailId = '';
    isCheckedDetail.forEach((key, value) {
      if (key != null && value && !_skipPenilaianDetail(key)) {
        penilaianDetailId += '$key,';
      }
    });
    if (penilaianDetailId.length <= 0) {
      Helper().showSnackBar(context, 'Pilih Tanggal Terlebih dahulu');
      return;
    }
    String status = (terima == 1) ? 'terima': 'tolak';
    String pesan = textCatatanController.text;
    var client = http.Client();
    try {
      Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/penilaian/verifikasi/${penilaian.id}');
      var body = {'penilaian_detail_id': penilaianDetailId, 'pengguna_id': pengguna!.id.toString(), 'status': status, 'pesan': pesan};
      var response = await client.post(uri, body: body);

      var decodedResponse = jsonDecode(response.body);
      if (decodedResponse['data'] != null) {
        setState(() {
          showVerification = false;
          loading = false;
        });
        isCheckedDetail.forEach((key, value) {
          if (key != null && value) {
            setState(() {
              isCheckedDetail[key] = false;
            });
          }
        });
        Helper().showSnackBar(context, 'Berhasil verifikasi data');

        Rest().fetchAllNotifikasiOneSignal({}).then((value) {
          setState((){
            listNotifikasi = value;
          });
        });
      }
    } finally {
      client.close();
    }
  }

  _showDetailPenilaian(BuildContext context, Penilaian penilaian) {
    List<Widget> listWidget = [];

    for (PenilaianDetail penilaianDetail in penilaian.listPenilaianDetail) {
      var index = penilaian.listPenilaianDetail.indexOf(penilaianDetail);
      if (!isCheckedDetail.containsKey(penilaianDetail.id)) isCheckedDetail.putIfAbsent(penilaianDetail.id, () => false);
      var styleDetail = TextStyle(color: Colors.blue);
      bool showCheckbox = true;
      if (penilaianDetail.status == 'terima') {
        styleDetail = TextStyle(color: Colors.green);
        showCheckbox = false;
      } else if (penilaianDetail.status == 'tolak') {
        styleDetail = TextStyle(color: Colors.red);
        showCheckbox = false;
      }

      Uri uri = Uri();
      if (penilaianDetail.file != null && penilaianDetail.file!.id > 0) {
        uri = Uri.http(Constant.HOST, Constant.URL + 'api/file/last/image', {'penilaian_detail_id': penilaianDetail.id.toString()});
      }
      String tanggal = DateFormat('dd MMMMM yyyy hh:ii:ss').format(DateTime.parse(penilaianDetail.createdAt));

      listWidget.add(
        Container(
          child: Column(
            children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    showCheckbox ? Checkbox(
                      checkColor: Colors.white,
                      fillColor: MaterialStateProperty.resolveWith(Helper().getColorGreen),
                      value: isCheckedDetail.containsKey(penilaianDetail.id) && isCheckedDetail[penilaianDetail.id] == true,
                      onChanged: (bool? value) {
                        setState(() {
                          showVerification = false;
                          isCheckedDetail[penilaianDetail.id] = value!;
                          _checkVerification();
                        });
                      },
                    ) : Container(),
                    Expanded(
                      child: Text(tanggal, style: styleDetail),
                    ),
                    (penilaianDetail.status == 'terima' || penilaianDetail.status == 'tolak' ?
                    Transform(
                        transform: new Matrix4.identity()..scale(0.6),
                        child: Chip(
                          padding: EdgeInsets.all(0),
                          backgroundColor: penilaianDetail.status=='terima' ? Colors.green : (penilaianDetail.status=='tolak'?Colors.red:Colors.deepPurple),
                          label: Text(penilaianDetail.status.capitalize(), style: TextStyle(color: Colors.white)),
                        )
                    ) : Container()),
                    uri.toString() != '' ? InkWell(
                      onTap: () {
                        _showDialog(context, tanggal, uri.toString());
                      },
                      child: Container(
                          width: 25,
                          height: 50,
                          child: Image.network(
                            uri.toString(),
                            loadingBuilder: _loadingBuilder,
                          )
                      ),
                    ) : Container(),
                  ]
              ),
              (penilaianDetail != null && penilaianDetail.alamat != null) ? Text(penilaianDetail.alamat) :
                (penilaianDetail.latitude != 0 && penilaianDetail.longitude != 0 ?
                Text("${penilaianDetail.latitude}, ${penilaianDetail.longitude}") : Container()),
              (index < penilaian.listPenilaianDetail.length-1) ? Divider() : Container()
            ],
          ),
        )
      );
    }

    return listWidget;
  }

  _checkVerification() {
    setState((){
      showVerification = false;
      if (isChecked > 0)  showVerification = true;
      for(int detailId in isCheckedDetail.keys){
        if (isCheckedDetail[detailId] == true) {
          showVerification = true;
          break;
        }
      }
    });
  }

  Future<void> _showDialog(BuildContext context, String tanggal, String url) async {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tanggal),
          content: Container(
            height: height,
            width: width,
            child: url != '' ? Container(
                width: width,
                height: height,
                child: Image.network(url)
            ) : Container()
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Tutup'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _loadingBuilder(BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
    if (loadingProgress == null) return child;

    double value = loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : 0;
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  _skipPenilaianDetail(id) {
    for (Penilaian penilaian in listPenilaian) {
      for (PenilaianDetail penilaianDetail in penilaian.listPenilaianDetail) {
        if (id == penilaianDetail.id && penilaianDetail.status == 'terima') return true;
      }
    }
    return false;
  }

  _moveToPenilaianList(BuildContext context, Tunjangan tunjangan) {
    Route route = MaterialPageRoute(builder: (context) => PenilaianListRoute("", tunjangan));
    Navigator.pushReplacement(context, route);
  }
}