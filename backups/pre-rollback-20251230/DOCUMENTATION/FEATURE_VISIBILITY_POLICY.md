# Feature Visibility Policy (새 기능은 반드시 페이지에 표시)

## 목적

새 기능(사용자가 직접 사용하는 기능/화면)을 추가했는데 UI(페이지)에 노출되지 않으면:
- 실사용 테스트가 불가능해지고,
- 기능이 "코드에만 존재"하는 상태가 오래 지속되며,
- 회귀/품질 관리(문서/테스트/릴리즈)가 깨지기 쉽습니다.

따라서 **새 기능은 반드시 페이지(메인 기능 아이콘)로 노출**하는 것을 운영 정책으로 강제합니다.

## 정책

- 새 기능(사용자 기능) 라우트를 `AppRoutes`에 추가하면,
  - 반드시 [lib/utils/main_feature_icon_catalog.dart](../lib/utils/main_feature_icon_catalog.dart) 에 아이콘을 추가하여 **페이지에서 진입 가능**해야 합니다.
- 예외(내부 화면/상세/플로우 전용/설정 서브페이지 등)로 "의도적으로 숨기는" 라우트는,
  - [tools/feature_visibility_exclude_routes.txt](../tools/feature_visibility_exclude_routes.txt) 에 **명시적으로 등록**합니다.

## 자동 점검

- 스크립트: [tools/check_feature_visibility.ps1](../tools/check_feature_visibility.ps1)
- 동작: `AppRoutes`의 route 상수 목록과 `MainFeatureIconCatalog`의 노출 목록을 비교
- 실패 조건: 노출되지 않았고(exposed icon 없음), 제외 목록에도 없는 라우트가 존재

## 실행

- 단독 실행:
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File tools/check_feature_visibility.ps1`
- 권장: 품질 게이트(`tools/quality_gate.ps1`)에서 자동 실행
