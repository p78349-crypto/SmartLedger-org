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
        // We consider permissions "granted" if all essential permissions
        // are granted
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('애플리케이션 설정')),
      body: _isChecking
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              children: [
                if (!_hasPermissions)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: scheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: scheme.error.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: scheme.error,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                '앱의 모든 기능을 사용하려면 저장소, 알림, 카메라, '
                                '위치, 마이크 권한이 필요합니다.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _requestPermissions,
                            icon: const Icon(Icons.security),
                            label: const Text('권한 허용하기'),
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.error,
                              foregroundColor: scheme.onError,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                _buildSectionHeader(context, '테마'),
                AbsorbPointer(
                  absorbing: !_hasPermissions,
                  child: Opacity(
                    opacity: _hasPermissions ? 1.0 : 0.5,
                    child: Card(
                      elevation: 0,
                      color: scheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const ThemeSettingsSection(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(context, '대시보드 & 배경'),
                _buildSettingsCard(
                  context,
                  icon: Icons.wallpaper_outlined,
                  title: '배경 설정',
                  subtitle: '월페이퍼, 이미지, 블러 효과를 변경합니다.',
                  enabled: _hasPermissions,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BackgroundSettingsScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(context, '권한 및 시스템'),
                _buildSettingsCard(
                  context,
                  icon: Icons.admin_panel_settings_outlined,
                  title: '기기 앱 설정 열기',
                  subtitle: '권한(알림/파일 등)은 기기 설정에서 변경합니다.',
                  onTap: () async {
                    await openAppSettings();
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Card(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: scheme.primary),
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
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  IconCatalog.chevronRight,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
