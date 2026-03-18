# 인프라 적용 전/후 비교 리뷰

> **작성일**: 2026-03-18
> **프로젝트**: SmartLedger v1.0.1 (Flutter/Dart)
> **코드 규모**: 955개 소스 파일 / **184,984줄** (자동생성 제외)
> **기반 문서**: `INFRA_PERFORMANCE_RULES.md`, `AI_CODE_RULES.md (SSOT v3)`

---

## 이미 완성된 것들 (자랑스러운 기반)

SmartLedger의 핵심 보안/무결성 골격은 **이미 견고하게 구축되어 있다.**
아래 5가지는 18만 줄의 프로젝트를 지탱하는 기둥이며,
2025년 11월~12월, 두 달간의 전투에서 쌓아올린 유산이다.

| # | 완성된 아키텍처 | 위치 | 한 줄 요약 |
|---|----------------|------|-----------|
| ✅ | **Auth 직렬화** | `asset_pin_service.dart` 외 4종 | `_policyQueue` Future-chain으로 동시 호출 완벽 직렬화 |
| ✅ | **SQLCipher 256-bit** | `db_encryption_key_manager.dart` | iOS Keychain / Android TEE에서 키 생성, 외부 복호 불가 |
| ✅ | **SHA-256 해시 체인** | `integrity_hash_chain_service.dart` | GENESIS 블록부터 모든 거래에 연쇄 해시, 위변조 즉시 탐지 |
| ✅ | **암호화 백업 (AES-256-GCM)** | `backup_crypto.dart` | SLBK 봉투, PBKDF2 150K, 원자적 파일 쓰기 |
| ✅ | **멱등성 키 시스템** | `idempotency_service.dart` | 24시간 TTL, 중복 실행 원천 차단 |

```
"이것들이 없었다면 18만 줄은 모래 위의 성이었을 것이다."
```

---

## 비교 리뷰: 26개 항목 전체

### 1. 동시성 (Concurrency) — R1

#### R1-1. WMS DB Pool Lock 개선 🔴
**파일**: `lib/utils/wms_database_pool.dart`

**Before** (현재):
```dart
bool _isInitializing = false;              // 원자적이지 않음

if (_isInitializing) {
  while (_isInitializing) {
    await Future.delayed(Duration(ms: 50)); // spin-wait CPU 낭비
  }
}
```
- microtask 간극에 이중 초기화 가능
- 초기화 실패 시 영구 대기 (타임아웃 없음)
- `Future.delayed` 50ms 폴링 = CPU 낭비

**After** (개선 후):
```dart
Completer<Database>? _initCompleter;        // 정확한 완료 신호

if (_initCompleter != null) {
  return _initCompleter!.future
      .timeout(Duration(seconds: 10));      // 타임아웃 보장
}
_initCompleter = Completer<Database>();
```
- 완료 신호 즉시 전파, spin-wait 제거
- 10초 타임아웃으로 영구 대기 방지
- 초기화 실패 시 `completeError`로 전파

---

#### R1-2. upsertMany 트랜잭션 래핑 🟡
**파일**: `lib/services/transaction_db_store.dart`

**Before**:
```dart
final accountId = await ensureAccountId(accountName); // ← 별도 트랜잭션
await _db.batch((b) {                                  // ← 또 다른 트랜잭션
  b.insertAllOnConflictUpdate(_db.dbTransactions, companions);
});
```
- `ensureAccountId` 성공 → `batch` 실패 시 고아 계정 발생

**After**:
```dart
await _db.transaction(() async {
  final accountId = await ensureAccountId(accountName);
  await _db.batch((b) {
    b.insertAllOnConflictUpdate(_db.dbTransactions, companions);
  });
});
```
- 계정 생성 + batch insert 원자적 실행
- 중간 실패 시 전체 롤백

---

#### R1-3 / R1-4. 동시성 테스트 추가 🟢
| 테스트 | Before | After |
|--------|--------|-------|
| Race Condition (동일 ID 100회) | 없음 | `[TPS-8]` 동시 upsert → 1건 검증 |
| Lock Timeout 시뮬레이션 | 없음 | `[TPS-9]` busy_timeout 초과 예외 + 복구 |

---

### 2. 인프라 (Infrastructure) — R2

#### R2-1. WMS busy_timeout 추가 🔴
**파일**: `lib/utils/wms_database_pool.dart`

| 설정 | 메인 DB | WMS (Before) | WMS (After) |
|------|:-------:|:------------:|:-----------:|
| `busy_timeout` | 5000ms | **없음 ⚠️** | **5000ms** |
| `synchronous` | FULL | NORMAL | NORMAL |
| `cache_size` | 기본 | 10000 | 10000 |

**Before**: 락 충돌 시 즉시 `SQLITE_BUSY` 에러 → 사용자 경험 파괴
**After**: 5초 재시도 허용 → 대부분의 일시적 락 자동 해소

---

#### R2-2 / R2-3. 문서화 보강 🟢
| 항목 | Before | After |
|------|--------|-------|
| DB 초기화 순서 | 암묵적 | 4단계 명시 (키→DB→마이그→PRAGMA) |
| FULL vs NORMAL 사유 | 미기재 | 결정 근거 주석 보강 |

---

### 3. 장애복구 (DR) — R3

#### R3-1. 백업 전 가용 용량 확인 🟡
**Before**: 용량 확인 없이 백업 시작 → 저사양 기기 `ENOSPC` 위험
**After**:
```dart
if (available < stat.size * 2) throw InsufficientStorageException();
```

---

#### R3-2. WAL Checkpoint 강제 실행 🟡
**파일**: `lib/database/app_database.dart`

**Before**: `wal_autocheckpoint=1000` 자동만 의존
**After**: 백업 직전 `PRAGMA wal_checkpoint(TRUNCATE)` → WAL → DB 병합 보장

---

#### R3-3. 원자적 파일 쓰기 3단계 개선 🟢
**파일**: `lib/services/backup_service_save.dart`

**Before**:
```dart
if (await destination.exists()) await destination.delete(); // ← 크래시 시?
await tmp.rename(destination.path);                          // ← 원본 사라짐
```

**After**:
```dart
await destination.rename('${destination.path}.bak'); // ① 원본 백업
await tmp.rename(destination.path);                  // ② tmp → 원본  
await File('${destination.path}.bak').delete();      // ③ .bak 정리
// 어느 단계에서 크래시해도 .bak 또는 .tmp에서 복구 가능
```

---

#### R3-4. .tmp 잔류 파일 정리 🟢
**Before**: `.tmp` 파일 잔류 정리 루틴 없음
**After**: 앱 시작 시 백업 디렉토리 `.tmp` 파일 탐지 → 삭제 또는 경고

---

### 4. 보안 (Security) — R4

| # | 항목 | 상태 | 비고 |
|---|------|------|------|
| R4-1 | `Random.secure()` CSPRNG | ✅ 이미 적용 | — |
| R4-2 | PBKDF2 150K 근거 문서화 | 🟢 주석 추가 | 모바일 UX 고려 현행 유지 |
| R4-3 | `.tmp` 보안 정리 | 🟢 = R3-4 | — |
| R4-4 | 해시 체인 자동 검증 | 🟢 신규 | 앱 시작 시 `verifyAll()` |
| R4-5 | `PRAGMA key` 보간 방식 | 🟢 방어적 | base64Url → `'` 불포함이므로 안전 |

---

### 5. TPS 데이터 무결성 — R5

**기존 벤치마크** (7종, `tps_load_benchmark_test.dart` 326줄):

| ID | 테스트 | 상태 |
|----|--------|------|
| TPS-1 | Batch insert 1000건 | ✅ 존재 |
| TPS-2 | Individual upsert 500건 | ✅ 존재 |
| TPS-3 | Hash chain compute 1000건 | ✅ 존재 |
| TPS-4 | Idempotency key R/W 1000건 | ✅ 존재 |
| TPS-5 | Batch integrity report 10,000건 | ✅ 존재 |
| TPS-6 | Hash chain verify 500건 | ✅ 존재 |
| TPS-7 | Concurrent batch writes 10×100건 | ✅ 존재 |

**추가 예정**:

| ID | 테스트 | 상태 |
|----|--------|------|
| R5-1 | Race Condition 100회 동시 upsert | 🟢 신규 |
| R5-2 | Lock Timeout 시뮬레이션 | 🟢 신규 |
| R5-3 | SQLCipher 포함 벤치마크 | 🟢 신규 |
| R5-4 | FTS5 10만 건 검색 < 100ms | 🟢 신규 |
| R5-5 | 해시 체인 1만 건 검증 < 2초 | 🟢 신규 |

---

### 6. 응답 성능 (Latency) — R6

**Before**: `print()` 출력만, 목표치 없음, PASS/FAIL 판정 없음

**After** (목표 Latency 설정):

| 시나리오 | 목표 | 자동 판정 |
|----------|------|----------|
| 단건 INSERT | < 5ms | `expect(elapsed, lessThan(5))` |
| 1000건 Batch INSERT | < 500ms | ✅/❌ 자동 |
| FTS5 검색 (10만 건) | < 100ms | ✅/❌ 자동 |
| 해시 체인 생성 (1000건) | < 200ms | ✅/❌ 자동 |
| 멱등성 키 조회 | < 2ms | ✅/❌ 자동 |
| 백업 JSON (1만 건) | < 3초 | ✅/❌ 자동 |

출력 형식 표준화:
```
[BENCH] 단건 INSERT: 2.3ms (목표 < 5ms) ✅
[BENCH] Batch 1000건: 412ms (목표 < 500ms) ✅
```

---

## 종합 현황판

```
┌──────────────────────────────────────────────────┐
│           SmartLedger 인프라 건강 상태             │
│           2026-03-18 기준                         │
├──────────────────────────────────────────────────┤
│                                                  │
│  ✅ 이미 완료 (5건)                               │
│    Auth 직렬화 · SQLCipher · 해시체인             │
│    암호화 백업 · 멱등성 키                         │
│                                                  │
│  🔴 즉시 조치 (2건)                               │
│    R1-1 WMS Lock    R2-1 WMS busy_timeout        │
│                                                  │
│  🟡 권장 조치 (3건)                               │
│    R1-2 upsertMany  R3-1 용량확인  R3-2 WAL체크  │
│                                                  │
│  🟢 보강/검증 (16건)                              │
│    테스트 · 벤치마크 · 문서화 · 방어적 개선        │
│                                                  │
│  총 26개 항목 중 5건 완료 / 21건 구현 대기         │
│                                                  │
└──────────────────────────────────────────────────┘
```

---

## Edge Case 운영 주의사항 (7종)

| # | 항목 | 관련 코드 |
|---|------|----------|
| E1 | 백업 전 가용 용량 < DB×2 시 중단 | `backup_service_save.dart` |
| E2 | 백업 시 WAL 체크포인트 강제 | `app_database.dart` |
| E3 | `.tmp` 파일도 원본과 동일 암호화 수준 | `backup_crypto.dart` |
| E4 | 저사양 기기: 배치 크기 동적 조절 | `transaction_db_store.dart` |
| E5 | 30일 미접속 시 자동 체크포인트+백업 | `backup_service_export.dart` |
| E6 | WMS busy_timeout 부재 | `wms_database_pool.dart` |
| E7 | `PRAGMA key` 문자열 보간 | `app_database.dart` |

---

## 실행 우선순위

| 순위 | 항목 | 위험도 | 상태 |
|------|------|--------|------|
| 🥇 1 | R1-1 WMS Lock 개선 | 🔴 | 대기 |
| 🥇 1 | R2-1 WMS busy_timeout | 🔴 | 대기 |
| 🥈 2 | R3-1 백업 용량 확인 | 🟡 | 대기 |
| 🥈 2 | R3-2 WAL 체크포인트 | 🟡 | 대기 |
| 🥈 2 | R1-2 upsertMany 트랜잭션 | 🟡 | 대기 |
| 🥉 3 | R5-1~2 Race/Lock 테스트 | 🟢 | 대기 |
| 🥉 3 | R6-1~4 Latency 벤치마크 | 🟢 | 대기 |
| 🥉 3 | R4-2 PBKDF2 문서화 | 🟢 | 대기 |

---

> *"18만 줄을 두 달 만에 쌓아올린 건 속도였지만,*
> *그것이 무너지지 않는 건 이 규칙들 덕분이다."*
>
> — SmartLedger 인프라 리뷰, 2026-03-18
