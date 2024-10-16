import 'package:app/entities/akses.dart';
import 'package:flutter/material.dart';

import 'entities/pengguna.dart';
import 'menu.dart';
import 'utils/helper.dart';

class ProfileRoute extends StatelessWidget {
  String message;
  Pengguna? _pengguna;

  ProfileRoute(this.message, this._pengguna);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Profile",
      home: ProfileStatefulWidget(this.message, this._pengguna),
    );
  }
}

class ProfileStatefulWidget extends StatefulWidget {
  String message;
  Pengguna? _pengguna;

  ProfileStatefulWidget(this.message, this._pengguna);

  @override
  CustomProfileStatefulWidget createState() => CustomProfileStatefulWidget(this.message, this._pengguna);
}

class CustomProfileStatefulWidget extends State<ProfileStatefulWidget> {
  String message;
  Pengguna? _pengguna;
  bool _status = true;
  final FocusNode focusNode = FocusNode();

  CustomProfileStatefulWidget(this.message, this._pengguna);

  @override
  void initState() {
    super.initState();

    // Helper().getPengguna().then((value) {
    //   _pengguna = Pengguna.fromJson(value);
    // });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return WillPopScope(
        onWillPop: () {
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
          title: Text('Profile'),
        ),
        body: Container(
          width: width,
          height: height,
          child: new ListView(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Container(
                    color: Color(0xffFFFFFF),
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 25.0),
                      child: new Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                              padding: EdgeInsets.only(left: 25.0, right: 25.0, top: 25.0),
                              child: new Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  new Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      new Text(
                                        'Personal Information',
                                        style: TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )),
                          Padding(
                              padding: EdgeInsets.only(
                                  left: 25.0, right: 25.0, top: 25.0),
                              child: new Row(
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  new Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      new Text(
                                        'Nama',
                                        style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )),
                          Padding(
                              padding: EdgeInsets.only(
                                  left: 25.0, right: 25.0, top: 2.0),
                              child: new Row(
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  new Flexible(
                                    child: new TextField(
                                      decoration: InputDecoration(
                                        hintText: _pengguna != null ? _pengguna!.nama : '',
                                      ),
                                      enabled: !_status,
                                      autofocus: !_status,
                                    ),
                                  ),
                                ],
                              )),
                          Padding(
                              padding: EdgeInsets.only(
                                  left: 25.0, right: 25.0, top: 25.0),
                              child: new Row(
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  new Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      new Text(
                                        'NIPP',
                                        style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )),
                          Padding(
                              padding: EdgeInsets.only(
                                  left: 25.0, right: 25.0, top: 2.0),
                              child: new Row(
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  new Flexible(
                                    child: new TextField(
                                      decoration: InputDecoration(
                                          hintText: _pengguna != null ? _pengguna!.nipp : ''
                                      ),
                                      enabled: !_status,
                                    ),
                                  ),
                                ],
                              )
                          ),
                          Padding(
                              padding: EdgeInsets.only(left: 25.0, right: 25.0, top: 25.0
                              ),
                              child: new Row(
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  new Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      new Text(
                                        'No HP',
                                        style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                          ),
                          Padding(
                              padding: EdgeInsets.only(left: 25.0, right: 25.0, top: 2.0),
                              child: new Row(
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  new Flexible(
                                    child: new TextField(
                                      decoration: InputDecoration(
                                          hintText: _pengguna != null ? _pengguna!.noHp : ''
                                      ),
                                      enabled: !_status,
                                    ),
                                  ),
                                ],
                              )
                          ),
                          Container(
                            child: Column(
                              children: _pengguna != null ? _showAccessList(_pengguna!.listAkses) : [],
                            ),
                          ),
                          !_status ? _getActionButtons() : new Container(),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    focusNode.dispose();
    super.dispose();
  }

  Widget _getActionButtons() {
    return Padding(
      padding: EdgeInsets.only(left: 25.0, right: 25.0, top: 45.0),
      child: new Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 10.0),
              child: Container(
                  child: new RaisedButton(
                    child: new Text("Save"),
                    textColor: Colors.white,
                    color: Colors.green,
                    onPressed: () {
                      setState(() {
                        _status = true;
                        FocusScope.of(context).requestFocus(new FocusNode());
                      });
                    },
                    shape: new RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(20.0)),
                  )),
            ),
            flex: 2,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 10.0),
              child: Container(
                  child: new RaisedButton(
                    child: new Text("Cancel"),
                    textColor: Colors.white,
                    color: Colors.red,
                    onPressed: () {
                      setState(() {
                        _status = true;
                        FocusScope.of(context).requestFocus(new FocusNode());
                      });
                    },
                    shape: new RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(20.0)),
                  )),
            ),
            flex: 2,
          ),
        ],
      ),
    );
  }

  Widget _getEditIcon() {
    return new GestureDetector(
      child: new CircleAvatar(
        backgroundColor: Colors.red,
        radius: 14.0,
        child: new Icon(
          Icons.edit,
          color: Colors.white,
          size: 16.0,
        ),
      ),
      onTap: () {
        setState(() {
          _status = false;
        });
      },
    );
  }

  _moveToMenuList(BuildContext context) {
    Route route = MaterialPageRoute(builder: (context) => MenuRoute(""));
    return Navigator.pushReplacement(context, route);
  }

  List<Widget> _showAccessList(List<Akses> listAkses) {
    List<Widget> list = [];

    Widget top = Padding(
        padding: EdgeInsets.only(left: 25.0, right: 25.0, top: 25.0
        ),
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            new Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                new Text(
                  'Jabatan',
                  style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ],
        )
    );
    list.add(top);
    for(Akses akses in listAkses) {
      String fullJabatan = akses.jabatanNama;
      if (akses.lokasiNama.isNotEmpty) fullJabatan += ' ${akses.lokasiNama}';
      Widget value = Padding(
          padding: EdgeInsets.only(left: 25.0, right: 25.0, top: 2.0),
          child: new Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              new Flexible(
                child: new TextField(
                  decoration: InputDecoration(
                      hintText: fullJabatan
                  ),
                  enabled: !_status,
                ),
              ),
            ],
          )
      );
      list.add(value);
    }

    return list;
  }
}