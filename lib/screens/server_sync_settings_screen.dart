import 'package:flutter/material.dart';

import '../services/account_service.dart';
import '../services/home_server_sync_service.dart';
import '../services/server_config_service.dart';
import '../services/user_pref_service.dart';
import '../utils/online_password_key_backup_facade.dart';
import '../utils/password_key_backup_models.dart';

part 'server_sync_settings_screen_logic.dart';

class ServerSyncSettingsScreen extends StatefulWidget {
  const ServerSyncSettingsScreen({super.key});

  @override
  State<ServerSyncSettingsScreen> createState() =>
      _ServerSyncSettingsScreenState();
}

class _ServerSyncSettingsScreenState extends State<ServerSyncSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('서버 설정')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_sync_outlined),
              title: const Text('서버 설정'),
              subtitle: const Text('서버 주소 및 관리자 키를 설정합니다.'),
              onTap: _showServerConfigDialog,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('지금 동기화'),
              subtitle: const Text('현재 계정 데이터를 서버와 즉시 동기화합니다.'),
              onTap: _runManualSync,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.vpn_key_outlined),
              title: const Text('복구키로 키복구'),
              subtitle: const Text('restoreWithRecoveryKey 흐름을 실행합니다.'),
              onTap: _showRecoveryKeyRestoreDialog,
            ),
          ),
        ],
      ),
    );
  }
}
