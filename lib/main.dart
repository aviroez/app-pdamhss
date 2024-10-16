import 'dart:convert';

import 'package:app/menu.dart';
import 'package:app/utils/constant.dart';
import 'package:app/utils/sqlite.dart';
import 'package:catcher/catcher.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:new_version/new_version.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'components/background.dart';
import 'components/text_subtitle.dart';
import 'components/text_title.dart';
import 'entities/akses.dart';
import 'entities/pengguna.dart';
import 'entities/token.dart';
import 'login.dart';
import 'utils/helper.dart';
import 'utils/rest.dart';

void main() {
  /// STEP 1. Create catcher configuration. 
  /// Debug configuration with dialog report mode and console handler. It will show dialog and once user accepts it, error will be shown   /// in console.
  CatcherOptions debugOptions = CatcherOptions(DialogReportMode(), [ConsoleHandler(
        enableApplicationParameters: true,
        enableDeviceParameters: true,
        enableCustomParameters: true,
        enableStackTrace: true,
        handleWhenRejected: false,
      )]);

  /// STEP 2. Pass your root widget (MyApp) along with Catcher configuration:
  // Catcher(rootWidget: MyApp(), debugConfig: debugOptions, releaseConfig: debugOptions);
  // Catcher(rootWidget: MyApp(), enableLogger: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    //Remove this method to stop OneSignal Debugging
    // OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);

    OneSignal.shared.setAppId(Constant.ONESIGNAL_APP_ID);

    // The promptForPushNotificationsWithUserResponse function will show the iOS push notification prompt. We recommend removing the following code and instead using an In-App Message to prompt for notification permission
    OneSignal.shared.promptUserForPushNotificationPermission().then((accepted) {
      print("Accepted permission: $accepted");
    });

    OneSignal.shared.setNotificationOpenedHandler((OSNotificationOpenedResult result) {
      print('OneSignal.shared.setNotificationOpenedHandler: $result');
    });

    return MaterialApp(
      navigatorKey: Catcher.navigatorKey,
      title: "Menu",
      home: MainStatefulWidget(),
    );
  }
}

class MainStatefulWidget extends StatefulWidget {

  MainStatefulWidget();

  @override
  CustomMainStatefulWidget createState() => CustomMainStatefulWidget();
}

class CustomMainStatefulWidget extends State<MainStatefulWidget> {
  final textUserController = TextEditingController();
  final textPasswordController = TextEditingController();
  final newVersion = NewVersion();
  bool obscureText = true;
  bool loading = true;
  VersionStatus? versionStatus;
  Sqlite sqlite = new Sqlite();
  int viewState = 0;

  CustomMainStatefulWidget();

  @override
  void initState() {
    super.initState();
    newVersion.getVersionStatus().then((value) {
      versionStatus = value;
    });
    try {
      Helper().getPengguna().then((value) async {
        loading = true;
        if (value.isNotEmpty && Helper().toInt(value['id']) > 0) {
          String token = await Helper().getSessionString('token');
          try {
            Map<String, dynamic> map = await Rest().fetchToken(token);
            if (map['data'] == null) {
              viewState = 1;
              Future(() {
                _moveToLogin(context);
              });
            } else {
              viewState = 2;
              Future(() {
                _moveToMenuList(context);
              });
            }
          } catch (error){
            viewState = 2;
            Future(() {
              _moveToMenuList(context);
            });
          }
        } else {
          viewState = 1;
          Future(() {
            _moveToLogin(context);
          });
        }
      });
    } catch (error) {
      loading = true;
      viewState = 1;
      Future(() {
        _moveToLogin(context);
      });
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    newVersion.showAlertIfNecessary(context: context);
    final height = MediaQuery.of(context).size.height;
    if (viewState == 2) {
      return Container();
    } else if (viewState == 1) {
      return getLoginView(context);
    }
    return Splash();
  }

  Future<int> checkPengguna() async {
    try {
      Map<String, dynamic> map = await Helper().getPengguna();
      setState((){
        loading = true;
      });
      return 2;
    } catch (error) {
      print('pengguna:error '+error.toString());
      setState((){
        loading = true;
      });
      return 1;
    }
  }

  Widget getLoginView(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
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
            var decodedResponse = jsonDecode(response.body);
            if (decodedResponse['data'] != null) {
              sqlite = new Sqlite();
              Token? token;
              List<Akses> listAkses = [];
              Pengguna pengguna = Pengguna.fromJson(Map<String, dynamic>.from(decodedResponse['data']));
              pengguna.toJson().forEach((key, value) {
                if (key == 'token') token = value;
                else if (key == 'akses_list') listAkses = value;
              });
              if (token != null) {
                await sqlite.insertToken(Map<String, dynamic>.from(token!.toJson()));
              }
              await sqlite.insertPengguna(Map<String, dynamic>.from(decodedResponse['data']));
              if (listAkses.length > 0) {
                await sqlite.deleteAkses(pengguna.id);
                for(Akses akses in listAkses) {
                  await sqlite.insertLokasi(Map<String, dynamic>.from(akses.toJson()));
                  await sqlite.insertJabatan(Map<String, dynamic>.from(akses.toJson()));
                  await sqlite.insertAkses(Map<String, dynamic>.from(akses.toJson()));
                }
              }
              Helper().setSession('pengguna', jsonEncode(decodedResponse['data']));
              _moveToMenuList(context);
            } else {
              Helper().showSnackBar(context, 'Gagal Login');
            }
          }).onError((error, stackTrace) {
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
    Route route = MaterialPageRoute(builder: (context) => MenuRoute(""));
    return Navigator.pushReplacement(context, route);
  }

  _moveToLogin(BuildContext context) {
    Helper().setSession('pengguna', '');
    sqlite.deleteDatabaseFile().then((value) {}).whenComplete(() {
      Route route = MaterialPageRoute(builder: (context) => LoginRoute(""));
      Navigator.pushReplacement(context, route);
    });
  }
}

class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          children: <Widget>[
            Background(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
            Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.only(top: 250),
                      child: Center(
                        child: Image.asset("assets/images/logo_tirta_darma.png", width: 250),
                      ),
                    ),
                  Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(bottom: 150, left: 5, right: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("PDAM HSS", textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.black54)),
                          Text("SIM Kinerja Karyawan", textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black54)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


