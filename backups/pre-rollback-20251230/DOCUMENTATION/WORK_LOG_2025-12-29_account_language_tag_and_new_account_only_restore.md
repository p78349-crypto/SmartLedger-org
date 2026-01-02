# Work Log — 2025-12-29

## Summary
- 계정명 입력 시(생성/복원) **계정명 아래에 언어 태그가 강제 삽입됨**을 표시하고, 실제 저장되는 계정명에도 suffix를 강제 적용.
- 언어 태그는 국제 표기(예: `EN`, `JP`, `KR`) 기반으로 통일.
- 복원은 “항상 새 계정으로만” 진행되도록 UI/호출 경로를 정리(덮어쓰기/혼합 경로 제거).

## Context / Goal
- 언어 전환/복원 과정에서 데이터 혼합(덮어쓰기/병합) 위험을 최소화하고, 계정 경계를 눈에 보이게 유지.
- “복원은 새 계정으로만”이라는 설계 의도를 코드 레벨에서 유지.

## Changes

### 1) 계정명 suffix 유틸 추가
- `lib/utils/account_name_language_tag.dart`
  - `suffixForLocale(Locale)`
    - `en` → ` EN`, `ja` → ` JP`, `ko` → ` KR` (기타는 languageCode를 대문자 처리)
    - 선행 공백을 포함하여 읽기/구분을 자연스럽게 함(예: `My Account EN`).
  - `applyForcedSuffix(baseName, locale)`
    - 입력값 trim
    - suffix가 이미 붙어 있으면(대소문자 무시) 중복 삽입 방지

### 2) 계정 생성 시 “강제 삽입” 안내 + 최종 계정명 프리뷰
- `lib/screens/account_create_screen.dart`
  - 계정명 입력 TextField 아래에 안내 문구 + “최종 계정명” 프리뷰 표시.
  - 저장 시에도 `applyForcedSuffix` 결과를 실제 계정명으로 사용.

- `lib/screens/root_account_manager_page.dart`
  - ROOT 계정 생성 다이얼로그에서도 동일한 안내/프리뷰/강제 저장 적용.

### 3) 복원(백업/휴지통)도 “새 계정으로만” + suffix 강제
- `lib/screens/backup_screen.dart`
  - 새 계정으로 복원 다이얼로그에서 동일한 안내/프리뷰/강제 suffix 적용.
  - 파일 선택 복원 흐름에서도 “새 계정명 입력 → 새 계정으로 복원”으로 통일.

- `lib/screens/trash_screen.dart`
  - 휴지통의 계정 복원에서도 새 계정명 입력 시 안내/프리뷰/강제 suffix 적용.
  - 복원 호출은 `importAccountDataAsNew(encoded, confirmedName)`로 고정하여 덮어쓰기 경로 제거.

### 4) 서비스 레벨: 새 계정 복원 API만 사용
- `lib/services/backup_service.dart`
  - 새 계정 복원은 `importAccountDataAsNew(jsonStr, newAccountName)`로만 수행.
  - 복원 후 해당 계정을 `lastAccountName`으로 선택하고, backupMeta(마지막 백업 시각 등)도 계정별로 복원.

## Validation
- VS Code task: `flutter analyze (no fatal infos)` → `No issues found!`
- VS Code task: `Validate INDEX format (PowerShell)` → `INDEX format validation passed.`
- 참고: `Check long lines (lib dart >80)`는 `lib/utils/nutrition_report_utils.dart`의 기존 장문 라인으로 실패(이번 변경과 무관).

## Notes / Follow-ups
- 본 변경은 “기능 완성 전 과강제는 피한다”는 범위 내에서, 데이터 혼합 리스크를 줄이는 최소 강제(계정명 suffix + 새 계정 복원만)를 적용한 상태.
