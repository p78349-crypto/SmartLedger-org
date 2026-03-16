import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'db_encryption_key_manager.dart';

part 'app_database.g.dart';

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
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))(); // 상단 고정 여부
  TextColumn get color => text().nullable()(); // 메모 색상 (red, blue, green, yellow, purple)
  IntColumn get sortOrder => integer().withDefault(const Constant(0))(); // 정렬 순서
  
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [DbAccounts, DbTransactions, DbAssets, DbFixedCosts, DbRootMemos])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test/override constructor.
  ///
  /// Allows injecting a custom [QueryExecutor] (e.g. in-memory database)
  /// to avoid platform-specific file/isolated background open issues.
  AppDatabase.connect(super.executor);

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();

      // FTS index for fast long-term memo/description search.
      // Stored as a virtual table (FTS5) because it is optimized for text.
      await customStatement(
        'CREATE VIRTUAL TABLE IF NOT EXISTS tx_fts USING fts5('
        'transaction_id UNINDEXED,'
        'account_name UNINDEXED,'
        'description,'
        'memo,'
        'payment_method,'
        'store,'
        'main_category,'
        'sub_category,'
        'detail_category,'
        'location,'
        'supplier,'
        'amount_text,'
        'date_ymd,'
        'date_ym,'
        'year_text,'
        'month_text,'
        'tokenize=\'unicode61\''
        ')',
      );

      // Monthly benefit aggregation for fast long-term totals.
      await customStatement(
        'CREATE TABLE IF NOT EXISTS tx_benefit_monthly('
        'account_id INTEGER NOT NULL,'
        'ym TEXT NOT NULL,'
        'benefit_type TEXT NOT NULL,'
        'total_amount REAL NOT NULL DEFAULT 0,'
        'tx_count INTEGER NOT NULL DEFAULT 0,'
        'PRIMARY KEY(account_id, ym, benefit_type),'
        'FOREIGN KEY(account_id) REFERENCES db_accounts(id) ON DELETE CASCADE'
        ')',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_benefit_monthly_account_ym '
        'ON tx_benefit_monthly(account_id, ym)',
      );
    },
    
    onUpgrade: (migrator, from, to) async {
      if (from < 10) {
        await migrator.addColumn(dbAccounts, dbAccounts.syncId);
        await migrator.addColumn(dbAccounts, dbAccounts.updatedAt);
        await migrator.addColumn(dbAccounts, dbAccounts.isDeleted);
        await migrator.addColumn(dbAccounts, dbAccounts.isSynced);

        await migrator.addColumn(dbTransactions, dbTransactions.syncId);
        await migrator.addColumn(dbTransactions, dbTransactions.updatedAt);
        await migrator.addColumn(dbTransactions, dbTransactions.isDeleted);
        await migrator.addColumn(dbTransactions, dbTransactions.isSynced);

        await migrator.addColumn(dbAssets, dbAssets.syncId);
        await migrator.addColumn(dbAssets, dbAssets.isDeleted);
        await migrator.addColumn(dbAssets, dbAssets.isSynced);

        await migrator.addColumn(dbFixedCosts, dbFixedCosts.syncId);
        await migrator.addColumn(dbFixedCosts, dbFixedCosts.updatedAt);
        await migrator.addColumn(dbFixedCosts, dbFixedCosts.isDeleted);
        await migrator.addColumn(dbFixedCosts, dbFixedCosts.isSynced);
      }

      // FTS is a cache. For schema changes, we can safely drop and recreate.
      if (from < 3) {
        await customStatement('DROP TABLE IF EXISTS tx_fts');
        await customStatement(
          'CREATE VIRTUAL TABLE IF NOT EXISTS tx_fts USING fts5('
          'transaction_id UNINDEXED,'
          'account_name UNINDEXED,'
          'description,'
          'memo,'
          'payment_method,'
          'store,'
          'main_category,'
          'sub_category,'
          'amount_text,'
          'date_ymd,'
          'date_ym,'
          'year_text,'
          'month_text,'
          'tokenize=\'unicode61\''
          ')',
        );
      }

      if (from < 4) {
        await migrator.addColumn(
          dbTransactions,
          dbTransactions.cardChargedAmount,
        );
        await migrator.addColumn(dbTransactions, dbTransactions.store);
        await migrator.addColumn(dbTransactions, dbTransactions.mainCategory);
        await migrator.addColumn(dbTransactions, dbTransactions.subCategory);
        await migrator.addColumn(
          dbTransactions,
          dbTransactions.savingsAllocation,
        );
        await migrator.addColumn(dbTransactions, dbTransactions.isRefund);
        await migrator.addColumn(
          dbTransactions,
          dbTransactions.originalTransactionId,
        );
        await migrator.addColumn(dbTransactions, dbTransactions.weatherJson);

        // Recreate FTS to ensure schema stays consistent.
        await customStatement('DROP TABLE IF EXISTS tx_fts');
        await customStatement(
          'CREATE VIRTUAL TABLE IF NOT EXISTS tx_fts USING fts5('
          'transaction_id UNINDEXED,'
          'account_name UNINDEXED,'
          'description,'
          'memo,'
          'payment_method,'
          'store,'
          'main_category,'
          'sub_category,'
          'amount_text,'
          'date_ymd,'
          'date_ym,'
          'year_text,'
          'month_text,'
          'tokenize=\'unicode61\''
          ')',
        );

        // Helpful indexes for large data (safe to run repeatedly).
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_tx_account_date '
          'ON db_transactions(account_id, date)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_tx_account_type_date '
          'ON db_transactions(account_id, type, date)',
        );
      }

      if (from < 5) {
        await migrator.addColumn(dbTransactions, dbTransactions.benefitJson);
      }

      if (from < 6) {
        await customStatement(
          'CREATE TABLE IF NOT EXISTS tx_benefit_monthly('
          'account_id INTEGER NOT NULL,'
          'ym TEXT NOT NULL,'
          'benefit_type TEXT NOT NULL,'
          'total_amount REAL NOT NULL DEFAULT 0,'
          'tx_count INTEGER NOT NULL DEFAULT 0,'
          'PRIMARY KEY(account_id, ym, benefit_type),'
          'FOREIGN KEY(account_id) REFERENCES db_accounts(id) ON DELETE CASCADE'
          ')',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_benefit_monthly_account_ym '
          'ON tx_benefit_monthly(account_id, ym)',
        );
      }

      if (from < 7) {
        await migrator.addColumn(dbTransactions, dbTransactions.detailCategory);
        await migrator.addColumn(dbTransactions, dbTransactions.location);
        await migrator.addColumn(dbTransactions, dbTransactions.supplier);
        await migrator.addColumn(dbTransactions, dbTransactions.expiryDate);
        await migrator.addColumn(dbTransactions, dbTransactions.unit);

        // Recreate FTS to include new fields.
        await customStatement('DROP TABLE IF EXISTS tx_fts');
        await customStatement(
          'CREATE VIRTUAL TABLE IF NOT EXISTS tx_fts USING fts5('
          'transaction_id UNINDEXED,'
          'account_name UNINDEXED,'
          'description,'
          'memo,'
          'payment_method,'
          'store,'
          'main_category,'
          'sub_category,'
          'detail_category,'
          'location,'
          'supplier,'
          'amount_text,'
          'date_ymd,'
          'date_ym,'
          'year_text,'
          'month_text,'
          'tokenize=\'unicode61\''
          ')',
        );
      }

      if (from < 8) {
        await migrator.addColumn(dbTransactions, dbTransactions.currency);
        await migrator.addColumn(dbTransactions, dbTransactions.exchangeRate);
        await migrator.addColumn(dbTransactions, dbTransactions.originalAmount);
        await migrator.addColumn(dbTransactions, dbTransactions.vatAmount);
      }
    },
    beforeOpen: (details) async {
      // Ensure foreign keys are enforced (SQLite defaults to OFF).
      await customStatement('PRAGMA foreign_keys = ON');

      // High-throughput integrity profile.
      // - WAL improves writer/reader concurrency.
      // - FULL synchronous prioritizes durability on crash/power loss.
      // - busy_timeout reduces transient lock failures under burst writes.
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA synchronous = FULL');
      await customStatement('PRAGMA busy_timeout = 5000');
      await customStatement('PRAGMA wal_autocheckpoint = 1000');
    },
  );

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
        db.execute("PRAGMA key = '$key';");
      },
    );
  });
}
