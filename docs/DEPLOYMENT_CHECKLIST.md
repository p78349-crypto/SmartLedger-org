# SmartLedger 배포 준비 체크리스트

## 📋 배포 전 필수 확인사항

### ✅ 빌드 및 테스트
- [x] Debug 빌드 성공
- [x] Release APK 빌드 성공 (난독화 적용)
- [x] Release AAB 빌드 성공 (Google Play용)
- [x] Flutter 테스트 통과
- [x] CI 파이프라인 테스트 통과

### ✅ 보안 및 코드 품질
- [x] 난독화(Obfuscation) 적용 확인
- [x] 민감한 정보 하드코딩 없음
- [x] Sentry DSN 및 환경변수 설정
- [x] 코드 분석 (flutter analyze) 통과
- [ ] Android 릴리즈 서명 키 준비 (`android/key.properties` + keystore, 비밀번호는 환경변수 사용)
- [x] Android 자동복원 차단 설정 확인 (`allowBackup=false`, `fullBackupContent=false`, `dataExtractionRules=@null`)
- [ ] 삭제→재설치 복원 차단 검증 (`adb uninstall` 후 재설치 시 내부 설정 초기 상태 확인)
- [ ] 외부 저장소/클라우드 백업 파일 잔존 안내 문구 검토 (앱 삭제와 별개로 남을 수 있음)
- [ ] AI 투자 분석 고지 문구 변경 시 `_consentVersion` 상향 반영 확인
- [ ] 설정 > 법적 고지 > 동의 기록 초기화 후 투자 분석 재진입 시 재동의 강제 동작 확인

### ✅ 문서화
- [x] 앱 기능 요약 문서 (APP_FEATURES_SUMMARY_KO.md)
- [x] CI/CD 설정 가이드 (CI_SECRETS_SETUP.md)
- [x] PR 템플릿 및 기여 가이드 (CI_PR_GUIDE.md)
- [x] 변경 로그 (CHANGELOG.md)

### 🔄 배포 플랫폼별 준비사항

#### Google Play Store
- [ ] Google Play Console 계정 준비
- [ ] 앱 서명 키 준비 (또는 Google에서 생성)
- [ ] 스토어 목록 정보 준비 (설명, 스크린샷, 아이콘)
- [ ] 개인정보 처리방침 URL 준비
- [ ] 테스트 계정 설정
- [ ] 내부/베타 테스트 트랙 설정

#### Apple App Store
- [ ] Apple Developer Program 계정
- [ ] 앱 아이디 및 번들 ID 준비
- [ ] 앱 스토어 커넥트 설정
- [ ] 테스트플라이트 설정
- [ ] 앱 심사 자료 준비

### 📊 모니터링 및 지원
- [x] Sentry 프로젝트 설정
- [x] CI에서 Sentry 매핑 파일 업로드 자동화
- [x] 오류 보고 환경 설정 (production/staging)

### 🔧 환경 설정
- [x] GitHub Secrets 설정 (SENTRY_* 변수들)
- [x] CI/CD 파이프라인 활성화
- [x] 자동 백업 시스템 설정

## 🚀 배포 단계

### 1단계: 내부 테스트 배포
```bash
# Google Play 내부 테스트
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info/android
# Play Console에 업로드하여 내부 테스터에게 배포
```

### Android 릴리즈 키 생성/입력 (신규)
```powershell
# 프로젝트 루트에서 실행
.\scripts\setup_android_release_signing.ps1 -GenerateKeystore

# 이미 keystore가 있으면 key.properties만 갱신
.\scripts\setup_android_release_signing.ps1 -ForceOverwrite
```

설명:
- keystore 생성 위치: `android/app/smartledger-release.jks`
- 서명 설정 파일: `android/key.properties`
- 템플릿: `android/key.properties.example`
- 앱 빌드 스크립트(`android/app/build.gradle.kts`)는 `key.properties`가 있으면 release 서명을 사용합니다.

비밀번호 하드코딩 금지(권장):
```powershell
$env:SLD_STORE_PASSWORD="<your_password>"
$env:SLD_KEY_PASSWORD="<your_password>"
```

정책:
- `key.properties`의 `storePassword`, `keyPassword`는 `__FROM_ENV__` 유지 권장
- 실제 비밀번호는 파일에 쓰지 않고 환경변수로 주입

서명 준비 상태 점검:
```powershell
.\scripts\check_android_release_signing.ps1
```

### 재설치 복원 차단 검증(릴리즈 전 필수)
```bash
# 1) 앱 완전 삭제(데이터 포함)
adb uninstall com.example.smartledger

# 2) 릴리즈 재설치
flutter install --release -d <DEVICE_ID>

# 3) 앱 실행 후 초기 상태 확인
# - 아이콘 숨김/배치, 보안 설정, 사용자 설정이 기본값인지 점검
```

검증 결과 기록:
- [ ] 내부 설정 초기화 상태 확인 완료
- [ ] 외부 다운로드/클라우드 백업 잔존 여부 확인 완료

### 투자 분석 법적 고지 E2E 테스트 (5단계)
- [ ] 1) 최초 진입 시 `AI 투자 분석 고지 및 동의` 다이얼로그가 자동 노출된다.
- [ ] 2) 체크박스 미선택 상태에서는 `동의 후 계속` 버튼이 비활성화된다.
- [ ] 3) `취소` 선택 시 투자 분석 화면 진입이 차단된다.
- [ ] 4) 동의 후 진입 시 설정 > 법적 고지에서 상태/시각/버전/로케일이 기록된다.
- [ ] 5) 동의 기록 초기화 후 재진입하면 다이얼로그가 다시 노출된다(재동의 강제).

### 2단계: 베타 테스트
```bash
# 동일한 빌드 파일로 베타 트랙으로 승격
```

### 3단계: 프로덕션 배포
```bash
# 최종 검토 후 프로덕션 트랙 배포
```

## 📈 배포 후 모니터링

### Sentry 대시보드 확인
- 오류율 모니터링
- 사용자 피드백 수집
- 크래시 분석

### 사용자 피드백
- 앱 스토어 리뷰 모니터링
- 지원 채널 설정
- 버그 리포트 처리

## 🔄 롤백 계획

### 긴급 롤백 시나리오
1. 이전 버전으로 즉시 롤백
2. 사용자에게 공지
3. 원인 분석 및 수정
4. 재배포

### 백업 및 복구
- 코드 백업: 자동 백업 시스템 작동 확인
- 사용자 데이터: 클라우드 백업 확인
- 설정 복구: SharedPreferences 마이그레이션 확인

---

**배포 준비 상태**: ✅ **완료**
**다음 단계**: 플랫폼별 스토어 계정 설정 및 초기 배포</content>
<parameter name="filePath">c:\Users\plain\SmartLedger\docs\DEPLOYMENT_CHECKLIST.md