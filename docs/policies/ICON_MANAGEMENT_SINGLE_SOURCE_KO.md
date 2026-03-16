# 아이콘 관리/페이지 인덱스 단일 기준 (Single Source of Truth)

문서 목적: **아이콘/페이지 인덱스/아이콘 관리(ENT) 관련 혼란을 없애기 위해**, 운영/디버깅/수정 시 이 파일 **1개만** 보면 되도록 기준을 고정합니다.

- 최종 갱신: 2026-02-28
- 적용 범위: 메인 페이지(PageView), MainFeatureIconCatalog, IconManagementScreen(사진 스타일/레거시), Reserved 페이지 정책

---

## 0) TL;DR (가장 중요한 5줄)

1. 메인 pageIndex(0-based)는 **pageCount=15**를 유지합니다.
2. Reserved 인덱스는 고정입니다: **통계=3 / 자산=4 / ROOT=5 / 설정=6**.
3. `MainFeatureIconCatalog.pages[index].index`는 **메인 pageIndex와 동일**합니다(혼동 방지).
4. 아이콘이 “엉뚱한 페이지로 보이거나(예: ROOT에서 자산 아이콘)” 하면, 거의 항상 **인덱스 불일치**가 원인입니다.
5. 아이콘 이동은 **표시 순서(하단 2번째 줄 우선)**와 **저장 인덱스(기존 유지)**를 분리해 관리합니다.

---

## 1) 메인 페이지 인덱스 정책 (0-based)

메인 화면의 pageIndex는 0부터 시작합니다.

- Index 0: 대시보드
- Index 1: 요리/쇼핑/지출
- Index 2: 수입
- Index 3: 통계 (Reserved)
- Index 4: 자산 (Reserved)
- Index 5: ROOT (Reserved)
- Index 6: 설정 (Reserved)
- Index 7~14: 미사용(빈 페이지)

정책이 고정인 이유: 아이콘 관리/저장/정리 로직이 pageIndex에 강하게 연결되어 있어, 인덱스가 흔들리면 유지보수가 급격히 어려워집니다.

---

## 2) Reserved 페이지 정책 (허용 모듈)

Reserved 페이지는 **특정 모듈 아이콘만 허용**합니다.

- 통계(Index 3): `stats` 모듈 아이콘
- 자산(Index 4): `asset` + (필요 시) `income` 모듈 아이콘
- ROOT(Index 5): `root` 모듈 아이콘
- 설정(Index 6): `settings` 모듈 아이콘

정책 위반 배치(예: ROOT 아이콘을 Index 4에 배치)는 저장되더라도, 메인 로딩/정규화 단계에서 필터링/이동될 수 있습니다.

---

## 3) “카탈로그 인덱스” vs “메인 인덱스” 규칙

과거에는 `MainFeatureIconCatalog.pages`의 섹션 인덱스가 메인 pageIndex와 어긋나서,
"ROOT 아이콘 관리인데 Index 4(자산)가 뜬다" 같은 혼란이 반복되었습니다.

현행 규칙(혼란 방지):

- `MainFeatureIconCatalog.pages[index].index`는 **메인 pageIndex와 동일**
- 따라서 "카탈로그 인덱스"라는 별도 개념으로 디버깅하지 않습니다.

> 즉, ROOT 전용 아이콘 관리 화면은
> - 편집 대상: pageIndex=5
> - 카탈로그 노출: index=5(root)
> 로 한 기준만 사용합니다.

---

## 4) 아이콘 관리(ENT) 동작 규칙

### 4-1) 사진 스타일 레이아웃(`usePhotoStyleLayout=true`)

- 선택한 아이콘은 **토글 방식**으로 적용됩니다.
  - 이미 배치됨 → 숨김(슬롯에서 제거)
  - 미배치 → 표시(빈 슬롯에 추가)
- 여러 개 선택 후 상단 `ENT`로 일괄 적용

이 방식의 목표: “현재 배치/드롭존” 섹션 없이도 표시/숨김을 끝낼 수 있게 하는 것.
> ⚠️ **중요: 앱 재실행 필요**  
> ENT로 아이콘 노출/비노출 설정 후, **메인 화면에 즉시 반영되지 않습니다**.  
> 설정이 저장된 후 **앱을 재실행**해야 메인 그리드에 변경사항이 적용됩니다.  
> (현재 동작 방식이며, 실시간 반영은 향후 개선 예정)
### 4-2) 레거시 레이아웃

- 선택한 아이콘을 **빈 슬롯에 추가**
- 슬롯이 꽉 차면 더 이상 추가 불가(안내/이동 유도 로직이 들어갈 수 있음)

---

## 4-A) 사진 스타일 레이아웃 UI 규칙 (2026-02-24 업데이트)

### 아이콘 상태별 시각적 구분

아이콘 관리 화면에서 **선택/배치/미선택** 상태를 명확히 구분합니다.

| 상태 | 배경색 | 테두리색 | 테두리두께 | 체크아이콘 |
|------|--------|----------|------------|------------|
| **선택됨** | 흰색 (surface) | primary | 3.0 | 24px |
| **배치됨** | 흰색 (surface) | tertiary | 2.5 | - |
| **미선택** | surfaceContainerHighest | onSurface | 1.4 | 20px |

이 규칙의 목적:
- "선택됨"과 "배치됨" 모두 흰색 배경으로 **가독성 향상**
- ENT 적용 후에도 배치된 아이콘이 눈에 띄게 유지
- 테두리 색상/두께로 상태 구분

### 코드 위치

- `lib/screens/icon_management_screen_build.dart` → `_buildPhotoCatalogIconTile()`

```dart
if (isSelected) {
  bgColor = scheme.surface; // 흰색 배경
  borderColor = scheme.primary;
  borderWidth = 3.0;
} else if (isPlaced) {
  bgColor = scheme.surface; // 배치됨도 흰색 배경
  borderColor = scheme.tertiary;
  borderWidth = 2.5;
} else {
  bgColor = scheme.surfaceContainerHighest;
  borderColor = scheme.onSurface;
  borderWidth = 1.4;
}
```

---

## 4-B) 아이콘 관리 ↔ 메인 그리드 동기화 (2026-02-24 수정)

### 문제 (과거 버그)

아이콘 관리 화면의 "배치됨" 표시와 실제 메인 그리드 페이지의 아이콘이 **불일치**하는 경우 발생.

**원인**: Reserved 페이지(ROOT/통계/자산/설정)에서 저장된 슬롯이 비어있을 때, 
- 메인 그리드(`icon_grid_page_slots.dart`)는 자동으로 아이콘을 채움 (prefill)
- 아이콘 관리(`icon_management_screen_helpers.dart`)는 빈 슬롯 그대로 표시

### 해결책 (현행)

`_sanitizeSlotsKeepingExisting()` 함수에 Reserved 페이지 자동 채움 로직 추가:

```dart
// Reserved page prefill: if all slots are empty, prefill from available icons.
final isReservedPage = _isStatsReservedPage(pageIndex) ||
    _isAssetReservedPage(pageIndex) ||
    _isRootReservedPage(pageIndex) ||
    _isSettingsOnlyPage(pageIndex);
final allEmpty = next.every((s) => s.trim().isEmpty);
if (isReservedPage && allEmpty) {
  final availableIcons = _autoFillSourceIconsForPage(pageIndex);
  var writeIndex = 0;
  for (final icon in availableIcons) {
    if (writeIndex >= _slotCount) break;
    next[writeIndex] = icon.id;
    writeIndex++;
  }
}
```

### 코드 위치

- `lib/screens/icon_management_screen_helpers.dart` → `_sanitizeSlotsKeepingExisting()`
- `lib/screens/icon_grid_page_slots.dart` → `_loadSlots()` (메인 그리드 측)

### 동기화 원칙

1. **Reserved 페이지**: 슬롯이 비어있으면 해당 모듈의 모든 아이콘 자동 채움
2. **일반 페이지**: 저장된 슬롯만 사용 (빈 슬롯 허용)
3. 두 화면(아이콘 관리/메인 그리드)이 **동일한 prefill 로직**을 사용해야 함

---

## 4-C) 아이콘 이동(드래그/드롭) 표시 순서 정책 (2026-02-28 추가)

### 배경

한 손 사용 접근성을 높이기 위해, 아이콘 이동 시 체감 우선순위를 다음으로 통일합니다.

- **하단 2번째 줄부터 위로** 우선 배치/이동
- 맨 하단 줄은 마지막 순서

예: 6행(24슬롯, 4열)일 때 row 우선순위는 `4 → 3 → 2 → 1 → 0 → 5`

### 핵심 원칙

1. **표시 순서만 변경**하고 저장 슬롯 index 자체는 변경하지 않습니다.
2. 드래그/스왑/저장은 기존 index 기반 저장 규칙을 그대로 사용합니다.
3. 메인 그리드와 아이콘 관리 화면은 동일한 시각 순서 정책을 사용해야 합니다.

### 적용 위치

- 메인 그리드
  - `lib/screens/icon_grid_page_build.dart`
  - `_slotIndexForDisplayPosition()`, `_mappedRowForThumbReach()`
- 아이콘 관리
  - `lib/screens/icon_management_screen_helpers.dart`
  - `_visualSlotIndices()`, `_mappedRowForThumbReach()`
  - `_dropZoneSlotIndices()`, `_editableSlotIndices()`
  - `lib/screens/icon_management_screen_dropzone.dart` (`현재 배치` 표시 순서)

### 정책상 기대 동작

- 같은 슬롯 데이터라도, 사용자가 보는 이동/배치 우선순위는 손가락 접근성 기준으로 동작합니다.
- 기존 prefs 키/슬롯 index/저장 데이터와의 호환성은 유지됩니다.

---

## 5) 저장/로드(Preferences) 관점 요약

아이콘 배치 저장은 기본적으로 index 기반 API를 사용합니다.

- `UserPrefService.getPageIconSlots(accountName, pageIndex)`
- `UserPrefService.setPageIconSlots(accountName, pageIndex, slots)`
- `UserPrefService.getPageIconSettings(accountName, pageIndex)`
- `UserPrefService.setPageIconSettings(accountName, pageIndex, order)`

추가로 `MainPageConfig` 기반(pageId 포함) 구조도 존재하지만,
아이콘 슬롯 로딩은 결국 “현재 pageIndex의 슬롯”을 읽는 흐름이 핵심입니다.

---

## 6) 문제 유형별 초고속 진단 (1분 컷)

### A. ROOT 아이콘 관리 터치 → 자산 아이콘이 보인다

대부분 **인덱스 불일치**입니다. 아래 3가지만 확인하세요.

1) Reserved 정책 인덱스가 통일돼 있는가?
- 통계=3, 자산=4, ROOT=5, 설정=6

2) ROOT 전용 아이콘 관리 화면이 정말 pageIndex=5로 열리는가?
- `IconManagementRootScreen.initialPageIndex == 5`

3) `MainFeatureIconCatalog.iconsForModuleKey('root')`가 pages[5]를 가리키는가?
- moduleKey → pages index 매핑이 틀리면 root/asset이 뒤섞입니다.


### B. ENT를 눌렀는데 메인 화면 아이콘이 안 바뀐다

1) 편집한 pageIndex가 맞는지(Reserved면 3/4/5/6)
2) 화면이 photo-style이면 토글(숨김/표시) 규칙이 맞게 적용되는지
3) load 시 prefill/auto-fill이 기존 슬롯을 되돌려놓지 않는지
4) 정책상 반영 시점이 "앱 재시작 후"인지 확인 (적용 스낵바 문구 기준)


### C. 아이콘이 갑자기 사라지거나 중복된다

- 중복 제거/정규화 로직이 실행되면서, “정책 위반 배치”가 이동/제거될 수 있습니다.
- 문제 재현 시, 어떤 아이콘이 어떤 pageIndex에 있었는지 먼저 기록한 뒤, Reserved 정책과 비교하세요.

### D. 아이콘 관리 "배치됨" 표시와 실제 그리드가 다르다 (2026-02-24 추가)

1) Reserved 페이지(ROOT/통계/자산/설정)인지 확인
2) 저장된 슬롯이 비어있는지 확인 (첫 실행/초기화 직후)
3) `_sanitizeSlotsKeepingExisting()`의 auto-prefill 로직이 정상 동작하는지 확인
4) 메인 그리드(`icon_grid_page_slots.dart`)와 아이콘 관리(`icon_management_screen_helpers.dart`)가 **동일한 prefill 규칙**을 사용하는지 확인

> 핵심: Reserved 페이지는 슬롯이 비면 **자동으로 해당 모듈 아이콘을 채움**.
> 두 화면에서 이 로직이 다르면 "배치됨" 표시가 불일치합니다.

### E. 아이콘 이동 순서가 기대와 다르다 (2026-02-28 추가)

1) 대상 화면이 메인 그리드/아이콘 관리 중 어디인지 확인
2) 하단 2번째 줄 우선 정책 함수가 반영되었는지 확인
  - 메인: `icon_grid_page_build.dart`
  - 관리: `icon_management_screen_helpers.dart`
3) 표시 순서 변경과 저장 index 변경을 혼동하지 않았는지 확인
4) 아이콘 관리 드롭존 4칸이 시각 순서 기준 앞 4칸을 사용하는지 확인
---

## 7) 코드 변경 시 체크리스트 (여기만 보면 됨)

인덱스/Reserved/아이콘 관리 관련 변경을 했다면, 아래 파일들을 **세트로** 점검합니다.

- 메인 페이지 정책/정규화
  - `lib/screens/account_main_helpers.dart`
- 메인 페이지 라벨(표시용)
  - `lib/screens/account_main_screen.dart`
- 카탈로그(페이지 구성 + moduleKey 매핑)
  - `lib/utils/main_feature_icon_catalog.dart`
- 아이콘 관리(Reserved 정책 + 적용 규칙)
  - `lib/screens/icon_management_screen.dart`
  - `lib/screens/icon_management_screen_helpers.dart` (슬롯 정규화/prefill)
  - `lib/screens/icon_management_screen_build.dart` (UI 스타일/상태 표시)
- 전용 관리 화면(대상 pageIndex 고정)
  - `lib/screens/icon_management_root_screen.dart`
  - `lib/screens/icon_management_asset_screen.dart`
- 메인 그리드 슬롯 로딩(prefill 로직)
  - `lib/screens/icon_grid_page_slots.dart`

---

## 8) 이 파일이 최신 기준입니다

- 정책/인덱스/Reserved/ENT 동작이 바뀌면, **반드시 이 문서 먼저 업데이트**합니다.
- 다른 보고서/작업로그는 “역사 기록” 성격이 강하므로, 최신 정책을 단정하는 문구가 있으면 이 문서로 링크를 걸어 혼선을 줄입니다.

---

## 9) 아이콘 이슈 재현/점검 템플릿 (복사해서 사용)

목표: 아이콘 문제가 발생해도 “무엇을 어디서 확인해야 하는지”를 1분 안에 정리합니다.

### 9-1) 재현 정보 템플릿

아래를 그대로 복사해서 메모/이슈에 붙여주세요.

```
[아이콘 이슈 리포트]

- 날짜/버전:
- 기기/OS:
- 계정명:

- 증상(하나만):
  - 예) ROOT 아이콘 관리에서 자산 아이콘이 나온다
  - 예) ENT 적용 후 메인 화면이 안 바뀐다
  - 예) 아이콘이 중복/사라짐

- 재현 단계:
  1)
  2)
  3)

- 기대 결과:
- 실제 결과:

- 스크린샷/로그:
  - (있으면 첨부)
```

### 9-2) 30초 체크리스트 (가장 흔한 원인부터)

1) **정책 인덱스가 맞는가**
- 통계=3 / 자산=4 / ROOT=5 / 설정=6

2) **들어간 화면이 맞는가(전용 관리 화면)**
- ROOT 관리: `/settings/icon-management-root` → pageIndex=5
- 자산 관리: `/settings/icon-management-asset` → pageIndex=4

3) **카탈로그가 pageIndex와 동일 인덱스인지**
- `MainFeatureIconCatalog.pages[index].index == index`

4) **photo-style(토글) vs 레거시(추가) 모드 혼동 없는지**
- photo-style이면 “숨김/표시 토글”이 정상 동작하는지 확인

### 9-3) 로그로 바로 확인(추천)

메인 아이콘 그리드는 Reserved 페이지일 때 다음 로그가 찍힙니다.

- 로그 키워드: `📍 Page` (moduleKey=stats/asset/root/settings)
- 위치: `lib/screens/icon_grid_page_icons.dart`

예상되는 로그 예시:
- `📍 Page 5: moduleKey=root, icons=...`

만약 `Page 5`에서 `moduleKey=asset`처럼 나오면, 거의 100% 인덱스/매핑 불일치입니다.

### 9-4) 수정 시 “세트 점검” 파일

아이콘/페이지 인덱스 관련 수정은 한 군데만 고치면 재발합니다. 아래는 항상 같이 봅니다.

- `lib/utils/main_feature_icon_catalog.dart` (pageCount=15 + pages index 구성 + moduleKey 매핑)
- `lib/screens/account_main_helpers.dart` (Reserved 정책/정규화)
- `lib/screens/icon_management_screen.dart` (Reserved/ENT 적용 로직)
- `lib/screens/icon_management_screen_helpers.dart` (슬롯 정규화/prefill - **동기화 핵심**)
- `lib/screens/icon_management_screen_build.dart` (UI 스타일/상태 표시)
- `lib/screens/icon_management_root_screen.dart` / `lib/screens/icon_management_asset_screen.dart` (전용 화면 initialPageIndex)
- `lib/screens/icon_grid_page_slots.dart` (메인 그리드 슬롯 로딩 - **prefill 로직 동기화 필수**)
---

## 10) 자동화 테스트 현황 (2026-02-24)

### 10-1) 테스트 파일

- `test/smoke/core_flows_smoke_test.dart`

### 10-2) 페이지별 ENT 아이콘 적용 테스트 (18개)

| 테스트명 | 페이지 | 결과 |
|---------|--------|------|
| SMOKE: Home (page 0) icon ENT reflects | 홈 (0) | ✅ |
| SMOKE: Purchase (page 1) icon ENT reflects | 구매 (1) | ✅ |
| SMOKE: Income (page 2) icon ENT reflects | 수입 (2) | ✅ |
| SMOKE: Stats icon ENT reflects | 통계 (3) | ✅ |
| SMOKE: Asset icon ENT reflects | 자산 (4) | ✅ |
| SMOKE: Root icon ENT reflects | ROOT (5) | ✅ |
| SMOKE: Settings (page 6) icon ENT reflects | 설정 (6) | ✅ |
| SMOKE: Empty page 7 renders without icons | 빈페이지 (7) | ✅ |
| SMOKE: Empty page 8 renders without icons | 빈페이지 (8) | ✅ |
| SMOKE: Empty page 9 renders without icons | 빈페이지 (9) | ✅ |
| SMOKE: Empty page 10 renders without icons | 빈페이지 (10) | ✅ |
| SMOKE: Empty page 11 renders without icons | 빈페이지 (11) | ✅ |
| SMOKE: Empty page 12 renders without icons | 빈페이지 (12) | ✅ |
| SMOKE: Empty page 13 renders without icons | 빈페이지 (13) | ✅ |
| SMOKE: Empty page 14 renders without icons | 빈페이지 (14) | ✅ |

### 10-3) 테스트 검증 내용

**페이지 0-6 (아이콘 있는 페이지):**
1. 초기 슬롯에 특정 아이콘 1개만 배치
2. IconManagementScreen에서 새 아이콘 선택 후 ENT 적용
3. AccountMainScreen 재렌더링 후 새 아이콘이 슬롯에 표시되는지 확인

**페이지 7-14 (빈 페이지):**
1. 슬롯 초기화 (모두 빈 상태)
2. AccountMainScreen에서 빈 그리드가 정상 렌더링되는지 확인
3. 슬롯 위젯(`main_icon_slot_{pageIndex}_{slotIndex}`)이 존재하는지 확인

### 10-4) 테스트 실행 명령

```powershell
flutter test test/smoke/core_flows_smoke_test.dart -v
```

### 10-5) 마지막 테스트 실행 결과

```
실행일시: 2026-02-24
총 테스트: 18개
통과: 18개
실패: 0개
소요시간: ~3초
```