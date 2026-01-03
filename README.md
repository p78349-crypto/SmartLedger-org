
# Multi-Account Household Ledger (가계부)

Flutter 기반 다중 계정 가계부 앱입니다. 각 계정별로 거래, 자산, 고정비용, 통계, 백업/복원 기능을 제공합니다.

## 주요 기능
- 계정별 데이터 완전 분리 (거래, 자산, 고정비용, 통계)
- 계정 생성/선택/임시 사용
- 거래 내역 입력 및 리스트
- 자산/고정비용 입력 및 관리
- 통계 화면
- 백업/복원 (JSON 파일)
- 자동 백업 (7일마다, 매월 1일)

## 실행 방법
1. Flutter 환경이 준비된 상태에서 프로젝트 폴더로 이동
	```
	cd C:/Users/plain/vccode1
	flutter pub get
	```
2. 앱 실행
	- Windows 데스크톱: `flutter run -d windows`
	- 웹: `flutter run -d web-server` 후, 출력되는 URL을 브라우저에 입력
	- Android/iOS: 에뮬레이터 또는 기기 연결 후 `flutter run`

## 개발 루틴 (INDEX 기록)
- 작업 중간/끝에 `flutter analyze --no-fatal-infos`로 기본 품질 확인
- 작업 종료 시 VS Code Task: `End of work: INDEX 기록(자동파일→검증→내보내기)` 실행
  - 자동으로 “추가 → 검증 → 내보내기”까지 수행

## 빠른 탐색(찾기 전용 INDEX 2단계)

- Parent(간략 지도): [tools/INDEX_PARENT.md](tools/INDEX_PARENT.md)
- Child(파일별 검색 단서): [tools/INDEX_CHILD.md](tools/INDEX_CHILD.md)
- 권장 흐름: Parent로 범위 결정 → Child로 키워드 확보 → 해당 폴더/파일만 검색

## Icon design & validation
- Add new custom icons to `assets/icons/custom/` (SVG) and update `assets/icons/metadata/icons.json`.
- Run validation: `python tools/validate_icons.py` (or `pwsh .\tools\validate_icons.ps1` on Windows).
- PRs that add icons will be validated automatically by `.github/workflows/validate-icons.yml`.

## 사용법
1. 앱 실행 후 계정 선택/생성 화면에서 원하는 방식 선택
	- 임시로 사용하기: 임시 계정으로 바로 진입
	- 새 계정 만들기: 계정명 입력 후 생성
	- 기존 계정 선택: 이미 생성된 계정 진입
2. 계정 메인 화면에서 거래 추가, 통계, 자산/고정비용 입력, 백업/복원 등 이용
3. 백업/복원 메뉴에서 JSON 파일로 내보내기/가져오기 가능

## 백업/복원 및 자동 백업
- 백업: 현재 계정의 모든 데이터를 JSON 파일로 저장
- 복원: JSON 파일을 선택해 새로운 계정으로 데이터 복원 (기존 데이터는 덮어쓰지 않음)
- 자동 백업: 각 계정별로 7일마다, 매월 1일 자동으로 백업 파일이 생성됨
  - 파일명: `{계정명}_YYYYMMDD_auto.json`
- 복원 시 데이터 구조가 변경되어도, 가능한 한 필드 매핑 및 마이그레이션 처리

## 참고
- 본 프로젝트는 학습 및 개인 사용 목적의 예제입니다.
- 문의 및 개선 제안은 언제든 환영합니다.

## 메인 페이지 정책

앱의 메인 페이지(1~7) 매핑 및 아이콘 노출 정책은 문서로 관리합니다: [DOCUMENTATION/MAIN_PAGES_POLICY.md](DOCUMENTATION/MAIN_PAGES_POLICY.md)

## 개발자 로컬 설정 및 CI 안내

간단한 개발자 온보딩과 로컬 검사 방법입니다. 새 환경에서는 아래를 먼저 실행하세요.

- 의존성 설치:
	```powershell
	flutter pub get
	```

- Git 훅 설치 (로컬에 pre-commit 훅 복사)
	```powershell
	pwsh .\scripts\install-hooks.ps1
	```
	이 스크립트는 `hooks/` 디렉터리에 있는 훅을 `.git/hooks`로 복사합니다.

- 로컬 검사(커밋 전 권장):
	- 포맷 확인: `dart format --set-exit-if-changed .`
	- 정적분석: `dart analyze`
	- 라인 길이 검사: `pwsh .\scripts\scan_long_lines.ps1` (80자 초과 시 비정상 종료)

- 백업(아티팩트):
	- APK/AAB 생성 후 압축 및 백업: `pwsh .\scripts\backup_artifacts.ps1`
	- 저장소 전체 백업: `pwsh .\scripts\run_local_backup.ps1`

- CI 정책 (요약):
	- GitHub Actions가 `dart format`, `dart analyze`, `dart_code_metrics`, 그리고 라인 길이 검사를 실행합니다.
	- `dart_code_metrics`와 라인 길이(>80)는 CI에서 실패 시 빌드가 차단됩니다.
	- 로컬에서 위 검사를 통과하면 PR이 통과할 가능성이 높습니다.

문의: 팀이 이 설정을 따르도록 하려면 PR 템플릿 또는 README 상단에 설치 섹션 고정(권장) 가능합니다.

