import 'package:flutter/material.dart';
import 'screen/scrHome.dart';

void main() {
  runApp(TodayWearApp());
}

class TodayWearApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '오늘 뭐입지?',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: scrHome(),
    );
  }
}