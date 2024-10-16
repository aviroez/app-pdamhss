import 'package:flutter/material.dart';

class TextSubTitle extends StatelessWidget {
  var text;

  TextSubTitle({Key? key, this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.centerLeft,
        child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Color.fromRGBO(0, 45, 57, 1)),
        ),
      );
  }
  
}