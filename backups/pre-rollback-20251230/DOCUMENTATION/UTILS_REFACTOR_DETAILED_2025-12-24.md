# 유틸리티 중복 정리 리포트 (Detailed)

작성일: 2025-12-24
작성자: 자동 리팩토러 (보조 AI)

## 1. 개요
- 목적: `lib/utils` 및 애플리케이션 전반에 중복으로 존재하던 날짜/숫자/통화 포매터, 입력 포매터, 아이콘 상수, 차트 관련 열거형 등을 한 곳으로 통합하여 유지보수성과 일관성을 확보함.
- 범위: `lib/` 내 주요 스크린, 위젯, 서비스 및 유틸리티 파일 전역.

## 2. 주요 변경점 요약
- 중앙 유틸 추가/확장
  - `lib/utils/date_formatter.dart` : 공통 날짜 포맷터 및 헬퍼 함수 모음
  - `lib/utils/number_formats.dart` : 통화/숫자 포맷 접근자
  - `lib/utils/currency_formatter.dart`, `lib/utils/type_converters.dart` : 파싱/포맷 로직 위임
  - 입력 포매터: `thousands_input_formatter.dart`, `currency_input_formatter.dart` 등 재사용 로직 정리
  - `lib/utils/icon_catalog.dart` : 중복 아이콘 상수 제거 및 SSOT 구성

- 레포 전역 대체
  - 기존 파일들에 흩어져 있던 `DateFormat`, `NumberFormat` 직접 생성 코드를 `DateFormatter` / `NumberFormats`로 교체
  - 여러 위젯/스크린에서 아이콘 상수를 `IconCatalog`로 교체

## 3. 변경된(또는 검토된) 주요 파일 목록(부분 발췌)
- Screens: `enhanced_chart_screen.dart`, `chart_detail_screen.dart`, `fixed_cost_stats_screen.dart`, `period_detail_stats_screen.dart`, `daily_transactions_screen.dart`, `root_account_screen.dart`, `asset_tab_screen.dart`, `savings_plan_search_screen.dart`, `memo_stats_screen.dart`, 등
- Widgets: `root_summary_card.dart`, `root_transaction_list.dart`, `in_app_screen_saver.dart`, `comparison_widgets.dart`, 등
- Services: `chart_data_service.dart`, `search_service.dart`, 등
- Utils/생성물: 추가된 `date_formatter.dart`, `number_formats.dart`, `icon_catalog.dart`, 입력 포매터 파일들

> 전체 변경 파일 목록은 Git diff/커밋 로그를 참조하세요. (이 리포트는 대표 변경점을 정리한 문서입니다.)

## 4. 구현 세부사항 및 결정 근거
- 날짜/시간 포맷: 애플리케이션 전반에서 동일한 로케일/패턴 사용을 보장하기 위해 `DateFormatter`에 상수와 변환 헬퍼를 둠.
- 숫자/통화 포맷: `NumberFormats`는 런타임에 `NumberFormat` 인스턴스를 재사용하는 getter를 노출하여 중복 생성과 로케일 불일치를 방지.
- 입력 포매터: 표시용/입력용 포맷팅/파싱 로직을 분리하여 `TextInputFormatter` 구현체들이 공통 파서/포맷터를 활용.
- 아이콘 카탈로그: 프로젝트 곳곳에 흩어진 아이콘 상수를 `IconCatalog`로 단일화. 중복 정의 제거 및 이름 충돌 해소.

## 5. 문제 및 해결 기록
- 초기 분석에서 정적 분석기(`flutter analyze`)가 많은 에러(약 135건)를 보고했음. 원인: 자동 대체 중 누락된 import 및 중복 심볼.
- 조치: 자동화된 교체 후 누락 import를 추가하고 중복 상수 제거, 코드 포맷터 실행, 반복적 분석-수정 사이클을 거쳐 에러를 제거함.
- 현재 상태: 에러(실패 레벨)는 모두 해결되었으며, 남아있는 항목은 정보 레벨(디렉티브 정렬, 중복 import 경고, 긴 라인, `prefer-final` 권장사항) 약 25건.

## 6. 남은 작업 (우선순위)
1. 디렉티브(Import) 섹션 정렬 및 중복 import 제거 — 우선순위 높음
2. 안전한 범위에서 긴 라인(>80자) 재포맷 — 중간 우선순위
3. `prefer-final` 로컬 변수 적용(재할당 없는 경우) — 저우선순위
4. 선택적: 입력 포매터 단위 테스트 추가 및 주요 위젯 스모크 UI 테스트 — 권장

## 7. 재현 및 검증 방법
1. 코드 포맷 적용
```
dart format .
```
2. 정적 분석 실행
```
flutter analyze --no-fatal-infos
```
3. 변경 검토: Git에서 변경된 파일 확인 및 diff 검토

## 8. 권장 후속 조치
- CI 파이프라인에서 `flutter analyze`를 경고 수준으로 엄격히 통과시키는 규칙 적용 검토
- 중요 유틸(포맷터/포매터)에 대한 단위 테스트 도입
- 대규모 자동 리팩터 시점에는 변경 로그(파일별) 자동 생성 스크립트 도입 권장

---
문서 작성 자동화: 이 문서는 리팩터 작업 중 생성된 메타 정보와 분석 결과를 바탕으로 자동 생성되었습니다. 추가 세부 검토를 원하시면 변경을 적용한 특정 파일명을 알려주세요.
