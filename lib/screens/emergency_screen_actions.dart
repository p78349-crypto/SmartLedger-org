part of emergency_screen;

Future<void> _findNearestHospital(BuildContext context) async {
  try {
    var permission = await Geolocator.checkPermission();
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

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('위치 확인 중...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    final url = Uri.parse(
      'https://www.google.com/maps/search/hospital/'
      '@${position.latitude},${position.longitude},15z',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return;
    }

    final webUrl = Uri.parse(
      'https://www.google.com/maps/search/hospital+near+me',
    );
    await launchUrl(webUrl, mode: LaunchMode.externalApplication);
  } catch (_) {
    final webUrl = Uri.parse(
      'https://www.google.com/maps/search/hospital+near+me',
    );
    if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }
}

Future<void> _makeEmergencyCall(BuildContext context, String number) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.red.shade600, size: 28),
          const SizedBox(width: 12),
          Text('$number 전화'),
        ],
      ),
      content: Text('$number 긴급 서비스에 전화하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('전화하기'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    final url = Uri.parse('tel:$number');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}

void _showLocationDeniedDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('위치 권한 필요'),
      content: const Text(
        '가장 가까운 병원을 찾으려면 위치 권한이 필요합니다.\n'
        '설정에서 위치 권한을 허용해주세요.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('확인'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            Geolocator.openAppSettings();
          },
          child: const Text('설정 열기'),
        ),
      ],
    ),
  );
}
