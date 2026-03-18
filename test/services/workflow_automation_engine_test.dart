import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/services/audit_log_service.dart';
import 'package:smart_ledger/services/workflow_automation_engine.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkflowAutomationEngine security automation', () {
    late WorkflowAutomationEngine engine;
    late Directory tempDir;
    late String auditLogPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sl_wf_audit_');
      auditLogPath = '${tempDir.path}${Platform.pathSeparator}audit_log.jsonl';
      AuditLogService.setLogFilePathForTesting(auditLogPath);

      SharedPreferences.setMockInitialValues({});
      final auditFile = File(auditLogPath);
      if (auditFile.existsSync()) {
        await auditFile.delete();
      }
      engine = WorkflowAutomationEngine();
      engine.resetForTesting();
      await engine.initialize();
    });

    tearDown(() async {
      AuditLogService.setLogFilePathForTesting(null);
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('triggers high-risk alert and lock on repeated violations', () async {
      final prefs = await SharedPreferences.getInstance();

      final results = await engine.evaluateRules(
        eventType: 'security_violation',
        eventData: {
          'violation_count': 3,
          'accountId': 'test_account',
          'transactionId': 'tx-001',
          'amount': 12345,
        },
      );

      expect(results, isNotEmpty);
      final actionText = results.first.actions.join(' | ');
      expect(actionText.contains('보안 알림'), isTrue);
      expect(actionText.contains('계정 잠금'), isTrue);

      final userPinLock = prefs.getInt(PrefKeys.userPinLockedUntilMs);
      final rootPinLock = prefs.getInt(PrefKeys.rootPinLockedUntilMs);
      expect(userPinLock, isNotNull);
      expect(rootPinLock, isNotNull);
      expect(userPinLock! > DateTime.now().millisecondsSinceEpoch, isTrue);

      final logs = await AuditLogService.getRecentLogs(limit: 200);
      expect(logs.any((e) => e.action == 'automation_high_risk_alert'), isTrue);
      expect(
        logs.any((e) => e.action == 'automation_account_lock_applied'),
        isTrue,
      );
    });

    test('does not trigger lock when violation threshold not met', () async {
      final prefs = await SharedPreferences.getInstance();

      final results = await engine.evaluateRules(
        eventType: 'security_violation',
        eventData: {'violation_count': 2, 'accountId': 'test_account'},
      );

      expect(results, isEmpty);
      expect(prefs.getInt(PrefKeys.userPinLockedUntilMs), isNull);
      expect(prefs.getInt(PrefKeys.rootPinLockedUntilMs), isNull);
    });
  });
}
