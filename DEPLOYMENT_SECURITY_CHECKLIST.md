# 🔒 SmartLedger 배포 전 보안 점검 보고서

**작성일**: 2026-02-14  
**점검 범위**: 코드 노출 가능성, 암호화, 난독화, 프로덕션 빌드 설정

---

## ✅ 현재 적용된 보안 조치

### 1. 데이터베이스 암호화 (✅ 양호)
- **라이브러리**: `sqflite_sqlcipher` 사용
- **키 관리**: `DbEncryptionKeyManager` + `FlutterSecureStorage`
- **키 저장소**: iOS Keychain (iCloud 동기화 활성화)
- **키 길이**: 256비트 (32바이트) AES 암호화
- **보안 수준**: ⭐⭐⭐⭐⭐ (매우 우수)

```dart
// lib/database/db_encryption_key_manager.dart
final key = await DbEncryptionKeyManager.getOrCreateKey();
_globalProductDb = await openDatabase(path, password: key, ...);
```

### 2. Flutter 코드 난독화 (✅ 설정됨)
- **빌드 스크립트**: `build_optimized.ps1`, `scripts/build_release_obfuscate.ps1`
- **플래그**: `--obfuscate --split-debug-info=build/debug-info`
- **효과**: Dart 코드 심볼, 클래스명, 함수명 난독화
- **보안 수준**: ⭐⭐⭐⭐ (우수)

```powershell
# build_optimized.ps1
flutter build apk --release --shrink --obfuscate --split-debug-info=build/debug-info
flutter build appbundle --release --shrink --obfuscate --split-debug-info=build/debug-info
```

### 3. Android 코드 축소 (✅ 활성화)
- **설정 위치**: `android/app/build.gradle.kts`
- **minifyEnabled**: `true` - Java/Kotlin 코드 난독화
- **shrinkResources**: `true` - 미사용 리소스 제거
- **ProGuard**: `proguard-android-optimize.txt` + `proguard-rules.pro`
- **보안 수준**: ⭐⭐⭐⭐ (우수)

```kotlin
release {
    isMinifyEnabled = true
    isShrinkResources = true
    proguardFiles(
        getDefaultProguardFile("proguard-android-optimize.txt"),
        "proguard-rules.pro"
    )
}
```

### 4. 민감 데이터 보호 (✅ 양호)
- **하드코딩된 API 키 없음**: ✅ 확인됨
- **비밀번호 저장**: SecureStorage/SharedPreferences 사용
- **ROOT 인증**: PIN/생체인증/비밀번호 다중 인증
- **백업 암호화**: BackupCrypto.encryptJsonPayload 지원

---

## ⚠️ 개선 필요 사항

### 1. ProGuard 규칙 강화 (⚠️ 중요도: 높음)

**현재 문제**:
```
# android/app/proguard-rules.pro
-dontshrink      # ❌ 코드 축소 비활성화
-dontoptimize    # ❌ 최적화 비활성화
```

**문제점**:
- `-dontshrink`: 사용되지 않는 코드도 APK에 포함 → 앱 크기 증가 + 코드 노출 위험
- `-dontoptimize`: 바이트코드 최적화 비활성화 → 리버스 엔지니어링 용이

**권장 수정**:
```proguard
## 보안 강화 설정
# -dontshrink     # 제거 (build.gradle의 minifyEnabled가 제어)
# -dontoptimize   # 제거 (최적화 활성화)

-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable  # 크래시 리포트용

## Flutter 필수 보호
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## 앱 특정 보호 (필요 시 추가)
-keep class com.yourcompany.smartledger.** { *; }
```

**적용 방법**:
1. `android/app/proguard-rules.pro` 수정
2. 테스트 빌드 실행: `.\build_optimized.ps1`
3. 앱 기능 전체 테스트 (특히 결제, 백업/복원)

---

### 2. 프로덕션 서명 설정 (⚠️ 중요도: 매우 높음)

**현재 문제**:
```kotlin
// android/app/build.gradle.kts
release {
    signingConfig = signingConfigs.getByName("debug")  // ❌ 디버그 키 사용
}
```

**위험**:
- Debug 키는 공개되어 있고, 모든 개발자가 사용 가능
- Google Play는 release 키로 서명된 앱만 허용
- 업데이트 시 서명이 달라지면 앱 배포 불가

**권장 수정**:

#### Step 1: Keystore 생성
```powershell
# Android Studio 또는 keytool로 생성
keytool -genkey -v -keystore smartledger-release.keystore `
  -alias smartledger -keyalg RSA -keysize 2048 -validity 10000
```

#### Step 2: key.properties 작성
```
# android/key.properties (⚠️ .gitignore에 추가)
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=smartledger
storeFile=C:\\path\\to\\smartledger-release.keystore
```

#### Step 3: build.gradle.kts 수정
```kotlin
// android/app/build.gradle.kts
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties["storeFile"] ?: "")
            storePassword = keystoreProperties["storePassword"] as String?
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")  // ✅ 프로덕션 키
            // ...
        }
    }
}
```

#### Step 4: .gitignore 업데이트
```
# android/key.properties - 절대 커밋 금지
*.keystore
key.properties
```

---

### 3. 디버그 로그 제거 (⚠️ 중요도: 중간)

**현재 문제**:
```dart
// 여러 파일에 debugPrint 존재
debugPrint('🔍 Receipt processing started');
debugPrint('OCR text length: ${ocrText.length} chars');
debugPrint('✅ Gemma extraction successful!');
```

**위험**:
- Release 빌드에서도 logcat에 출력됨
- 민감한 데이터(거래 내역, 사용자 정보) 노출 가능
- 앱 동작 흐름 파악 용이

**권장 조치**:

#### Option A: kReleaseMode 체크
```dart
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  debugPrint('🔍 Receipt processing started');
}
```

#### Option B: 커스텀 로거
```dart
// lib/utils/logger.dart
import 'package:flutter/foundation.dart';

void appLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
```

#### Option C: 빌드 시 자동 제거
```yaml
# pubspec.yaml
flutter:
  # Release 빌드에서 디버그 코드 제거
  strip-debug: true
```

**일괄 변경 스크립트**:
```powershell
# scripts/remove_debug_prints.ps1
Get-ChildItem -Path lib -Recurse -Filter *.dart | ForEach-Object {
    (Get-Content $_.FullName) -replace 'debugPrint\(', 'if (kDebugMode) debugPrint(' | 
        Set-Content $_.FullName
}
```

---

## 📋 배포 전 체크리스트

### 필수 항목 (배포 전 반드시 완료)
- [ ] **프로덕션 keystore 생성 및 적용**
- [ ] **key.properties → .gitignore 추가**
- [ ] **ProGuard 규칙에서 -dontshrink/-dontoptimize 제거**
- [ ] **Release 빌드 테스트** (`.\build_optimized.ps1`)
- [ ] **앱 기능 전체 검증** (로그인, 거래 추가, 백업/복원, ROOT 인증)

### 권장 항목
- [ ] debugPrint를 kDebugMode로 감싸기
- [ ] Google Play 앱 서명 활성화 (Play Console)
- [ ] R8 풀모드 활성화 (`android.enableR8.fullMode=true`)
- [ ] 크래시 리포팅 설정 (Sentry/Firebase Crashlytics)

### 보안 검증
- [ ] APK 역컴파일 테스트 (jadx/apktool)
- [ ] 하드코딩된 키/비밀번호 재검토
- [ ] logcat 출력 확인 (민감 정보 노출 여부)
- [ ] 데이터베이스 파일 암호화 확인

---

## 🚀 안전한 배포 절차

### 1. 빌드 준비
```powershell
# 1. 의존성 정리
flutter clean
flutter pub get

# 2. 코드 분석
flutter analyze

# 3. 테스트 실행
flutter test
```

### 2. Release 빌드
```powershell
# APK (직접 배포용)
.\build_optimized.ps1

# AAB (Google Play용)
flutter build appbundle --release --shrink --obfuscate `
  --split-debug-info=build/debug-info
```

### 3. 빌드 검증
```powershell
# APK 크기 확인
Get-Item build\app\outputs\flutter-apk\app-release.apk | 
  Select-Object Name, @{N='SizeMB';E={[math]::Round($_.Length/1MB,2)}}

# 서명 확인
keytool -printcert -jarfile build\app\outputs\flutter-apk\app-release.apk
```

### 4. 보안 스캔 (권장)
```powershell
# MobSF (Mobile Security Framework)
# https://github.com/MobSF/Mobile-Security-Framework-MobSF

# APK 분석
docker run -it -p 8000:8000 opensecurity/mobile-security-framework-mobsf:latest
```

---

## 📊 보안 등급 요약

| 항목 | 현재 상태 | 보안 등급 | 개선 후 |
|------|----------|----------|---------|
| 데이터베이스 암호화 | ✅ 적용 | ⭐⭐⭐⭐⭐ | - |
| Flutter 코드 난독화 | ✅ 적용 | ⭐⭐⭐⭐ | - |
| Android 코드 축소 | ⚠️ 부분 적용 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 프로덕션 서명 | ❌ 미적용 | ⭐ | ⭐⭐⭐⭐⭐ |
| 디버그 로그 제거 | ⚠️ 필요 | ⭐⭐⭐ | ⭐⭐⭐⭐ |

**종합 보안 등급**: ⭐⭐⭐ (중간) → ⭐⭐⭐⭐⭐ (매우 우수) [개선 후]

---

## 🔗 참고 자료

- [Flutter Code Obfuscation](https://docs.flutter.dev/deployment/obfuscate)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [ProGuard Manual](https://www.guardsquare.com/manual/configuration/usage)
- [R8 Optimization](https://developer.android.com/studio/build/shrink-code)
- [Flutter Security Best Practices](https://flutter.dev/security)

---

## ✅ 최종 권장 사항

### 즉시 적용 (배포 전 필수)
1. **프로덕션 keystore 생성 및 적용** (30분)
2. **ProGuard 규칙 개선** (10분)
3. **Release 빌드 전체 테스트** (1시간)

### 단기 개선 (1주일 내)
1. debugPrint → kDebugMode 감싸기 (2시간)
2. APK 역컴파일 테스트 (30분)
3. 보안 문서화 업데이트

### 장기 개선 (이후)
1. Firebase Crashlytics 연동
2. 정기 보안 감사 (월 1회)
3. 침투 테스트 (분기 1회)

---

**결론**: 현재 데이터베이스 암호화와 Flutter 난독화는 잘 적용되어 있으나, 프로덕션 서명 설정과 ProGuard 최적화가 배포 전 반드시 필요합니다. 위 체크리스트를 완료하면 Play Store 배포에 안전한 상태가 됩니다.
