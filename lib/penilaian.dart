import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:developer' as developer;

import 'package:app/utils/sqlite.dart';
import 'package:app/utils/sync.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:path_provider/path_provider.dart';

import 'entities/event.dart';
import 'entities/notifikasi.dart';
import 'entities/pengguna.dart';
import 'entities/penilaian.dart';
import 'entities/penilaian_detail.dart';
import 'entities/tunjangan.dart';
import 'penilaian_list.dart';
import 'utils/constant.dart';
import 'utils/helper.dart';
import 'utils/rest.dart';
import 'utils/string_extension.dart';

class PenilaianRoute extends StatelessWidget {
  String message;
  Penilaian penilaian;
  Tunjangan tunjangan;

  PenilaianRoute(this.message, this.penilaian, this.tunjangan);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Detail Pekerjaan",
      home: PenilaianStatefulWidget(this.message, this.penilaian, this.tunjangan),
    );
  }
}

class PenilaianStatefulWidget extends StatefulWidget {
  String message;
  Penilaian penilaian;
  Tunjangan tunjangan;

  PenilaianStatefulWidget(this.message, this.penilaian, this.tunjangan);

  @override
  CustomPenilaianStatefulWidget createState() => CustomPenilaianStatefulWidget(this.message, this.penilaian, this.tunjangan);
}

class CustomPenilaianStatefulWidget extends State<PenilaianStatefulWidget> {
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;
  TextEditingController textNilaiController = TextEditingController(text: '');
  String message;
  bool initialData = false;
  bool loading = false;
  bool showButtonCapture = false;
  bool showButtonSubmit = false;
  bool submitPenilaian = false;
  ScrollController controller = ScrollController();
  Pengguna? pengguna;
  Penilaian penilaian;
  Tunjangan tunjangan;
  List<Penilaian> listPenilaian = [];
  List<PenilaianDetail> listPenilaianDetail = [];
  List<Notifikasi> listNotifikasi = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  File _image = File("");
  String _fullAddress = '';
  String _statusValue = '';
  String _timeValue = '';
  String _statusAddress = '';
  String _imageValue = '';
  String _tipe = '';
  double _nilai = 0;
  int totalDays = 31;
  Position? _position;
  List<Placemark> _placemarks = [];
  Sqlite sqlite = new Sqlite();

  CustomPenilaianStatefulWidget(this.message, this.penilaian, this.tunjangan);

  @override
  void initState() {
    super.initState();
    controller = ScrollController()
      ..addListener(_scrollListener);
    _tanggalMulai = DateTime.parse(this.tunjangan.tanggalMulai);
    _tanggalSelesai = DateTime.parse(this.tunjangan.tanggalSelesai);

    if (DateTime.now().isAfter(_tanggalSelesai!)) {
      _focusedDay = _tanggalSelesai!;
      showButtonCapture = false;
      showButtonSubmit = false;
    } else if (DateTime.now().isBefore(_tanggalMulai!)) {
      _focusedDay = _tanggalMulai!;
      showButtonCapture = false;
      showButtonSubmit = false;
    }
    _selectedDay = _focusedDay;

    showListPenilaianDetail(penilaian.id);

    setState(() {
      _tipe = penilaian.tipe;
      if (['harian', 'sekali'].contains(_tipe)){
        _nilai = 1;
      } else {
        _nilai = 0;
      }
      textNilaiController.text = Helper().removeLastCommaZero(_nilai);
    });

    Rest().fetchHoliday(penilaian.tunjanganId).then((value) {
      if (value != null && value['total'] != null) {
        int total = Helper().toInt(value['total']);
        setState((){
          if (total > 0) totalDays = total;
        });
      }
    });
    // _checkGps();
    Helper().getPengguna().then((value) {
      pengguna = Pengguna.fromJson(value);

      _showButton();
    });
  }

  @override
  void dispose() {
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription!.cancel();
      _positionStreamSubscription = null;
    }
    super.dispose();
  }

  List<Event> _getEventsForDay(DateTime day) {
    for (PenilaianDetail penilaianDetail in listPenilaianDetail) {
      var tanggal = DateFormat('yyyy-MM-dd').format(day);
      if (tanggal == penilaianDetail.tanggal) {
        Event event = Event(penilaianDetail.status);
        return [event];
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery
        .of(context)
        .size
        .height;
    final width = MediaQuery
        .of(context)
        .size
        .width;
    if (!initialData) {
      setState(() {
        initialData = true;
      });
      Rest().fetchPenilaianDetailList(penilaian).then((value) {
        setState(() {
          listPenilaianDetail = value;
        });
        for (PenilaianDetail penilaianDetail in listPenilaianDetail) {
          sqlite.insertPenilaianDetail(Map<String, dynamic>.from(penilaianDetail.toJson()));
          if (penilaianDetail.verifikasi != null) {
            sqlite.insertVerifikasi(Map<String, dynamic>.from(penilaianDetail.verifikasi!.toJson()));
          }
          if (penilaianDetail.file != null) {
            sqlite.insertFile(Map<String, dynamic>.from(penilaianDetail.file!.toJson()));
          }
        }
      });
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
          title: const Text('Detail Pekerjaan'),
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
                height: 30,
                child: Row(
                  children: [
                    Expanded(
                      child: Text("Tanggal"),
                    ),
                    Text("${Helper().parseTanggal(
                        this.penilaian.tanggalMulai, false)} - ${Helper()
                        .parseTanggal(this.tunjangan.tanggalSelesai, true)}"),
                  ],
                ),
              ),
              Container(
                height: 30,
                child: Row(
                  children: [
                    Expanded(
                      child: Text("Nilai / Target"),
                    ),
                    Text("${Helper().currency(
                        this.penilaian.nilai)} / ${Helper().currency(
                        this.penilaian.target)}"),
                  ],
                ),
              ),
              Container(
                alignment: Alignment.topLeft,
                width: width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Deskripsi:"),
                    Text(this.penilaian.nama),
                  ],
                ),
              ),
              // Divider(),
              // Container(
              //   height: 30,
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: Text("Lokasi"),
              //       ),
              //       Text(_fullAddress),
              //     ],
              //   ),
              // ),
              // Container(
              //     height: 40,
              //     child: Row(
              //       children: [
              //         Expanded(
              //           child: Text("Status"),
              //         ),
              //         Chip(
              //           padding: EdgeInsets.all(0),
              //           backgroundColor: Colors.deepPurple,
              //           label: Text('Pending', style: TextStyle(color: Colors.white)),
              //         ),
              //       ],
              //     ),
              // ),
              Container(
                child: TableCalendar(
                  firstDay: _tanggalMulai!,
                  lastDay: _tanggalSelesai!,
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.twoWeeks,
                  onDaySelected: _onDaySelected,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  eventLoader: _getEventsForDay,
                  calendarStyle: CalendarStyle(
                    // Use `CalendarStyle` to customize the UI
                    outsideDaysVisible: false,
                  ),
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
              ),
              _statusValue != '' ? Container(
                  width: width,
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        var tanggal = DateFormat('yyyy-MM-dd').format(
                            _selectedDay!);
                        _showDialog(context, tanggal, _image, _imageValue);
                      },
                      child: Container(
                        padding: EdgeInsets.all(10),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                  children: [
                                    parseNilaiComponent(),
                                    _nilai > 1 ? SizedBox(width: 10) : Container(),
                                    Expanded(
                                      child: Text(
                                        _statusValue.capitalize(),
                                        style: TextStyle(
                                            color: _statusValue == 'terima' ? Colors.blueAccent : (_statusValue == 'tolak' ? Colors.redAccent : Colors.black87)
                                        ),
                                      ),
                                    ),
                                    _timeValue != '' ? Container(
                                      child: Text(
                                          _timeValue,
                                          style: TextStyle(
                                            color: Colors.green
                                          ),
                                      ),
                                    ) : Container(),
                                    _imageValue != '' ? Container(
                                        child: Padding(
                                            padding: EdgeInsets.all(10),
                                            child: Container(
                                                width: 25,
                                                height: 50,
                                                child: Image.network(_imageValue, loadingBuilder: _loadingBuilder,)
                                            )
                                        ),
                                    ) : _image.path != '' ? Container(
                                      child: Padding(
                                          padding: EdgeInsets.all(10),
                                          child: ClipRRect(
                                            child: Image.file(
                                              _image,
                                              width: 25,
                                              height: 50,
                                              fit: BoxFit.fitWidth,
                                            ),
                                          )
                                      )
                                    ) : Container()
                                  ]
                              ),
                              _statusAddress != '' ? Text(_statusAddress) : Container(),
                            ]
                        ),
                      ),
                    ),
                  )
              ) : Container(),
              Expanded(
                child: Container(),
              ),
              loading ? CircularProgressIndicator() :
              (
                  showButtonCapture && showButtonSubmit ? Column(
                    children: [
                      (penilaian.tipe == 'nominal' || penilaian.tipe == 'persen') || penilaian.target >= 31?
                      TextFormField(
                        controller: textNilaiController,
                        keyboardType: TextInputType.number,
                        enabled: true,
                        onChanged: (value) {
                          setState(() {
                            // _nilai = Helper().currencyRemove(value);
                            // textNilaiController.text = Helper().removeLastCommaZero(_nilai);
                          });
                        },
                        decoration: InputDecoration(
                          labelText: "Nilai",
                          border: OutlineInputBorder(),
                        ),
                      ) : Container(),
                      penilaian.tipe == 'nominal' || _nilai <= 0 ? SizedBox(height: 10) : Container(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          showButtonCapture ? Expanded(
                            child: _captureButton(context),
                          ) : Container(),
                          showButtonSubmit ? Expanded(
                            child: _submitButton(context),
                          ) : Container(),
                        ],
                      )
                    ],
                  ) : Container()
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    _getLastKnownPosition();
    setState(() {
      showButtonCapture = false;
      showButtonSubmit = false;
      _statusValue = '';
      _statusAddress = '';
      _timeValue = '';
      _imageValue = '';
      _selectedDay = selectedDay;
      // _focusedDay = selectedDay;
    });
    _showListEvent();
    _showButton();
  }

  Widget _captureButton(BuildContext context) {
    return InkWell(
      onTap: () {
        // _showPicker(context);
        _imgFromCamera(1);
      },
      onLongPress: () {},
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
          color: Colors.green,
        ),
        child: Text(
          "Ambil Gambar",
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }

  Widget _submitButton(BuildContext context) {
    return InkWell(
      onTap: () {
        double nilai = Helper().currencyRemove(textNilaiController.text);
        if (nilai <= 0) {
          // Helper().showSnackBar(context, 'Isi Nilai terlebih dahulu');
          // return;
          nilai = 1;
        }
        if (_selectedDay != null) {
          if (_image.path == '') {
            Helper().showSnackBar(context, 'Ambil gambar terlebih dahulu');
            return;
          }
          setState(() {
            _statusValue = 'Sedang Diproses';
            _imageValue = '';
            _timeValue = '';
          });
          var tanggal = DateFormat('yyyy-MM-dd').format(_selectedDay!);
          setState(() {
            loading = true;

            var body = {
              'penilaian_id': penilaian.id.toString(),
              'nilai': nilai.toString(),
              'tanggal': tanggal,
              'status': 'proses'
            };
            if (pengguna != null) {
              body['pengguna_id'] = pengguna!.id.toString();
            }
            if (_position != null) {
              body['latitude'] = _position!.latitude.toString();
              body['longitude'] = _position!.longitude.toString();
            }
            _fullAddress = '';
            if (_placemarks.length > 0){
              _fullAddress = getFullAddress(_placemarks[0]);
              body['alamat'] = _fullAddress;
            }
            Rest().savePenilaianDetail(body).then((
                penilaianDetail) async {
              setState(() {
                _statusValue = 'Proses';
                _statusAddress = _fullAddress;
                _timeValue = penilaianDetail.createdAt;
              });
              if (penilaianDetail != null && penilaianDetail.id > 0) {
                sqlite.insertPenilaianDetail(Map<String, dynamic>.from(penilaianDetail.toJson()));
                _nilai = penilaianDetail.nilai;
                Rest().saveFile(_image, penilaianDetail.id).then((value) {
                  showSuccessAlert(context);
                });
              } else {
                showSuccessAlert(context);
              }
            }).onError((error, stackTrace) {
              setState(() {
                loading = false;
              });

              sqlite.insertPenilaianDetailInput(body).then((
                  penilaianDetail) async {
                print('Penilaian:_submitButton: ${penilaianDetail!.toJson().toString()}');
                setState(() {
                  _statusValue = 'Proses Lokal';
                  _statusAddress = _fullAddress;
                  _timeValue = DateFormat('dd-MM-yyyy hh:ii:ss').format(DateTime.now());
                });
                if (penilaianDetail != null && penilaianDetail.id > 0) {
                  _nilai = penilaianDetail.nilai;
                  Map<String, dynamic> values = new Map<String, dynamic>();
                  // values['penilaian_detail_id'] = penilaianDetail.id;

                  values['id'] = await sqlite.getFileInputId();
                  values['penilaian_id'] = penilaian.id;
                  values['nama'] = _image.path;
                  values['tanggal'] = tanggal;
                  sqlite.insertFileInput(values).then((value) {
                    showSuccessAlert(context);
                  });
                } else {
                  showSuccessAlert(context);
                }
              }).onError((error, stackTrace) {
                print(error);
                setState(() {
                  loading = false;
                });
                Helper().showSnackBar(context, error.toString());
              });
            });
          });
        }
      },
      onLongPress: () {},
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
          color: Colors.blue,
        ),
        child: Text(
          "Proses",
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }

  _moveToPenilaianList(BuildContext context, Tunjangan tunjangan) {
    Route route = MaterialPageRoute(
        builder: (context) => PenilaianListRoute("", tunjangan));
    return Navigator.pushReplacement(context, route);
  }

  showSuccessAlert(BuildContext context) {
    // Rest().fetchPenilaianDetailList(penilaian).then((value) {
    //   setState(() {
    //     loading = false;
    //     listPenilaianDetail = value;
    //   });
    //   SnackBar snackBar = SnackBar(content: Text('Berhasil menyimpan data'));
    //   ScaffoldMessenger.of(context).showSnackBar(snackBar);
    //   Rest().fetchAllNotifikasiOneSignal({}).then((value) {
    //     listNotifikasi = value;
    //   });
    // });
    sqlite.getAllPenilaianDetail(penilaian.id).then((value) {
        setState(() {
          loading = false;
          listPenilaianDetail = value;
        });
        SnackBar snackBar = SnackBar(content: Text('Berhasil menyimpan data'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        // Sync().synchronizePenilaianDetailFile().then((value) {
          // showListPenilaianDetail(penilaian.id);
        // });
        // Sync().synchronizePenilaian();
      });
  }

  showButton(BuildContext context) {
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

  _imgFromCamera(type) async {
    ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(
        source: ImageSource.camera, maxWidth: 1024, maxHeight: 1024);

    setState(() {
      _statusValue = 'Belum Diproses';
      _imageValue = '';
      _timeValue = '';
    });
    if (image != null) {
      // getting a directory path for saving
      final Directory directory = await getApplicationDocumentsDirectory();

      var tanggal = DateFormat('yyyyMMdd').format(_selectedDay!);
      var waktu = DateFormat('yyMMddhhiiss').format(DateTime.now());

      String newPath = '${directory.path}/${penilaian.id}_${tanggal}_${waktu}.jpg';
      image.saveTo(newPath);

      print('Penilaian:_imgFromCamera:newPath $newPath');
      setState(() {
        _image = File(newPath);
      });
    }
    _handlePermission().then((value) {
      print('Penilaian:_handlePermission: $value');
      setState(() {
        if (value) {
          _statusAddress = '';
          _getLocation().then((value) {
            _statusAddress = '${value?.latitude}, ${value?.longitude}';

            double latitude = value?.latitude ?? 0;
            double longitude = value?.longitude ?? 0;

            if (value?.latitude != 0 && value?.longitude != 0) {
              placemarkFromCoordinates(latitude, longitude).then((value) {
                setState((){
                  _placemarks = value;

                  if (_placemarks.length > 0){
                    _statusAddress = getFullAddress(_placemarks[0]);
                  }
                });
              });
            }
          });
        } else {
          _statusAddress = 'GPS Belum Diaktifkan';
        }
      });
    });
    _showButton();
  }

  void _showPicker(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Container(
              child: new Wrap(
                children: <Widget>[
                  new ListTile(
                      leading: new Icon(Icons.photo_library),
                      title: new Text('Photo Library'),
                      onTap: () {
                        _imgFromCamera(2);
                        Navigator.of(context).pop();
                      }
                  ),
                  new ListTile(
                    leading: new Icon(Icons.photo_camera),
                    title: new Text('Camera'),
                    onTap: () {
                      _imgFromCamera(1);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  Future<void> _showDialog(BuildContext context, String tanggal, File file,
      String url) async {
    final height = MediaQuery
        .of(context)
        .size
        .height;
    final width = MediaQuery
        .of(context)
        .size
        .width;
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
            ) : (file.path != '' ? Container(
                child: Image.file(
                  _image,
                  width: width,
                  height: height,
                  fit: BoxFit.fitWidth,
                )
            ) : Container()),
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

  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.

      return false;
    }

    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.

        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.

      return false;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return true;
  }

  void _getLastKnownPosition() async {
    final position = await _geolocatorPlatform.getLastKnownPosition();
    if (position != null) {

    }
  }

  void _handleLocationAccuracyStatus(LocationAccuracyStatus status) {
    String locationAccuracyStatusValue;
    if (status == LocationAccuracyStatus.precise) {
      locationAccuracyStatusValue = 'Precise';
    } else if (status == LocationAccuracyStatus.reduced) {
      locationAccuracyStatusValue = 'Reduced';
    } else {
      locationAccuracyStatusValue = 'Unknown';
    }
  }

  _showButton() async {
    if (pengguna!.id == tunjangan.penggunaId) {
      // _toggleServiceStatusStream();

      if (_selectedDay!.weekday <= 6 && isSameDay(DateTime.now(), _selectedDay)) {
        setState((){
          loading = false;
          showButtonCapture = true;
          showButtonSubmit = true;
        });

        // final hasPermission = await _handlePermission();
        // print('penilaianDetail:_showButton:hasPermission: ${hasPermission}');

        // if (!hasPermission) return;

        _geolocatorPlatform.getCurrentPosition().then((value) {
          setState((){
            _position = value;
          });
          _updatePlacemark(value.latitude, value.longitude);
        });
      }
    }
  }

  Future<Position?> _getLocation() async {
    Position? p;
    p = await _geolocatorPlatform.getCurrentPosition();
    if (p.latitude != 0 && p.longitude != 0) return p;
    p = await _geolocatorPlatform.getLastKnownPosition();
    return p;
  }

  _updatePlacemark(latitude, longitude){
     placemarkFromCoordinates(latitude, longitude).then((value) {
      setState((){
        _placemarks = value;
      });
    });
  }

  Widget _loadingBuilder(BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
    if (loadingProgress == null) return child;

    double value = loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : 0;
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  String getFullAddress(Placemark placemark) {
    Placemark placeMark  = _placemarks[0];
    String? name = placeMark.name;
    String? subLocality = placeMark.subLocality;
    String? locality = placeMark.locality;
    String? administrativeArea = placeMark.administrativeArea;
    String? postalCode = placeMark.postalCode;
    String? country = placeMark.country;
    return "${name}, ${subLocality}, ${locality}, ${administrativeArea}";
  }

  void _showListEvent() {
    for (PenilaianDetail penilaianDetail in listPenilaianDetail) {
      var tanggal = DateFormat('yyyy-MM-dd').format(_selectedDay!);
      if (tanggal == penilaianDetail.tanggal) {
        setState(() {
          _statusValue = penilaianDetail.status;
          _timeValue = penilaianDetail.createdAt;
          _nilai = penilaianDetail.nilai;
          if (penilaianDetail.alamat != null && penilaianDetail.alamat.isNotEmpty) _statusAddress = penilaianDetail.alamat;
          else if (penilaianDetail.latitude != 0 && penilaianDetail.longitude != 0) {
            _statusAddress = '${penilaianDetail.latitude}, ${penilaianDetail.longitude}';
            placemarkFromCoordinates(penilaianDetail.latitude, penilaianDetail.longitude).then((value) {
              setState((){
                _placemarks = value;
                if (_placemarks.length > 0) _statusAddress = getFullAddress(_placemarks[0]);
              });
            });
          } else {
            _statusAddress = 'GPS belum diaktifkan';
          }
          Uri uri = Uri.http(Constant.HOST, Constant.URL + 'api/file/last/image',
              {'penilaian_detail_id': penilaianDetail.id.toString()});
          _imageValue = uri.toString();
        });
      }
    }
  }

  Widget parseNilaiComponent() {
    if (_nilai <= 1) return Container();

    if (_tipe == 'persen') return Text("${Helper().currency(_nilai)}%");
    else if (_tipe == 'nominal') return Text("Rp ${Helper().currency(_nilai)}");
    else return Text("${Helper().currency(_nilai)}");
  }

  void showListPenilaianDetail(int id) {
    sqlite.getAllPenilaianDetail(id).then((value) {
      setState(() {
        listPenilaianDetail = value;
        _showListEvent();
      });
    });
  }
}