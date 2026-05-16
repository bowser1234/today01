import 'package:flutter/material.dart';

class Recommend extends StatelessWidget {
  Recommend();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("옷차림 추천")),
      body: Center(
        child: Text("옷차림 추천.",
            style: TextStyle(fontSize: 20)),
      ),
    );
  }
}