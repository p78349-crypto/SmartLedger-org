import 'package:flutter/material.dart';
import '../services/incremental_backup_service.dart';
import '../services/backup_service.dart';
import '../utils/constants.dart';

part 'incremental_backup_screen_extensions.dart';

/// 점진적 백업 시스템 화면
/// 스마트 백업 및 변경사항 감지 기능 제공
class IncrementalBackupScreen extends StatefulWidget {
  const IncrementalBackupScreen({super.key});

  @override
  State<IncrementalBackupScreen> createState() => _IncrementalBackupScreenState();
}

class _IncrementalBackupScreenState extends State<IncrementalBackupScreen> {
  final IncrementalBackupService _incrementalService = IncrementalBackupService();
  final BackupService _backupService = BackupService();
  
  bool _isLoading = false;
  String? _lastBackupResult;
  Map<String, dynamic>? _changesSummary;

  @override
  void initState() {
    super.initState();
    _loadChangesSummary();
  }

  Future<void> _loadChangesSummary() async {
    try {
      final changes = await _incrementalService.detectChanges();
      setState(() {
        _changesSummary = {
          'total': changes.length,
          'modules': changes.map((c) => c.module).toSet().toList(),
          'lastCheck': DateTime.now(),
        };
      });
    } catch (e) {
      setState(() {
        _changesSummary = {'error': e.toString()};
      });
    }
  }

  Future<void> _performIncrementalBackup() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _backupService.performIncrementalBackup();
      setState(() {
        _lastBackupResult = result['success'] 
            ? '성공: ${result['changes']}개 변경사항 백업 완료'
            : '실패: ${result['error']}';
        _isLoading = false;
      });
      
      await _loadChangesSummary(); // 백업 후 변경사항 다시 체크
      
    } catch (e) {
      setState(() {
        _lastBackupResult = '오류: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('점진적 백업'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChangesSummaryCard(),
            const SizedBox(height: 20),
            _buildBackupButton(),
            if (_lastBackupResult != null) ...[
              const SizedBox(height: 20),
              _buildResultCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChangesSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('변경사항 감지', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_changesSummary != null) ...[
              if (_changesSummary!['error'] != null)
                Text('오류: ${_changesSummary!['error']}', style: const TextStyle(color: Colors.red))
              else ...[
                Text('총 변경사항: ${_changesSummary!['total']}개'),
                if (_changesSummary!['modules'] != null && _changesSummary!['modules'].isNotEmpty)
                  Text('변경된 모듈: ${(_changesSummary!['modules'] as List).join(", ")}'),
                Text('마지막 확인: ${_formatDateTime(_changesSummary!['lastCheck'])}'),
              ]
            ] else
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}