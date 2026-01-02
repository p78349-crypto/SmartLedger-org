# DB 전환 설계서 (SharedPreferences JSON → Drift/SQLite) (2025-12-27)

## 왜 이게 “핵심”인가
현재 병목은 크게 2가지입니다.
1) 앱 재실행 시: SharedPreferences의 대형 JSON 디코딩(전체 거래 로딩)
2) 데이터가 10만건+로 커질 때: “전체 리스트를 메모리에 올리는 구조” 자체가 한계

이미 이 프로젝트는 Drift/SQLite를 도입했고(계정은 DB로 이전 완료), FTS(검색)도 DB에 구축되어 있습니다. 남은 핵심은 **거래 저장소를 DB로 전환**하여 “대형 JSON”을 제거하고, 장기적으로는 “필요한 범위만 쿼리”하는 구조로 바꾸는 것입니다.

---

## 현재 상태(관찰)
- 거래 원본(Source of Truth): SharedPreferences의 `PrefKeys.transactions` JSON
- 앱 런타임 캐시: `TransactionService`가 모든 계정 거래를 메모리에 적재
- 검색(FTS): DB의 `tx_fts` 가상 테이블(FTS5)
  - 단, 현재 데이터 소스는 DB가 아니라 `TransactionService` 메모리
- 계정: Drift 테이블 `DbAccounts`로 이전 완료

즉, DB는 이미 들어와 있지만 **거래는 아직 JSON 기반**이라서 “규모가 커질수록” 근본 병목이 남아 있습니다.

---

## 목표 / 비목표
### 목표
- 10만건 이상에서도 앱 재실행/화면 진입 체감 속도 유지
- 거래 저장을 DB로 전환(원본은 DB)
- 기존 UI/화면 로직을 단계적으로 안전하게 전환(한 번에 갈아엎지 않기)
- 백업/복구 포맷 호환 유지(기존 JSON 백업 읽기/쓰기)

### 비목표(이번 설계서에서는 하지 않음)
- 새로운 화면/마이그레이션 진행 UI 추가
- 전 화면을 즉시 페이징/무한스크롤로 개편

---

## 최종 아키텍처(권장 종착점)
1) 거래 원본: Drift `DbTransactions`
2) 런타임:
   - 통계는 월단위 사전집계(`MonthlyAggCacheService`) 중심(이미 적용)
   - 리스트/상세는 “필요한 기간만” DB 쿼리
3) 검색:
   - `tx_fts`는 `DbTransactions`에서 갱신(트리거 또는 증분 upsert)
4) 백업:
   - 내보내기: DB에서 읽어 기존 백업 JSON 구조로 export
   - 가져오기: 백업 JSON을 DB로 import

---

## 스키마 설계(거래)
현재 [lib/models/transaction.dart](../lib/models/transaction.dart) 필드를 기준으로 **DB 컬럼을 완전 매핑**해야 합니다.

### 1) Drift 테이블 확장: `DbTransactions`
현재 [lib/database/app_database.dart](../lib/database/app_database.dart)의 `DbTransactions`에는 다음 필드가 부족합니다.

추가 권장 컬럼(최소 필수):
- `cardChargedAmount REAL NULL`
- `store TEXT NULL`
- `mainCategory TEXT NOT NULL DEFAULT '미분류'`
- `subCategory TEXT NULL`
- `savingsAllocation TEXT NULL`
- `isRefund INTEGER NOT NULL DEFAULT 0`  (SQLite bool)
- `originalTransactionId TEXT NULL`
- `weatherJson TEXT NULL`  (필요 시: `WeatherSnapshot`을 JSON 문자열로 저장)

기존 컬럼과 합치면 “Transaction ↔ Row”가 1:1로 성립해야 합니다.

> 금액 타입: 현재 앱은 `double`을 사용하므로 1차는 `REAL` 유지가 가장 리스크가 낮습니다.
> 다만 장기적으로 정밀도를 엄격히 보장하려면 v2에서 `INTEGER cents`로 전환하는 플랜을 별도 문서로 분리 권장.

### 2) 인덱스 설계(성능 핵심)
대부분의 화면은 “계정 + 날짜 범위” 또는 “계정 + 타입 + 날짜 범위”로 조회합니다.

권장 인덱스:
- `(accountId, date)`
- `(accountId, type, date)`
- `(accountId, paymentMethod, date)` (카드/현금 등 필터가 잦다면)

> Drift에서는 `customStatement('CREATE INDEX ...')`로 생성하거나, 테이블 정의에서 인덱스 선언 패턴을 사용합니다.

---

## 저장소 전환 방식(가장 안전한 단계적 접근)
핵심은 “한 번에 갈아끼우지 말고, **플래그 기반**으로 점진 전환”입니다.

### Phase 0: 준비(현 상태 유지)
- 계정은 DB, 거래는 SharedPreferences(JSON)
- FTS는 DB지만 소스는 메모리

### Phase 1: DB를 거래 원본으로 도입(호환 유지)
- `TransactionService` 퍼블릭 API는 유지(화면 코드는 그대로)
- 내부에 저장소 추상화 도입
  - `TransactionStore`(인터페이스)
  - `PrefsTransactionStore`(현행)
  - `DbTransactionStore`(신규)
- 기능 플래그(SharedPreferences):
  - `tx_storage_backend = prefs|db`
  - 기본은 `prefs`로 시작

### Phase 2: 1회 마이그레이션(자동)
트리거(권장): 앱 시작 후 유휴 타이밍(예: AccountHome 진입 후)

마이그레이션 조건(예):
- `tx_storage_backend != db` 이고
- DB 거래 테이블이 비어있고
- SharedPreferences JSON이 존재할 때

알고리즘:
1) `AccountService`를 통해 계정명→accountId 매핑 확보(없으면 생성)
2) SharedPreferences JSON 디코딩 → 계정별 거래 리스트
3) Drift batch insert로 N개씩 삽입(예: 500~2000)
4) 삽입 완료 후 검증
   - (계정별) row count == json count
5) 성공 시 `tx_storage_backend = db`로 전환
6) FTS를 DB 소스 기준으로 rebuild
7) 월단위 캐시(사전집계) dirty 처리

롤백(안전장치):
- 최소 1~2 버전 동안은 SharedPreferences의 원본 JSON을 삭제하지 않고 보존
- 치명 오류 시 플래그를 `prefs`로 되돌리면 즉시 복구 가능

> 한계: SharedPreferences에 “이미” 초대형 JSON이 들어가면, 마이그레이션 자체도 디코딩 병목이 됩니다.
> 그래서 전환은 “데이터가 더 커지기 전에” 적용하는 것이 가장 효과적입니다.

### Phase 3: 메모리 적재 모델 제거(진짜 대용량 대응)
DB로 옮겨도 `TransactionService.loadTransactions()`가 전체를 메모리에 올리면
- 메모리/정렬 비용 때문에 10만건에서 다시 병목이 생깁니다.

따라서 최종적으로는 API를 다음처럼 확장(또는 신규 서비스 추가)하는 게 정답입니다.
- `watchTransactions(account, start, end)` 또는 `getTransactionsInRange(...)`
- `getRecentTransactions(limit)`
- `getTransactionsByDay(day)`

그리고 화면들은 “전체 리스트”가 아니라 “필요한 기간만” 요청하도록 순차적으로 교체합니다.

---

## FTS(검색) 전환 설계
현재 [lib/services/transaction_fts_index_service.dart](../lib/services/transaction_fts_index_service.dart)는
`TransactionService` 메모리에서 `tx_fts`를 rebuild 합니다.

DB 전환 후 권장:
1) rebuild 소스: `DbTransactions`에서 직접 SELECT
2) 증분 갱신:
   - 단순 구현: 거래 추가/수정/삭제 시 `tx_fts`에 upsert/delete 호출
   - 더 강한 구현: SQLite trigger로 `DbTransactions` 변경 시 자동 반영

1차(리스크 낮음): “증분 upsert + 스탬프 + 필요 시 전체 rebuild” 조합이 가장 실용적입니다.

---

## 백업/복구(호환 유지가 핵심)
현행 백업 코드는 `TransactionService`를 통해 `Transaction` 리스트를 export 합니다.

DB 전환 후에도 외부 호환을 위해:
- export 포맷은 유지(기존 JSON 구조 그대로)
- import 시에는 DB에 insert
- “구버전 백업 파일”을 계속 읽을 수 있어야 함

즉, 백업/복구는 UI/포맷을 바꾸지 않고도 내부만 DB로 교체 가능합니다.

---

## 월단위 사전집계와의 결합(장기 성능의 핵심)
이미 월 버킷 캐시를 통해 통계는 O(개월 수)로 해결 중입니다.
DB 전환 이후에는 아래가 종착점입니다.
- 거래 추가/수정/삭제 → 해당 `YearMonth`만 dirty
- 화면 진입 시:
  - “합계”는 월 버킷만 읽음(즉시)
  - “상세”는 최근 6개월/선택 월만 DB로 조회

월 버킷 저장소는 현재 SharedPreferences라도 충분히 빠르지만,
장기적으로는 DB 테이블로 옮기면(예: `db_monthly_agg`) 무결성과 복구성이 더 좋아집니다.

---

## 위험요소와 대응
- 데이터 정합성(누락/중복): 마이그레이션 후 계정별 count 검증 필수
- 부동소수점(REAL) 오차: 1차는 유지, 필요 시 cents 정수로 v2 계획
- 성능:
  - 인덱스 없이 범위조회하면 느려짐 → 인덱스 우선
  - 전체 적재/정렬은 금지 → 화면 API를 범위 쿼리로 교체
- 장애 대비:
  - 플래그 기반 롤백
  - SharedPreferences 원본을 일정 기간 보관

---

## 구현 순서(추천)
1) `DbTransactions` 스키마 확장 + 마이그레이션 작성(Drift schemaVersion 업)
2) `DbTransactionStore`(DAO) 작성: insert/update/delete/query(range)
3) `TransactionService`에 저장소 추상화 도입(기존 API 유지)
4) 1회 마이그레이션 서비스 추가 + 플래그 전환
5) FTS 인덱서 소스를 DB로 교체
6) “전체 리스트” 의존 화면부터 범위 쿼리로 순차 전환

---

## 체크 질문(결정이 필요한 2가지)
- 거래 금액을 “정수(cents)”로 바꾸는 v2까지 이번 전환에 포함할지, 아니면 1차는 `REAL`로 빠르게 갈지?
- 마이그레이션 완료 후 SharedPreferences 원본 JSON을 언제 삭제할지(즉시/2버전 후/유저 수동)?
