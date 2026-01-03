# WORK LOG — 작업 기록

- 목적: 인덱스(구조/지도)와 별도로, “무엇을 왜/어떻게 바꿨는지” 작업 이력을 날짜별로 남깁니다.
- 원칙: 기능 동작 변경이 있으면 인덱스(tools/INDEX_CODE_FEATURES.md)도 같이 갱신합니다.

---

## TL;DR (빠른 사용법)

### 작업 종료 루틴(인덱스 기록 습관)

- 새 기록을 남길 때: VS Code → `Tasks: Run Task` → `End of work: INDEX 기록(추가→검증→내보내기)`
- 새 기록(파일 자동)로 남길 때: VS Code → `Tasks: Run Task` → `End of work: INDEX 기록(자동파일→검증→내보내기)`
- 기록은 이미 했고 점검만 할 때(무프롬프트): VS Code → `Tasks: Run Task` → `End of work: INDEX 검증+내보내기(무프롬프트)`
- 최소 입력 권장값(인덱스 입력창): `What/Why/Verify/Tests/Files`
- 실패하면(검증 실패/내보내기 실패) 그 즉시 고치고 다시 실행

- 순서(요약→위치→내용)
  - 1) 아래 Summary 표로 “언제/무엇” 확인
  - 2) 해당 날짜 섹션(예: `## 2025-12-18`)로 이동
  - 3) “몇 줄인지(라인)”가 필요하면 헤더 라인번호를 즉시 조회

- 헤더 라인번호 조회(권장): `pwsh -File tools/locate_md_headings.ps1 tools/WORK_LOG.md`
- 구조/라우트/Args 지도는 INDEX에서 확인: tools/INDEX_CODE_FEATURES.md

---

## ENTRY TEMPLATE (복붙용)

> “문제 생겼을 때 바로 재현/추적/롤백” 할 수 있게 기록.

### 요약(1~3줄)
- 무엇을 바꿈 / 왜 바꿈 / 사용자 영향

### 배경/증상(있으면)
- 증상:
- 재현 단계(최소 3단계):
- 기대 동작 vs 실제 동작:

### 변경 내용(핵심)
- 변경 요약:
- 영향 범위(라우트/Args/저장소/UI/서비스):

### 변경 파일(링크/목록)
- 예) lib/..., tools/...

### 검증(필수)
- 실행한 명령 + 결과:
- 기기/환경:

### 롤백/대안(선택)
- 되돌리는 방법(커밋이 없으면 “어떤 파일/어떤 라우트” 되돌리면 되는지):

### 참고/결정(선택)
- 선택지/트레이드오프/남은 TODO:

## Summary (1-line per entry)

| Date | What | Verified |
|---|---|---|
| 2025-12-29 | 계정명: 언어 태그(EN/JP/KR) 강제 삽입 + 복원은 새 계정만 | analyze OK / INDEX validate OK |
| 2025-12-20 | 메인 15페이지 고정/배너 번호만 + 아이콘관리 막힘 방지(다음 빈 슬롯 안내) + 설정 재구성(초기화 하단) + 언어설정 분리/시작 반영 | (권장) Quality Gate OK |
| 2025-12-20 | (기반) 1페이지 전체 광고 오버레이 게이트 추가(기본 비노출, 비정식 사용자만 노출 + 터치로 닫기) | analyze OK |
| 2025-12-18 | (LEGACY) Smart Ledger(QuickActions) 시작 고정 + 상단 `+` 제거 + 상단 햄버거(설정 통합) + 인덱스/작업로그 최적화 + (내 자산 흐름) 통계/지출 분리 유틸 추가 | analyze OK / build apk OK |
| 2025-12-18 | QuickActions 완전 삭제(라우트/진입점/상태/PrefKeys/관련 파일·테스트) + 문서(인덱스/로그) 기록 보강 | analyze OK / build apk OK / install OK |
| 2025-12-18 | AccountMainScreen 모든 UI 삭제(사진 기준: 요약 카드/AppBar 제거) | (권장) analyze / 앱 실행 확인 |
| 2025-12-18 | (REMOVED) smart_quick_actions_view.dart 파일 삭제(잔재 정리) | analyze OK |

---

## 2025-12-29

### 요약(1~3줄)
- 계정명 입력 아래에 “언어 태그가 강제 삽입됨” 안내 + 최종 계정명 프리뷰 표시.
- 실제 저장되는 계정명에도 locale 기반 suffix(`EN/JP/KR`)를 강제로 적용(중복 삽입 방지).
- 복원은 “항상 새 계정으로만” 수행되도록 UI/호출 경로를 새 계정 복원 API로 통일.

### 배경/의도
- 언어 전환/복원 과정에서 계정 경계를 눈에 보이게 하여 데이터 혼합(덮어쓰기/병합) 위험을 줄이기 위함.

### 변경 내용(핵심)
- `AccountNameLanguageTag` 유틸 추가
  - locale → 국제 표기 코드: `en→EN`, `ja→JP`, `ko→KR` (기타는 대문자)
  - suffix는 선행 공백 포함(예: `My Account EN`)
  - 이미 suffix가 붙어 있으면(대소문자 무시) 중복 삽입 방지

- UI 적용 지점
  - 계정 생성 화면/다이얼로그: 계정명 아래 안내 + 최종 계정명 프리뷰 + 저장 시 강제 적용
  - 백업 복원(파일/새 계정): 새 계정명 입력 시 동일 적용, 복원 호출은 새 계정 복원 API로 고정
  - 휴지통 계정 복원: 새 계정명 입력 시 동일 적용, 복원은 새 계정 복원 API로 고정

### 변경 파일(주요)
- lib/utils/account_name_language_tag.dart
- lib/screens/account_create_screen.dart
- lib/screens/root_account_manager_page.dart
- lib/screens/backup_screen.dart
- lib/screens/trash_screen.dart
- lib/services/backup_service.dart

### 검증(필수)
- flutter analyze: OK
- Validate INDEX format (PowerShell): OK

---

## 2025-12-20

### 요약(1~3줄)
- 출시 안정성을 위해 메인 페이지 구조를 15페이지로 고정하고, 상단 배너는 “번호만” 표시하도록 단순화.
- 아이콘 관리 화면에서 “빈 슬롯이 없어서 추가가 막히는” 케이스를 막기 위해 다음 빈 슬롯 페이지 안내/이동 UX를 추가.
- 설정 화면은 아이콘/진입점 중심으로 정리하고, 페이지/아이콘 초기화는 섹션 맨 아래로 배치. 언어 설정은 분리 화면으로 독립 저장/관리하며 앱 시작 시 로케일에 반영.
- (기반) 1페이지에 전체 광고 오버레이 구조를 미리 추가(기본 비노출). 비정식 사용자일 때만 노출하며 터치로 닫힘(세션 1회).

### 배경/증상(있으면)
- 증상: 아이콘 추가 시 빈 슬롯이 없으면 사용자가 다음 행동을 결정하기 어려움(막힘).
- 목표: “페이지는 틀(불변), 기능은 아이콘(바로가기)” 원칙을 지키면서 출시 후 구조 변경 리스크를 최소화.

### 변경 내용(핵심)
- 메인 페이지/배너
  - pageCount를 15로 고정하고, 배너는 라벨 대신 번호만 표시.
- 1페이지 전체 광고(기반)
  - 1페이지에서만 전체 오버레이 광고 구조를 추가(기본 OFF). 비정식 사용자일 때만 노출, 터치로 닫힘(세션 1회).
- Preferences(SSOT)
  - 기본 페이지 구성/정규화는 `UserPrefService` 중심으로 유지(문자열 교체/기본값 변경이 1곳에서 가능하도록).
- 아이콘 관리(막힘 방지)
  - 현재 페이지에 빈 슬롯이 없으면, 다음으로 빈 슬롯이 있는 페이지를 탐색해 이동 버튼/스낵바 액션으로 안내.
- 설정/언어
  - “초기화(리셋)” 계열은 페이지/아이콘 섹션 맨 아래로 내리고, 언어는 전용 화면으로 분리.
  - 저장된 언어 값은 앱 시작 시 Intl 로케일 초기화에 반영.

### 변경 파일(주요)
- lib/screens/account_main_screen.dart
- lib/widgets/page_banner_bar.dart
- lib/widgets/page1_fullscreen_ad_overlay.dart
- lib/services/user_pref_service.dart
- lib/utils/pref_keys.dart
- lib/screens/icon_management_screen.dart
- lib/screens/settings_screen.dart
- lib/screens/language_settings_screen.dart
- lib/navigation/app_routes.dart
- lib/navigation/app_router.dart
- lib/main.dart
- lib/utils/main_feature_icon_catalog.dart
- lib/utils/icon_launch_utils.dart

### 검증(필수)
- 권장(SSOT): VS Code task `Quality Gate (analyze + test + INDEX)` → 마지막 마커가 `=== QUALITY_GATE_OK ===` 인지 확인
- 최소: `flutter analyze` + `flutter test` + `Validate INDEX format (PowerShell)`

---

## 2025-12-18

> (LEGACY) 이 항목은 당시 “QuickActions를 메인으로 만들던 작업” 기록입니다.
> 현재 상태는 같은 날짜의 아래 “QuickActions 완전 삭제” 항목이 최신이며, 문제 발생 시 최신 항목을 우선 참고하세요.

### 요약
- 앱 첫 실행/복귀 시 “Smart Ledger(QuickActions)” 화면만 보이도록 시작 진입을 고정하고, 다른 메인(TopLevel/레거시)이 끼어드는 케이스를 차단.
- Smart Ledger 메인 UI를 PageView + dots + 섹션 타이틀 형태로 고정 렌더링.
- 상단 `+` 버튼 제거.
- 우측 상단 햄버거 메뉴 추가 + 설정 진입을 메뉴로 통합.
- “내 자산 흐름” 통계 계산을 utils로 분리(AssetMove 기반 inflow/outflow).
- 문서(인덱스/Change Log) 갱신.

### 변경 포인트
- 시작/라우팅
  - LaunchScreen 신설 및 시작 시 QuickActions로 pushReplacement.
  - 루트 라우트(`/`)가 다른 메인으로 연결되는 케이스를 차단(항상 LaunchScreen으로 진입).

- UI
  - SmartQuickActionsView: 메인 UI를 “페이지 스와이프 + 하단 점(dots) + 섹션 타이틀”로 고정.
  - 상단 `+` 제거.

### 영향 파일(주요)
- lib/screens/launch_screen.dart
- lib/main.dart
- lib/navigation/app_router.dart
- lib/widgets/smart_quick_actions_view.dart
- lib/utils/asset_flow_stats.dart
- tools/INDEX_CODE_FEATURES.md

### 검증
- flutter analyze: OK (Exit Code 0)
- flutter build apk: OK (Exit Code 0)

---

## 2025-12-18 — QuickActions 완전 삭제(최신)

### 요약
- QuickActions 기능을 앱에서 완전히 제거(라우트/진입점/상태/PrefKeys/관련 파일/테스트)하여 “메인 흐름”을 단순화.
- 앱 시작 흐름은 `(/) → LaunchScreen → accountMain` 기준으로 고정.

### 변경 내용(핵심)
- 라우트 제거: `/quick-actions` 및 `AppRoutes.quickActions` 사용 경로 제거
- 진입점 제거: 버튼/아이콘/FAB/자동 진입 흐름에서 QuickActions로 이동하던 코드 제거
- 상태/저장소 정리: QuickActions 관련 Provider/PrefKeys 제거
- 레거시 구현은 “기록 목적”으로만 남기고, 현재 동작에는 영향을 주지 않게 문서에 `Legacy / REMOVED`로 표기

### 변경 파일(주요)
- lib/navigation/app_routes.dart
- lib/navigation/app_router.dart
- lib/screens/launch_screen.dart
- lib/screens/account_main_screen.dart
- lib/utils/pref_keys.dart
- tools/INDEX_CODE_FEATURES.md

### 검증
- flutter analyze: OK
- flutter clean; flutter build apk --release: OK
- flutter install: OK

---

## 2025-12-18 — AccountMainScreen 모든 UI 삭제(사진 기준)

### 요약
- 사용자 제공 캡처 기준으로, 메인 화면(accountMain)에 남아있던 요약 카드 등 **모든 UI를 제거**하여 의도적으로 “빈 화면”만 보이도록 변경.

### 변경 내용(핵심)
- `AccountMainScreen`에서 AppBar 제거
- 요약 카드/콘텐츠 UI 제거
- Body를 `ColoredBox(surface)` + `SizedBox.expand()`로 변경

### 영향 범위
- 기본 메인 진입 경로: `(/) → LaunchScreen → accountMain`

### 변경 파일(주요)
- lib/screens/account_main_screen.dart
- tools/INDEX_CODE_FEATURES.md
- tools/WORK_LOG.md

### 검증
- (권장) flutter analyze
- (권장) 앱 실행 후 accountMain 진입 시 UI가 완전히 비어있는지 확인

---

## 2025-12-18 — (REMOVED) smart_quick_actions_view.dart 파일 삭제

### 요약
- QuickActions 기능 완전 삭제 이후에도 남아있던 레거시 UI 파일(`lib/widgets/smart_quick_actions_view.dart`)을 **실제 삭제**하여 잔재를 제거.

### 변경 내용(핵심)
- `lib/widgets/smart_quick_actions_view.dart` 삭제

### 영향 범위
- 현재 코드에서 import/사용되지 않는 파일 정리(동작 영향 없음)

### 검증
- flutter analyze: OK
