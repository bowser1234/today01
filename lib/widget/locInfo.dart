import 'package:flutter/material.dart';

class LocInfo extends StatelessWidget {
  final String info;
  LocInfo({required this.info});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(info, style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
