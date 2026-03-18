part of 'app_database.dart';

extension AppDatabaseMigration on AppDatabase {
  MigrationStrategy get migrationStrategy {
    return MigrationStrategy(
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

        // v11: 해시 체인 + 멱등성 키
        if (from < 11) {
          await migrator.addColumn(
            dbTransactions,
            dbTransactions.integrityHash,
          );
          await migrator.createTable(dbIdempotencyKeys);
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
          await migrator.addColumn(
            dbTransactions,
            dbTransactions.detailCategory,
          );
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
          await migrator.addColumn(
            dbTransactions,
            dbTransactions.originalAmount,
          );
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
        // R2-3: FULL = 모든 WAL write 후 fsync 호출.
        // 금융 데이터이므로 crash 시에도 절대 유실 불가 → 성능 비용 감수.
        // (WMS DB는 NORMAL — 재고 데이터는 재스캔으로 복구 가능)
        await customStatement('PRAGMA synchronous = FULL');
        await customStatement('PRAGMA busy_timeout = 5000');
        await customStatement('PRAGMA wal_autocheckpoint = 1000');
      },
    );
  }
}
