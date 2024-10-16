import 'package:flutter/material.dart';

class TextTitle extends StatelessWidget {
  var text;

  TextTitle({Key? key, this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color.fromRGBO(0, 45, 57, 1)),
        ),
      );
  }
  
}