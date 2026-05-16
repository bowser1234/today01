import 'package:flutter/material.dart';

class LocationSel extends StatelessWidget {
  final Function(String) onLocationSelected;
  LocationSel({required this.onLocationSelected});

  final locations = ["서울", "부산", "대구", "광주", "아산"];

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: locations.first,
      items: locations.map((loc) {
        return DropdownMenuItem(value: loc, child: Text(loc));
      }).toList(),
      onChanged: (value) => onLocationSelected(value!),
    );
  }
}
