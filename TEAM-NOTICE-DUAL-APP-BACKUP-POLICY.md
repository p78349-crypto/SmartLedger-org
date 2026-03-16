# [팀 공지 템플릿] 가계부앱/주역앱 비밀번호 저장·복구 정책 적용 안내

배포 이후 고객 환경이 다양하므로, 서버 강제 정책 대신 선택형 정책으로 운영합니다.

## 1) 핵심 정책
- 서버 사용 정책 3가지
  - `required`: 서버 필수
  - `optional`: 서버 선택(기본값)
  - `disabled`: 서버 미사용
- 기본값은 `optional`
- 서버 불가 환경(모바일 단독 포함)에서도 앱 사용 가능해야 함

## 2) 공통 보안 원칙
- 비밀번호 평문 저장 금지(앱/서버/로그)
- 서버에는 검증용 해시만 저장
- DEK와 인증 비밀번호 분리
- DEK를 비밀번호 유도 키/복구키로 각각 래핑 저장
- 복구키 1회 노출 후 재노출 금지

## 3) 앱팀 전달 항목
- 계정 생성 직후 `bootstrap`
- 비밀번호 변경 시 `rotate`
- 복구 화면에 `restoreWithRecoveryKey`
- 설정에서 정책(`required/optional/disabled`) 저장/복원
- 상태 분기
  - `isSuccess`: 정상 진행
  - `isOffline`: 서버 필수 모드 안내
  - `isDisabled`: 선택/미사용 모드 로컬 진행

## 4) 서버팀 전달 항목
- 유지 API
  - `POST /api/ledger/key-backup/bootstrap`
  - `POST /api/ledger/key-backup/recover`
  - `POST /api/ledger/key-backup/rotate`
  - `GET /api/ledger/health`
- 권한키 검증 및 감사로그 유지

## 5) 배포 체크
- 기본값 `optional` 확인
- 서버 오프라인 시 앱 동작 확인
- 복구키 안내/정책 문구 QA 확인

---
작성일: 2026-02-28
