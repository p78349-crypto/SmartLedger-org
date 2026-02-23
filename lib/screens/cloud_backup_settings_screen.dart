import 'package:flutter/material.dart';
import '../services/cloud_backup_service.dart';
import '../models/cloud_backup_models.dart';

/// 클라우드 백업 설정 화면
/// 자동 백업 스케줄링 및 클라우드 제공업체 설정 (오프라인 기반)
class CloudBackupSettingsScreen extends StatefulWidget {
  const CloudBackupSettingsScreen({super.key});

  @override
  State<CloudBackupSettingsScreen> createState() => _CloudBackupSettingsScreenState;
}

class _CloudBackupSettingsScreenState extends State<CloudBackupSettingsScreen> {
  final CloudBackupService _cloudService = CloudBackupService();
  
  bool _autoBackupEnabled = false;
  BackupFrequency _selectedFrequency = BackupFrequency.daily;
  String _selectedProvider = 'firebase_storage';
  bool _encryptionEnabled = true;
  int _retentionDays = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('클라우드 백업 설정'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildOfflineNotice(),
            const SizedBox(height: 16),
            _buildAutoBackupToggle(),
            if (_autoBackupEnabled) _buildBackupSettings(),
            const Spacer(),
            _buildManualBackupButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineNotice() {
    return Card(
      color: Colors.blue.shade50,
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Text('이 기능은 시뮬레이션 모드입니다. 실제 클라우드 연결은 구현되지 않았습니다.'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoBackupToggle() {
    return Card(
      child: SwitchListTile(
        title: const Text('자동 백업'),
        subtitle: const Text('설정된 주기마다 자동으로 백업'),
        value: _autoBackupEnabled,
        onChanged: (value) => setState(() => _autoBackupEnabled = value),
      ),
    );
  }

  Widget _buildBackupSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<BackupFrequency>(
              value: _selectedFrequency,
              decoration: const InputDecoration(labelText: '백업 주기'),
              items: BackupFrequency.values.map((freq) => DropdownMenuItem(
                value: freq,
                child: Text(_getFrequencyText(freq)),
              )).toList(),
              onChanged: (value) => setState(() => _selectedFrequency = value!),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('암호화'),
              subtitle: const Text('백업 파일을 암호화하여 저장'),
              value: _encryptionEnabled,
              onChanged: (value) => setState(() => _encryptionEnabled = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualBackupButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _performManualBackup(),
        icon: const Icon(Icons.cloud_upload),
        label: const Text('수동 백업 실행'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  String _getFrequencyText(BackupFrequency frequency) {
    switch (frequency) {
      case BackupFrequency.hourly: return '매시간';
      case BackupFrequency.daily: return '매일';
      case BackupFrequency.weekly: return '매주';
      case BackupFrequency.monthly: return '매월';
    }
  }

  Future<void> _performManualBackup() async {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('백업 시뮬레이션'),
        content: Text('실제 클라우드 백업 기능은 구현되지 않았습니다.\n로컬 백업만 수행됩니다.'),
      ),
    );
  }
}