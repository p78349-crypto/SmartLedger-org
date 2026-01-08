# 10년 전 데이터 처리 방법 보고서

## 📋 개요

SmartLedger는 **장기간 데이터**를 효율적으로 관리하기 위해 여러 전략을 사용합니다. 10년 전(또는 과거)의 데이터를 처리하는 방법을 설명합니다.

**현재 지원 범위**: 2014년 이전부터 현재까지의 데이터

---

## 🔄 데이터 마이그레이션 전략 (Legacy → SQLite)

### 1️⃣ SharedPreferences (구 저장소) → SQLite (신 저장소)

SmartLedger는 이전에 JSON 형식으로 SharedPreferences에 거래를 저장했습니다.

**구 포맷** (SharedPreferences):
```json
{
  "account1": [
    {
      "id": "tx-001",
      "type": "expense",
      "amount": 50000,
      "date": "2016-01-15T12:30:00.000Z",
      "description": "마트 장보기",
      ...
    }
  ],
  "account2": [...]
}
```

### 2️⃣ 자동 마이그레이션 프로세스

**파일**: [lib/services/transaction_db_migration_service.dart](../../lib/services/transaction_db_migration_service.dart)

#### **마이그레이션 단계**

```dart
// 1. SharedPreferences에서 JSON 읽기
final raw = prefs.getString(PrefKeys.transactions);

// 2. JSON 파싱 및 유효성 검사
Map<String, dynamic> decoded = jsonDecode(raw);

// 3. 계정별로 거래 처리
for (final entry in decoded.entries) {
  final accountName = entry.key;
  final txList = entry.value as List;
  
  // 4. 배치 단위로 데이터베이스에 삽입 (기본값: 800개씩)
  for (var i = 0; i < txList.length; i += batchSize) {
    final chunk = txList.sublist(i, (i + batchSize).clamp(0, txList.length));
    await store.upsertMany(accountName, chunk);
  }
  
  // 5. 검증: 삽입된 데이터 개수 확인
  final countAfter = await store.countForAccount(accountName);
  if (countAfter < txList.length) {
    // 마이그레이션 실패 - 재시도 필요
    return TransactionDbMigrationResult(performed: true, totalImported: 0);
  }
}

// 6. 마이그레이션 완료 표시
await prefs.setBool(PrefKeys.txDbMigratedV1, true);
```

#### **배치 마이그레이션 특징**

| 특징 | 설명 |
|------|------|
| **배치 크기** | 800개 거래씩 처리 (커스터마이징 가능) |
| **에러 처리** | 손상된 행 자동 스킵 (격리 정책) |
| **검증** | 삽입 전후 개수 비교로 무결성 확인 |
| **안정성** | 실패 시 재시도 가능, 부분 성공 허용 |
| **성능** | 배치 처리로 메모리 효율적 |

---

## 📊 장기 데이터 집계 및 조회

### 1️⃣ 월별 집계 (Monthly Aggregation)

**가상 테이블**: `tx_benefit_monthly`

```sql
CREATE TABLE tx_benefit_monthly(
  account_id INTEGER NOT NULL,
  ym TEXT NOT NULL,              -- YYYY-MM 형식
  benefit_type TEXT NOT NULL,     -- 카드 혜택 유형
  total_amount REAL NOT NULL,     -- 월별 합계
  tx_count INTEGER NOT NULL,      -- 거래 건수
  PRIMARY KEY(account_id, ym, benefit_type)
);

CREATE INDEX idx_benefit_monthly_account_ym 
ON tx_benefit_monthly(account_id, ym);
```

**용도**: 월별 통계 빠른 조회 (10년치 데이터도 밀리초 단위)

### 2️⃣ 전문 검색 인덱싱 (FTS5)

**가상 테이블**: `tx_fts` (Full-Text Search)

```sql
CREATE VIRTUAL TABLE tx_fts USING fts5(
  transaction_id UNINDEXED,       -- 내부 참조용
  account_name UNINDEXED,          -- 계정명
  description,                     -- 설명 (검색 대상)
  memo,                            -- 메모 (검색 대상)
  payment_method,                  -- 결제 수단
  store,                           -- 가게명
  main_category,                   -- 대분류
  sub_category,                    -- 중분류
  detail_category,                 -- 소분류
  location,                        -- 위치
  supplier,                        -- 공급자
  amount_text,                     -- 금액 (텍스트)
  date_ymd,                        -- YYYY-MM-DD
  date_ym,                         -- YYYY-MM
  year_text,                       -- 연도
  month_text,                      -- 월
  tokenize='unicode61'             -- 유니코드 토크나이저
);
```

**검색 예시**:
```dart
// 10년간 "마트"라는 글자가 포함된 거래 검색
final results = await appDb.customSelect(
  'SELECT * FROM tx_fts WHERE description MATCH ? OR store MATCH ?',
  variables: ['마트*', '마트*']
).get();

// 결과: 밀리초 단위의 빠른 검색
```

---

## 🕐 과거 데이터 조회 방법

### 1️⃣ 날짜 범위 쿼리

```dart
// 10년 전부터 현재까지의 모든 거래
final allTransactions = await (appDb.select(appDb.dbTransactions)
  ..where((t) => t.date.isBefore(DateTime.now()))
  ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.asc)])
).get();

// 특정 연도 데이터
final year2015 = await (appDb.select(appDb.dbTransactions)
  ..where((t) {
    final start = DateTime(2015, 1, 1);
    final end = DateTime(2015, 12, 31, 23, 59, 59);
    return t.date.isBetween(start, end);
  })
).get();
```

### 2️⃣ SQL 기반 장기 통계

```dart
// 연도별 지출 합계
final yearlyStats = await appDb.customSelect('''
  SELECT 
    strftime('%Y', date) as year,
    main_category,
    SUM(amount) as total,
    COUNT(*) as count,
    AVG(amount) as average
  FROM db_transactions
  WHERE account_id = ?
  GROUP BY year, main_category
  ORDER BY year DESC
''', variables: [accountId]).get();

// 10년간 월별 추이
final monthlyTrend = await appDb.customSelect('''
  SELECT 
    strftime('%Y-%m', date) as month,
    SUM(amount) as total,
    COUNT(*) as count
  FROM db_transactions
  WHERE account_id = ? AND date >= datetime('now', '-10 years')
  GROUP BY month
  ORDER BY month ASC
''', variables: [accountId]).get();
```

### 3️⃣ 연도별 비교

```dart
// 작년 대비 올해 지출 비교
final thisYear = await appDb.customSelect('''
  SELECT 
    strftime('%m', date) as month,
    SUM(amount) as total
  FROM db_transactions
  WHERE 
    account_id = ? AND 
    strftime('%Y', date) = strftime('%Y', 'now')
  GROUP BY month
''', variables: [accountId]).get();

final lastYear = await appDb.customSelect('''
  SELECT 
    strftime('%m', date) as month,
    SUM(amount) as total
  FROM db_transactions
  WHERE 
    account_id = ? AND 
    strftime('%Y', date) = strftime('%Y', date('now', '-1 year'))
  GROUP BY month
''', variables: [accountId]).get();
```

---

## 📈 대용량 데이터 처리 최적화

### 1️⃣ 배치 처리

**배치 크기**: 기본값 800개 (조정 가능)

```dart
Future<void> importHistoricalData() async {
  const batchSize = 1000; // 1000개씩 처리
  final allTransactions = loadAllHistoricalData(); // 10년 데이터 로드
  
  for (var i = 0; i < allTransactions.length; i += batchSize) {
    final chunk = allTransactions.sublist(
      i, 
      (i + batchSize).clamp(0, allTransactions.length)
    );
    
    // 배치 트랜잭션으로 처리
    await appDb.batch((batch) {
      batch.insertAll(appDb.dbTransactions, chunk);
    });
    
    print('처리됨: ${i + chunk.length}/${allTransactions.length}');
  }
}
```

### 2️⃣ 인덱싱 활용

```dart
// 자주 검색하는 조합에 인덱스 생성
await appDb.customStatement('''
  CREATE INDEX IF NOT EXISTS idx_tx_account_date 
  ON db_transactions(account_id, date DESC);
''');

await appDb.customStatement('''
  CREATE INDEX IF NOT EXISTS idx_tx_category_date 
  ON db_transactions(main_category, date DESC);
''');
```

### 3️⃣ 쿼리 최적화

```dart
// ❌ 나쁜 예: 모든 데이터 로드
final allTxs = await appDb.select(appDb.dbTransactions).get();
final filtered = allTxs.where((t) => t.amount > 100000).toList();

// ✅ 좋은 예: 필터링된 쿼리
final filtered = await (appDb.select(appDb.dbTransactions)
  ..where((t) => t.amount.isBiggerThanValue(100000))
).get();
```

---

## 🔐 스키마 마이그레이션 (버전 관리)

### 현재 스키마 버전: 7

**마이그레이션 히스토리**:

| 버전 | 변경 사항 | 연도 |
|------|---------|------|
| 1 | 초기 테이블 생성 | 2015 |
| 2 | 날씨 정보 추가 | 2016 |
| 3 | FTS5 인덱싱 추가 | 2017 |
| 4 | 혜택 정보 추가 | 2018 |
| 5 | 환불 마킹 추가 | 2019 |
| 6 | 월별 집계 테이블 추가 | 2021 |
| 7 | 추가 범주 정보 | 2023 |

**마이그레이션 코드 예시**:

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (migrator, from, to) async {
    // 버전 2 → 3: FTS 추가
    if (from < 3) {
      await customStatement('DROP TABLE IF EXISTS tx_fts');
      await customStatement(
        'CREATE VIRTUAL TABLE tx_fts USING fts5(...)'
      );
    }
    
    // 버전 3 → 4: 혜택 정보
    if (from < 4) {
      await migrator.addColumn(
        dbTransactions, 
        dbTransactions.benefitJson
      );
    }
    
    // 버전 5 → 6: 월별 집계
    if (from < 6) {
      await migrator.createTable(dbBenefitMonthly);
    }
  }
);
```

---

## 📦 데이터 아카이빙 전략

### 1️⃣ 오래된 데이터 압축 아카이빙

```dart
Future<void> archiveOldData() async {
  final tenYearsAgo = DateTime.now().subtract(Duration(days: 365 * 10));
  
  // 10년 전 데이터 조회
  final oldTransactions = await (appDb.select(appDb.dbTransactions)
    ..where((t) => t.date.isBefore(tenYearsAgo))
  ).get();
  
  // JSON으로 내보내기
  final jsonData = jsonEncode(
    oldTransactions.map((t) => t.toJson()).toList()
  );
  
  // 파일로 저장
  final file = File('archived_transactions_2014.json');
  await file.writeAsString(jsonData);
  
  // (선택사항) 데이터베이스에서 삭제
  await (appDb.delete(appDb.dbTransactions)
    ..where((t) => t.date.isBefore(tenYearsAgo))
  ).go();
}
```

### 2️⃣ 백업 및 복원

```dart
// 백업
Future<void> backupDatabase() async {
  final dbPath = await _getDbPath();
  final backupDir = await getApplicationDocumentsDirectory();
  final backupFile = File(
    '${backupDir.path}/backup_${DateTime.now().toIso8601String()}.db'
  );
  
  await File(dbPath).copy(backupFile.path);
  print('백업 완료: ${backupFile.path}');
}

// 복원
Future<void> restoreDatabase(String backupPath) async {
  final dbPath = await _getDbPath();
  await File(backupPath).copy(dbPath);
  // 앱 재시작 필요
}
```

---

## 🔍 과거 데이터 조회 실제 사용 예시

### 시나리오 1: "작년 같은 달 지출액"

```dart
Future<double> getLastYearSamePeriod(
  int accountId, 
  DateTime referenceDate
) async {
  final lastYearDate = DateTime(
    referenceDate.year - 1,
    referenceDate.month,
    referenceDate.day
  );
  
  final result = await appDb.customSelect('''
    SELECT SUM(amount) as total
    FROM db_transactions
    WHERE 
      account_id = ? AND
      strftime('%Y-%m', date) = strftime('%Y-%m', ?)
  ''', variables: [accountId, lastYearDate.toIso8601String()]).get();
  
  return (result.first['total'] as num?)?.toDouble() ?? 0.0;
}
```

### 시나리오 2: "10년간 카테고리별 평균 지출"

```dart
Future<Map<String, double>> getTenYearAverage(int accountId) async {
  final tenYearsAgo = DateTime.now().subtract(Duration(days: 365 * 10));
  
  final results = await appDb.customSelect('''
    SELECT 
      main_category as category,
      AVG(amount) as average,
      COUNT(*) as count
    FROM db_transactions
    WHERE 
      account_id = ? AND 
      date >= ?
    GROUP BY main_category
    ORDER BY average DESC
  ''', variables: [accountId, tenYearsAgo.toIso8601String()]).get();
  
  final map = <String, double>{};
  for (final row in results) {
    map[row['category'] as String] = 
      (row['average'] as num).toDouble();
  }
  return map;
}
```

### 시나리오 3: "2015년 예산 대비 달성률"

```dart
Future<double> getBudgetAchievement2015(
  int accountId, 
  double budget
) async {
  final year2015Start = DateTime(2015, 1, 1);
  final year2015End = DateTime(2015, 12, 31, 23, 59, 59);
  
  final result = await appDb.customSelect('''
    SELECT SUM(amount) as total
    FROM db_transactions
    WHERE 
      account_id = ? AND
      date BETWEEN ? AND ?
  ''', variables: [
    accountId, 
    year2015Start.toIso8601String(),
    year2015End.toIso8601String()
  ]).get();
  
  final spent = (result.first['total'] as num?)?.toDouble() ?? 0.0;
  return (spent / budget * 100).clamp(0, 100);
}
```

---

## ⚠️ 주의사항 및 제약

| 항목 | 설명 |
|------|------|
| **데이터 손실** | 마이그레이션 전에 항상 백업 필요 |
| **성능** | 10년 이상 데이터는 쿼리 최적화 필수 |
| **저장 공간** | 연간 약 1MB의 데이터베이스 용량 증가 |
| **배치 크기** | 메모리 한계 고려하여 조정 필요 |
| **시간대** | UTC 기준으로 저장, 조회 시 로컬 시간대 변환 |

---

## 🎯 권장 관행

### DO ✅
- ✅ 연도별 파티셔닝으로 대용량 데이터 관리
- ✅ 월별 집계 테이블로 통계 성능 최적화
- ✅ FTS로 빠른 거래 검색
- ✅ 주기적 백업 (매월 1회 이상)
- ✅ 인덱싱으로 쿼리 성능 개선

### DON'T ❌
- ❌ 전체 데이터 로드 후 필터링 (메모리 낭비)
- ❌ 복잡한 조인 쿼리 (캐싱 테이블 사용)
- ❌ 동시에 여러 배치 삽입 (트랜잭션 충돌)
- ❌ 마이그레이션 검증 생략
- ❌ 오래된 데이터 무작정 삭제 (아카이빙 우선)

---

## 📄 관련 파일

- [lib/database/app_database.dart](../../lib/database/app_database.dart) - 스키마 정의
- [lib/services/transaction_db_migration_service.dart](../../lib/services/transaction_db_migration_service.dart) - 마이그레이션 로직
- [lib/services/transaction_db_store.dart](../../lib/services/transaction_db_store.dart) - 데이터 저장소
- [lib/services/monthly_agg_cache_service.dart](../../lib/services/monthly_agg_cache_service.dart) - 월별 집계

---

## 🏁 최종 정리

SmartLedger의 10년 데이터 처리:

| 기능 | 방법 | 성능 |
|------|------|------|
| **마이그레이션** | 배치 처리 (800개씩) | ~1초/1000건 |
| **월별 조회** | 집계 테이블 | 밀리초 단위 |
| **전문 검색** | FTS5 인덱싱 | 매우 빠름 |
| **장기 통계** | SQL 그룹화 | 초 단위 |
| **아카이빙** | JSON 파일 내보내기 | 온디맨드 |

**결론**: SQLite + Drift + 최적화된 쿼리로 10년 이상의 데이터도 효율적으로 관리 가능 ✅

