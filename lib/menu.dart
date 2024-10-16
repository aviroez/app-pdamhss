import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:app/components/text_subtitle.dart';
import 'package:app/components/text_title.dart';
import 'package:app/entities/tunjangan.dart';
import 'package:app/login.dart';
import 'package:app/profile.dart';
import 'package:app/tunjangan_list.dart';
import 'package:app/utils/sqlite.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'components/background.dart';
import 'entities/akses.dart';
import 'entities/pengguna.dart';
import 'penilaian_list.dart';
import 'utils/helper.dart';
import 'utils/rest.dart';
import 'utils/sync.dart';

class MenuRoute extends StatelessWidget {
  String message;

  MenuRoute(this.message);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Menu",
      home: MenuStatefulWidget(this.message),
    );
  }
}

class MenuStatefulWidget extends StatefulWidget {
  String message;

  MenuStatefulWidget(this.message);

  @override
  CustomMenuStatefulWidget createState() => CustomMenuStatefulWidget(this.message);
}

class CustomMenuStatefulWidget extends State<MenuStatefulWidget> {
  String message;
  final textEmailController = TextEditingController();
  final textPasswordController = TextEditingController();
  bool obscureText = true;
  bool loading = false;
  bool showPekerjaanList = false;
  bool operatorStaff = false;
  bool tunjanganLoad = false;
  bool submitPenilaian = false;
  int buildCount = 0;
  var now = DateTime.now();
  List<Tunjangan> listTunjangan = [];
  Pengguna? pengguna;
  Sqlite sqlite = new Sqlite();
  String periode = '';

  CustomMenuStatefulWidget(this.message);

  @override
  void initState() {
    super.initState();
    print('menu:initState');

    Helper().getPengguna().then((value) {
      pengguna = Pengguna.fromJson(value);

      if (pengguna != null && pengguna!.id > 0) {
        periode = DateFormat('yMM').format(now);
        if (now.day >= 26) {
          var nextMonth = DateTime(now.year, now.month + 1, 1);
          periode = DateFormat('yMM').format(nextMonth);
        }
        Sync().synchronizeTunjangan().then((tunjanganList) async {
          print('menu:initState:listTunjangan ${tunjanganList.length.toString()}');

          for(Tunjangan t in tunjanganList) {
            await sqlite.insertTunjangan(Map<String, dynamic>.from(t.toJson()));
            if (t.pengguna != null) {
              sqlite.insertPengguna(Map<String, dynamic>.from(t.pengguna!.toJson()));
              if (t.pengguna!.listAkses != null && t.pengguna!.listAkses.length > 0) {
                sqlite.deleteAkses(t.pengguna!.id);
                for (Akses akses in t.pengguna!.listAkses) {
                  sqlite.insertAkses(Map<String, dynamic>.from(akses.toJson()));
                }
              }
            }
          }
          sqlite.getAllTunjanganId().then((value) {
            Sync().synchronizePenilaian(value);
          });
        }).onError((error, stackTrace) {
          print(error);
          print(stackTrace);
        });
        Sync().synchronizeMaster();

        for(Akses akses in pengguna!.listAkses){
          switch (akses.jabatanCode) {
            case 'admin':
              setState((){
                showPekerjaanList = true;
              });
              break;
            case 'direktur':
              setState((){
                showPekerjaanList = true;
              });
              break;
            case 'kepala_bagian':
              setState((){
                showPekerjaanList = true;
              });
              break;
            case 'kepala_unit':
              setState((){
                showPekerjaanList = true;
              });
              break;
            case 'kepala_seksi':
              setState((){
                showPekerjaanList = true;
              });
              break;
            case 'operator':
              setState((){
                showPekerjaanList = false;
                operatorStaff = true;
              });
              break;
            case 'staff':
              setState((){
                showPekerjaanList = false;
                operatorStaff = true;
              });
              break;
          }
        }

        OneSignal.shared.getDeviceState().then((value) {
          var playerId = value!.userId;
          print('OneSignal.shared.getDeviceState: $playerId');
          if (pengguna!.token!.playerId != playerId && playerId != null){
            Map<String, String> body = Map<String, String>();
            body['player_id'] = playerId;
            Rest().updateToken(pengguna!.token!.id, body).then((value) {
              if (pengguna != null && value != null) {
                pengguna!.token = value;
                Helper().setSession('pengguna', jsonEncode(pengguna!.toJson()));
              }
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    if (listTunjangan.isEmpty && pengguna != null && pengguna!.id > 0 && !tunjanganLoad) {
      setState(() {
        tunjanganLoad = true;
        buildCount = 0;
      });
      Map<String, String> body = {'periode': periode, 'pengguna_id': pengguna!.id.toString()};
      sqlite.getTunjanganList(body).then((valueTunjangan) {
        print('Menu:fetchTunjanganList:listTunjangan: ${listTunjangan.length}');
        if (valueTunjangan.length > 0) {
          setState(() {
            listTunjangan = valueTunjangan;
            tunjanganLoad = false;
          });
        } else {
          body['pengguna_id_only'] = pengguna!.id.toString();
          Rest().fetchTunjanganList(body).then((value) {
            setState(() {
              listTunjangan = value;
              tunjanganLoad = true;
            });
            print('Menu:fetchTunjanganList:rest: ${listTunjangan.length}');
          }).onError((error, stackTrace) {
            setState(() {
              tunjanganLoad = true;
            });
          });

        }
      });
    }
    setState(() {
      buildCount++;
    });

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

    return Scaffold(
      body: Container(
        width: width,
        height: height,
        // decoration: BoxDecoration(
        //   image: DecorationImage(
        //     alignment: Alignment.bottomCenter,
        //     image: AssetImage("images/rectangle_blue.png"),
        //     fit: BoxFit.fitWidth,
        //   ),
        // ),
        child: Stack(
          children: <Widget>[
            Background(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                // crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: 20),
                        TextTitle(text: "PDAM HSS"),
                        SizedBox(height: 10),
                        TextSubTitle(text: "SIM Kinerja Karyawan"),
                        showPekerjaanList ? SizedBox(height: 25) : Container(),
                        showPekerjaanList ? InkWell(
                          onTap: () {
                            _moveToPekerjaanList(context);
                          },
                          child: _menuButton(context, "Pekerjaan Staff"),
                        ) : Container(),
                        listTunjangan.length > 0 ? SizedBox(height: 25) : Container(),
                        listTunjangan.length > 0 ? InkWell(
                          onTap: () {
                            Helper().setSession('penilaian_list_page_from', 'menu');
                            Route route = MaterialPageRoute(builder: (context) => PenilaianListRoute("", listTunjangan[0]));
                            Navigator.pushReplacement(context, route);
                          },
                          child: _menuButton(context, "Pekerjaan Harian"),
                        ) : Container(),
                        !showPekerjaanList ? SizedBox(height: 25) : Container(),
                        !showPekerjaanList ? InkWell(
                          onTap: () {
                            _moveToPekerjaanList(context);
                          },
                          child: _menuButton(context, "Rekap Capaian Pekerjaan"),
                        ) : Container(),
                        SizedBox(height: 25),
                        // InkWell(
                        //   onTap: () {
                        //
                        //   },
                        //   child: _menuButton(context, "Rekap Capaian Pekerjaan"),
                        // ),
                        // SizedBox(height: 25),
                        pengguna != null ? InkWell(
                          onTap: () {
                            Route route = MaterialPageRoute(builder: (context) => ProfileRoute("", pengguna));
                            Navigator.pushReplacement(context, route);
                          },
                          child: _menuButton(context, "Profile"),
                        ) : Container(),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(bottom: 50),
                    child: Center(
                      child: _logoutButton(context, "Logout"),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _menuButton(BuildContext context, text) {
    return Container(
      height: 75,
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
        text,
        style: TextStyle(fontSize: 20, color: Colors.white),
      ),
    );
  }

  Widget _logoutButton(BuildContext context, text) {
    return InkWell(
      onTap: (){
        Helper().setSession('pengguna', "");
        sqlite.deleteDatabaseFile().then((value) {}).whenComplete(() {
          _moveToLogin(context);
        });
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
                colors: [Colors.white, Colors.white]
            )
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 20, color: Colors.black),
        ),
      ),
    );
  }

  bool isPerfectSquare(x){
    var s = Helper().toInt(sqrt(x));
    return (s * s == x);
  }

  bool isFibonacci(n)
  {
    return isPerfectSquare(5 * n * n + 4) || isPerfectSquare(5 * n * n - 4);
  }

  _moveToPekerjaanList(BuildContext context) {
    Route route = MaterialPageRoute(builder: (context) => TunjanganListRoute(""));
    return Navigator.pushReplacement(context, route);
  }

  _moveToLogin(BuildContext context) {
    Route route = MaterialPageRoute(builder: (context) => LoginRoute(""));
    return Navigator.pushReplacement(context, route);
  }

}