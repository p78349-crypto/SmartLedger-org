import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/background_widget.dart';
import '../utils/pref_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionGateScreen extends StatefulWidget {
  final VoidCallback onGranted;

  const PermissionGateScreen({super.key, required this.onGranted});

  @override
  State<PermissionGateScreen> createState() => _PermissionGateScreenState();
}

class _PermissionGateScreenState extends State<PermissionGateScreen>
    with WidgetsBindingObserver {
  bool _isChecking = true;
  PermissionStatus _photosStatus = PermissionStatus.denied;
  PermissionStatus _storageStatus = PermissionStatus.denied;
  PermissionStatus _notificationStatus = PermissionStatus.denied;
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  PermissionStatus _locationStatus = PermissionStatus.denied;
  PermissionStatus _microphoneStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndProceed();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndProceed();
    }
  }

  Future<void> _checkAndProceed() async {
    if (!mounted) return;
    setState(() => _isChecking = true);

    try {
      _photosStatus = await Permission.photos.status;
      _storageStatus = await Permission.storage.status;
      _notificationStatus = await Permission.notification.status;
      _cameraStatus = await Permission.camera.status;
      _locationStatus = await Permission.location.status;
      _microphoneStatus = await Permission.microphone.status;

      debugPrint(
        '[PermissionGate] Photos: $_photosStatus, Storage: $_storageStatus, '
        'Notification: $_notificationStatus',
      );

      final hasStorage =
          _photosStatus.isGranted ||
          _storageStatus.isGranted ||
          _photosStatus.isLimited;
      // On some older devices, notification permission might not be
      // explicitly grantable but is allowed.
      // We check for isGranted or isProvisional.
      final hasNotification =
          _notificationStatus.isGranted || _notificationStatus.isProvisional;

      if (hasStorage && hasNotification) {
        debugPrint(
          '[PermissionGate] Essential permissions granted. Proceeding...',
        );
        widget.onGranted();
      } else {
        debugPrint(
          '[PermissionGate] Essential permissions missing. '
          'hasStorage: $hasStorage, hasNotification: $hasNotification',
        );
        if (mounted) {
          setState(() => _isChecking = false);
        }
      }
    } catch (e) {
      debugPrint('[PermissionGate] Error checking permissions: $e');
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _requestPermissions() async {
    // 필수 권한만 요청 (저장소, 알림)
    await [
      Permission.photos,
      Permission.storage,
      Permission.notification,
    ].request();
    _checkAndProceed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<Color>(
      valueListenable: BackgroundHelper.colorNotifier,
      builder: (context, bgColor, _) {
        return Scaffold(
          backgroundColor: bgColor,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.security_rounded,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '필수 권한만 허용해 주세요',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '기본 기능 사용을 위해 저장소와 알림 권한만 허용해 주세요.\n기타 권한은 관련 기능 사용 시 개별적으로 요청됩니다.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _PermissionItem(
                    icon: Icons.image_outlined,
                    title: '저장소 / 사진 (필수)',
                    description: '테마 아이콘 및 배경 이미지를 불러오기 위해 필요합니다.',
                    isGranted:
                        _photosStatus.isGranted ||
                        _storageStatus.isGranted ||
                        _photosStatus.isLimited,
                  ),
                  const SizedBox(height: 16),
                  _PermissionItem(
                    icon: Icons.notifications_active_outlined,
                    title: '알림 (필수)',
                    description: '지출 알림 및 중요 안내를 받기 위해 필요합니다.',
                    isGranted:
                        _notificationStatus.isGranted ||
                        _notificationStatus.isProvisional,
                  ),
                  const Divider(height: 48),
                  Text(
                    '아래 권한은 관련 기능 사용 시 자동으로 요청됩니다',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '• 카메라: 영수증 촬영 시\n'
                    '• 위치: 날씨 정보 확인 시\n'
                    '• 마이크: 음성 입력 사용 시',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (_isChecking)
                    const CircularProgressIndicator()
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _requestPermissions,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('필수 권한만 허용하고 시작'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool(
                          PrefKeys.permissionGateBypassed,
                          true,
                        );
                        widget.onGranted();
                      },
                      child: Text(
                        '모든 권한 나중에 설정 (일부 기능 제한)',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isGranted
                ? Colors.green.withValues(alpha: 0.1)
                : theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isGranted ? Icons.check_circle : icon,
            color: isGranted
                ? Colors.green
                : theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isGranted ? Colors.green : null,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
