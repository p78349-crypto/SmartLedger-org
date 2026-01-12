library emergency_screen;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

part 'emergency_screen_actions.dart';
part 'emergency_screen_widgets.dart';

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

}

