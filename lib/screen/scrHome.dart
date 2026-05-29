import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import '../service/locService.dart';
import '../screen/regionSelScr.dart';

class scrHome extends StatefulWidget {
  const scrHome({Key? key}) : super(key: key);

  @override
  State<scrHome> createState() => _ScrHomeState();
}

class _ScrHomeState extends State<scrHome> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _savedLocations = ['현 위치'];
  String _selectedLocation = '현 위치';

  String _weatherInfo = '날씨 정보 표시';
  String _clothingRecommendation = '내용 표시';
  String _preparations = '내용 표시';


  bool _isLoading = false;
  String? _errorMessage;

  String _currentPtyCode = "0";

  // 아이콘 선택 함수
  IconData _getWeatherIcon(String ptyCode) {
    switch (ptyCode) {
      case "1": // 비
        return Icons.beach_access;
      case "2": // 비/눈
        return Icons.grain;
      case "3": // 눈
        return Icons.ac_unit;
      case "4": // 소나기
        return Icons.cloud;
      default:  // 맑음/구름
        return Icons.wb_sunny;
    }
  }

  Color _getWeatherColor(String ptyCode) {
    switch (ptyCode) {
      case "1": // 비
        return Colors.blue;
      case "2": // 비/눈
        return Colors.purple;
      case "3": // 눈
        return Colors.lightBlueAccent;
      case "4": // 소나기
        return Colors.grey;
      default:  // 맑음/구름
        return Colors.orange;
    }
  }


  final String kmaServiceKey = 'key';

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
    _fetchDataForCurrentLocation();
  }

  Future<void> _loadSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      List<String>? saved = prefs.getStringList('locations');
      if (saved != null) {
        _savedLocations = ['현 위치', ...saved.where((loc) => loc != '현 위치')];
      }
    });
  }

  Future<void> _saveLocation(String location) async {
    if (location.isEmpty || location == '현 위치') return;
    final prefs = await SharedPreferences.getInstance();
    if (!_savedLocations.contains(location)) {
      setState(() {
        _savedLocations.add(location);
      });
      await prefs.setStringList('locations', _savedLocations.where((loc) => loc != '현 위치').toList());
    }
  }

  Future<void> _fetchDataForCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Position position = await LocService.getCurrentLocation();

      // 좌표 → 주소 변환
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String locationName = "현재 위치";
      if (placemarks.isNotEmpty) {
        // 예: "아산시", "서울특별시" 등
        locationName = placemarks.first.locality ?? placemarks.first.administrativeArea ?? "현재 위치";
      }

      Map<String, int> grid = _convertGrid(position.latitude, position.longitude);
      int nx = grid['x']!;
      int ny = grid['y']!;

      await _fetchKmaWeather(nx, ny, locationName);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }


  Future<void> _fetchWeatherByCity(String city) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 도시명을 위도/경도로 변환
      List<Location> locations = await locationFromAddress(city);
      if (locations.isNotEmpty) {
        double lat = locations.first.latitude;
        double lon = locations.first.longitude;

        // 변환된 좌표를 KMA 격자 좌표로 변환
        Map<String, int> grid = _convertGrid(lat, lon);
        int nx = grid['x']!;
        int ny = grid['y']!;

        await _fetchKmaWeather(nx, ny, city);
        await _saveLocation(city);
      } else {
        setState(() {
          _errorMessage = "위치를 불러올 수 없습니다.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "위치 변환 중 오류 발생: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _fetchKmaWeather(int nx, int ny, String locationName) async {
    final now = DateTime.now().subtract(const Duration(minutes: 40));
    final baseDate = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final baseTime = "${now.hour.toString().padLeft(2, '0')}00";

    final Uri url = Uri.parse(
        'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getUltraSrtNcst'
            '?serviceKey=$kmaServiceKey'
            '&pageNo=1&numOfRows=10&dataType=JSON'
            '&base_date=$baseDate&base_time=$baseTime'
            '&nx=$nx&ny=$ny'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final responseHeader = data['response']['header'];

        if (responseHeader['resultCode'] == "00") {
          final List<dynamic> items = data['response']['body']['items']['item'];

          String temp = "0";
          String ptyCode = "0";

          for (var item in items) {
            if (item['category'] == 'T1H') temp = item['obsrValue'];
            if (item['category'] == 'PTY') ptyCode = item['obsrValue'];
          }

          String weatherDesc = "맑음/구름";
          if (ptyCode == "1") weatherDesc = "비 (下雨)";
          if (ptyCode == "2") weatherDesc = "비/눈 (雨夹雪)";
          if (ptyCode == "3") weatherDesc = "눈 (下雪)";
          if (ptyCode == "4") weatherDesc = "소나기 (阵雨)";

          setState(() {
            _weatherInfo = '$locationName: ${temp}°C, $weatherDesc';
            _currentPtyCode = ptyCode; // 아이콘 표시용 코드 저장
          });


          await _fetchAIRecommendation(double.parse(temp), weatherDesc);
        } else {
          setState(() { _errorMessage = "기상청 API 에러: ${responseHeader['resultMsg']}"; });
        }
      } else {
        setState(() { _errorMessage = "날씨 정보를 가져오지 못했습니다."; });
      }
    } catch (e) {
      setState(() { _errorMessage = "네트워크 오류가 발생했습니다."; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _fetchAIRecommendation(double temp, String weatherDesc) async {
    const String aiApiKey = 'key';
    final Uri aiUrl = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    const String modelName = 'llama-3.3-70b-versatile';

    final Map<String, dynamic> requestBody = {
      "model": modelName,
      "messages": [
        {
          "role": "system",
          "content": "당신은 사용자의 친절하고 센스 있는 개인 패션 스타일리스트입니다. "
              "기온 $temp°C와 날씨상태($weatherDesc)에 맞는 센스있는 옷차림과 준비물을 친구에게 말하듯 (~요, ~세요 어조로) 추천하세요. "
              "반드시 마크다운 없이 다음 구조의 순수한 JSON 데이터만 출력하세요: "
              "{\"clothing\": \"추천 옷차림\", \"preparations\": \"추천 준비물\"}"
        },
        {
          "role": "user",
          "content": "오늘 날씨에 딱 맞는 코디 제안해줘."
        }
      ],
      "temperature": 0.7,
      "response_format": {"type": "json_object"}
    };

    try {
      final response = await http.post(
        aiUrl,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $aiApiKey',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        String aiContentString = responseData['choices'][0]['message']['content'];
        aiContentString = aiContentString.replaceAll('```json', '').replaceAll('```', '').trim();

        final Map<String, dynamic> aiJson = json.decode(aiContentString);
        setState(() {
          _clothingRecommendation = aiJson['clothing'] ?? '추천 정보를 가져오지 못했습니다.';
          _preparations = aiJson['preparations'] ?? '내용 표시';
        });
      }
    } catch (e) {
      setState(() {
        _clothingRecommendation = 'AI 코디를 생성하는 중 오류가 발생했습니다.';
      });
    }
  }

  Map<String, int> _convertGrid(double lat, double lon) {
    double RE = 6371.00877;
    double GRID = 5.0;
    double SLAT1 = 30.0;
    double SLAT2 = 60.0;
    double OLON = 126.0;
    double OLAT = 38.0;
    double XO = 43;
    double YO = 136;

    double DEGRAD = math.pi / 180.0;

    double re = RE / GRID;
    double slat1 = SLAT1 * DEGRAD;
    double slat2 = SLAT2 * DEGRAD;
    double olon = OLON * DEGRAD;
    double olat = OLAT * DEGRAD;

    double sn = math.tan(math.pi * 0.25 + slat2 * 0.5) / math.tan(math.pi * 0.25 + slat1 * 0.5);
    sn = math.log(math.cos(slat1) / math.cos(slat2)) / math.log(sn);
    double sf = math.tan(math.pi * 0.25 + slat1 * 0.5);
    sf = math.pow(sf, sn) * math.cos(slat1) / sn;
    double ro = math.tan(math.pi * 0.25 + olat * 0.5);
    ro = re * sf / math.pow(ro, sn);

    double ra = math.tan(math.pi * 0.25 + (lat) * DEGRAD * 0.5);
    ra = re * sf / math.pow(ra, sn);
    double theta = lon * DEGRAD - olon;
    if (theta > math.pi) theta -= 2.0 * math.pi;
    if (theta < -math.pi) theta += 2.0 * math.pi;
    theta *= sn;

    int nx = (ra * math.sin(theta) + XO + 0.5).floor();
    int ny = (ro - ra * math.cos(theta) + YO + 0.5).floor();

    return {"x": nx, "y": ny};
  }

  void _onSearchSubmit(String value) {
    if (value.trim().isNotEmpty) {
      setState(() { _selectedLocation = value.trim(); });
      _fetchWeatherByCity(value.trim());
      _searchController.clear();
    }
  }

  void _onDropdownChanged(String? newValue) {
    if (newValue != null) {
      setState(() { _selectedLocation = newValue; });
      if (newValue == '현 위치') {
        _fetchDataForCurrentLocation();
      } else {
        _fetchWeatherByCity(newValue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '오늘 뭐입지?',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('메뉴', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('초기화'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                setState(() {
                  _savedLocations = ['지금 위치'];
                  _selectedLocation = '지금 위치';
                });
                await prefs.remove('locations');
                Navigator.pop(context); // 드로어 닫기
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_city),
              title: const Text('지역 선택'),
              onTap: () async {
                Navigator.pop(context); // 드로어 닫기
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegionSelScr(
                      onRegionSelected: (region) {
                        setState(() {
                          _selectedLocation = region;
                        });
                        _fetchWeatherByCity(region);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '지역을 검색하세요',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                ),
                onSubmitted: _onSearchSubmit,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: DropdownButton<String>(
                  value: _savedLocations.contains(_selectedLocation) ? _selectedLocation : null,
                  icon: const Icon(Icons.arrow_drop_down),
                  onChanged: _onDropdownChanged,
                  items: _savedLocations.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                Center(
                  child: Icon(
                    _getWeatherIcon(_currentPtyCode),
                    size: 80,
                    color: _getWeatherColor(_currentPtyCode),
                  ),
                ),
                Center(
                  child: Text(
                    _weatherInfo,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 40),
                const Text('옷차림 추천', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_clothingRecommendation, style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 30),
                const Text('준비물', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_preparations, style: const TextStyle(fontSize: 16)),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

}
