# [팀 공지] 가계부앱/주역앱 비밀번호 저장·복구 정책 적용 안내

배포 이후 고객 환경이 다양하므로, 서버 강제 정책을 사용하지 않고 선택형 정책으로 운영합니다.

## 1) 핵심 정책

- 서버 사용 정책은 3가지 중 선택
  - `required` : 서버 필수
  - `optional` : 서버 선택(기본값)
  - `disabled` : 서버 미사용
- 기본값은 `optional`
- 서버 불가 환경(모바일 1대 단독 포함)에서도 앱 사용 가능해야 함

## 2) 공통 보안 원칙

- 비밀번호 평문 저장 금지(앱/서버/로그)
- 서버에는 비밀번호 해시만 저장
- 데이터키(DEK)는 비밀번호/복구키로 래핑하여 저장
- 복구키는 1회 노출 후 재노출 금지

## 3) 가계부앱 전달 항목

- 계정 생성 직후 `bootstrap` 호출
- 비밀번호 변경 시 `rotate` 호출
- 복구 화면에서 `restoreWithRecoveryKey` 제공
- 설정 화면에서 서버 정책(`required/optional/disabled`) 저장/복원
- 상태 분기 처리
  - `isSuccess` : 정상 진행
  - `isOffline` : 서버 필수 모드에서 안내
  - `isDisabled` : 선택/미사용 모드에서 로컬 진행

## 4) 주역앱 전달 항목

- 가계부앱과 동일한 보안/복구 구조 재사용
- 앱 톤에 맞는 복구키 안내 문구 적용
- 서버 선택 모드(`optional`/`disabled`)에서 로컬 사용 허용
- 배포 전 공용 E2E 점검 1회 이상 수행

## 5) 서버팀 전달 항목

- 유지 API
  - `POST /api/ledger/key-backup/bootstrap`
  - `POST /api/ledger/key-backup/recover`
  - `POST /api/ledger/key-backup/rotate`
  - `GET /api/ledger/health`
- 권한키 검증 및 감사로그 유지

## 6) 배포 체크

- 설정 기본값 `optional` 확인
- 서버 오프라인 시 앱 동작 확인(클레임 방지)
- 복구키 안내 문구/정책 문구 QA 확인

## 7) 참고 문서

- 통합 운영 가이드: `DUAL-KEY-BACKUP-USAGE.md`
- 앱별 체크리스트: `DUAL-APP-PASSWORD-RECOVERY-CHECKLIST.md`
- 앱 README: `WMS_VALUE/EXTRACTED/README.md`
- 서버 README: `mobile-approval-server/README.md`

---
작성일: 2026-02-28
