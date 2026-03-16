# 키백업/복구 공용 E2E 런북 (앱 + 서버)

- 작성일: 2026-02-28
- 대상: SmartLedger 앱 + mobile-approval-server
- 목적: `bootstrap → recover → rotate → recover`를 운영 환경과 유사하게 재현 검증

## 1) 사전 준비

- 서버 기동
  - `cd .\mobile-approval-server`
  - `python .\app.py`
- 서버 헬스 확인
  - `Invoke-RestMethod -Method Get -Uri "http://127.0.0.1:8787/api/ledger/health"`
- 앱 서버 설정
  - 주소: `http://127.0.0.1:8787`
  - 관리자 키: 운영/테스트 키 입력
  - 키백업 정책: `required` 또는 `optional`

## 2) E2E 시나리오

### STEP A. bootstrap
1. 앱에서 새 계정 생성 + 비밀번호 설정
2. bootstrap 호출 성공 확인
3. 복구키 1회 표시 확인 및 안전 저장

기대 결과:
- 서버: bootstrap 2xx
- 앱: 성공 안내 + 복구키 표시

### STEP B. 비밀번호 복구(recover with password)
1. 동일 계정으로 `restoreWithPassword` 실행
2. 성공 응답 확인
3. 로컬 DB 키 반영 성공 확인

기대 결과:
- 서버: recover 2xx
- 앱: 복구 성공, 로컬 키 적용 오류 없음

### STEP C. 비밀번호 변경(rotate)
1. 설정 > 비밀번호 변경
2. 현재 비밀번호 검증 통과
3. 새 비밀번호 설정 후 rotate 호출 성공 확인

기대 결과:
- 서버: rotate 2xx
- 앱: 비밀번호 변경 완료 + 서버 동기화 성공

### STEP D. 복구키 복구(recover with recovery key)
1. 서버 설정 화면에서 복구키 복구 실행
2. 계정 ID + 복구키 입력
3. 성공 응답 및 로컬 DB 키 반영 확인

기대 결과:
- 서버: recover 2xx
- 앱: 복구 성공 메시지 + 로컬 키 적용 성공

## 3) 장애 시나리오

- 잘못된 관리자 키 → `403`
- 미등록 계정 → `404`
- payload 계정 불일치 → `400`
- 서버 중단/단절
  - `required`: 오프라인 차단/안내
  - `optional`: 로컬 모드 진행

## 4) 결과 기록 템플릿

| 항목 | 결과(PASS/FAIL) | 비고 |
|---|---|---|
| A bootstrap |  |  |
| B recover(password) |  |  |
| C rotate |  |  |
| D recover(recovery key) |  |  |
| 403 처리 |  |  |
| 404 처리 |  |  |
| 400 처리 |  |  |
| offline 처리(required/optional) |  |  |

## 5) 합격 기준

- 핵심 4단계(A~D) 모두 PASS
- 403/404/400/offline 처리 모두 정책대로 동작
- 치명 오류(앱 크래시/키 반영 실패/데이터 접근 불가) 0건

## 6) 관련 문서

- [DUAL-KEY-BACKUP-USAGE.md](../../DUAL-KEY-BACKUP-USAGE.md)
- [DUAL-APP-PASSWORD-RECOVERY-CHECKLIST.md](../../DUAL-APP-PASSWORD-RECOVERY-CHECKLIST.md)
