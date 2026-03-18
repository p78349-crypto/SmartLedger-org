import 'dart:async';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as p;
import '../migrations/migration_global_product_db.dart';
import '../database/db_encryption_key_manager.dart';

/// WMS 데이터베이스 연결 풀 (성능 최적화)
/// R1-1: Completer 기반 초기화 게이트 (이중 초기화 방지)
/// R2-1: busy_timeout=5000 추가 (락 충돌 방어)
class WmsDatabasePool {
  WmsDatabasePool._();
  static final WmsDatabasePool instance = WmsDatabasePool._();

  Database? _globalProductDb;
  Completer<Database>? _initCompleter;

  /// 글로벌 제품 DB 연결 (싱글톤)
  Future<Database> getGlobalProductDb() async {
    if (_globalProductDb != null && _globalProductDb!.isOpen) {
      return _globalProductDb!;
    }

    // 초기화 중이면 완료 신호 대기 (10초 타임아웃)
    if (_initCompleter != null) {
      return _initCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('WMS DB 초기화 타임아웃 (10초)'),
      );
    }

    return await _initializeGlobalProductDb();
  }

  Future<Database> _initializeGlobalProductDb() async {
    _initCompleter = Completer<Database>();

    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'global_products.db');
      final key = await DbEncryptionKeyManager.getOrCreateKey();

      _globalProductDb = await openDatabase(
        path,
        password: key,
        version: 1,
        onCreate: (db, _) async {
          await migrationGlobalProductDatabase(db);
        },
        onOpen: (db) async {
          await db.execute('PRAGMA journal_mode=WAL');
          // R2-1: 락 충돌 시 5초 재시도 허용
          await db.execute('PRAGMA busy_timeout=5000');
          // R2-3: NORMAL = fsync 생략으로 쓰기 성능 우선.
          // 재고 데이터는 바코드 재스캔으로 복구 가능하므로
          // 메인 DB(FULL)보다 성능 우선.
          await db.execute('PRAGMA synchronous=NORMAL');
          await db.execute('PRAGMA cache_size=10000');
          await db.execute('PRAGMA temp_store=MEMORY');
        },
      );

      _initCompleter!.complete(_globalProductDb!);
      return _globalProductDb!;
    } catch (e, st) {
      _initCompleter!.completeError(e, st);
      rethrow;
    } finally {
      _initCompleter = null;
    }
  }

  /// 연결 해제 (앱 종료 시)
  Future<void> close() async {
    if (_globalProductDb != null && _globalProductDb!.isOpen) {
      await _globalProductDb!.close();
      _globalProductDb = null;
    }
  }

  /// 연결 상태 확인
  bool get isConnected => _globalProductDb != null && _globalProductDb!.isOpen;
}
