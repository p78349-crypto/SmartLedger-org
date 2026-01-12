// 안전 이동 경로 화면
//
// 허리케인(태풍) 등 극한 날씨 시 대피 경로를 상세히 안내합니다.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/device_location_service.dart';
import '../services/evacuation_workflow_monitor.dart';
import '../utils/evacuation_route_utils.dart';
import '../utils/weather_price_sensitivity.dart';

class EvacuationRouteScreen extends StatefulWidget {
  final EvacuationPlan plan;

  const EvacuationRouteScreen({super.key, required this.plan});

  @override
  State<EvacuationRouteScreen> createState() => _EvacuationRouteScreenState();
}

class _EvacuationRouteScreenState extends State<EvacuationRouteScreen> {
  late EvacuationPlan _activePlan;
  StreamSubscription<EvacuationWorkflowEvent>? _workflowSubscription;
  EvacuationWorkflowHealthSnapshot? _healthSnapshot;
  DeviceLocation? _currentLocation;
  DeviceLocationErrorType? _locationErrorType;
  String? _locationErrorMessage;
  bool _isLocating = false;
  EvacuationRoute? _nearestRoute;
  double? _nearestDistanceKm;

  @override
  void initState() {
    super.initState();
    _activePlan = widget.plan;
    _subscribeWorkflow();
    _resolveLocation();
  }

  @override
  void didUpdateWidget(covariant EvacuationRouteScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plan != widget.plan) {
      _activePlan = widget.plan;
      _calculateNearestRoute();
    }
  }

  @override
  void dispose() {
    _workflowSubscription?.cancel();
    super.dispose();
  }

  void _subscribeWorkflow() {
    EvacuationWorkflowMonitor.instance.ensureMonitoring();
    _workflowSubscription = EvacuationWorkflowMonitor.instance.events.listen((
      event,
    ) {
      if (!mounted) return;
      switch (event.type) {
        case EvacuationWorkflowEventType.healthChanged:
          setState(() {
            _healthSnapshot = event.health;
          });
          if (event.shouldRefreshLocation) {
            _resolveLocation();
          }
          break;
        case EvacuationWorkflowEventType.alertUpdated:
          final updatedPlan = event.updatedPlan;
          if (updatedPlan != null) {
            setState(() {
              _activePlan = updatedPlan;
            });
            _calculateNearestRoute();
          }
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('안전 이동 경로'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePlan(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSafetyCard(),
            const SizedBox(height: 16),
            if (_shouldShowHealthCard) ...[
              _buildWorkflowHealthCard(),
              const SizedBox(height: 16),
            ],
            _buildLocationCard(),
            const SizedBox(height: 16),
            _buildRecommendedActions(),
            const SizedBox(height: 16),
            _buildCheckpoints(),
            const SizedBox(height: 16),
            _buildRoutesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyCard() {
    final color = _adviceColor(_activePlan.adviceLevel);

    return Card(
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: color),
                const SizedBox(width: 8),
                Text(
                  _adviceLabel(_activePlan.adviceLevel),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _activePlan.safetyMessage,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            () {
              final locationStr = _activePlan.location;
              final cond = _activePlan.condition;
              final weatherStr = weatherConditionNames[cond] ?? '극한 날씨';
              final details = '대상 지역: $locationStr\n'
                  '예상 날씨: $weatherStr\n'
                  '가족 인원: ${_activePlan.familySize}명\n'
                  '생성 시각: ${_activePlan.generatedAt.toLocal()}';
              return Text(
                details,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              );
            }(),
            if (_isUserInSafeArea) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '현재 위치는 권장 대피소 반경 안쪽입니다. 즉시 대피 대신 물자/연락망 점검만 진행하세요.',
                        style: TextStyle(fontSize: 13, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
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

  Widget _buildWorkflowHealthCard() {
    final snapshot = _healthSnapshot;
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    final entries = <MapEntry<String, bool>>[
      MapEntry('데이터 연결', snapshot.hasConnectivity),
      MapEntry('위치 서비스', snapshot.locationServiceEnabled),
      MapEntry('GPS 권한', snapshot.locationPermissionGranted),
    ];
    final issues = entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();
    final cardColor = snapshot.isOperational ? Colors.green : Colors.red;

    return Card(
      color: cardColor.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: cardColor),
                const SizedBox(width: 8),
                const Text(
                  '워크플로우 헬스 체크',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _runHealthCheck,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('헬스체크 재실행'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entries
                  .map((entry) => _statusChip(entry.key, entry.value))
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            Text(
              snapshot.isOperational
                  ? '네트워크 · GPS 체인이 정상입니다. 지도/경로 데이터가 실시간으로 유지됩니다.'
                  : '문제 감지: ${issues.join(', ')}. 복구 즉시 위치/지도 레이어가 재계산됩니다.',
              style: TextStyle(
                color: snapshot.isOperational ? Colors.green : Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '마지막 점검: ${snapshot.checkedAt.toLocal()}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
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
                onPressed: () => _openRouteOnMap(nearestRoute),
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

  Widget _buildRecommendedActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.playlist_add_check, size: 20),
                SizedBox(width: 8),
                Text(
                  '즉시 실행 체크리스트',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._activePlan.recommendedActions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(action, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckpoints() {
    if (_activePlan.checkpoints.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.map, size: 20),
                SizedBox(width: 8),
                Text(
                  '중간 점검 사항',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._activePlan.checkpoints.map(
              (checkpoint) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '✔ $checkpoint',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.route, size: 20),
            const SizedBox(width: 8),
            Text(
              '추천 대피 경로 (${_activePlan.routes.length}개)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._activePlan.routes.map(_buildRouteCard),
      ],
    );
  }

  Widget _buildRouteCard(EvacuationRoute route) {
    final color = _safetyLevelColor(route.safetyLevel);
    final distanceFromUser = _currentLocation == null
        ? null
        : _haversineDistance(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            route.shelterLat,
            route.shelterLon,
          );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    route.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _safetyChip(route.safetyLevel),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.directions_car, color: color, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${route.routeType} • ${route.distanceKm.toStringAsFixed(1)}km • '
                  '약 ${route.estimatedMinutes}분',
                ),
              ],
            ),
            if (distanceFromUser != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.social_distance,
                    size: 16,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '현재 위치에서 약 ${_formatDistance(distanceFromUser)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '대피소: ${route.shelterName}\n주소: ${route.shelterAddress}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              '비상 편의시설: ${route.amenities.join(', ')}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            const Text(
              '이동 단계',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ...route.steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(step, style: const TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _openRouteOnMap(route),
                icon: const Icon(Icons.map),
                label: const Text('지도에서 보기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _safetyChip(EvacuationSafetyLevel level) {
    final color = _safetyLevelColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _safetyLevelLabel(level),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statusChip(String label, bool ok) {
    final color = ok ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ok ? Icons.check_circle : Icons.error, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runHealthCheck() {
    return EvacuationWorkflowMonitor.instance.refreshHealth();
  }

  Color _adviceColor(EvacuationAdviceLevel level) {
    switch (level) {
      case EvacuationAdviceLevel.evacuate:
        return Colors.red;
      case EvacuationAdviceLevel.prepare:
        return Colors.orange;
      case EvacuationAdviceLevel.monitor:
        return Colors.blue;
    }
  }

  String _adviceLabel(EvacuationAdviceLevel level) {
    switch (level) {
      case EvacuationAdviceLevel.evacuate:
        return '즉시 대피 권고';
      case EvacuationAdviceLevel.prepare:
        return '대피 준비 단계';
      case EvacuationAdviceLevel.monitor:
        return '상황 모니터링';
    }
  }

  Color _safetyLevelColor(EvacuationSafetyLevel level) {
    switch (level) {
      case EvacuationSafetyLevel.primary:
        return Colors.green;
      case EvacuationSafetyLevel.alternate:
        return Colors.blue;
      case EvacuationSafetyLevel.lastResort:
        return Colors.orange;
    }
  }

  String _safetyLevelLabel(EvacuationSafetyLevel level) {
    switch (level) {
      case EvacuationSafetyLevel.primary:
        return '1순위 경로';
      case EvacuationSafetyLevel.alternate:
        return '우회 경로';
      case EvacuationSafetyLevel.lastResort:
        return '최후 수단';
    }
  }

  Future<void> _sharePlan(BuildContext context) async {
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
          '• ${route.name} (${route.routeType}, ${route.distanceKm.toStringAsFixed(1)}km / '
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
      await SharePlus.instance.share(ShareParams(text: text, subject: subject));
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('공유 중 오류가 발생했습니다: $error')),
      );
    }
  }

  Future<void> _resolveLocation() async {
    setState(() {
      _isLocating = true;
      _locationErrorMessage = null;
      _locationErrorType = null;
    });

    try {
      final location = await DeviceLocationService.instance
          .getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _currentLocation = location;
        _calculateNearestRoute();
      });
    } on DeviceLocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _currentLocation = null;
        _nearestRoute = null;
        _nearestDistanceKm = null;
        _locationErrorMessage = e.message;
        _locationErrorType = e.type;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentLocation = null;
        _nearestRoute = null;
        _nearestDistanceKm = null;
        _locationErrorMessage = '현재 위치 정보를 가져오지 못했습니다.';
        _locationErrorType = DeviceLocationErrorType.unknown;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  void _calculateNearestRoute() {
    final location = _currentLocation;
    if (location == null) {
      _nearestRoute = null;
      _nearestDistanceKm = null;
      return;
    }

    EvacuationRoute? bestRoute;
    double? bestDistance;

    for (final route in _activePlan.routes) {
      final distance = _haversineDistance(
        location.latitude,
        location.longitude,
        route.shelterLat,
        route.shelterLon,
      );

      if (bestDistance == null || distance < bestDistance) {
        bestDistance = distance;
        bestRoute = route;
      }
    }

    _nearestRoute = bestRoute;
    _nearestDistanceKm = bestDistance;
  }

  bool get _isUserInSafeArea {
    final distance = _nearestDistanceKm;
    if (distance == null) return false;
    return distance <= 0.2; // 200m 이내면 대피소 범위로 간주
  }

  bool get _shouldShowHealthCard => _healthSnapshot != null;

  String _formatDistance(double distanceKm) {
    if (distanceKm >= 100) {
      return '${distanceKm.toStringAsFixed(0)}km';
    }
    if (distanceKm >= 10) {
      return '${distanceKm.toStringAsFixed(1)}km';
    }
    if (distanceKm >= 1) {
      return '${distanceKm.toStringAsFixed(1)}km';
    }
    return '${(distanceKm * 1000).toStringAsFixed(0)}m';
  }

  double _haversineDistance(
    double startLat,
    double startLon,
    double endLat,
    double endLon,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(endLat - startLat);
    final dLon = _degToRad(endLon - startLon);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(startLat)) *
            math.cos(_degToRad(endLat)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double degree) => degree * (math.pi / 180.0);

  Future<void> _openRouteOnMap(EvacuationRoute route) async {
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
      messenger.showSnackBar(const SnackBar(content: Text('지도 앱을 열 수 없습니다.')));
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
