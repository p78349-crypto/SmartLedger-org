-- SmartLedger SQLite schema (code-derived)
-- Generated from:
-- - lib/database/app_database.dart
-- - lib/migrations/migration_global_product_db.dart

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS db_accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  sync_id TEXT UNIQUE,
  updated_at DATETIME,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  is_synced INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS db_transactions (
  id TEXT NOT NULL PRIMARY KEY,
  account_id INTEGER NOT NULL,
  type TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  amount REAL NOT NULL,
  card_charged_amount REAL,
  date DATETIME NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price REAL NOT NULL DEFAULT 0.0,
  payment_method TEXT NOT NULL DEFAULT '',
  memo TEXT NOT NULL DEFAULT '',
  store TEXT,
  main_category TEXT NOT NULL DEFAULT '미분류',
  sub_category TEXT,
  detail_category TEXT,
  location TEXT,
  supplier TEXT,
  expiry_date DATETIME,
  unit TEXT,
  currency TEXT NOT NULL DEFAULT 'KRW',
  exchange_rate REAL NOT NULL DEFAULT 1.0,
  original_amount REAL,
  vat_amount REAL NOT NULL DEFAULT 0.0,
  savings_allocation TEXT,
  is_refund INTEGER NOT NULL DEFAULT 0,
  original_transaction_id TEXT,
  weather_json TEXT,
  benefit_json TEXT,
  sync_id TEXT UNIQUE,
  updated_at DATETIME,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  is_synced INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(account_id) REFERENCES db_accounts(id)
);

CREATE TABLE IF NOT EXISTS db_assets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  account_id INTEGER NOT NULL,
  category TEXT,
  name TEXT NOT NULL,
  amount REAL NOT NULL,
  location TEXT,
  memo TEXT,
  updated_at DATETIME,
  sync_id TEXT UNIQUE,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  is_synced INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(account_id) REFERENCES db_accounts(id)
);

CREATE TABLE IF NOT EXISTS db_fixed_costs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  account_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  amount REAL NOT NULL,
  cycle TEXT,
  next_due_date DATETIME,
  memo TEXT,
  sync_id TEXT UNIQUE,
  updated_at DATETIME,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  is_synced INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(account_id) REFERENCES db_accounts(id)
);

CREATE TABLE IF NOT EXISTS db_root_memos (
  id TEXT NOT NULL PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  is_pinned INTEGER NOT NULL DEFAULT 0,
  color TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE VIRTUAL TABLE IF NOT EXISTS tx_fts USING fts5(
  transaction_id UNINDEXED,
  account_name UNINDEXED,
  description,
  memo,
  payment_method,
  store,
  main_category,
  sub_category,
  detail_category,
  location,
  supplier,
  amount_text,
  date_ymd,
  date_ym,
  year_text,
  month_text,
  tokenize='unicode61'
);

CREATE TABLE IF NOT EXISTS tx_benefit_monthly (
  account_id INTEGER NOT NULL,
  ym TEXT NOT NULL,
  benefit_type TEXT NOT NULL,
  total_amount REAL NOT NULL DEFAULT 0,
  tx_count INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY(account_id, ym, benefit_type),
  FOREIGN KEY(account_id) REFERENCES db_accounts(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_tx_account_date
ON db_transactions(account_id, date);

CREATE INDEX IF NOT EXISTS idx_tx_account_type_date
ON db_transactions(account_id, type, date);

CREATE INDEX IF NOT EXISTS idx_benefit_monthly_account_ym
ON tx_benefit_monthly(account_id, ym);

CREATE TABLE IF NOT EXISTS global_product_master (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ean13 TEXT,
  upc_a TEXT,
  jan_code TEXT,
  kan_code TEXT,
  product_name_ko TEXT,
  product_name_en TEXT,
  product_name_ja TEXT,
  category_1 TEXT,
  category_2 TEXT,
  category_3 TEXT,
  category_4 TEXT,
  manufacturer TEXT,
  packaging_unit TEXT,
  default_quantity INTEGER DEFAULT 1,
  country_code TEXT DEFAULT 'KR',
  calories_per_100g REAL,
  protein_per_100g REAL,
  fat_per_100g REAL,
  carbs_per_100g REAL,
  is_active BOOLEAN DEFAULT 1,
  data_source TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(ean13, upc_a, jan_code, kan_code)
);

CREATE INDEX IF NOT EXISTS idx_ean13 ON global_product_master(ean13);
CREATE INDEX IF NOT EXISTS idx_upc_a ON global_product_master(upc_a);
CREATE INDEX IF NOT EXISTS idx_jan_code ON global_product_master(jan_code);
CREATE INDEX IF NOT EXISTS idx_kan_code ON global_product_master(kan_code);
CREATE INDEX IF NOT EXISTS idx_product_name_ko ON global_product_master(product_name_ko);
CREATE INDEX IF NOT EXISTS idx_category_1 ON global_product_master(category_1);
CREATE INDEX IF NOT EXISTS idx_country_code ON global_product_master(country_code);
CREATE INDEX IF NOT EXISTS idx_country_active ON global_product_master(country_code, is_active);
