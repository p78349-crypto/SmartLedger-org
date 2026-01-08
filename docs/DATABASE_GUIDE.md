# SmartLedger 데이터베이스 동작 방법

## 📚 개요

SmartLedger는 **Drift** (Dart의 오픈소스 ORM) 라이브러리를 사용하여 **SQLite** 데이터베이스를 관리합니다.

- **데이터베이스**: SQLite 3
- **ORM 프레임워크**: Drift (moor의 후속)
- **스키마 버전**: 7
- **생성 코드**: `lib/database/app_database.g.dart` (자동 생성)

---

## 🏗️ 데이터베이스 아키텍처

### 1️⃣ 핵심 테이블 (4개)

#### **DbAccounts** (계정)
```dart
- id (INTEGER) - 자동증가
- name (TEXT) - 계정명 (고유)
- createdAt (DATETIME) - 생성일
```
**용도**: 사용자 계정/가계부 분리

#### **DbTransactions** (거래 내역)
```dart
- id (TEXT) - 고유 ID (기본키)
- accountId (INTEGER) - 계정 FK
- type (TEXT) - 거래 유형
- description (TEXT) - 설명
- amount (REAL) - 금액
- cardChargedAmount (REAL) - 카드 청구액 (선택)
- date (DATETIME) - 거래 날짜
- quantity (INTEGER) - 수량
- unitPrice (REAL) - 단가
- paymentMethod (TEXT) - 결제 수단
- memo (TEXT) - 메모
- store (TEXT) - 가게명
- mainCategory (TEXT) - 대분류
- subCategory (TEXT) - 중분류
- detailCategory (TEXT) - 소분류
- location (TEXT) - 위치
- supplier (TEXT) - 공급자
- expiryDate (DATETIME) - 만료일 (식재료용)
- unit (TEXT) - 단위
- savingsAllocation (TEXT) - 적금 배분
- isRefund (INTEGER) - 환불 여부 (0/1)
- originalTransactionId (TEXT) - 원래 거래 ID
- weatherJson (TEXT) - 날씨 정보 (JSON)
- benefitJson (TEXT) - 혜택 정보 (JSON)
```
**용도**: 모든 금융 거래 기록

#### **DbAssets** (자산)
```dart
- id (INTEGER) - 자동증가
- accountId (INTEGER) - 계정 FK
- category (TEXT) - 자산 분류
- name (TEXT) - 자산명
- amount (REAL) - 금액
- location (TEXT) - 위치
- memo (TEXT) - 메모
- updatedAt (DATETIME) - 수정일
```
**용도**: 통장, 적금, 부동산 등 자산 추적

#### **DbFixedCosts** (고정비)
```dart
- id (INTEGER) - 자동증가
- accountId (INTEGER) - 계정 FK
- name (TEXT) - 항목명
- amount (REAL) - 금액
- cycle (TEXT) - 주기
- nextDueDate (DATETIME) - 다음 예정일
- memo (TEXT) - 메모
```
**용도**: 월세, 보험료 등 반복 고정비 관리

---

### 2️⃣ 가상 테이블 (인덱싱용)

#### **tx_fts** (Full-Text Search)
```sql
CREATE VIRTUAL TABLE tx_fts USING fts5(
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
)
```
**용도**: 빠른 거래 검색 (전문 검색 FTS5 사용)

#### **tx_benefit_monthly** (이익 집계)
```sql
CREATE TABLE tx_benefit_monthly(
  account_id INTEGER,
  ym TEXT,
  benefit_type TEXT,
  total_amount REAL,
  tx_count INTEGER,
  PRIMARY KEY(account_id, ym, benefit_type)
)
```
**용도**: 월별 혜택 금액 빠른 조회

---

## 🔄 데이터베이스 초기화 및 마이그레이션

### 초기화 (onCreate)
```dart
MigrationStrategy(
  onCreate: (migrator) async {
    // 1. 모든 테이블 생성
    await migrator.createAll();
    
    // 2. FTS 가상 테이블 생성
    await customStatement('CREATE VIRTUAL TABLE...');
    
    // 3. 인덱스 생성
    await customStatement('CREATE INDEX...');
  }
)
```

### 마이그레이션 (onUpgrade)
현재 스키마 버전: **7**

마이그레이션 패턴:
```dart
if (from < 2) {
  await migrator.addColumn(dbTransactions, dbTransactions.newCol);
}
if (from < 3) {
  await migrator.createTable(dbNewTable);
}
```

**주요 전략**:
- ✅ 추가 전용 (Additive): 이전 데이터 보존
- ✅ FTS 재생성: 스키마 변경 시 FTS 재인덱싱

---

## 🔌 데이터베이스 연결

### 파일 위치
```dart
// lib/database/app_database.dart

Future<QueryExecutor> _openConnection() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'app.db'));
  return NativeDatabase.createInBackground(file);
}
```

**저장 경로**:
- **Android**: `/data/data/com.example.smart_ledger/databases/app.db`
- **iOS**: `/var/mobile/Containers/Data/Application/.../Documents/app.db`
- **Windows**: `%APPDATA%\smart_ledger\app.db`
- **Linux**: `~/.local/share/smart_ledger/app.db`

### 싱글톤 패턴
```dart
final appDb = AppDatabase();
```

---

## 📖 기본 CRUD 작업

### 1️⃣ CREATE (삽입)

**단일 거래 추가**:
```dart
await appDb.into(appDb.dbTransactions).insert(
  DbTransactionsCompanion(
    id: Value(uuid.v4()),
    accountId: Value(1),
    type: Value('expense'),
    amount: Value(50000),
    date: Value(DateTime.now()),
  )
);
```

**배치 삽입**:
```dart
await appDb.batch((batch) {
  for (var tx in transactions) {
    batch.insert(appDb.dbTransactions, tx);
  }
});
```

### 2️⃣ READ (조회)

**모든 거래 조회**:
```dart
final allTxs = await appDb.select(appDb.dbTransactions).get();
```

**조건부 조회**:
```dart
final expenses = await (appDb.select(appDb.dbTransactions)
  ..where((t) => t.type.equals('expense'))
  ..where((t) => t.accountId.equals(1))
  ..orderBy([(t) => OrderingTerm(expression: t.date)])
).get();
```

**전문 검색 (FTS)**:
```dart
final results = await appDb.customSelect(
  'SELECT * FROM tx_fts WHERE description MATCH ?',
  variables: [searchQuery]
).get();
```

### 3️⃣ UPDATE (수정)

**거래 수정**:
```dart
await appDb.update(appDb.dbTransactions).replace(
  DbTransactionsCompanion(
    id: Value(txId),
    amount: Value(newAmount),
    date: Value(newDate),
  )
);
```

### 4️⃣ DELETE (삭제)

**거래 삭제**:
```dart
await (appDb.delete(appDb.dbTransactions)
  ..where((t) => t.id.equals(txId))
).go();
```

---

## 🔍 고급 쿼리

### 월별 합계
```dart
final monthlyTotals = await appDb.customSelect('''
  SELECT 
    strftime('%Y-%m', date) as month,
    SUM(amount) as total,
    COUNT(*) as count
  FROM db_transactions
  WHERE account_id = ?
  GROUP BY month
  ORDER BY month DESC
''', variables: [accountId]).get();
```

### 카테고리별 통계
```dart
final stats = await appDb.customSelect('''
  SELECT 
    main_category,
    COUNT(*) as count,
    SUM(amount) as total,
    AVG(amount) as average
  FROM db_transactions
  WHERE account_id = ? AND date >= ?
  GROUP BY main_category
  ORDER BY total DESC
''', variables: [accountId, startDate]).get();
```

### 조인 쿼리
```dart
final txsWithAccounts = await (appDb.select(appDb.dbTransactions)
  .join([
    innerJoin(appDb.dbAccounts, 
      appDb.dbAccounts.id.equalsExp(appDb.dbTransactions.accountId))
  ])
).get();
```

---

## 🔐 트랜잭션 관리

### 다중 작업 트랜잭션
```dart
await appDb.transaction(() async {
  // 거래 추가
  await appDb.into(appDb.dbTransactions).insert(txData);
  
  // 자산 수정
  await (appDb.update(appDb.dbAssets)
    ..where((a) => a.id.equals(assetId))
  ).write(DbAssetsCompanion(amount: Value(newAmount)));
  
  // 오류 발생 시 모두 롤백
});
```

---

## 📊 데이터베이스 마이그레이션 시나리오

### 시나리오 1: 새로운 컬럼 추가

```dart
if (from < 8) {
  // 거래에 "tag" 컬럼 추가
  await migrator.addColumn(dbTransactions, dbTransactions.tag);
}
```

### 시나리오 2: 새로운 테이블 생성

```dart
if (from < 9) {
  await migrator.createTable(dbNewCategories);
}
```

### 시나리오 3: 데이터 마이그레이션

```dart
if (from < 10) {
  // 기존 데이터 변환
  await customStatement('''
    UPDATE db_transactions 
    SET main_category = 'food' 
    WHERE main_category = '식료품'
  ''');
}
```

---

## 🛠️ 유용한 도구

### 1️⃣ 데이터베이스 코드 생성
```bash
flutter pub run build_runner build
```
→ `app_database.g.dart` 자동 생성/갱신

### 2️⃣ 변경사항 감지 (Watch)
```bash
flutter pub run build_runner watch
```
→ 파일 변경 시 자동 재생성

### 3️⃣ 데이터베이스 검사
- **SQLite 클라이언트**: DB Browser for SQLite (https://sqlitebrowser.org)
- **명령어**: `sqlite3 app.db`

---

## 📈 성능 최적화

### 1️⃣ 인덱싱
```dart
// 자주 검색하는 컬럼에 인덱스 생성
await customStatement(
  'CREATE INDEX idx_tx_account_date ON db_transactions(account_id, date)'
);
```

### 2️⃣ 배치 작업
```dart
// 많은 데이터 삽입할 때 배치 사용
await appDb.batch((batch) {
  batch.insertAll(appDb.dbTransactions, txList);
});
```

### 3️⃣ 선택적 조회
```dart
// 필요한 컬럼만 선택
final result = await appDb.customSelect(
  'SELECT id, date, amount FROM db_transactions WHERE account_id = ?',
  variables: [accountId]
).get();
```

---

## 🔗 관련 파일

- [lib/database/app_database.dart](../../lib/database/app_database.dart) - 데이터베이스 정의
- [lib/database/app_database.g.dart](../../lib/database/app_database.g.dart) - 자동 생성 코드
- [lib/services/transaction_db_store.dart](../../lib/services/transaction_db_store.dart) - 거래 저장소
- [lib/services/transaction_db_migration_service.dart](../../lib/services/transaction_db_migration_service.dart) - 마이그레이션

---

## 📝 주요 특징 정리

| 기능 | 설명 |
|------|------|
| **FTS5** | 빠른 전문 검색 (Full-Text Search) |
| **자동 증가** | 주요 ID는 자동증가 |
| **참조 무결성** | 계정 삭제 시 거래도 자동 삭제 |
| **JSON 저장** | 복잡한 데이터는 JSON으로 저장 |
| **트랜잭션** | 다중 작업 원자성 보장 |
| **마이그레이션** | 스키마 버전 관리로 자동 업그레이드 |

---

## 🎯 사용 예시

### 예시: 월별 지출 통계
```dart
final stats = await appDb.customSelect('''
  SELECT 
    strftime('%Y-%m', date) as month,
    main_category as category,
    SUM(amount) as total
  FROM db_transactions
  WHERE 
    account_id = ? AND 
    date >= datetime('now', '-12 months') AND
    type = 'expense'
  GROUP BY month, category
  ORDER BY month DESC, total DESC
''', variables: [accountId]).get();

// 결과 사용
for (var row in stats) {
  print('${row['month']}: ${row['category']} = ${row['total']}');
}
```

---

## 최종 정리

SmartLedger의 데이터베이스는:
- ✅ **구조화됨**: 명확한 테이블 설계
- ✅ **성능 최적화됨**: FTS, 인덱싱
- ✅ **유연함**: 스키마 마이그레이션 지원
- ✅ **안전함**: 트랜잭션, 참조 무결성
- ✅ **확장 가능**: Drift ORM으로 쉬운 개발

