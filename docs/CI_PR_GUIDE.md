# PR 가이드: CI 테스트 및 릴리스 검증

이 문서는 PR 작성자가 CI를 통과시키고 릴리스 연동(난독화 매핑 업로드 등)을 원활히 수행하기 위한 체크리스트와 절차를 제공합니다.

## 사전 체크
- `flutter test` 로 모든 테스트가 통과하는지 확인하세요.
- 변경사항이 릴리스/빌드 관련이면 `docs/CI_SECRETS_SETUP.md`에 설명된 시크릿이 설정되어 있는지 확인하세요.

## 로컬 검증
1. 의존성 설치
```bash
flutter pub get
```
2. 테스트 실행
```bash
flutter test
```
3. 릴리즈 빌드(선택, 매핑 확인용)
```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info/android --dart-define=SENTRY_RELEASE=smartledger@$(git rev-parse --short HEAD)
```

## PR 작성 시 템플릿 사용
- `.github/PULL_REQUEST_TEMPLATE/pull_request_template.md`를 사용해 변경 요약, 테스트 방법, CI 체크 항목을 기입하세요.

## CI 실행 확인
- PR을 생성하면 `CI` 워크플로우가 자동 실행됩니다.
- 테스트가 실패하면 PR을 업데이트해 문제를 해결하세요.
- PR이 머지되면 `build` job이 자동으로 릴리스 매핑을 Sentry에 업로드합니다(시크릿 필요).

## 문제 발생 시
- `build/debug-info/*`가 생성되지 않거나 업로드 실패 시 워크플로우 로그를 확인하고 `sentry-cli` 호출 및 권한(토큰)을 점검하세요.

*** End Patch