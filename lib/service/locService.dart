import 'package:geolocator/geolocator.dart';

class LocService {
  /// 현재 위치 가져오기
  static Future<Position> getCurrentLocation() async {
    // 위치 서비스 활성화 여부 확인
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("위치 서비스가 꺼져 있습니다. 설정에서 위치 서비스를 켜주세요.");
    }

    // 권한 확인
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("위치 권한이 거부되었습니다. 앱 설정에서 권한을 허용해주세요.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // 거부된 경우2
      throw Exception("위치 권한이 거부되었습니다. 앱 설정에서 직접 권한을 허용해주세요.");
    }

    // 현재 위치 가져오기
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
