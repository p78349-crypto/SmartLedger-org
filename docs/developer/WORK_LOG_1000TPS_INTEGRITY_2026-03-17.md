# 작업 상세 기록 — 1000 TPS 데이터 무결성 시스템 구축

| 항목 | 내용 |
|------|------|
| **작업일시** | 2026-03-17 (월) 20:50 ~ 21:35 |
| **작업자** | AI 페어 프로그래밍 (Copilot Claude Opus 4.6) |
| **프로젝트** | SmartLedger v1.0.1+2 |
| **DB Schema** | v10 → **v11** |
| **flutter analyze** | **Error: 0** / Info: 7 (avoid_redundant_argument_values) |
| **TPS 벤치마크** | **All 7 tests passed** |

---

## 1. 작업 배경

SmartLedger의 SQLCipher + Drift 기반 오프라인 DB가
1000 TPS(초당 트랜잭션) 환경에서도 데이터 위변조 없이
무결성을 유지할 수 있는 방어 체계 구축 요청.

기존 상태:
- WAL 모드 + `PRAGMA synchronous = FULL` + `busy_timeout = 5000` 가동 중
- `syncId` / `updatedAt` / `isDeleted` 동기화 필드 존재
- **해시 체인, 멱등성 키, 정합성 배치 검증 = 부재**

---

## 2. 구현 내역 (4종)

### 2-1. SHA-256 해시 체인 무결성 서비스
- **파일**: `lib/services/integrity_hash_chain_service.dart` (224 lines)
- **해시 알고리즘**: SHA-256 (via `package:cryptography`)
- **체인 구조**: `prevHash | txId | accountId | type | amount | date | description`
- **기능**:
  - `computeHash()` — 단일 레코드 해시 계산
  - `computeNextHash()` — DB에서 마지막 해시 조회 후 연쇄 계산
  - `verifyChain(accountId)` — 계정 전체 체인 순회 검증
  - `verifyAll()` — 모든 계정 일괄 검증
  - `backfillHashes(accountId)` — 레거시 데이터 소급 해시 적용

### 2-2. 멱등성(Idempotency) 키 서비스
- **파일**: `lib/services/idempotency_service.dart` (101 lines)
- **DB 테이블**: `db_idempotency_keys` (operationKey PK, result, createdAt, expiresAt)
- **TTL**: 기본 24시간, 자동 퍼지
- **기능**:
  - `tryGet(key)` — 캐시된 결과 조회 (null이면 미처리)
  - `record(key, result)` — 처리 완료 기록
  - `executeOnce(key, action)` — 멱등 실행 래퍼 (중복 차단)
  - `purgeExpired()` — 만료 키 수동 제거
  - `activeKeyCount()` — 모니터링용 활성 키 수

### 2-3. 배치 데이터 정합성 검증 쿼리
- **파일**: `lib/services/batch_integrity_verifier.dart` (306 lines)
- **7가지 검증 쿼리**:

| # | 검증 항목 | SQL 기반 |
|---|----------|----------|
| 1 | 계정별 잔액 정합성 (수입-지출) | SUM + GROUP BY |
| 2 | 고아 레코드 (없는 account_id 참조) | LEFT JOIN ... WHERE NULL |
| 3 | 중복 syncId 탐지 | GROUP BY HAVING cnt > 1 |
| 4 | 해시 누락 레코드 카운트 | WHERE integrity_hash IS NULL |
| 5 | 미래 날짜 거래 이상치 | WHERE date > NOW+1day |
| 6 | 금액 이상치 (음수/극단값) | WHERE amount < 0 OR > threshold |
| 7 | 멱등성 키 통계 (active/expired) | COUNT + WHERE expires_at |

- `runFullReport()` — 전체 7종 통합 리포트 1회 호출

### 2-4. 1000 TPS 부하 벤치마크 테스트
- **파일**: `test/services/tps_load_benchmark_test.dart` (282 lines)
- **인메모리 Drift DB** (SQLCipher 없이 순수 쓰기 성능 측정)
- **7개 벤치마크**:

| 테스트 | 측정 대상 | 결과 (2026-03-17) |
|--------|----------|-------------------|
| TPS-1 | Batch insert 1,000건 | 42ms → **23,810 TPS** |
| TPS-2 | Individual upsert 500건 | 62ms → **8,065 TPS** |
| TPS-3 | SHA-256 해시 체인 1,000건 | 35ms → **28,571 H/s** |
| TPS-4a | 멱등성 키 쓰기 1,000건 | 88ms → **11,364 TPS** |
| TPS-4b | 멱등성 키 읽기 1,000건 | 120ms → **8,333 TPS** |
| TPS-5 | 배치 리포트 10K건 | **14ms** |
| TPS-6 | 해시 체인 검증 500건 | **10ms** (verified=500, broken=0) |
| TPS-7 | 동시 배치 10×100건 | 23ms → **43,478 TPS** |

---

## 3. DB Schema 변경 (v10 → v11)

### 3-1. `db_transactions` 테이블 — 칼럼 추가
```sql
ALTER TABLE db_transactions ADD COLUMN integrity_hash TEXT;
```

### 3-2. `db_idempotency_keys` 테이블 — 신규 생성
```sql
CREATE TABLE db_idempotency_keys (
  operation_key TEXT NOT NULL PRIMARY KEY,
  result        TEXT,
  created_at    INTEGER NOT NULL DEFAULT (strftime('%s','now')),
  expires_at    INTEGER NOT NULL
);
```

### 3-3. 마이그레이션 코드
```dart
// app_database.dart — onUpgrade
if (from < 11) {
  await migrator.addColumn(dbTransactions, dbTransactions.integrityHash);
  await migrator.createTable(dbIdempotencyKeys);
}
```

---

## 4. 파일 변경 총괄

### 신규 생성 (4개)
| 파일 | 라인 수 | 용도 |
|------|---------|------|
| `lib/services/integrity_hash_chain_service.dart` | 224 | 해시 체인 |
| `lib/services/idempotency_service.dart` | 101 | 멱등성 키 |
| `lib/services/batch_integrity_verifier.dart` | 306 | 배치 검증 |
| `test/services/tps_load_benchmark_test.dart` | 282 | TPS 벤치마크 |

### 수정 (2개, 이번 작업 분)
| 파일 | 변경 내용 |
|------|----------|
| `lib/database/app_database.dart` | schema v11, integrityHash 칼럼, DbIdempotencyKeys 테이블, 마이그레이션 |
| `lib/database/app_database.g.dart` | Drift 코드젠 자동 재생성 (+607 lines) |

### 이전 세션 작업 포함 수정 (7개)
| 파일 | 변경 내용 |
|------|----------|
| `lib/services/audit_log_service.dart` | 테스트 격리용 경로 오버라이드 |
| `test/services/transaction_service_test.dart` | 감사 로그 temp dir 격리 |
| `test/services/workflow_automation_engine_test.dart` | 감사 로그 temp dir 격리 |
| `scripts/ci_local.ps1` | Invoke-NativeChecked 래퍼 (fail-fast) |
| `local_security_check.ps1` | Docker preflight + 표준 exit code |
| `docs/developer/DR_RUNBOOK_KO.md` | DR 런북 (신규) |
| `docs/developer/DR_CHECKLIST_ONEPAGE_KO.md` | DR 1페이지 체크리스트 (신규) |
| `scripts/dr_quick_recover.ps1` | DR 원커맨드 복구 스크립트 (신규) |

---

## 5. 검증 결과

```
flutter analyze   → Error: 0 / Info: 7 (avoid_redundant_argument_values only)
flutter test (TPS) → All 7 tests passed (0 failures)
build_runner      → 1873 outputs generated (schema v11 codegen 정상)
```

---

## 6. 사용 예시

### 해시 체인 — 신규 트랜잭션 삽입 시
```dart
final hash = await IntegrityHashChainService.instance.computeNextHash(
  accountId: 1,
  transactionId: tx.id,
  type: tx.type.name,
  amount: tx.amount,
  date: tx.date,
  description: tx.description,
);
// companion에 integrityHash: Value(hash) 포함하여 upsert
```

### 멱등성 — 중복 요청 차단
```dart
final result = await IdempotencyService.instance.executeOnce(
  'tx_add_${tx.id}',
  () async {
    await dbStore.upsertTransaction(account, tx);
    return 'ok';
  },
);
// result == 'ok' (두 번째 호출 시 DB 쓰기 없이 캐시 반환)
```

### 배치 정합성 — 일일 점검
```dart
final report = await BatchIntegrityVerifier.instance.runFullReport();
print(report); // 고아/중복/해시누락/이상치 한눈에
if (!report.isClean) { /* 알림 발송 */ }
```

---

> **작성**: 2026-03-17 21:35 KST
> **다음 작업**: 커밋 / format gate 수정 (ai_compliance_engine.dart, regional_ai_policy.dart)
