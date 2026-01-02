# Release Notes

- Since: 2025-12-20

## Changes

 -  2025-12-20 | Fix: 메인 아이콘 그리드 Key/빈슬롯 숨김 정합성 | drag&drop 테스트가 `main_icon_slot_*` Key를 못 찾고 실패; hide_empty_slots 설정이 보기모드에 반영되지 않아 `+`가 노출 | 각 슬롯에 `main_icon_slot_{pageIndex}_{slotIndex}` Key를 부여하고, 보기모드+hideEmptySlots일 때 빈 슬롯은 `+` 없이 렌더(편집모드는 유지) | Playbook=AccountMainScreen; Verify=Quality Gate (analyze + test + INDEX); Tests=flutter test; Files=lib/screens/account_main_screen.dart, REAL_WORLD_TEST_PLAN.md |
 -  2025-12-20 | Main pages: pageCount 15 고정 + 배너는 번호만 표시 | 페이지 수/배너 텍스트가 변경될 수 있고(출시 후 리스크), 배너에 라벨/텍스트가 혼재 | pageCount=15로 고정(출시 안정성), 상단 배너는 “번호만” 표시(텍스트/라벨 의존 제거) | Playbook=AccountMainScreen; Why=출시 후 구조 변경 금지/유지보수 안정성; Verify=flutter analyze; Tests=flutter test; Files=lib/screens/account_main_screen.dart, lib/widgets/page_banner_bar.dart, lib/utils/main_feature_icon_catalog.dart |
 -  2025-12-20 | Prefs: 메인 페이지 기본값/정규화 SSOT 강화 | 기본 페이지 구성/이름/타입이 여러 위치에 흩어져 수정 리스크 | 기본값을 UserPrefService 중심으로 중앙화(폴백/정규화 포함), 1페이지 '가족' 라벨은 공백으로 정규화 | Why=문자열/기본값 변경을 1곳에서 안전하게; Verify=flutter analyze; Tests=flutter test; Files=lib/services/user_pref_service.dart |
 -  2025-12-20 | Settings: 페이지/아이콘 초기화는 섹션 하단으로 정리 | 설정 내 기능들이 혼재되어 “위험 기능(초기화)”이 눈에 띄기 쉬움 | 설정을 아이콘/진입점 중심으로 정리하고, 페이지/아이콘 초기화는 해당 섹션 맨 아래로 배치 | Why=오조작 리스크 감소 + 동선 단순화; Verify=flutter analyze; Tests=flutter test; Files=lib/screens/settings_screen.dart |
 -  2025-12-20 | Language: 언어 설정 분리 + 저장값 앱 시작 시 반영 | 설정 화면 내 드롭다운 등으로 섞여 있고, 앱 시작 시 로케일 반영이 불명확 | 언어 설정 전용 화면/라우트 추가 + PrefKeys.language 저장 + 앱 시작 시 Intl locale 초기화에 반영 | Why=설정 단일 책임/개별 저장; Verify=flutter analyze; Tests=flutter test; Files=lib/screens/language_settings_screen.dart, lib/navigation/app_routes.dart, lib/navigation/app_router.dart, lib/main.dart |
 -  2025-12-20 | Icon management: 빈 슬롯 없으면 “다음 페이지 안내” 추가 | 아이콘 추가 시 빈 슬롯이 없으면 사용자 흐름이 막힘 | 다음 빈 슬롯이 있는 페이지를 자동 탐색하고 이동 버튼/스낵바 액션으로 안내 | Why=막힘 방지/가이드 강화; Verify=flutter analyze; Tests=flutter test; Files=lib/screens/icon_management_screen.dart |
 -  2025-12-20 | Page1: 전체 광고 오버레이 게이트(기본 비노출) | 출시 전/후 광고 삽입 시 매번 화면 구조를 뜯어야 함 | 1페이지에서만 전체 오버레이 광고 구조를 미리 제공(기본 OFF); 비정식 사용자만 노출 + 터치로 닫기(세션 1회) | Why=UX 단순/유지보수 안정 + 출시 전 토글로 조정; Verify=flutter analyze; Files=lib/screens/account_main_screen.dart, lib/widgets/page1_fullscreen_ad_overlay.dart, lib/services/user_pref_service.dart, lib/utils/pref_keys.dart |
