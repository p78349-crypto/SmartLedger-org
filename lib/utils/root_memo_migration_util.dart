import 'package:flutter/material.dart';
import '../services/root_memo_service_v2.dart';
import '../utils/snackbar_utils.dart';
import '../utils/dialog_utils.dart';

/// ROOT 메모 시스템 마이그레이션 유틸리티
class RootMemoMigrationUtil {
  static bool _migrationChecked = false;
  static bool _migrationCompleted = false;

  /// 앱 시작시 마이그레이션 필요성 확인 및 실행
  static Future<void> checkAndMigrate(BuildContext context) async {
    if (_migrationChecked) return;
    _migrationChecked = true;

    try {
      final newService = RootMemoServiceV2.getInstance();
      final stats = await newService.getStats();
      
      // SQLite에 메모가 없으면 마이그레이션 시도
      if (stats['total'] == 0) {
        await _performMigration(context);
      }
    } catch (e) {
      print('마이그레이션 확인 오류: $e');
    }
  }

  /// 실제 마이그레이션 수행
  static Future<void> _performMigration(BuildContext context) async {
    try {
      final newService = RootMemoServiceV2.getInstance();
      final success = await newService.migrateFromSharedPreferences();
      
      if (success) {
        _migrationCompleted = true;
        if (context.mounted) {
          SnackbarUtils.showSuccess(
            context, 
            '🎉 ROOT 메모 시스템이 새로운 데이터베이스로 업그레이드되었습니다',
          );
        }
      }
    } catch (e) {
      print('마이그레이션 수행 오류: $e');
      if (context.mounted) {
        SnackbarUtils.showError(
          context, 
          '메모 시스템 업그레이드 중 오류가 발생했습니다',
        );
      }
    }
  }

  /// 수동 마이그레이션 다이얼로그
  static Future<void> showMigrationDialog(BuildContext context) async {
    final confirmed = await DialogUtils.showConfirmationDialog(
      context,
      title: '📝 메모 시스템 업그레이드',
      content: '''
ROOT 메모 시스템이 향상된 데이터베이스로 업그레이드됩니다.

🔄 개선사항:
• 빠른 검색 성능
• 안정적인 데이터 저장
• 메모 순서 정렬 기능
• 색상별 필터링
• 향상된 백업/복원

기존 메모가 새로운 시스템으로 자동 이전됩니다.
업그레이드를 진행하시겠습니까?
''',
      confirmText: '업그레이드',
      cancelText: '나중에',
    );

    if (confirmed == true) {
      await _performMigrationWithProgress(context);
    }
  }

  /// 진행상황 표시와 함께 마이그레이션
  static Future<void> _performMigrationWithProgress(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('메모 시스템 업그레이드 중...'),
          ],
        ),
      ),
    );

    try {
      final newService = RootMemoServiceV2.getInstance();
      final success = await newService.migrateFromSharedPreferences();
      
      if (context.mounted) {
        Navigator.pop(context); // 진행 다이얼로그 닫기
        
        if (success) {
          _migrationCompleted = true;
          SnackbarUtils.showSuccess(
            context, 
            '✅ 메모 시스템 업그레이드가 완료되었습니다!',
          );
        } else {
          SnackbarUtils.showInfo(
            context, 
            '이전할 메모가 없습니다. 새로운 시스템을 사용해보세요!',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        SnackbarUtils.showError(
          context, 
          '업그레이드 중 오류가 발생했습니다: $e',
        );
      }
    }
  }

  /// 마이그레이션 완료 여부 확인
  static bool get isMigrationCompleted => _migrationCompleted;

  /// 시스템 비교 정보 생성
  static Map<String, dynamic> getSystemComparison() {
    return {
      'old_system': {
        'name': 'SharedPreferences 기반',
        'pros': [
          '간단한 구현',
          '빠른 초기 설정',
        ],
        'cons': [
          '전체 데이터 로딩 필요',
          '검색 성능 저하',
          '대용량 데이터 처리 한계',
          '트랜잭션 지원 없음',
          '복잡한 쿼리 불가능',
        ],
      },
      'new_system': {
        'name': 'SQLite (Drift) 기반',
        'pros': [
          '고성능 검색',
          '부분 데이터 로딩',
          '트랜잭션 지원',
          '복잡한 쿼리 가능',
          '데이터 무결성 보장',
          '메모 순서 관리',
          '색상별 필터링',
          '통계 기능',
        ],
        'cons': [
          '초기 설정 복잡',
          '약간의 학습 곡선',
        ],
      },
    };
  }

  /// 백업 전 안전성 확인
  static Future<bool> verifyDataIntegrity(BuildContext context) async {
    try {
      final newService = RootMemoServiceV2.getInstance();
      final memos = await newService.getAllMemos();
      final stats = await newService.getStats();
      
      print('📊 데이터 무결성 확인:');
      print('  • 총 메모 수: ${stats['total']}');
      print('  • 고정된 메모: ${stats['pinned']}');
      print('  • 최근 메모: ${stats['recent']}');
      print('  • 실제 로딩된 메모: ${memos.length}');
      
      return stats['total'] == memos.length;
    } catch (e) {
      print('데이터 무결성 확인 오류: $e');
      return false;
    }
  }
}