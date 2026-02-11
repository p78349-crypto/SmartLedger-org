part of 'emergency_button.dart';

/// 긴급 서비스 시트 표시
Future<void> _showEmergencySheet(BuildContext context) async {
  final scheme = Theme.of(context).colorScheme;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // 핸들 바
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 제목
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_hospital,
                      color: Colors.red.shade600,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '긴급 서비스',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          '공공 안전 정보만 표시됩니다',
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 긴급 옵션 목록
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _EmergencyOption(
                    icon: Icons.local_hospital,
                    iconColor: Colors.red,
                    title: '가장 가까운 병원 찾기',
                    subtitle: '현재 위치 기준 응급실 검색',
                    onTap: () => _findNearestHospital(context),
                  ),
                  _EmergencyOption(
                    icon: Icons.phone,
                    iconColor: Colors.green,
                    title: '119 응급 전화',
                    subtitle: '소방서/응급의료 서비스',
                    onTap: () => _makeEmergencyCall('119'),
                  ),
                  _EmergencyOption(
                    icon: Icons.local_police,
                    iconColor: Colors.blue,
                    title: '112 경찰 전화',
                    subtitle: '경찰청 긴급 신고',
                    onTap: () => _makeEmergencyCall('112'),
                  ),
                  _EmergencyOption(
                    icon: Icons.water_drop,
                    iconColor: Colors.orange,
                    title: '해양 긴급 전화',
                    subtitle: '122 해양경찰청',
                    onTap: () => _makeEmergencyCall('122'),
                  ),
                  const SizedBox(height: 16),
                  // 현재 위치 표시
                  const _LocationCard(),
                  const SizedBox(height: 16),
                  // 보안 안내
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: scheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '개인 의료 기록은 표시되지 않습니다.\n공공 위치 정보만 안전하게 제공됩니다.',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
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

/// 가장 가까운 병원 찾기 (Google Maps로 연동)
Future<void> _findNearestHospital(BuildContext context) async {
  Navigator.pop(context); // 시트 닫기

  try {
    // 위치 권한 확인
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      if (context.mounted) {
        _showLocationDeniedDialog(context);
      }
      return;
    }

    // 현재 위치 가져오기
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    // Google Maps에서 근처 병원 검색
    final url = Uri.parse(
      'https://www.google.com/maps/search/hospital/@'
      '${position.latitude},${position.longitude},15z',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // 폴백: 웹 브라우저로 열기
      final webUrl = Uri.parse(
        'https://www.google.com/maps/search/hospital+near+me',
      );
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    // 위치 가져오기 실패 시 일반 검색
    final webUrl = Uri.parse(
      'https://www.google.com/maps/search/hospital+near+me',
    );
    if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }
}

/// 긴급 전화 걸기
Future<void> _makeEmergencyCall(String number) async {
  final url = Uri.parse('tel:$number');
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  }
}

/// 길게 누르면 119 전화
Future<void> _callEmergency(BuildContext context) async {
  // 확인 다이얼로그 표시
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.red, size: 28),
          SizedBox(width: 12),
          Text('119 전화'),
        ],
      ),
      content: const Text('119 응급 서비스에 전화하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('전화하기'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    _makeEmergencyCall('119');
  }
}

/// 위치 권한 거부 다이얼로그
void _showLocationDeniedDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('위치 권한 필요'),
      content: const Text(
        '가장 가까운 병원을 찾으려면 위치 권한이 필요합니다.\n'
        '설정에서 위치 권한을 허용해주세요.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            Geolocator.openAppSettings();
          },
          child: const Text('설정 열기'),
        ),
      ],
    ),
  );
}
