# SSOT: Quality Gate (Analyze + Test + INDEX)

이 문서는 “품질 게이트 결과의 단일 기준(SSOT)”을 정의합니다.

## SSOT 정의

- **SSOT는 VS Code task `Quality Gate (analyze + test + INDEX)`의 마지막 마커 라인**입니다.
- 성공: `=== QUALITY_GATE_OK ===`
- 실패: `Step failed: ...` 또는 비정상 종료(Exit Code != 0)

즉, 터미널에 예전 로그가 남아 있거나 VS Code가 이전 출력 일부를 보여주더라도,
**가장 마지막에 찍힌 마커**만 보고 현재 상태를 판단합니다.

## 왜 SSOT가 필요한가

- 동일한 작업을 여러 터미널/명령으로 돌리면 “어느 로그가 최신인지” 혼동이 발생할 수 있습니다.
- VS Code task 패널/터미널은 재사용되며, 이전 출력이 스크롤 위에 남아 있을 수 있습니다.

그래서 게이트는 항상 **START/OK 마커가 있는 단일 스크립트**로 실행하여 결과 해석을 단순화합니다.

## 실행 방법(권장)

- VS Code: `Tasks: Run Task` → `Quality Gate (analyze + test + INDEX)`
- Windows PowerShell 직접 실행:
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File tools/quality_gate.ps1`

## 구성 요소(무엇을 체크하나)

게이트는 아래 항목을 순서대로 실행합니다.

1. `flutter analyze`
2. `flutter test`
3. INDEX 포맷 검증: `tools/validate_index.ps1` (Windows)
4. 새 기능 페이지 노출 점검: `tools/check_feature_visibility.ps1`

## 관련 파일

- `tools/quality_gate.ps1`
  - START/OK 마커를 찍고 3단계를 순차 실행
- `.vscode/tasks.json`
  - Windows에서는 위 스크립트를 실행하도록 연결

## 운영 규칙

- 코드 변경이 있으면 가능한 한 빨리 INDEX Change Log를 갱신하고, 게이트를 통과시킵니다.
- 게이트가 성공하면 SSOT는 `=== QUALITY_GATE_OK ===` 입니다.
