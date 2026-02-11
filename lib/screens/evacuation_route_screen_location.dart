part of 'evacuation_route_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension EvacuationLocationShare on _EvacuationRouteScreenState {
  Widget buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.my_location, size: 20),
                SizedBox(width: 8),
                Text(
                  '현재 위치 기반 안내',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLocating)
              const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(width: 12),
                  Text('현재 위치 확인 중...'),
                ],
              )
            else if (_locationErrorMessage != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _locationErrorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: _resolveLocation,
                        child: const Text('다시 시도'),
                      ),
                      if (_locationErrorType ==
                              DeviceLocationErrorType.permissionDenied ||
                          _locationErrorType ==
                              DeviceLocationErrorType.permissionDeniedForever)
                        TextButton(
                          onPressed:
                              DeviceLocationService.instance.openAppSettings,
                          child: const Text('권한 설정 열기'),
                        ),
                      if (_locationErrorType ==
                          DeviceLocationErrorType.serviceDisabled)
                        TextButton(
                          onPressed: DeviceLocationService
                              .instance
                              .openLocationSettings,
                          child: const Text('위치 서비스 켜기'),
                        ),
                    ],
                  ),
                ],
              )
            else if (_currentLocation != null)
              _buildLiveDistanceSummary(),
            if (!_isLocating && _locationErrorMessage == null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _resolveLocation,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('위치 새로고침'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveDistanceSummary() {
    final location = _currentLocation;
    if (location == null) {
      return const Text('현재 위치 정보를 불러오지 못했습니다.');
    }
    final nearestRoute = _nearestRoute;
    final nearestDistance = _nearestDistanceKm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '위치 좌표: ${location.latitude.toStringAsFixed(4)}, '
          '${location.longitude.toStringAsFixed(4)}',
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        if (nearestRoute != null && nearestDistance != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '가장 가까운 대피소: ${nearestRoute.name}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '현재 위치에서 약 ${_formatDistance(nearestDistance)} 거리',
                style: const TextStyle(fontSize: 13),
              ),
              if (_isUserInSafeArea)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    '이미 안전 반경(200m) 내에 있어 추가 이동이 필요하지 않습니다.',
                    style: TextStyle(fontSize: 13, color: Colors.green),
                  ),
                ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => openRouteOnMap(nearestRoute),
                icon: const Icon(Icons.navigation),
                label: const Text('가장 가까운 대피소로 길찾기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          )
        else
          const Text('대피소 좌표가 없는 경로입니다. 수동으로 확인해주세요.'),
      ],
    );
  }

  Future<void> sharePlan(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final conditionName =
        weatherConditionNames[_activePlan.condition] ?? '극한 날씨';
    final deepLink =
        'smartledger://weather/evacuation?condition=${_activePlan.condition.name}&'
        'location=${Uri.encodeComponent(_activePlan.location)}';
    final buffer = StringBuffer()
      ..writeln('🚨 $conditionName 대비 안전 이동 경로')
      ..writeln('대상 지역: ${_activePlan.location}')
      ..writeln('가족 인원: ${_activePlan.familySize}명')
      ..writeln('권고 단계: ${_adviceLabel(_activePlan.adviceLevel)}')
      ..writeln('생성 시각: ${_activePlan.generatedAt.toLocal()}')
      ..writeln()
      ..writeln(_activePlan.safetyMessage)
      ..writeln();

    if (_activePlan.recommendedActions.isNotEmpty) {
      buffer.writeln('✅ 즉시 실행 체크리스트');
      for (final action in _activePlan.recommendedActions) {
        buffer.writeln('• $action');
      }
      buffer.writeln();
    }

    if (_activePlan.checkpoints.isNotEmpty) {
      buffer.writeln('🔎 체크포인트');
      for (final checkpoint in _activePlan.checkpoints) {
        buffer.writeln('• $checkpoint');
      }
      buffer.writeln();
    }

    buffer.writeln('📍 추천 경로 ${_activePlan.routes.length}개');
    for (final route in _activePlan.routes) {
      buffer
        ..writeln(
          '• ${route.name} (${route.routeType}, '
          '${route.distanceKm.toStringAsFixed(1)}km / '
          '약 ${route.estimatedMinutes}분)',
        )
        ..writeln('  - 대피소: ${route.shelterName} (${route.shelterAddress})')
        ..writeln('  - 편의시설: ${route.amenities.join(', ')}');

      if (route.steps.isNotEmpty) {
        buffer.writeln('  - 이동 단계:');
        for (final step in route.steps) {
          buffer.writeln('    · $step');
        }
      }

      buffer.writeln();
    }

    buffer
      ..writeln('앱에서 계속 확인:')
      ..writeln(deepLink);

    final text = buffer.toString();
    final subject = '안전 이동 경로 - ${_activePlan.location}';

    try {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: subject),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('공유 중 오류가 발생했습니다: $error')),
      );
    }
  }

  Future<void> openRouteOnMap(EvacuationRoute route) async {
    final messenger = ScaffoldMessenger.of(context);
    final buffer = StringBuffer('https://www.google.com/maps/dir/?api=1');
    buffer.write('&destination=${route.shelterLat},${route.shelterLon}');

    final origin = _currentLocation;
    if (origin != null) {
      buffer.write('&origin=${origin.latitude},${origin.longitude}');
    }

    buffer.write('&travelmode=${_travelModeParam(route.routeType)}');

    final uri = Uri.parse(buffer.toString());
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('지도 앱을 열 수 없습니다.')),
      );
    }
  }

  String _travelModeParam(String routeType) {
    final lower = routeType.toLowerCase();
    if (lower.contains('도보') || lower.contains('walk')) return 'walking';
    if (lower.contains('대중교통') ||
        lower.contains('지하철') ||
        lower.contains('subway')) {
      return 'transit';
    }
    return 'driving';
  }
}
