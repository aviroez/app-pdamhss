import 'dart:convert';

import 'package:app/components/text_subtitle.dart';
import 'package:app/utils/helper.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

import 'components/background.dart';
import 'components/text_title.dart';
import 'entities/akses.dart';
import 'entities/pengguna.dart';
import 'entities/token.dart';
import 'menu.dart';
import 'utils/constant.dart';
import 'utils/sqlite.dart';

class LoginRoute extends StatelessWidget {
  String message;

  LoginRoute(this.message);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Login",
      home: LoginStatefulWidget(this.message),
    );
  }
}

class LoginStatefulWidget extends StatefulWidget {
  String message;

  LoginStatefulWidget(this.message);

  @override
  CustomLoginStatefulWidget createState() => CustomLoginStatefulWidget(this.message);
}

class CustomLoginStatefulWidget extends State<LoginStatefulWidget> {
  String message;
  final textUserController = TextEditingController();
  final textPasswordController = TextEditingController();
  bool obscureText = true;
  bool loading = false;
  Sqlite sqlite = new Sqlite();

  CustomLoginStatefulWidget(this.message);

  @override
  void initState() {
    super.initState();
    sqlite = new Sqlite();
    sqlite.initDatabase(Constant.DB_NAME);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Container(
          height: height,
          child: Stack(
            children: <Widget>[
              Background(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      primaryColor: Colors.blueAccent,
                      primaryColorDark: Colors.blue,
                      accentColor: Colors.lightBlueAccent,
                    ),
                    child: loading ?
                    Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(height: 10),
                            Image.asset("assets/images/logo_tirta_darma.png", width: 100),
                            SizedBox(height: 25),
                            CircularProgressIndicator()
                          ]
                      ),
                    ) :
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(height: 20),
                        TextTitle(text: "PDAM HSS"),
                        SizedBox(height: 10),
                        TextSubTitle(text: "SIM Kinerja Karyawan"),
                        SizedBox(height: 25),
                        Image.asset("assets/images/logo_tirta_darma.png", width: 100),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: textUserController,
                          // initialValue: isPassword ? 'Password' : 'Email',
                          decoration: InputDecoration(
                            labelText: "NIPP / No HP",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: textPasswordController,
                          obscureText: obscureText,
                          decoration: InputDecoration(
                            labelText: "Password",
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blueAccent, width: 1),
                            ),
                            suffixIcon: IconButton(
                              onPressed: (){
                                setState(() {
                                  obscureText = !obscureText;
                                });
                              },
                              icon: obscureText ? Icon(Icons.remove_red_eye) : Icon(Icons.remove_red_eye_outlined),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        _submitButton(context),
                        SizedBox(height: 5),
                        Container(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: (){
                            },
                            child: Text("Lupa Password"),
                          ),
                        ),
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
      onTap: () async {
        setState(() {
          loading = true;
        });
        content: Text(textUserController.text);
        String no = textUserController.text;
        String password = textPasswordController.text;
        var client = http.Client();
        var body = {'no': no, 'password': password};
        print('login:_submitButton:body: ${body.toString()}');
        try {
          Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/login');
          print('login:_submitButton:uri: ${uri.toString()}');
          client.post(uri, body: body).then((response) async {
            print('login:_submitButton:response: ${response.body}');
            var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
            if (decodedResponse['data'] != null) {
              Helper().setSession('pengguna', jsonEncode(decodedResponse['data']));
              Token? token;
              List<Akses> listAkses = [];
              Pengguna pengguna = Pengguna.fromJson(decodedResponse['data']);
              if (pengguna != null) {
                // pengguna.toJson().forEach((key, value) {
                //   if (key == 'token') token = value;
                //   else if (key == 'akses_list') listAkses = value;
                // });
                listAkses = pengguna.listAkses;
                await sqlite.insertPengguna(decodedResponse['data']);
                if (listAkses.length > 0) {
                  await sqlite.deleteAkses(pengguna.id);
                  for(Akses akses in listAkses) {
                    await sqlite.insertLokasi(Map<String, dynamic>.from(akses.toJson()));
                    await sqlite.insertJabatan(Map<String, dynamic>.from(akses.toJson()));
                    await sqlite.insertAkses(Map<String, dynamic>.from(akses.toJson()));
                  }
                }
                if (pengguna.token != null) {
                  print('login:_submitButton:token: ${pengguna.token!.toJson().toString()}');
                  await Helper().setSession('token', pengguna.token!.token);
                  await sqlite.insertToken(new Map<String, dynamic>.from(pengguna.token!.toJson()));
                }
                if (mounted) {
                  _moveToMenuList(context);
                }
              } else {
                Helper().showSnackBar(context, 'Gagal Login');
              }
            } else {
              Helper().showSnackBar(context, 'Gagal Login');
            }
          }).onError((error, stackTrace) {
            print(error);
            print(stackTrace);
            Helper().showSnackBar(context, error.toString());
          }).whenComplete(() {
            setState(() {
              loading = false;
            });
          });
        } finally {
          setState(() {
            loading = false;
          });
          client.close();
        }
      },
      onLongPress: (){
        developer.log('login', name: textUserController.text);
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
          "Login",
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }

  _moveToMenuList(BuildContext context) {
    print('Login:_moveToMenuList');
    Route route = MaterialPageRoute(builder: (context) => MenuRoute(""));
    return Navigator.pushReplacement(context, route);
  }

}