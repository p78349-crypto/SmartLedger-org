import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_ledger/screens/background_settings_screen.dart';
import 'package:smart_ledger/screens/theme_settings_screen.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';

class ApplicationSettingsScreen extends StatelessWidget {
  const ApplicationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('애플리케이션 설정')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _SettingsSectionLabel('테마'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: const ThemeSettingsSection(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          const _SettingsSectionLabel('대시보드 & 배경'),
          ListTile(
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
