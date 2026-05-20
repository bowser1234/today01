// lib/region_data.dart

class RegionInfo {
  final String name;
  final int nx;
  final int ny;

  const RegionInfo({
    required this.name,
    required this.nx,
    required this.ny,
  });
}

const Map<String, RegionInfo> regionData = {
  '서울':   RegionInfo(name: '서울',   nx: 60,  ny: 127),
  '부산':   RegionInfo(name: '부산',   nx: 98,  ny: 76),
  '대구':   RegionInfo(name: '대구',   nx: 89,  ny: 90),
  '인천':   RegionInfo(name: '인천',   nx: 55,  ny: 124),
  '광주':   RegionInfo(name: '광주',   nx: 58,  ny: 74),
  '대전':   RegionInfo(name: '대전',   nx: 67,  ny: 100),
  '울산':   RegionInfo(name: '울산',   nx: 102, ny: 84),
  '수원':   RegionInfo(name: '수원',   nx: 60,  ny: 121),
  '청주':   RegionInfo(name: '청주',   nx: 69,  ny: 106),
  '전주':   RegionInfo(name: '전주',   nx: 63,  ny: 89),
  '포항':   RegionInfo(name: '포항',   nx: 102, ny: 94),
  '제주':   RegionInfo(name: '제주',   nx: 53,  ny: 38),
  '아산':   RegionInfo(name: '아산',   nx: 60,  ny: 110),
  '춘천':   RegionInfo(name: '춘천',   nx: 73,  ny: 134),
  '강릉':   RegionInfo(name: '강릉',   nx: 92,  ny: 131),
  '여수':   RegionInfo(name: '여수',   nx: 73,  ny: 66),
  '창원':   RegionInfo(name: '창원',   nx: 90,  ny: 77),
  '천안':   RegionInfo(name: '천안',   nx: 63,  ny: 110),
  '구미':   RegionInfo(name: '구미',   nx: 84,  ny: 96),
  '평택':   RegionInfo(name: '평택',   nx: 62,  ny: 114),
};

// '포항시' → '포항' 처럼 시/구/군 제거 후 정규화
String normalizeRegionName(String input) {
  String text = input.trim();

  // '시', '구', '군' 으로 끝나면 제거
  if (text.length > 1 && (text.endsWith('시') || text.endsWith('구') || text.endsWith('군'))) {
    text = text.substring(0, text.length - 1);
  }

  return text;
}

RegionInfo? findRegion(String input) {
  final normalized = normalizeRegionName(input);
  return regionData[normalized];
}