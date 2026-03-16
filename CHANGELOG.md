# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2026-03-03

### Changed
- 인증 정책 동시성 제어 강화: `verifyPinWithPolicy()` / `verifyPasswordWithPolicy()` 경로를 서비스 내부 직렬 큐(`_policyQueue`, `_runPolicySerialized`)로 보호.
  - 대상: `UserPinService`, `UserPasswordService`, `RootPinService`, `AssetPinService`, `AssetPasswordService`
- 동시 호출 회귀 테스트 추가: `test/services/auth_policy_concurrency_test.dart`
- 순차 인프라 오케스트레이션 스크립트 추가: `scripts/orchestrate_lifecycle.ps1`
  - 단계: quality → release → ops (또는 full)
  - 운영 단계에 Lock 동시성 스모크 테스트 포함

### Removed
- In-app Screen Saver 기능 전체 삭제 (15개 파일 제거, 13개 파일 참조 정리).
  - 위젯: `in_app_screen_saver*.dart` (7개)
  - 유틸: `screen_saver_launcher.dart`, `screen_saver_ids.dart`, `screen_saver_background_photo.dart`
  - 화면: `root_screen_saver_settings_screen.dart`, `root_screen_saver_exposure_settings_screen.dart`
  - 테스트: `screen_saver_*_test.dart` (3개)
- `AuthScope.screenSaverExit` enum 값 및 `authenticateScreenSaverExit()` 메서드 제거.
- Screen Saver 관련 PrefKeys 15개 및 정책 리셋 목록 정리.
- 라우트 `/root/screen-saver-settings`, `/root/screen-saver-exposure-settings` 제거.
- 아이콘 그리드 `_ensureScreenSaverShortcut()` 자동삽입 로직 제거.

### Validation
- `flutter analyze` 에러 0건.
- lib/ 내 `screen_saver|ScreenSaver|screenSaver` grep 결과 0건.
- 동시성 타깃 테스트 `flutter test test/services/auth_policy_concurrency_test.dart` 2건 통과.
- 전체 회귀 `flutter test` 1325건 통과.
- 오케스트레이터 검증: `-Stage full -DryRun` 정상, `-Stage ops -SkipProjectBackup` 실실행 통과.

## [Unreleased] - 2026-02-28

### Added
- Asset credential isolation services: `AssetPinService`, `AssetPasswordService`.
- Asset 전용 현재 자격 증명 확인 다이얼로그 추가 (`_verify_current_asset_pin_dialog.dart`, `_verify_current_asset_password_dialog.dart`).

### Changed
- 보안 구조 확정: 생체인식(지문/얼굴)은 공통 기기 인증 사용, PIN/비밀번호는 `ROOT`/`USER`/`ASSET` 완전 분리.
- 자산 인증 흐름을 사용자 저장소 의존에서 자산 저장소 의존으로 전환.
- 사용자/자산 인증 게이트를 ROOT와 동일한 단일/2중 인증 패턴으로 정렬.
- 메인 아이콘 그리드 표시 순서를 한손 접근성 기준으로 조정(하단 2번째 줄 우선, 맨 하단 줄 마지막).
- 아이콘 관리 화면의 드롭존/편집 슬롯/현재 배치 표시 순서를 메인 그리드와 동일 정책으로 동기화.
- 아이콘 이동은 표시 순서와 저장 index를 분리해 처리하도록 정렬 정책을 고정(기존 슬롯 데이터 호환 유지).
- AI 투자 분석 화면 진입 시 강제 고지/동의 게이트를 추가하고, 미동의 시 화면 진입을 차단.
- 설정 화면에 투자 분석 동의 기록(상태/시각/버전/로케일) 조회 및 초기화 기능 추가.

### Documentation
- 보안 정본 문서(`보안.md`)를 ROOT/USER/ASSET 분리 아키텍처 기준으로 갱신.
- 사용자 매뉴얼 보안 범위 문구 및 백업 제외 항목(비밀번호 포함) 갱신.
- 문서 인덱스(`docs/README.md`, `docs/policies/README.md`, `docs/developer/README.md`)에 보안 정본 링크/요약 정책 반영.
- 아이콘 단일 정책 문서에 2026-02-28 아이콘 이동 정렬 정책(4-C) 및 진단 체크 항목(E) 추가.
- 투자 분석 동의 운영 가이드 문서(`docs/policies/AI_INVESTMENT_CONSENT_OPERATION_KO.md`) 추가 및 인덱스 연결.
- 배포 체크리스트에 투자 분석 법적 고지 E2E 5단계 테스트 카드 추가.

### Validation
- `flutter analyze` 통과.
- `flutter build apk --release` 성공.
- `flutter install --release -d R5CT60Q5FYR` 성공.
- `flutter analyze --no-fatal-infos` 재검증 통과 (동의 게이트/설정 관리 반영 후).

### Closeout
- 아이콘 이동 정책 문서 반영 완료: `docs/policies/ICON_MANAGEMENT_SINGLE_SOURCE_KO.md` (4-C, 6-E).
- 릴리즈 문서 동기화 완료: `RELEASE_DRAFT.md`, `TODO.md`, `docs/work-logs/AI_WORK_LOG_2026-02-28.md`.
- 최종 압축 백업 완료: `SmartLedger_backup_2026-02-28_115846.zip` 생성.
- Android 릴리즈 서명 검증 완료: 환경변수(`SLD_STORE_PASSWORD`, `SLD_KEY_PASSWORD`) 기반 서명으로 `app-release.aab` 재빌드 및 SHA-256 확인.

## [Unreleased] - 2026-02-24

### 📋 AI Agent 작업 상세 기록 (AI_WORK_LOG_RULES 준수)

#### 1. 🔄 작업 절차 (Procedure)
1. 아이콘 관리 스모크 테스트 추가 (18개 테스트 케이스)
2. 아이콘 관리 화면 UI 개선 (녹색 선택 표시)
3. 아이콘 관리를 자산(page 4)에서 설정(page 6)으로 이동
4. 페이지별 기본 아이콘 순서 설정 (사용자 스크린샷 기준)
5. 기본아이콘/전체아이콘 버튼 기능 구현
6. 전체 테스트 실행 및 품질 검증

#### 2. 🎯 문제 발견 위치 (Problem Location)
- **파일**: `lib/screens/icon_management_screen_build.dart`
- **위치**: `_photoTopBoxButton()` 탭 버튼 onTap 핸들러
- **원인**: 기본아이콘/전체아이콘 버튼이 단순 탭 전환만 수행, 실제 아이콘 선택 리셋 기능 없음

#### 3. 🛠️ 수정 파일 및 내용 (Modified Files & Changes)

##### `lib/screens/icon_management_screen_build.dart`
- [추가] `_onDefaultIconsTabTap()`: 기본 아이콘 세트로 `_pendingIds` 리셋
- [추가] `_onAllIconsTabTap()`: 모든 아이콘을 `_pendingIds`에 추가
- [변경] 선택 표시 색상을 `Colors.green.shade600`으로 통일 (테두리 + 체크마크)

##### `lib/screens/icon_management_settings_screen.dart` (신규 생성)
- 설정 페이지(page 6) 전용 아이콘 관리 화면
- `IconManagementRootScreen`과 동일 구조, `initialPageIndex: 6`

##### `lib/utils/main_feature_icon_catalog_stats_settings.dart`
- **kStatsPageItems (Page 3)**: 검색 → 통계 → 주간 → 월간 → 분기 → 반기 → 연간 → 고정비 → 지출분석
- **kAssetPageItems (Page 4)**: 간편입력 → 자산목록 → 자산분석 → 내보내기 → 자산배분
- **buildSettingsItems (Page 6)**: `백업` → `RootBackup` 라벨 변경
- icon_management_asset_entry 제거, icon_management_settings_entry 추가

##### `lib/utils/main_feature_icon_catalog_purchase_income.dart`
- **kPurchasePageItems (Page 1)**: 간편지출 → 요리레시피 → 장바구니 → 거래입력 → 오늘의지출 → WMS입출고 → WMS재고관리 → WMS도움말

##### `lib/navigation/app_routes_paths.dart`
- [추가] `iconManagementSettings = '/icon-management/settings'`

##### `lib/navigation/app_router_settings.dart`
- [추가] `iconManagementSettings` 라우트 핸들러

##### `docs/policies/ICON_MANAGEMENT_SINGLE_SOURCE_KO.md`
- §4-1: 앱 재시작 필요 경고 추가
- §10: 스모크 테스트 결과 기록

##### `test/smoke/core_flows_smoke_test.dart`
- [추가] 18개 아이콘 ENT 스모크 테스트 (페이지 0~14)

#### 4. ✅ 현재 상태 (Current Status)
- `flutter analyze`: 오류 0, 경고 0, info 3 (테스트 파일만)
- `flutter test`: **1,310개 테스트 100% 통과**
- `flutter build apk --release`: 빌드 성공 (105.4MB)
- 기기 설치 완료

#### 5. ⚠️ 잔여 이슈 및 권장 사항 (Recommendations)
- ENT 적용 후 **앱 재시작 필요** (문서화 완료)
- Page 2 (수입) 기본 아이콘 순서는 사용자 스크린샷 미제공으로 기존 유지
- 실제 기기에서 각 페이지 기본 아이콘 레이아웃 확인 권장

---

### Added
- 아이콘 관리 스모크 테스트 18개 (페이지 0~14 ENT 검증)
- `IconManagementSettingsScreen`: 설정 페이지 전용 아이콘 관리
- 기본아이콘 버튼: 해당 페이지 기본 아이콘만 선택
- 전체아이콘 버튼: 숨겨진 아이콘까지 모두 선택

### Changed
- 아이콘 선택 UI: 녹색 테두리 + 녹색 체크마크
- 아이콘 관리 위치: 자산(page 4) → 설정(page 6)
- 페이지 0~6 기본 아이콘 순서 사용자 지정 레이아웃으로 변경
- 설정 페이지 `백업` → `RootBackup` 라벨 변경

### Removed
- 자산 페이지(page 4)에서 아이콘 관리 진입점 제거

---

## [Unreleased] - 2025-12-30

### Added
- Icon repository: added 12 sample custom SVG icons (`assets/icons/custom/icon_01.svg` ... `icon_12.svg`).
- Icon manifest: `assets/icons/metadata/icons.json` expanded with new entries.
- Validation: added `tools/validate_icons.py` and `tools/validate_icons.ps1` to verify catalog ↔ manifest ↔ assets.
- CI: GitHub Actions workflow `.github/workflows/validate-icons.yml` runs icon validation + `flutter test` on push/PR.

### Changed
- `pubspec.yaml` updated to include new SVG assets and manifest.
- `docs/ICON_REPO_GUIDE.md` clarifications and CI instructions added.
- Smart Ledger input field prototype: `lib/widgets/smart_input_field.dart` and transaction screen updates.
- Documentation: refreshed Smart Ledger main-screen references (`tools/LEGACY_USER_MAIN_LOCATION.md`, `tools/INDEX_CODE_FEATURES.md`) and recorded design checklist status for `SmartInputField` rollout.

### Notes
- Image processing performance optimizations (Isolate/compute) are scheduled after design/icon work is finalized.

## [Unreleased] - 2026-01-08

### Changed
- Shopping recommendations: apply household activity trend ratio (short vs baseline) to suggested quantities, with clamped scaling and memo note.
- Quick stock use: apply the same activity ratio to auto-added “imminent depletion” shopping items.

### Notes
- 2026-01-09 checkpoint: `lib/**/*.dart` has 0 lines over 80 chars; `flutter analyze` reports no issues; import-style work continues (next: mixed import style cleanup).

## [Unreleased] - 2026-01-09

### Added
- Food expiry dashboard auto-refresh mixin: standardized item-change refresh behavior across widgets.
- Daily recipe recommendation builder utils: standardized recommendation result construction.

### Changed
- Expiring ingredients utils: generalized “within 3 days” filtering to “within N days” and retained backwards-compatible wrapper.
- Auto-refresh mixin: added small debounce (default 250ms) to reduce repeated recompute on rapid updates.
- Recipe knowledge data: prevent repeated concurrent asset loads by guarding `RecipeKnowledgeService.loadData()`.
