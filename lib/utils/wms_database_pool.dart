import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as p;
import '../migrations/migration_global_product_db.dart';
import '../database/db_encryption_key_manager.dart';

/// WMS 데이터베이스 연결 풀 (성능 최적화)
class WmsDatabasePool {
  WmsDatabasePool._();
  static final WmsDatabasePool instance = WmsDatabasePool._();

  Database? _globalProductDb;
  bool _isInitializing = false;

  /// 글로벌 제품 DB 연결 (싱글톤)
  Future<Database> getGlobalProductDb() async {
    if (_globalProductDb != null && _globalProductDb!.isOpen) {
      return _globalProductDb!;
    }

    // 초기화 중복 방지
    if (_isInitializing) {
      // 다른 초기화 완료까지 대기
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (_globalProductDb != null && _globalProductDb!.isOpen) {
        return _globalProductDb!;
      }
    }

    return await _initializeGlobalProductDb();
  }

  Future<Database> _initializeGlobalProductDb() async {
    _isInitializing = true;
    
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
        // 성능 최적화 설정
        onOpen: (db) async {
          await db.execute('PRAGMA journal_mode=WAL');
          await db.execute('PRAGMA synchronous=NORMAL');
          await db.execute('PRAGMA cache_size=10000');
          await db.execute('PRAGMA temp_store=MEMORY');
        },
      );
      
      return _globalProductDb!;
    } finally {
      _isInitializing = false;
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
  bool get isConnected => 
    _globalProductDb != null && _globalProductDb!.isOpen;
}