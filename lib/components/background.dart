import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  var height;
  var width;

  Background({Key? key, this.width, this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // height = height ? height : MediaQuery.of(context).size.height;
    // width = width ? width : MediaQuery.of(context).size.width;
    return Stack(
      children: <Widget>[
        Container(
          // width: width,
          // height: height,
          decoration: BoxDecoration(
            image: DecorationImage(
              alignment: Alignment.bottomCenter,
              image: AssetImage("assets/images/rectangle_green.png"),
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            image: DecorationImage(
              alignment: Alignment.bottomCenter,
              image: AssetImage("assets/images/rectangle_blue.png"),
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
      ],
    );
  }
  
}