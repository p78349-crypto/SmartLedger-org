import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/evacuation_route_utils.dart';

/// 워크플로우 헬스 스냅샷
class EvacuationWorkflowHealthSnapshot {
  final bool hasConnectivity;
  final bool locationServiceEnabled;
  final bool locationPermissionGranted;
  final DateTime checkedAt;

  const EvacuationWorkflowHealthSnapshot({
    required this.hasConnectivity,
    required this.locationServiceEnabled,
    required this.locationPermissionGranted,
    required this.checkedAt,
  });

  bool get isGpsOperational => locationServiceEnabled && locationPermissionGranted;

  bool get isOperational => isGpsOperational && hasConnectivity;
}

enum EvacuationWorkflowEventType {
  healthChanged,
  alertUpdated,
}

class EvacuationWorkflowEvent {
  final EvacuationWorkflowEventType type;
  final EvacuationWorkflowHealthSnapshot? health;
  final EvacuationPlan? updatedPlan;
  final bool shouldRefreshLocation;

  const EvacuationWorkflowEvent._({
    required this.type,
    this.health,
    this.updatedPlan,
    this.shouldRefreshLocation = false,
  });

  factory EvacuationWorkflowEvent.healthChanged(
    EvacuationWorkflowHealthSnapshot snapshot, {
    bool shouldRefreshLocation = false,
  }) {
    return EvacuationWorkflowEvent._(
      type: EvacuationWorkflowEventType.healthChanged,
      health: snapshot,
      shouldRefreshLocation: shouldRefreshLocation,
    );
  }

  factory EvacuationWorkflowEvent.alertUpdated(EvacuationPlan plan) {
    return EvacuationWorkflowEvent._(
      type: EvacuationWorkflowEventType.alertUpdated,
      updatedPlan: plan,
      shouldRefreshLocation: true,
    );
  }
}

/// 대피 워크플로우 모니터링 (연결/위치/경보 이벤트)
class EvacuationWorkflowMonitor {
  EvacuationWorkflowMonitor._();

  static final EvacuationWorkflowMonitor instance = EvacuationWorkflowMonitor._();

  final _connectivity = Connectivity();
  final _controller = StreamController<EvacuationWorkflowEvent>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _healthTimer;
  EvacuationWorkflowHealthSnapshot? _latestHealth;
  bool _isMonitoring = false;
  bool _isCheckingHealth = false;

  Stream<EvacuationWorkflowEvent> get events => _controller.stream;

  Future<void> ensureMonitoring() async {
    if (_isMonitoring) {
      return;
    }
    _isMonitoring = true;
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final hasNetwork = _hasNetwork(results);
      refreshHealth(triggeredByConnectivityChange: hasNetwork);
    });
    await refreshHealth();
    _healthTimer = Timer.periodic(const Duration(seconds: 45), (_) => refreshHealth());
  }

  Future<void> refreshHealth({bool triggeredByConnectivityChange = false}) async {
    if (_isCheckingHealth) return;
    _isCheckingHealth = true;
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final hasConnectivity = _hasNetwork(connectivityResults);

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();
      final permissionGranted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      final snapshot = EvacuationWorkflowHealthSnapshot(
        hasConnectivity: hasConnectivity,
        locationServiceEnabled: serviceEnabled,
        locationPermissionGranted: permissionGranted,
        checkedAt: DateTime.now(),
      );

      final shouldRefreshLocation = _shouldTriggerLocationRefresh(snapshot);
      _latestHealth = snapshot;
      _controller.add(
        EvacuationWorkflowEvent.healthChanged(
          snapshot,
            shouldRefreshLocation: shouldRefreshLocation ||
              (triggeredByConnectivityChange && snapshot.hasConnectivity),
        ),
      );
    } catch (error) {
      final snapshot = EvacuationWorkflowHealthSnapshot(
        hasConnectivity: false,
        locationServiceEnabled: false,
        locationPermissionGranted: false,
        checkedAt: DateTime.now(),
      );
      _controller.add(
        EvacuationWorkflowEvent.healthChanged(snapshot),
      );
    }
    _isCheckingHealth = false;
  }

  bool _shouldTriggerLocationRefresh(EvacuationWorkflowHealthSnapshot next) {
    final prev = _latestHealth;
    if (prev == null) {
      return next.isOperational;
    }
    final permissionRecovered = !prev.locationPermissionGranted && next.locationPermissionGranted;
    final serviceRecovered = !prev.locationServiceEnabled && next.locationServiceEnabled;
    final connectivityRecovered = !prev.hasConnectivity && next.hasConnectivity;
    return (permissionRecovered || serviceRecovered || connectivityRecovered) && next.isOperational;
  }

  void emitAlertUpdate(EvacuationPlan plan) {
    _controller.add(EvacuationWorkflowEvent.alertUpdated(plan));
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    _healthTimer?.cancel();
    await _controller.close();
  }

  bool _hasNetwork(List<ConnectivityResult> results) {
    for (final result in results) {
      if (result != ConnectivityResult.none) {
        return true;
      }
    }
    return false;
  }
}
