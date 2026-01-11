import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// 긴급 서비스 화면 - 병원/경찰/소방서 빠른 접근
///
/// 보안 원칙: 공공 데이터(병원 위치)만 노출, 개인 의료 기록 절대 노출 금지
class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('긴급 서비스'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 헤더 배너
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade600, Colors.red.shade800],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.local_hospital, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text(
                  '긴급 상황 시 아래 버튼을 사용하세요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '공공 안전 정보만 표시됩니다',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // 긴급 옵션 목록
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _EmergencyCard(
                  icon: Icons.local_hospital,
                  iconColor: Colors.red,
                  title: '가장 가까운 병원 찾기',
                  subtitle: '현재 위치 기준 응급실 검색',
                  onTap: () => _findNearestHospital(context),
                ),
                const SizedBox(height: 12),
                _EmergencyCard(
                  icon: Icons.phone,
                  iconColor: Colors.green,
                  title: '119 응급 전화',
                  subtitle: '소방서/응급의료 서비스',
                  onTap: () => _makeEmergencyCall(context, '119'),
                ),
                const SizedBox(height: 12),
                _EmergencyCard(
                  icon: Icons.local_police,
                  iconColor: Colors.blue,
                  title: '112 경찰 전화',
                  subtitle: '경찰청 긴급 신고',
                  onTap: () => _makeEmergencyCall(context, '112'),
                ),
                const SizedBox(height: 12),
                _EmergencyCard(
                  icon: Icons.water_drop,
                  iconColor: Colors.orange,
                  title: '122 해양 긴급 전화',
                  subtitle: '해양경찰청',
                  onTap: () => _makeEmergencyCall(context, '122'),
                ),
                const SizedBox(height: 24),
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
                          '개인 의료 기록은 표시되지 않습니다.\n'
                          '공공 위치 정보만 안전하게 제공됩니다.',
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
    );
  }

  /// 가장 가까운 병원 찾기 (Google Maps 연동)
  Future<void> _findNearestHospital(BuildContext context) async {
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

      // 로딩 표시
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

      // 현재 위치 가져오기
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Google Maps에서 근처 병원 검색
      final url = Uri.parse(
        'https://www.google.com/maps/search/hospital/'
        '@${position.latitude},${position.longitude},15z',
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
  Future<void> _makeEmergencyCall(BuildContext context, String number) async {
    // 확인 다이얼로그
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

  /// 위치 권한 거부 다이얼로그
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
}

/// 긴급 옵션 카드
class _EmergencyCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _EmergencyCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: scheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 현재 위치 카드
class _LocationCard extends StatefulWidget {
  const _LocationCard();

  @override
  State<_LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<_LocationCard> {
  String _locationText = '위치 확인 중...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationText = '위치 권한이 필요합니다';
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      if (mounted) {
        setState(() {
          _locationText =
              '현재 위치: '
              '${position.latitude.toStringAsFixed(4)}, '
              '${position.longitude.toStringAsFixed(4)}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationText = '위치를 가져올 수 없습니다';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.my_location, color: scheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: _isLoading
                ? Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _locationText,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  )
                : Text(
                    _locationText,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
