import 'dart:convert';
import 'dart:ui';
import 'dart:developer' as developer;

import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

import 'entities/akses.dart';
import 'entities/jabatan.dart';
import 'entities/pekerjaan.dart';
import 'entities/pengguna.dart';
import 'entities/penilaian.dart';
import 'entities/penilaian_detail.dart';
import 'entities/tunjangan.dart';
import 'menu.dart';
import 'penilaian.dart';
import 'penilaian_input.dart';
import 'penilaian_list.dart';
import 'tunjangan_list.dart';
import 'utils/constant.dart';
import 'utils/helper.dart';
import 'utils/rest.dart';

class PenilaianListDuplicateRoute extends StatelessWidget {
  String message;
  Tunjangan tunjangan;

  PenilaianListDuplicateRoute(this.message, this.tunjangan);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Duplikasi Detail Pekerjaan",
      home: PenilaianListDuplicateStatefulWidget(this.message, this.tunjangan),
    );
  }
}

class PenilaianListDuplicateStatefulWidget extends StatefulWidget {
  String message;
  Tunjangan tunjangan;

  PenilaianListDuplicateStatefulWidget(this.message, this.tunjangan);

  @override
  CustomPenilaianListDuplicateStatefulWidget createState() => CustomPenilaianListDuplicateStatefulWidget(this.message, this.tunjangan);
}

class CustomPenilaianListDuplicateStatefulWidget extends State<PenilaianListDuplicateStatefulWidget> {
  String message;
  bool initialData = false;
  bool loading = false;
  bool buttonSimpan = false;
  ScrollController controller = new ScrollController();
  Tunjangan tunjangan;
  Jabatan? jabatan;
  Pengguna? pengguna;
  String? _periode = '';
  List<Jabatan> listJabatan = [];
  List<Pengguna> listPengguna = [];
  List<bool> isChecked = [];
  List<int> isCheckedPengguna = [0];
  List<String> listPeriode = [];
  var now = DateTime.now();

  CustomPenilaianListDuplicateStatefulWidget(this.message, this.tunjangan);

  @override
  void initState() {
    super.initState();
    controller = new ScrollController()..addListener(_scrollListener);
    _periode = DateFormat('yMM').format(now);
    if (now.day >= 26) {
      var nextMonth = DateTime(now.year, now.month + 1, 1);
      _periode = DateFormat('yMM').format(nextMonth);
    }

    listPeriode.add(DateFormat('yMM').format(now));
    for (var i = 0; i < 5; i++) {
      var nextMonth = new DateTime(now.year, now.month + (i+1), now.day);
      listPeriode.add(DateFormat('yMM').format(nextMonth));
    }

    _parseJabatan();

    Helper().getPengguna().then((value) {
      pengguna = Pengguna.fromJson(value);

      if (pengguna != null && pengguna!.listAkses.length > 0){
        for(Akses akses in pengguna!.listAkses){
          if (akses != null && akses.jabatanCode == 'admin'){
            setState((){
              buttonSimpan = true;
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

    return WillPopScope(
      onWillPop: () {
        return _moveToPenilaianList(context, tunjangan);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              _moveToPenilaianList(context, tunjangan);
            },
          ),
          title: const Text('Duplikat Pekerjaan'),
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
                      child: Text("Bobot"),
                    ),
                    Text("${Helper().removeLastCommaZero(this.tunjangan.bobot)} %"),
                  ],
                ),
              ),

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
                validator: (data){
                  if (data == '') return 'Pilih Periode';
                  return null;
                },
                onChanged: (data) {
                  setState(() {
                    _periode = data;
                  });
                },
              ),
              SizedBox(height: 10),

              DropdownSearch<Jabatan>(
                autoFocusSearchBox: true,
                selectedItem: jabatan,
                label: 'Jabatan',
                onFind: (String filter) async {
                  return listJabatan;
                },
                itemAsString: (Jabatan jabatan) {
                  return jabatan.nama != null ? jabatan.nama : 'Pilih Jabatan';
                },
                onChanged: (data) {
                  setState(() {
                    jabatan = data!;
                    Rest().fetchPenggunaList(jabatan!.id, pengguna!.id).then((value) {
                      setState((){
                        listPengguna = value;
                      });
                    });
                  });
                },
                validator: (data){
                  if (data!.id <= 0) return 'Pilih Jabatan';
                  return null;
                },
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  controller: controller,
                  itemCount: listPengguna != null ? listPengguna.length : 0,
                  itemBuilder: _getListItemTile,
                ),
              ),
              buttonSimpan ? loading ? CircularProgressIndicator() : Container(child: _simpanButton(context)) : Container()
            ],
          ),
        ),
      ),
    );
  }

  Widget _simpanButton(BuildContext context) {
    return InkWell(
      onTap: (){
        setState((){
          loading = true;
        });
        List<int> penggunaIds = [];
        isCheckedPengguna.forEach((element) {
          if (element > 0) penggunaIds.add(element);
        });
        if (penggunaIds.length > 0) {
          Rest().pushTunjanganDuplicate(tunjangan.id, penggunaIds, _periode).then((value) {
            List<Tunjangan> listTunjangan = value;
            setState((){
              loading = false;
            });
            Helper().showSnackBar(context, 'Berhasil menduplikasi data');
            _moveToTunjanganList(context);
          });
        }
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
          "Simpan",
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

  _moveToPenilaianList(BuildContext context, Tunjangan tunjangan) {
    Route route = MaterialPageRoute(builder: (context) => PenilaianListRoute("", tunjangan));
    Navigator.pushReplacement(context, route);
  }

  _moveToTunjanganList(BuildContext context) {
    Route route = MaterialPageRoute(builder: (context) => TunjanganListRoute(""));
    return Navigator.pushReplacement(context, route);
  }

  _parseJabatan(){
    Rest().fetchJabatanList().then((value) {
      setState((){
        listJabatan = value;
      });
    });
  }

  Widget _getListItemTile(BuildContext context, int index) {
    Pengguna pengguna = listPengguna[index];
    print('PenilaianListDuplicate:_getListItemTile:${isCheckedPengguna.length}');
    if (isCheckedPengguna.length <= index) {
      isCheckedPengguna.add(0);
    }
    return Container(
        child: Row(
            children: [
              Checkbox(
                checkColor: Colors.white,
                fillColor: MaterialStateProperty.resolveWith(Helper().getColor),
                value: isCheckedPengguna.length > 0 && isCheckedPengguna[index] > 0,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) isCheckedPengguna[index] = pengguna.id;
                    else isCheckedPengguna[index] = 0;
                  });
                },
              ),
              Text(pengguna.nama)
            ]
        )
    );
  }
}