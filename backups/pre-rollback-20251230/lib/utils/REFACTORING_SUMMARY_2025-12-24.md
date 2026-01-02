# 리팩토링 요약 (2025-12-24)

간단한 변경 내역 및 권고사항입니다.

변경 사항
- `chart_display_utils.dart`: 로컬 `ChartDisplay` 제거, `ChartDisplayType`(lib/utils/chart_utils.dart) 재사용(통합).
- `date_formats.dart`: 중복 정의를 제거하고 `DateFormatter`로 위임(일관된 날짜 포맷 사용).
- `type_converters.dart`: `parseCurrency()` 추가하여 통화 파싱 로직 중앙화.
- `currency_formatter.dart`: `parse()`를 `TypeConverters.parseCurrency`로 위임.
- `number_formats.dart`: `currency`를 `CurrencyFormatter.currency`로 위임(로케일 일관성).
- `thousands_input_formatter.dart`: 내부적으로 `CurrencyInputFormatter`를 재사용하도록 변경(중복 콤마 로직 제거).

수정된 파일 (핵심)
- lib/utils/chart_display_utils.dart
- lib/utils/date_formats.dart
- lib/utils/type_converters.dart
- lib/utils/currency_formatter.dart
- lib/utils/number_formats.dart
- lib/utils/thousands_input_formatter.dart

권고/다음 단계
- 코드베이스 전역에서 오래된 enum/함수(예: `ChartDisplay`, 직접 `DateFormat('yyyy-MM-dd')`) 사용 여부를 검색하여 추가 교체 적용.
- 변경 후 `flutter analyze` 실행 및 주요 화면에서 수동 검증(차트 표시, 날짜/통화 포맷, 인풋 동작).
- 입력 포매터 관련 경계 케이스(음수, 소수, 커서 위치) 단위 테스트 추가 권장.
- 장기적으로: `lib/utils` 내부 역할(포맷터, 파서, UI 헬퍼 등)을 문서화하여 새로운 중복 생성을 방지.

간단 체크리스트
- [ ] `flutter analyze` 통과
- [ ] 주요 화면(통계, 거래 입력, 장바구니) 수동 확인
- [ ] 추가 리팩토링 PR 생성(변경 이력 포함)

필요하시면 위 단계들 중 하나를 자동으로 실행하거나, 변경된 파일들을 PR로 묶어 커밋까지 진행해 드리겠습니다.
