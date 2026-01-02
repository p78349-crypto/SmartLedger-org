요약
- 중앙 상수: `Page1BottomQuickIcons.slotCount` (값: 24)
- 목적: 페이지 1~15의 하단 아이콘 슬롯 개수를 중앙에서 관리하여 배포 후 수정 비용과 데이터 불일치 위험을 줄임

권장 사용법
- 새로운 코드나 테스트에서는 직접 숫자(24)를 사용하지 말고 `Page1BottomQuickIcons.slotCount`를 사용하세요.
- 슬롯 길이 초기화: `List<String>.filled(Page1BottomQuickIcons.slotCount, '')`
- 서브리스트/트리밍: `list.length >= Page1BottomQuickIcons.slotCount ? list.sublist(0, Page1BottomQuickIcons.slotCount) : [...list, ...List<String>.filled(Page1BottomQuickIcons.slotCount - list.length, '')]`

주의사항
- `24`는 UI 패딩/아이콘 크기 등 다른 맥락에서도 자주 등장합니다. 숫자 `24`를 한꺼번에 교체하면 UI가 깨질 수 있으므로 파일/문맥별 판단을 하세요.
- DB/Prefs 포맷 변경이 수반되는 경우(예: 슬롯 개수 축소 시)에는 사용자 데이터 마이그레이션 계획이 필요합니다.

마이그레이션 체크리스트
1. 코드: 모든 슬롯 관련 초기화/제한 지점이 중앙 상수를 사용하도록 변경
2. 테스트: 관련 위젯/서비스 테스트를 파일별로 실행하여 회귀 확인
3. 런타임: `flutter analyze` 및 전체 `flutter test` 통과 확인
4. 배포전: 핫픽스/롤백 절차 문서화 및 릴리스 노트에 명시

연락처
- 변경에 문제가 발생하면 `vccode1` 저장소의 `team` 채널로 보고하세요.

역사적 변경(12 → 24)
- 배경: 초기 설계에서는 페이지 하단의 슬롯이 12개로 가정된 곳이 일부 있었습니다. 이후 사용자 요구와 기능 확장을 반영하여 기본 슬롯 수를 24로 확장했습니다.
- 문서화 필요성: 출시 후 슬롯 수 변경은 사용자 Prefs/저장소 포맷에 영향을 줄 수 있어 반드시 변경 기록과 마이그레이션 지침을 문서화해야 합니다.
- 권장 조치:
	- 코드 및 테스트에서 `12`로 되어 있는 모든 슬롯 관련 하드코드를 `Page1BottomQuickIcons.slotCount`로 대체하세요.
	- 기존 사용자 데이터(12길이 배열 등)를 불러올 때는 `List`를 `slotCount`에 맞춰 패딩하거나 자르는 마이그레이션 로직을 반드시 포함하세요.
	- 마이그레이션은 앱 시작 시 안전하게 실행되도록 하고, 데이터 손실 가능성은 릴리스 노트에 명시하세요.
