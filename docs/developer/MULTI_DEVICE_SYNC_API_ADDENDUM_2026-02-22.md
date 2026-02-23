# 앱 개발팀 전달 사항 (추가)

다중 기기 동기화 완성도를 높이기 위한 추가 API 사용 가이드입니다.

## 추가 동기화 API 안내

### 1) 데이터 내려받기 (Pull)
- **호출 시점:** 앱 시작 시, 또는 사용자가 동기화 버튼 클릭 시
- **엔드포인트:** `GET /api/ledger/sync/pull?last_updated=<마지막동기화시간>`
- **동작:** 서버의 최신 변경분(Delta)만 내려받아 로컬 Drift DB에 병합(Upsert)
- **권장 구현 포인트:**
  - 로컬에 저장한 마지막 동기화 시각(UTC ISO8601)을 `last_updated`로 전송
  - 응답 레코드는 PK 기준 Upsert, 서버에서 삭제된 데이터는 tombstone(`isDeleted`) 처리
  - 병합 완료 후에만 `lastSyncAt` 갱신

### 2) 다른 테이블 올리기 (Push)
- **트랜잭션 외 테이블 전송 시 규칙:** URL에 테이블 이름을 명시
- **예시 엔드포인트:**
  - `POST /api/ledger/sync/push/assets`
  - `POST /api/ledger/sync/push/fixed-costs`
  - `POST /api/ledger/sync/push/memos`
- **동작:** 해당 테이블의 로컬 변경분(Delta)을 서버로 전송
- **권장 구현 포인트:**
  - 배치 단위 전송 + 부분 실패 재시도
  - 성공 항목만 `isSynced=true` 갱신
  - 충돌 시 `updatedAt` 기준 최신본 우선 또는 서버 정책에 맞춘 재조정

### 3) 인증
- **필수 헤더:** `X-Admin-Key`
- **적용 범위:** 이번에 추가된 Pull/Push API 포함, 기존 Sync API 전부 동일

```http
X-Admin-Key: <admin_key>
```

## 앱 구현 체크리스트
- [ ] 앱 시작 진입점에서 Pull 수행
- [ ] 수동 동기화 버튼에서 Pull 재실행
- [ ] 테이블별 Push 라우팅 적용 (`/push/{table}`)
- [ ] `X-Admin-Key` 공통 헤더 주입
- [ ] Pull/Push 실패 재시도 및 사용자 알림 처리
- [ ] 마지막 동기화 시각(`lastSyncAt`) 저장/갱신 일관성 유지
