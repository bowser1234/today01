import 'package:flutter/material.dart';
import '../region_data.dart';

class RegionSelScr extends StatelessWidget {
  final Function(String) onRegionSelected;

  const RegionSelScr({Key? key, required this.onRegionSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("지역 선택"),
        centerTitle: true,
      ),
      body: ListView(
        children: regionData.keys.map((regionName) {
          return ListTile(
            title: Text(regionName),
            onTap: () {
              onRegionSelected(regionName);
              Navigator.pop(context); // 선택 후 이전 화면으로 돌아가기
            },
          );
        }).toList(),
      ),
    );
  }
}
