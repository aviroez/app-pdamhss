import 'dart:convert';

import 'package:app/entities/akses.dart';
import 'package:app/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:date_format/date_format.dart';
import '/entities/pengguna.dart';

class Helper {

  Future<Map<String, dynamic>> getPengguna() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String penggunaString = prefs.getString('pengguna') ?? '';
    return penggunaString.length > 0 ? jsonDecode(penggunaString) : new Map<String, dynamic>();
  }

  setSession(key, value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  Future<String> getSessionString(key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? '';
  }

  parsePeriode(String date) {
    if (date.length < 6) return "";
    var tahun = date.substring(0, 4);
    var bulan = int.parse(date.substring(4)) - 1;
    return "${Constant.BULAN[bulan]} ${tahun}";
  }

  parseTanggal(String date, bool yearIncluded) {
    if (date == '0000-00-00') return '';
    var tahun = date.substring(0, 4);
    var bulan = int.parse(date.substring(5, 7)) - 1;
    var hari = date.substring(8, 10);

    if (yearIncluded && bulan == 0) return "$hari ${Constant.BULAN[bulan]} $tahun";
    else if (yearIncluded) return "$hari ${Constant.BULAN[bulan]} $tahun";

    return "${hari} ${Constant.BULAN[bulan]}";
  }

  DateTime subtractMonths(int count, DateTime dateTime) {
    var y = count ~/ 12;
    var m = count - y * 12;

    if (m > dateTime.month) {
      y += 1;
      m = dateTime.month - m;
    }

    return DateTime(dateTime.year - y, dateTime.month - m, dateTime.day);
  }

  DateTime addMonths(int count, DateTime dateTime) {
    var y = count ~/ 12;
    var m = count + y * 12;

    if (m < dateTime.month) {
      y -= 1;
      m = dateTime.month + m;
    }

    return DateTime(dateTime.year + y, dateTime.month + m, dateTime.day);
  }

  String reformatDate(dateTime){
    return DateFormat('y-MM-dd').format(dateTime);
  }

  toDouble(dynamic number){
    if (number != null){
      if (number is String){
        return double.tryParse(number);
      } else if (number is int){
        return number+.0;
      } else if (number is num){
        return number+.0;
      }
    }
    return 0.0;
  }

  strToDouble(String number){
    if (number != null && number.length > 0){
      return double.tryParse(number);
    }
    return 0;
  }

  strToInt(String number, int defaultNumber){
    if (number != null && number.length > 0){
      return int.tryParse(number);
    }
    return defaultNumber;
  }

  toInt(number){
    if (number != null){
      if (number is String){
        return int.parse(number);
      } else {
        return number.toInt();
      }
    }
    return 0;
  }

  String toStr(number){
    if (number is double){
      return removeDecimalZeroFormat(number);
    } else {
      return number.toString();
    }
  }

  String removeDecimalZeroFormat(double n) {
    return n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 1);
  }

  String currency(nominal){
    if (nominal != null){
      nominal = nominal.abs();
      var f = NumberFormat('#,###', 'id_ID');
      return f.format(nominal);
    }

    return '0';
  }

  double currencyRemove(String nominal){
    if (nominal != null && nominal.length > 0){
      String val = nominal.replaceAll('.', '');
      return strToDouble(val);
    }
    return 0;
  }

  bool isEmail(String em) {
    String p = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regExp = new RegExp(p);
    return regExp.hasMatch(em);
  }

  String removeLastCommaZero(double val){
    String string = val.toString();
    var lastString = string.substring(string.length - 2);
    if (lastString == '.0'){
      return string.substring(0, string.length - 2);
    }
    return string;
  }

  String getJabatan(Pengguna? pengguna){
    String string = '';
    if (pengguna != null && pengguna.listAkses != null) {
      for (Akses akses in pengguna.listAkses){
        if (pengguna.listAkses.indexOf(akses) > 0) string += ',';

        string = akses.jabatanNama;
        if (akses.lokasiId != null) string += ' ' + akses.lokasiNama;
        return string;
      }
    }
    return string;
  }

  int getLevel(String code){
    for(int i = 0; i < Constant.LEVEL.length; i++){
      if (Constant.LEVEL[i] == code) return i;
    }

    return -1;
  }

  showSnackBar(BuildContext context, message) {
    if (message != '') {
      SnackBar snackBar = SnackBar(content: Text(message));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Color getColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return Colors.blue;
    }
    return Colors.lightBlue;
  }

  Color getColorGreen(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return Colors.green;
    }
    return Colors.lightGreen;
  }
}