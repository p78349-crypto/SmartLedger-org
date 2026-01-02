## 유틸(날짜/숫자/통화 등) 리팩터링 보고서

작성일: 2025-12-24

요약
- 목적: 코드베이스 전역에 흩어진 날짜/숫자/통화 포맷, 입력 포매터, 작은 UI enum 등의 중복 기능을 중앙 유틸로 통합하여 유지보수성과 일관성을 확보함.
- 범위: `lib/utils` 내부의 유틸을 기준으로 스크린 및 위젯 전역 인라인 사용을 순차적으로 대체함.

주요 변경 사항
- 중앙 유틸 확장
  - `DateFormatter`에 공통 포맷 추가: `defaultDate`, `dateTime`, `dateTimeSeconds`, `monthLabel`, `monthDay`, `shortMonth`, `yearMonth`, `rangeMonth`, `yearKorean`, `dateWithWeekdayTimeSeconds`, `fileNameDate`, `fileNameDateTime`, `mmdd`, `mmddHHmm`.
  - `NumberFormats`에 통화/압축/사용자 패턴 접근기 추가: `currency`, `currencyCompactKo`, `custom(pattern)`.

- 기존 코드 대체
  - 인라인 `DateFormat('...')` 사용을 `DateFormatter.<name>` 으로 대체.
  - 인라인 `NumberFormat('#,###')` 등 패턴을 `NumberFormats.custom('#,###')` 로 대체.
  - 인라인 `NumberFormat('#,##0')` (통화) 를 `NumberFormats.currency` 로 대체.
  - 일부 입력 포매터(`CurrencyInputFormatter` 등)에서 동일한 천단위 포맷을 `NumberFormats.custom` 으로 재사용.

수정한 주요 파일 (예시)
- 유틸: `lib/utils/date_formatter.dart`, `lib/utils/number_formats.dart`, `lib/utils/currency_input_formatter.dart`, `lib/utils/REFACTORING_SUMMARY_2025-12-24.md` 등
- 서비스: `lib/services/chart_data_service.dart`, `lib/services/search_service.dart`
- 스크린/위젯: `lib/screens/account_stats_screen.dart`, `lib/screens/asset_detail_screen.dart`, `lib/screens/asset_tab_screen.dart`, `lib/screens/asset_list_screen.dart`, `lib/screens/root_transaction_manager_screen.dart`, `lib/screens/root_search_screen.dart`, `lib/screens/top_level_main_screen.dart`, `lib/screens/period_detail_stats_screen.dart`, `lib/screens/enhanced_chart_screen.dart`, `lib/screens/memo_stats_screen.dart`, `lib/screens/fixed_cost_stats_screen.dart`, `lib/screens/root_account_screen.dart`, `lib/screens/savings_plan_search_screen.dart`, `lib/widgets/in_app_screen_saver.dart`, `lib/widgets/zero_quick_buttons.dart`, `lib/widgets/comparison_widgets.dart`, `lib/widgets/root_summary_card.dart`, 등 다수

현재 상태
- 현재까지의 자동 대체로 인라인 포맷 사용의 상당 부분을 중앙화했습니다. 전역 검색 결과(마지막 체크 기준) 약 36건의 인라인 `DateFormat`/`NumberFormat` 사용이 남아 있습니다.
- `flutter analyze --no-fatal-infos` 실행 결과: 135개의 이슈가 보고되었습니다. 이들 대부분은 리팩터 과정에서의 임포트, 네이밍(오타), 타입 불일치 등으로 추정됩니다.

남은 작업
1. 남은 인라인 포맷(약 36건) 전수 교체(자동화 스윕 권장).
2. 정적분석 상위 오류(예: 네이밍/임포트 관련) 우선 수정 — 아래 '분석/수정 우선순위' 참고.
3. UI 핵심 경로(거래 입력, 통계, 차트)에 대해 수동 스모크 테스트 수행.
4. 입력 포매터(특히 커서 동작) 단위 테스트 추가.

분석/수정 우선순위
1. 컴파일/분석 오류: 에러 레벨 문제 우선 수정(변수명 오타, 누락된 import). 이는 앱 빌드를 막을 수 있음.
2. 런타임 위험: 포맷 변경으로 인한 문자열 파싱/표시 로직 변경 여부 확인.
3. 사용자 UX: 입력기 커서/삭제 동작의 이상 여부 테스트 및 보완.

테스트 및 검증 가이드
1) 정적분석
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -Command flutter analyze --no-fatal-infos
```
2) 주요 시나리오 수동 확인
- 거래 추가/편집/삭제 화면
- 통계(월별/연별/그래프) 화면
- 자산 세부/내보내기(파일명 포맷) 기능

3) 간단한 로컬 런: (앱이 있는 환경에서)
```powershell
pwsh -NoProfile -Command flutter run -d <deviceId>
```

롤백 방법
- 변경이 문제를 유발하면 Git에서 해당 커밋을 되돌리거나 브랜치를 이용해 롤백하세요.
```bash
git checkout -b revert/utils-refactor-backup
git revert <commit-hash>  # 필요 커밋들을 되돌림
```

개발자용 사용 규칙 (마이그레이션 가이드)
- 날짜 포맷 사용: `DateFormatter.defaultDate.format(date)` 또는 `DateFormatter.formatDate(date)` (유틸에 helper가 있으면 사용).
- 통화 포맷 사용: `NumberFormats.currency.format(value)` 또는 `CurrencyFormatter.format(value)` (기능에 따라).
- 임의 패턴: `NumberFormats.custom('#,###').format(value)`.

예제 (대체 전/후)
- Before:
```dart
final df = DateFormat('yyyy-MM-dd');
final text = df.format(date);
```
- After:
```dart
final text = DateFormatter.defaultDate.format(date);
```

운영 메모
- PR에는 변경된 파일 목록을 요약하여 포함시키고, QA 팀에는 핵심 화면 스모크 테스트를 요청하세요.
- 변경 범위가 넓으므로 작은 단위로 계속 PR을 분할하면 리뷰/롤백이 쉬워집니다.

문의/연락
- 추가 변경을 원하거나 우선적으로 수정할 항목을 지정해 주세요. 저는 남은 전수 스윕과 분석 오류 수정을 계속 진행할 수 있습니다.

-- 끝 --
