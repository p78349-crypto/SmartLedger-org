import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WireGuard VPN 연결 관리 서비스 (wireguard_vpn 플러그인 사용)
class VpnConnectionService {
  VpnConnectionService._internal();
  static final VpnConnectionService _instance = VpnConnectionService._internal();
  factory VpnConnectionService() => _instance;

  static const String _vpnConfigKey = 'wireguard_config';
  static const String _autoConnectKey = 'vpn_auto_connect';

  final StreamController<VpnConnectionState> _connectionStateController =
      StreamController<VpnConnectionState>.broadcast();

  Stream<VpnConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  VpnConnectionState _currentState = VpnConnectionState.disconnected;

  VpnConnectionState get currentState => _currentState;

  /// VPN 연결 상태 초기화 및 모니터링 시작
  Future<void> initialize() async {
    try {
      // 실제 WireGuard 플러그인 초기화 (현재는 모의 구현)
      // TODO: 실제 VPN 플러그인 연동 시 구현
      _updateConnectionState(VpnConnectionState.disconnected);

      // 자동 연결 설정 확인
      final shouldAutoConnect = await getAutoConnectEnabled();
      if (shouldAutoConnect) {
        // TODO: 자동 연결 로직 구현
      }
    } catch (e) {
      debugPrint('VPN 초기화 오류: $e');
      _updateConnectionState(VpnConnectionState.error);
    }
  }

  /// VPN 연결 (모의 구현)
  Future<bool> connectVpn() async {
    try {
      _updateConnectionState(VpnConnectionState.connecting);

      // TODO: 실제 WireGuard 연결 구현
      await Future.delayed(const Duration(seconds: 2)); // 모의 연결 시간

      // 연결 성공 시뮬레이션 (실제로는 VPN 상태 확인)
      _updateConnectionState(VpnConnectionState.connected);
      return true;
    } catch (e) {
      debugPrint('VPN 연결 실패: $e');
      _updateConnectionState(VpnConnectionState.error);
      return false;
    }
  }

  /// VPN 연결 해제 (모의 구현)
  Future<void> disconnectVpn() async {
    try {
      _updateConnectionState(VpnConnectionState.disconnecting);

      // TODO: 실제 WireGuard 연결 해제 구현
      await Future.delayed(const Duration(seconds: 1));

      _updateConnectionState(VpnConnectionState.disconnected);
    } catch (e) {
      debugPrint('VPN 연결 해제 실패: $e');
      _updateConnectionState(VpnConnectionState.error);
    }
  }

  /// VPN 구성 저장
  Future<void> saveVpnConfig(String config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vpnConfigKey, config);
  }

  /// 저장된 VPN 구성 로드
  Future<String?> loadVpnConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_vpnConfigKey);
  }

  /// VPN 연결 (실제로는 WireGuard 앱이나 시스템 VPN 사용 지침)
  Future<bool> connect() async {
    return await connectVpn();
  }

  /// VPN 연결 해제 (실제로는 WireGuard 앱이나 시스템 VPN 사용 지침)
  Future<bool> disconnect() async {
    await disconnectVpn();
    return true;
  }

  /// 자동 연결 설정
  Future<void> setAutoConnectEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoConnectKey, enabled);
  }

  /// 자동 연결 설정 확인
  Future<bool> getAutoConnectEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoConnectKey) ?? false;
  }

  /// 연결 상태 확인
  Future<bool> isConnected() async {
    return _currentState == VpnConnectionState.connected;
  }

  /// 연결 상태 업데이트
  void _updateConnectionState(VpnConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  /// 리소스 정리
  void dispose() {
    _connectionStateController.close();
  }
}

/// VPN 연결 상태
enum VpnConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}