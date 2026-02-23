# 🛡️ GitHub Actions CI/CD 보안 점검 파이프라인

이 문서는 프로젝트의 보안 점검을 자동화하는 GitHub Actions 파이프라인 구성과 로컬 환경에서의 실행 방법을 안내합니다.

## 📋 파이프라인 주요 점검 항목

- **코드 분석**: `dart analyze`, `flutter analyze`
- **테스트**: `flutter test --coverage`, `flutter test --reporter expanded`
- **의존성 점검**: `flutter pub outdated`, `flutter pub upgrade --major-versions`
- **Android/iOS 보안 검사**: `./gradlew lint`, `xcodebuild`
- **보안 스캐닝**: `sonar-scanner`, `zap-cli`

이렇게 구성하면 코드 푸시나 Pull Request 시 자동으로 보안 점검이 실행됩니다.

---

## ⚙️ GitHub Actions 워크플로우 설정 (예시)

`.github/workflows/security-pipeline.yml` 파일에 아래 내용을 구성할 수 있습니다.

```yaml
name: Flutter Security Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  security-check:
    runs-on: ubuntu-latest

    steps:
      # 1. 코드 체크아웃
      - name: Checkout repository
        uses: actions/checkout@v3

      # 2. Flutter 환경 설정
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'

      # 3. 보안 점검 결과 저장용 폴더 생성
      - name: Create Security Reports Directory
        run: mkdir -p security_reports

      # 4. 엄격한 코드 분석 및 린트 검사 (결과 모으기)
      - name: Strict Security Scan
        run: |
          # 로그를 파일로 저장
          flutter analyze > security_reports/analysis_report.txt 2>&1 || export SCAN_EXIT_CODE=$?
          
          # 파일 내용 확인 (에이전트가 읽을 대상)
          cat security_reports/analysis_report.txt
          
          # 실제 에러가 있었는지 시스템 코드로 엄격히 체크
          if [ ! -z "$SCAN_EXIT_CODE" ]; then
            echo "❌ 보안 검사 실패: 에러가 존재합니다."
            exit 1
          fi

      # 5. 테스트 및 커버리지
      - name: Run Tests with Coverage
        run: flutter test --coverage

      - name: Expanded Test Logs
        run: flutter test --reporter expanded

      # 6. 의존성 보안 점검
      - name: Check Dependencies
        run: flutter pub outdated

      - name: Upgrade Dependencies
        run: flutter pub upgrade --major-versions

      # 7. Android 빌드 보안 검사
      - name: Android Lint
        run: ./gradlew lint

      - name: Android Release Build
        run: ./gradlew assembleRelease

      # 8. iOS 빌드 보안 검사
      - name: iOS Build Security Check
        run: |
          xcodebuild -workspace Runner.xcworkspace \
          -scheme Runner -sdk iphonesimulator

      # 9. 정적/동적 보안 스캔
      - name: SonarQube Scan
        run: sonar-scanner

      - name: OWASP ZAP Scan
        run: zap-cli quick-scan http://localhost:8080

      # 10. 보안 점검 결과 아티팩트 업로드 (별도 폴더 모음)
      - name: Upload Security Reports
        uses: actions/upload-artifact@v4
        if: always() # 실패하더라도 리포트는 업로드
        with:
          name: security-reports
          path: security_reports/
```

---

## 💻 로컬 환경에서 보안 점검 실행 방법

GitHub Actions 파이프라인에 등록된 보안 점검(Gitleaks, Semgrep)을 로컬 환경에서도 동일하게 실행할 수 있도록 스크립트가 준비되어 있습니다.

### 사전 준비사항
1. **Docker Desktop**이 설치되어 있고 실행 중이어야 합니다. (보안 도구들을 Docker 컨테이너로 실행하여 로컬 환경을 오염시키지 않습니다.)
2. Windows 환경의 경우 **PowerShell**을 사용합니다.

### 실행 방법
1. 프로젝트 루트 디렉토리(`C:\Users\plain\SmartLedger`)에서 PowerShell을 엽니다.
2. 다음 명령어를 실행하여 보안 점검 스크립트를 동작시킵니다.

```powershell
.\local_security_check.ps1
```

### 스크립트 동작 내용
- **Gitleaks**: 프로젝트 내에 하드코딩된 비밀번호, API 키, 토큰 등이 있는지 검사합니다.
- **Semgrep**: 소스 코드의 보안 취약점 및 버그를 정적 분석(SAST)하여 찾아냅니다.

검사가 완료되면 터미널에 결과가 출력되며, 모든 검사 결과 파일은 자동으로 생성되는 `security_reports` 폴더 내에 저장됩니다. 취약점이 발견될 경우 해당 폴더의 리포트 파일(`gitleaks_report.json`, `semgrep_report.json`)을 확인하고 수정할 수 있습니다.

---

## ⚠️ AI Agent 작업 후 필수 검증 절차

AI Agent가 보안 점검 스크립트 작성이나 파이프라인 설정을 완료했다고 보고하더라도, **실제 환경에서 정상적으로 동작하는지 개발자가 직접 교차 검증(Cross-Validation)해야 합니다.**

### 🔍 직접 검사 체크리스트
1. **로컬 스크립트 실행 확인**: `.\local_security_check.ps1` 스크립트가 에러 없이 끝까지 실행되는지 직접 터미널에서 확인합니다.
2. **결과 폴더 생성 확인**: 스크립트 실행 후 프로젝트 루트에 `security_reports` 폴더가 실제로 생성되었는지 확인합니다.
3. **리포트 파일 내용 확인**: `security_reports` 폴더 내에 `gitleaks_report.json`, `semgrep_report.json`, `analysis_report.txt` 등의 파일이 비어있지 않고 정상적인 포맷으로 생성되었는지 직접 열어봅니다.
4. **CI/CD 파이프라인 동작 확인**: GitHub에 코드를 Push하거나 PR을 생성하여 Actions 탭에서 파이프라인이 정상적으로 트리거되고, Artifacts에 `security-reports`가 업로드되는지 확인합니다.
