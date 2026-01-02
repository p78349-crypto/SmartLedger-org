# 백업 지침서 (Backup Instructions)

**생성일**: 2025-12-06  
**프로젝트**: vccode1 - Multi-Account Household Ledger

---

## 📦 자동 백업 시스템

> 앱 내 백업/복원 보안(암호화/2단계) 설정 및 암호 동작은 [SECURITY_GUIDE.md](SECURITY_GUIDE.md) 참고.

### 현재 구현된 자동 백업
앱에는 이미 자동 백업 시스템이 구현되어 있습니다:

> 참고: 백업 암호화(암호 필요) 옵션이 ON이면, 암호 입력이 필요한 구조이므로 **자동 백업은 스킵**됩니다.

```dart
// lib/services/backup_service.dart
Future<void> autoBackupIfNeeded(String accountName) async {
  final now = DateTime.now();
  final last = await getLastBackupDate(accountName);
  
  // 7일마다 자동 백업
  final needWeekly = last == null || now.difference(last).inDays >= 7;
  
  // 매월 1일 자동 백업
  final needMonthly = last == null || 
    (isFirstDay && (last.month != now.month || last.year != now.year));
  
  if (needWeekly || needMonthly) {
    final fileName = '${accountName}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_auto.json';
    await saveBackupToFile(accountName, fileName);
  }
}
```

### 백업 파일 위치
- **Windows**: `C:\Users\[사용자명]\Documents\`
- **Android**: `/data/data/com.example.vccode1/files/`
- **iOS**: `~/Library/Application Support/`

---

## 🔧 수동 백업 방법

### 방법 1: 앱 내 백업 기능 사용

1. 앱 실행
2. 계정 메인 화면에서 "백업/복원" 메뉴 선택
3. "백업하기" 버튼 클릭
4. 백업 파일이 자동으로 생성됨

### 방법 2: 프로젝트 전체 백업 (권장)

#### Windows PowerShell 사용
```powershell
# 백업 디렉토리 생성
$backupDir = "C:\Users\plain\vccode1_backups"
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$backupPath = "$backupDir\backup_$timestamp"

# 디렉토리 생성
New-Item -ItemType Directory -Force -Path $backupPath

# 프로젝트 복사 (node_modules 제외)
Copy-Item -Path "C:\Users\plain\vccode1\*" -Destination $backupPath -Recurse -Exclude @("build", ".dart_tool", ".idea", "*.iml")

# 압축 (선택사항)
Compress-Archive -Path $backupPath -DestinationPath "$backupPath.zip"

Write-Host "백업 완료: $backupPath.zip"
```

### 방법 3: 유틸리티(lib/utils) 전용 백업

긴 시간 들여 정비한 유틸리티 모듈을 별도로 보관하려면 전용 스크립트를 사용할 수 있습니다.

#### PowerShell 스크립트 사용
```powershell
# 기본 위치(C:\Users\plain\vccode1_utils_backups)에 백업 생성
./backup_utils.ps1

# 압축본으로 보관
./backup_utils.ps1 -Compress

# 다른 경로로 지정
./backup_utils.ps1 -BackupDir "D:\Archives\utils_backups"
```

> 스크립트는 `lib/utils` 폴더 전체를 `utils_manifest.txt`와 함께 보관하므로, 필요한 경우 폴더 통째로 복사하여 복원할 수 있습니다.

#### Git 사용 (버전 관리)
```bash
# Git 초기화 (처음 한 번만)
cd C:\Users\plain\vccode1
git init
git add .
git commit -m "Initial commit - 전체 코드 백업"

# 이후 백업
git add .
git commit -m "백업: $(date +%Y-%m-%d)"
git tag -a "backup-$(date +%Y%m%d)" -m "백업 태그"
```

---

## 📋 백업 체크리스트

### 백업 전 확인사항
- [ ] `flutter test` 실행해 `utils_presence_test.dart` 통과 확인 (유틸리티 폴더 보존 여부 점검)

- [ ] 사용자 데이터 (SharedPreferences, SQLite DB)

### 백업 제외 대상
- [ ] build/
- [ ] .dart_tool/
- [ ] .idea/
- [ ] *.iml
- [ ] .flutter-plugins
- [ ] .flutter-plugins-dependencies
- [ ] .packages

---

## 💾 데이터 백업

### SharedPreferences 데이터 백업
```dart
// 앱 내에서 실행
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

Future<void> backupSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys();
  final data = <String, dynamic>{};
  
  for (final key in keys) {
    data[key] = prefs.get(key);
  }
  
  final json = jsonEncode(data);
  final file = File('shared_prefs_backup.json');
  await file.writeAsString(json);
  
  print('SharedPreferences 백업 완료: ${file.path}');
}
```

### SQLite 데이터베이스 백업
```dart
// 데이터베이스 파일 복사
import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<void> backupDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final dbFile = File('${dir.path}/app_database.sqlite');
  
  if (await dbFile.exists()) {
    final backupFile = File('${dir.path}/app_database_backup.sqlite');
    await dbFile.copy(backupFile.path);
    print('데이터베이스 백업 완료: ${backupFile.path}');
  }
}
```

---

## 🔄 복원 방법

### 프로젝트 복원
```powershell
# 백업 파일 압축 해제
Expand-Archive -Path "C:\Users\plain\vccode1_backups\backup_2025-12-06_120000.zip" -DestinationPath "C:\Users\plain\vccode1_restored"

# 복원된 프로젝트로 이동
cd C:\Users\plain\vccode1_restored

# 의존성 설치
flutter pub get

# 빌드 파일 생성
flutter pub run build_runner build --delete-conflicting-outputs

# 앱 실행
flutter run -d windows
```

### 데이터 복원
1. 앱 실행
2. "백업/복원" 메뉴 선택
3. "복원하기" 버튼 클릭
4. JSON 백업 파일 선택
5. 복원 완료

---

## 📊 백업 전략

### 백업 주기
- **일일**: Git 커밋 (코드 변경 시)
- **주간**: 자동 백업 (7일마다)
- **월간**: 자동 백업 (매월 1일)
- **주요 릴리스 전**: 수동 전체 백업

### 백업 보관
- **로컬**: 최근 3개월
- **외부 저장소**: 모든 백업
- **클라우드**: 주요 버전만

---

## 🛡️ 백업 검증

### 백업 파일 검증
```powershell
# JSON 백업 파일 유효성 검사
$jsonContent = Get-Content "backup.json" -Raw
try {
    $jsonObject = $jsonContent | ConvertFrom-Json
    Write-Host "✅ JSON 파일 유효함"
} catch {
    Write-Host "❌ JSON 파일 손상됨"
}
```

### 복원 테스트
1. 백업 파일로 새 프로젝트 생성
2. 의존성 설치 확인
3. 빌드 성공 확인
4. 앱 실행 확인
5. 주요 기능 테스트

---

## 📝 백업 로그

### 백업 기록 양식
```
날짜: 2025-12-06
시간: 12:00:00
백업 유형: 전체 백업
파일명: backup_2025-12-06_120000.zip
크기: 50 MB
상태: 성공
비고: 코드 점검 후 백업
```

---

## 🚨 긴급 복구

### 데이터 손실 시
1. 최신 자동 백업 확인
2. JSON 백업 파일로 복원
3. SQLite 백업 파일 복사
4. SharedPreferences 복원

### 프로젝트 손상 시
1. 최신 Git 커밋으로 복원
2. 또는 압축 백업 파일 해제
3. 의존성 재설치
4. 빌드 파일 재생성

---

## 📞 백업 관련 문의

### 자주 묻는 질문

**Q: 백업 파일이 너무 큽니다.**  
A: build/, .dart_tool/ 폴더를 제외하고 백업하세요.

**Q: 자동 백업이 작동하지 않습니다.**  
A: BackupService의 autoBackupIfNeeded() 함수가 앱 시작 시 호출되는지 확인하세요.

**Q: 다른 기기로 데이터를 옮기고 싶습니다.**  
A: JSON 백업 파일을 내보내고 새 기기에서 복원하세요.

---

**마지막 업데이트**: 2025-12-06  
**다음 백업 예정**: 자동 (7일 후 또는 매월 1일)