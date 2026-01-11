import 'package:geolocator/geolocator.dart';

/// 간단한 위치 좌표
class DeviceLocation {
  final double latitude;
  final double longitude;

  const DeviceLocation({required this.latitude, required this.longitude});
}

/// 위치 관련 예외 유형
enum DeviceLocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}

/// 위치 예외
class DeviceLocationException implements Exception {
  final DeviceLocationErrorType type;
  final String message;

  const DeviceLocationException(this.type, this.message);

  @override
  String toString() => 'DeviceLocationException($type, $message)';
}

/// 기기 위치 헬퍼
class DeviceLocationService {
  DeviceLocationService._();

  static final DeviceLocationService instance = DeviceLocationService._();

  /// 현재 위치 좌표를 반환 (권한/서비스 확인 포함)
  Future<DeviceLocation> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const DeviceLocationException(
        DeviceLocationErrorType.serviceDisabled,
        '위치 서비스가 꺼져 있습니다. 설정에서 위치를 켜주세요.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const DeviceLocationException(
          DeviceLocationErrorType.permissionDenied,
          '위치 권한이 거부되었습니다. 권한을 허용해주세요.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const DeviceLocationException(
        DeviceLocationErrorType.permissionDeniedForever,
        '위치 권한이 영구적으로 거부되었습니다. 설정에서 직접 허용해야 합니다.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(),
    );

    return DeviceLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<void> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  Future<void> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }
}
