# SmartLedger 데이터베이스 요약 (2026-03-02)

## 기준
- 실제 `.db/.sqlite` 파일은 현재 워크스페이스에서 확인되지 않음
- 아래 내용은 코드 정의 기준
	- `lib/database/app_database.dart`
	- `lib/migrations/migration_global_product_db.dart`
- 제출/전달용 SQL 스키마 파일: `docs/sqlite_schema_from_code.sql`
- 런타임 생성 DB 파일명(앱 문서 디렉터리): `db.sqlite`

## 1) 테이블 스키마

### `db_accounts`
- `id` INTEGER PK AUTOINCREMENT
- `name` TEXT UNIQUE NOT NULL
- `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP
- `syncId` TEXT UNIQUE NULL
- `updatedAt` DATETIME NULL
- `isDeleted` BOOL DEFAULT false
- `isSynced` BOOL DEFAULT false

### `db_transactions`
- `id` TEXT PK
- `accountId` INTEGER FK -> `db_accounts.id`
- `type` TEXT NOT NULL
- `description` TEXT DEFAULT ''
- `amount` REAL NOT NULL
- `cardChargedAmount` REAL NULL
- `date` DATETIME NOT NULL
- `quantity` INTEGER DEFAULT 1
- `unitPrice` REAL DEFAULT 0.0
- `paymentMethod` TEXT DEFAULT ''
- `memo` TEXT DEFAULT ''
- `store` TEXT NULL
- `mainCategory` TEXT DEFAULT '미분류'
- `subCategory` TEXT NULL
- `detailCategory` TEXT NULL
- `location` TEXT NULL
- `supplier` TEXT NULL
- `expiryDate` DATETIME NULL
- `unit` TEXT NULL
- `currency` TEXT DEFAULT 'KRW'
- `exchangeRate` REAL DEFAULT 1.0
- `originalAmount` REAL NULL
- `vatAmount` REAL DEFAULT 0.0
- `savingsAllocation` TEXT NULL
- `isRefund` INTEGER DEFAULT 0
- `originalTransactionId` TEXT NULL
- `weatherJson` TEXT NULL
- `benefitJson` TEXT NULL
- `syncId` TEXT UNIQUE NULL
- `updatedAt` DATETIME NULL
- `isDeleted` BOOL DEFAULT false
- `isSynced` BOOL DEFAULT false

### `db_assets`
- `id` INTEGER PK AUTOINCREMENT
- `accountId` INTEGER FK -> `db_accounts.id`
- `category` TEXT NULL
- `name` TEXT NOT NULL
- `amount` REAL NOT NULL
- `location` TEXT NULL
- `memo` TEXT NULL
- `updatedAt` DATETIME NULL
- `syncId` TEXT UNIQUE NULL
- `isDeleted` BOOL DEFAULT false
- `isSynced` BOOL DEFAULT false

### `db_fixed_costs`
- `id` INTEGER PK AUTOINCREMENT
- `accountId` INTEGER FK -> `db_accounts.id`
- `name` TEXT NOT NULL
- `amount` REAL NOT NULL
- `cycle` TEXT NULL
- `nextDueDate` DATETIME NULL
- `memo` TEXT NULL
- `syncId` TEXT UNIQUE NULL
- `updatedAt` DATETIME NULL
- `isDeleted` BOOL DEFAULT false
- `isSynced` BOOL DEFAULT false

### `db_root_memos`
- `id` TEXT PK
- `title` TEXT NOT NULL
- `content` TEXT NOT NULL
- `createdAt` DATETIME DEFAULT CURRENT_TIMESTAMP
- `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP
- `isPinned` BOOL DEFAULT false
- `color` TEXT NULL
- `sortOrder` INTEGER DEFAULT 0

### `tx_fts` (FTS5 가상 테이블)
- 텍스트 검색 최적화용 가상 테이블
- 주요 컬럼: `description`, `memo`, `payment_method`, `store`, `main_category`, `sub_category`, `detail_category`, `location`, `supplier`, `amount_text`, `date_ymd`, `date_ym`, `year_text`, `month_text`

### `tx_benefit_monthly`
- `account_id` INTEGER NOT NULL
- `ym` TEXT NOT NULL
- `benefit_type` TEXT NOT NULL
- `total_amount` REAL DEFAULT 0
- `tx_count` INTEGER DEFAULT 0
- PK: (`account_id`, `ym`, `benefit_type`)

### `global_product_master`
- `id` INTEGER PK AUTOINCREMENT
- 바코드: `ean13`, `upc_a`, `jan_code`, `kan_code`
- 상품명: `product_name_ko`, `product_name_en`, `product_name_ja`
- 카테고리: `category_1` ~ `category_4`
- 기타: `manufacturer`, `packaging_unit`, `default_quantity`, `country_code`
- 영양: `calories_per_100g`, `protein_per_100g`, `fat_per_100g`, `carbs_per_100g`
- 상태/메타: `is_active`, `data_source`, `created_at`, `updated_at`
- UNIQUE 제약: (`ean13`, `upc_a`, `jan_code`, `kan_code`)

## 2) 인덱스

### 명시적 인덱스
- `idx_tx_account_date` ON `db_transactions(account_id, date)`
- `idx_tx_account_type_date` ON `db_transactions(account_id, type, date)`
- `idx_benefit_monthly_account_ym` ON `tx_benefit_monthly(account_id, ym)`

- `idx_ean13` ON `global_product_master(ean13)`
- `idx_upc_a` ON `global_product_master(upc_a)`
- `idx_jan_code` ON `global_product_master(jan_code)`
- `idx_kan_code` ON `global_product_master(kan_code)`
- `idx_product_name_ko` ON `global_product_master(product_name_ko)`
- `idx_category_1` ON `global_product_master(category_1)`
- `idx_country_code` ON `global_product_master(country_code)`
- `idx_country_active` ON `global_product_master(country_code, is_active)`

### 암시적 인덱스
- 각 테이블 `PRIMARY KEY` 기반 자동 인덱스
- `UNIQUE` 제약(`db_accounts.name`, `syncId` 등) 기반 자동 인덱스

## 3) 샘플 3행 (민감정보 제외)

> 출처: `koreanProductSamples` (코드 상 샘플 데이터)

| kan_code | category_1 | category_2 | category_3 | category_4 | product_name_ko | default_quantity | country_code | data_source |
|---|---|---|---|---|---|---:|---|---|
| 01010101 | 가공식품 | 조미료 | 종합조미료 | 천연/발효조미료 | 간장 (자연발효) | 2 | KR | korean |
| 01010102 | 가공식품 | 조미료 | 종합조미료 | 식초 | 식초 (천연) | 2 | KR | korean |
| 01010103 | 가공식품 | 조미료 | 종합조미료 | 천일염 | 천일염 | 2 | KR | korean |

---

필요하면 다음 단계로 실제 런타임 DB 연결 후,
- `PRAGMA table_info(테이블명)`
- `PRAGMA index_list(테이블명)`
- `SELECT ... LIMIT 5`
결과 기준으로 문서를 실측값으로 갱신 가능.
