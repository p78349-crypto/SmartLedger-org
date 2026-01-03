# INDEX (Parent) — Quick File Map

목적: 작업 시작/검색 전에 “어디를 보면 되는지”를 10초 안에 결정.

사용 흐름(권장)
- 1) 여기서 파일 후보를 고른다
- 2) 바로 아래의 Jump로 자식 인덱스로 이동한다
- 3) 그 파일/폴더 범위에서만 검색(Select-String/VS Code Search)

유지 규칙(비대화 방지)
- Parent에는 “자주 여는 파일”만 유지(영역당 3~10개 선).
- 덜 자주 쓰는 파일은 Parent에 추가하지 말고 Child에서만 키워드로 관리.
- Parent에서 항목을 추가했다면, 같은 날 Child에 검색 단서 3개 이상도 함께 추가.

---

## Quick List

| Area | File | 1-line Summary | Jump (Child) |
|---|---|---|---|
| App entry / routing | lib/main.dart | 앱 시작점 + LaunchScreen 고정 진입 | tools/INDEX_CHILD.md#libmaindart |
| App entry / routing | lib/screens/launch_screen.dart | 스플래시→마지막 계정 확인→accountMain 이동 | tools/INDEX_CHILD.md#libscreenslaunch_screendart |
| Navigation | lib/navigation/app_routes.dart | 라우트 문자열 + Args 타입 정의 | tools/INDEX_CHILD.md#libnavigationapp_routesdart |
| Navigation | lib/navigation/app_router.dart | onGenerateRoute 중앙 라우팅(Args 캐스팅 포함) | tools/INDEX_CHILD.md#libnavigationapp_routerdart |
| Main UI | lib/screens/account_main_screen.dart | 메인(ONE UI) 페이지/아이콘 그리드 | tools/INDEX_CHILD.md#libscreensaccount_main_screendart |
| Shopping | lib/screens/shopping_cart_screen.dart | 장바구니(체크+물품명+거래추가+삭제) + 쇼핑 준비 | tools/INDEX_CHILD.md#libscreensshopping_cart_screendart |
| Icon management | lib/screens/icon_management_screen.dart | 아이콘 관리(추가/숨김/슬롯/카탈로그) | tools/INDEX_CHILD.md#libscreensicon_management_screendart |
| Backup/Restore | lib/screens/backup_screen.dart | 백업/복원 UI(Downloads, 파일 리스트) | tools/INDEX_CHILD.md#libscreensbackup_screendart |
| Backup/Restore | lib/services/backup_service.dart | 백업/복원 핵심 로직(JSON + 파일 I/O) | tools/INDEX_CHILD.md#libservicesbackup_servicedart |
| Privacy | lib/screens/privacy_policy_screen.dart | 개인정보 처리방침 + 동의 저장 | tools/INDEX_CHILD.md#libscreensprivacy_policy_screendart |
| Tests | test/screens/account_main_icon_picker_test.dart | 아이콘 다중 선택/일괄 적용 위젯 테스트 | tools/INDEX_CHILD.md#testscreensaccount_main_icon_picker_testdart |
| Tools | .vscode/tasks.json | VS Code 작업(Analyze/Test/INDEX/Find-only helpers) | tools/INDEX_CHILD.md#vscodetasksjson |
| Tools | tools/open_find_indexes.ps1 | Parent/Child 인덱스를 즉시 열기 | tools/INDEX_CHILD.md#toolsopen_find_indexesps1 |
| Tools | tools/check_long_lines.ps1 | lib/*.dart 80자 초과 라인 체크 | tools/INDEX_CHILD.md#toolscheck_long_linesps1 |

---

## Notes

- 이 Parent는 “찾기 전용”이다(설명서 X).
- 상세는 Child에서 확인하고, 실제 코드는 해당 파일에서 확인.
