# CI 시크릿 설정 가이드

이 문서는 GitHub Actions 등 CI에서 필요한 시크릿과 설정 방법을 정리합니다. Sentry 연동 및 난독화 매핑 업로드를 위해 아래 시크릿을 설정하세요.

## 필수 시크릿
- `SENTRY_AUTH_TOKEN` : Sentry에서 발급한 auth token. `project:releases` 권한(또는 적절한 권한)이 필요합니다.
- `SENTRY_ORG` : Sentry 조직(slug)
- `SENTRY_PROJECT` : Sentry 프로젝트(slug)

## 선택(권장) 시크릿/값
- `SENTRY_DSN` : 앱에서 직접 이벤트를 전송하려면 DSN을 사용하거나 `--dart-define`로 전달합니다.

## GitHub에 시크릿 추가 (UI)
1. GitHub 리포지토리 페이지로 이동 → `Settings` → `Secrets and variables` → `Actions` → `New repository secret`
2. 이름(`Name`)에 예: `SENTRY_AUTH_TOKEN`, 값(`Value`)에 토큰을 붙여넣기 후 저장

## GitHub CLI로 추가
```bash
gh secret set SENTRY_AUTH_TOKEN --body "$SENTRY_AUTH_TOKEN"
gh secret set SENTRY_ORG --body "your-org"
gh secret set SENTRY_PROJECT --body "your-project"
```

## Sentry에서 `SENTRY_AUTH_TOKEN` 발급 방법
1. Sentry 웹 → Settings → `API Keys` 또는 `Auth Tokens`(계정/조직 설정 위치는 Sentry 버전에 따라 다름)
2. 새 토큰 생성 시 `org:read`, `project:read`, `project:releases`, `project:write` 권한(또는 최소 필요한 권한)을 부여

## CI 사용 예시
- CI 워크플로우는 `SENTRY_AUTH_TOKEN`, `SENTRY_ORG`, `SENTRY_PROJECT`가 설정되어 있을 때만 매핑 업로드 및 릴리스 등록을 수행합니다.
- 로컬 테스트 시에는 환경변수로 설정하거나 `--dart-define=SENTRY_RELEASE=smartledger@<sha>`를 사용해 `lib/main.dart`에서 release 값을 주입할 수 있습니다.

## 보안 권장사항
- `build/debug-info/*` 매핑 파일은 크래시 디버깅에 필수적이므로 안전한 저장소(예: 내부 아카이브, Sentry 릴리스)에만 보관하세요.
- 시크릿은 절대 코드 리포지터리에 커밋하지 마세요.
- Sentry 토큰 사용 범위를 최소 권한 원칙에 따라 제한하세요.

## 빠른 확인 (로컬)
```bash
export SENTRY_AUTH_TOKEN=xxx
export SENTRY_ORG=your-org
export SENTRY_PROJECT=your-project
RELEASE="smartledger@$(git rev-parse --short HEAD)"
sentry-cli releases new -p $SENTRY_PROJECT $RELEASE
sentry-cli releases set-commits --auto $RELEASE
sentry-cli upload-dif --org $SENTRY_ORG --project $SENTRY_PROJECT build/debug-info/android
sentry-cli releases finalize $RELEASE
```

---
파일을 추가했습니다: `docs/CI_SECRETS_SETUP.md` — 원하시면 CI 시크릿 추가 절차를 자동화하는 스크립트(예: `gh` 기반)도 만들어 드리겠습니다.

## 자동 설정 스크립트 (gh CLI)
레포지토리 시크릿을 `gh` 명령으로 자동화하려면 저장소 루트의 `scripts/set_github_secrets.sh`(bash) 또는 `scripts/set_github_secrets.ps1`(PowerShell)을 사용하세요.

- 사용 예 (bash):
```bash
export GITHUB_REPOSITORY=owner/repo
export SENTRY_AUTH_TOKEN=XXX
export SENTRY_ORG=your-org
export SENTRY_PROJECT=your-project
./scripts/set_github_secrets.sh
```

- 사용 예 (PowerShell):
```powershell
$env:GITHUB_REPOSITORY = 'owner/repo'
$env:SENTRY_AUTH_TOKEN = 'XXX'
$env:SENTRY_ORG = 'your-org'
$env:SENTRY_PROJECT = 'your-project'
.\scripts\set_github_secrets.ps1
```

> 주의: `gh`에 로그인되어 있어야 하며, 실행 시 인터랙티브로 값을 입력할 수도 있습니다.
