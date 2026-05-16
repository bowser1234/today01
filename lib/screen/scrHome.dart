import 'package:flutter/material.dart';
import '../service/locService.dart';
import 'package:geocoding/geocoding.dart';
import '../widget/recommend.dart';


class scrHome extends StatefulWidget {
  @override
  _ScrHome createState() => _ScrHome();
}

class _ScrHome extends State<scrHome> {
  String? locationInfo;
  String currentLocation = "위치 확인...";
  String selectedRegion = "현 위치";

  @override
  void initState() {
    super.initState();
    fetchLocation();
  }

  Future<void> fetchLocation() async {
    try {
      final position = await LocService.getCurrentLocation();
      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);

      Placemark place = placemarks[0];
      setState(() {
        currentLocation = "${place.locality}, ${place.administrativeArea}";
      });
    } catch (e) {
      setState(() {
        locationInfo = "위치 정보를 가져올 수 없습니다: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("오늘 뭐입지?"),
      ),
      body: Scrollbar(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '지역을 검색하세요',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                  onSubmitted: (value) {
                    setState(() {
                      selectedRegion = value;
                    });
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.all(8),
                alignment: Alignment.topRight,
                child: DropdownButton<String>(
                  value: selectedRegion,
                  items: ["현 위치", "서울", "인천",
                    "광주", "대구", "울산", "부산"]
                      .map((region) => DropdownMenuItem(
                    child: Text(region),
                    value: region,
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRegion = value!;
                    });
                  },
                ),
              ),

              Container(
                padding: EdgeInsets.all(8),
                alignment: Alignment.topLeft,
                child: Text(
                  selectedRegion == "현 위치"
                      ? (locationInfo ?? currentLocation)
                      : selectedRegion,
                  style: TextStyle(fontSize: 25),
                ),
              ),

              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    Text("날씨 정보 표시",
                        style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Recommend()),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        color: Colors.blue.shade50, // 임시
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("옷차림 추천",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 25),
                            Text("내용 표시"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      color: Colors.green.shade50, // 임시
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("준비물",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 25),
                          Text("내용 표시"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScrClthRecom extends StatelessWidget {
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
