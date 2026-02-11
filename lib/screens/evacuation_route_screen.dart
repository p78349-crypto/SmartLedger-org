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

part 'evacuation_route_screen_safety.dart';
part 'evacuation_route_screen_location.dart';
part 'evacuation_route_screen_routes.dart';

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
            onPressed: () => sharePlan(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSafetyCard(),
            const SizedBox(height: 16),
            if (_shouldShowHealthCard) ...[
              buildWorkflowHealthCard(),
              const SizedBox(height: 16),
            ],
            buildLocationCard(),
            const SizedBox(height: 16),
            buildRecommendedActions(),
            const SizedBox(height: 16),
            buildCheckpoints(),
            const SizedBox(height: 16),
            buildRoutesSection(),
          ],
        ),
      ),
    );
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

  Future<void> _runHealthCheck() {
    return EvacuationWorkflowMonitor.instance.refreshHealth();
  }

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
}
