import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_ledger/screens/background_settings_screen.dart';
import 'package:smart_ledger/screens/theme_settings_screen.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';

class ApplicationSettingsScreen extends StatefulWidget {
  const ApplicationSettingsScreen({super.key});

  @override
  State<ApplicationSettingsScreen> createState() =>
      _ApplicationSettingsScreenState();
}

class _ApplicationSettingsScreenState extends State<ApplicationSettingsScreen>
    with WidgetsBindingObserver {
  bool _hasPermissions = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    // Android 13+ (API 33+) uses Permission.photos and Permission.notification
    // Older versions use Permission.storage
    final photosStatus = await Permission.photos.status;
    final storageStatus = await Permission.storage.status;
    final notificationStatus = await Permission.notification.status;
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.location.status;
    final microphoneStatus = await Permission.microphone.status;

    if (mounted) {
      setState(() {
        // We consider permissions "granted" if all essential permissions are granted
        _hasPermissions =
            (photosStatus.isGranted ||
                storageStatus.isGranted ||
                photosStatus.isLimited) &&
            (notificationStatus.isGranted ||
                notificationStatus.isProvisional) &&
            cameraStatus.isGranted &&
            locationStatus.isGranted &&
            microphoneStatus.isGranted;
        _isChecking = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.photos,
      Permission.storage,
      Permission.notification,
      Permission.camera,
      Permission.location,
      Permission.microphone,
    ].request();

    _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('애플리케이션 설정')),
      body: _isChecking
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (!_hasPermissions)
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '앱의 모든 기능을 사용하려면 저장소, 알림, 카메라, 위치, 마이크 권한이 필요합니다.',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _requestPermissions,
                          icon: const Icon(Icons.security),
                          label: const Text('권한 허용하기'),
                        ),
                      ],
                    ),
                  ),
                const _SettingsSectionLabel('테마'),
                AbsorbPointer(
                  absorbing: !_hasPermissions,
                  child: Opacity(
                    opacity: _hasPermissions ? 1.0 : 0.5,
                    child: const Card(
                      margin: EdgeInsets.symmetric(horizontal: 12),
                      child: ThemeSettingsSection(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _SettingsSectionLabel('대시보드 & 배경'),
                AbsorbPointer(
                  absorbing: !_hasPermissions,
                  child: Opacity(
                    opacity: _hasPermissions ? 1.0 : 0.5,
                    child: ListTile(
                      leading: const Icon(Icons.wallpaper_outlined),
                      title: const Text('배경 설정'),
                      subtitle: const Text('월페이퍼, 이미지, 블러 효과를 변경합니다.'),
                      trailing: const Icon(IconCatalog.chevronRight),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BackgroundSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const Divider(height: 32),
                const _SettingsSectionLabel('권한 및 시스템'),
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('기기 앱 설정 열기'),
                  subtitle: const Text('권한(알림/파일 등)은 기기 설정에서 변경합니다.'),
                  trailing: const Icon(IconCatalog.chevronRight),
                  onTap: () async {
                    await openAppSettings();
                  },
                ),
              ],
            ),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  final String text;

  const _SettingsSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
