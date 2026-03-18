import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'db_encryption_key_manager.dart';

part 'app_database.g.dart';
part 'app_database_migration.dart';

class DbAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncId => text().nullable().unique()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

class DbTransactions extends Table {
  TextColumn get id => text()();
  IntColumn get accountId => integer().references(DbAccounts, #id)();
  TextColumn get type => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  RealColumn get amount => real()();
  RealColumn get cardChargedAmount => real().nullable()();
  DateTimeColumn get date => dateTime()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  RealColumn get unitPrice => real().withDefault(const Constant(0.0))();
  TextColumn get paymentMethod => text().withDefault(const Constant(''))();
  TextColumn get memo => text().withDefault(const Constant(''))();
  TextColumn get store => text().nullable()();
  TextColumn get mainCategory => text().withDefault(const Constant('미분류'))();
  TextColumn get subCategory => text().nullable()();
  TextColumn get detailCategory => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get supplier => text().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get unit => text().nullable()();

  TextColumn get currency => text().withDefault(const Constant('KRW'))();
  RealColumn get exchangeRate => real().withDefault(const Constant(1.0))();
  RealColumn get originalAmount => real().nullable()();
  RealColumn get vatAmount => real().withDefault(const Constant(0.0))();

  /// Savings allocation option for savings transactions.
  ///
  /// Stored as a string (enum name) for forward compatibility.
  TextColumn get savingsAllocation => text().nullable()();

  /// Refund marker (SQLite has no bool type; use int 0/1).
  IntColumn get isRefund => integer().withDefault(const Constant(0))();
  TextColumn get originalTransactionId => text().nullable()();

  /// Weather snapshot serialized as JSON (nullable).
  TextColumn get weatherJson => text().nullable()();

  /// Structured benefits serialized as JSON (nullable).
  ///
  /// Example: {"카드":1200,"배송":3000}
  TextColumn get benefitJson => text().nullable()();

  TextColumn get syncId => text().nullable().unique()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// SHA-256 해시 체인 — 이전 레코드의 해시를 포함하여 변조 감지.
  TextColumn get integrityHash => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class DbAssets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get accountId => integer().references(DbAccounts, #id)();
  TextColumn get category => text().nullable()();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  TextColumn get location => text().nullable()();
  TextColumn get memo => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get syncId => text().nullable().unique()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

class DbFixedCosts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get accountId => integer().references(DbAccounts, #id)();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  TextColumn get cycle => text().nullable()();
  DateTimeColumn get nextDueDate => dateTime().nullable()();
  TextColumn get memo => text().nullable()();
  TextColumn get syncId => text().nullable().unique()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

/// ROOT 전용 메모 테이블
class DbRootMemos extends Table {
  TextColumn get id => text()(); // UUID 형태의 고유 ID
  TextColumn get title => text()(); // 메모 제목
  TextColumn get content => text()(); // 메모 내용
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isPinned =>
      boolean().withDefault(const Constant(false))(); // 상단 고정 여부
  TextColumn get color =>
      text().nullable()(); // 메모 색상 (red, blue, green, yellow, purple)
  IntColumn get sortOrder =>
      integer().withDefault(const Constant(0))(); // 정렬 순서

  @override
  Set<Column> get primaryKey => {id};
}

/// 멱등성(Idempotency) 키 테이블 — 중복 요청 차단.
///
/// 동일한 operationKey로 들어온 요청은 24시간 내 재실행되지 않음.
class DbIdempotencyKeys extends Table {
  TextColumn get operationKey => text()();
  TextColumn get result => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column> get primaryKey => {operationKey};
}

@DriftDatabase(
  tables: [
    DbAccounts,
    DbTransactions,
    DbAssets,
    DbFixedCosts,
    DbRootMemos,
    DbIdempotencyKeys,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test/override constructor.
  ///
  /// Allows injecting a custom [QueryExecutor] (e.g. in-memory database)
  /// to avoid platform-specific file/isolated background open issues.
  AppDatabase.connect(super.executor);

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => migrationStrategy;

  Future<List<DbAccount>> getAllAccounts() {
    return (select(
      dbAccounts,
    )..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)])).get();
  }

  Future<int> insertAccount(DbAccountsCompanion entry) {
    return into(dbAccounts).insert(entry, mode: InsertMode.insertOrIgnore);
  }

  Future<int> deleteAccountByName(String name) {
    return (delete(dbAccounts)..where((tbl) => tbl.name.equals(name))).go();
  }

  Future<DbAccount?> getAccountByName(String name) {
    return (select(
      dbAccounts,
    )..where((tbl) => tbl.name.equals(name))).getSingleOrNull();
  }
}

// R2-2: 메인 DB 초기화 순서
// 1. FlutterSecureStorage → 256-bit AES 키 로드/생성
// 2. NativeDatabase.createInBackground(file, setup: PRAGMA key)
// 3. Drift 마이그레이션 (version 1→8)
// 4. beforeOpen → foreign_keys, WAL, synchronous=FULL, busy_timeout
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    final key = await DbEncryptionKeyManager.getOrCreateKey();

    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        // R4-5: key is base64Url-encoded (A-Z, a-z, 0-9, -, _)
        // so it cannot contain ' and is safe from SQL injection.
        // Assertion guards against future key-format changes.
        assert(!key.contains("'"), 'DB key must not contain single quotes');
        db.execute("PRAGMA key = '$key';");
      },
    );
  });
}
