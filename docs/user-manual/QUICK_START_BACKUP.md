# 빠른 백업 가이드 (Quick Backup Guide)

**생성일**: 2025-12-06

---

## 🚀 즉시 백업 실행 방법

### 방법 1: 배치 파일 사용 (권장)

1. **PowerShell 또는 명령 프롬프트 열기**
   - 프로젝트 폴더에서 마우스 우클릭 > "터미널에서 열기"

2. **백업 스크립트 실행**
   ```cmd
   backup_project.bat
   ```

3. **백업 완료 확인**
   - 백업 위치: `C:\Users\plain\vccode1_backups\`
   - 폴더명: `vccode1_backup_YYYY-MM-DD_HHMM`

### 방법 2: PowerShell 스크립트 사용

1. **PowerShell 열기**
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\backup_project.ps1 -Compress
   ```

2. **백업 완료 확인**
   - 백업 파일: `C:\Users\plain\vccode1_backups\vccode1_backup_YYYY-MM-DD_HHMMSS.zip`

### 방법 3: 수동 복사

1. **프로젝트 폴더 전체 복사**
   ```
   C:\Users\plain\vccode1
   ```

2. **다음 위치에 붙여넣기**
   ```
   C:\Users\plain\vccode1_backups\vccode1_backup_manual_YYYY-MM-DD
   ```

3. **불필요한 폴더 삭제** (선택사항)
   - `build\`
   - `.dart_tool\`
   - `.idea\`

---

## 📦 생성된 백업 파일

### 백업 스크립트
1. **backup_project.bat** - Windows 배치 파일 (가장 간단)
2. **backup_project.ps1** - PowerShell 스크립트 (압축 기능 포함)

### 문서 파일
1. **CODE_INSPECTION_REPORT.md** - 전체 코드 점검 보고서
2. **BACKUP_INSTRUCTIONS.md** - 상세 백업 지침서
3. **REFACTORING_CHECKLIST.md** - 리팩토링 체크리스트
4. **SUMMARY_2025-12-06.md** - 작업 요약
5. **QUICK_START_BACKUP.md** - 이 파일

---

## ✅ 백업 후 확인사항

### 백업 파일 확인
- [ ] 백업 폴더가 생성되었는가?
- [ ] `lib/` 폴더가 포함되어 있는가?
- [ ] `pubspec.yaml` 파일이 포함되어 있는가?
- [ ] 모든 `.md` 문서가 포함되어 있는가?
- [ ] `BACKUP_INFO.txt` 파일이 생성되었는가?

### 백업 크기 확인
- 일반적인 백업 크기: **20-50 MB**
- 압축 후 크기: **5-15 MB**

---

## 🔄 복원 방법

### 백업에서 복원하기

1. **백업 폴더 복사**
   ```
   C:\Users\plain\vccode1_backups\vccode1_backup_YYYY-MM-DD_HHMM
   ```

2. **원하는 위치에 붙여넣기**
   ```
   C:\Users\plain\vccode1_restored
   ```

3. **터미널에서 복원된 폴더로 이동**
   ```cmd
   cd C:\Users\plain\vccode1_restored
   ```

4. **의존성 설치**
   ```cmd
   flutter pub get
   ```

5. **빌드 파일 생성**
   ```cmd
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

6. **앱 실행**
   ```cmd
   flutter run -d windows
   ```

---

## 📊 백업 내용

### 포함된 항목
- ✅ 소스 코드 (`lib/`, `test/`)
- ✅ 플랫폼 설정 (`android/`, `ios/`, `windows/`, `web/`, `linux/`, `macos/`)
- ✅ 설정 파일 (`pubspec.yaml`, `analysis_options.yaml`)
- ✅ 문서 (모든 `.md` 파일)
- ✅ 스크립트 (모든 `.ps1` 파일)

### 제외된 항목
- ❌ `build/` (빌드 결과물)
- ❌ `.dart_tool/` (자동 생성)
- ❌ `.idea/` (IDE 설정)
- ❌ `.vscode/` (IDE 설정)
- ❌ `node_modules/` (없음)
- ❌ `.git/` (버전 관리)

---

## 🎯 다음 단계

### 백업 완료 후
1. ✅ 백업 파일 확인
2. ⏳ 외부 저장소에 복사 (USB, 클라우드)
3. ⏳ 정기 백업 일정 설정

### 코드 개선 작업
1. ⏳ 리팩토링 시작 (`REFACTORING_CHECKLIST.md` 참조)
2. ⏳ 테스트 코드 작성
3. ⏳ 문서 업데이트

---

## 💡 팁

### 정기 백업 설정
Windows 작업 스케줄러에 백업 스크립트 등록:
1. 작업 스케줄러 열기
2. 기본 작업 만들기
3. 트리거: 매주 금요일 오후 6시
4. 작업: `backup_project.bat` 실행

### Git 사용 권장
```bash
# 프로젝트 폴더에서
git init
git add .
git commit -m "Initial commit - Code inspection backup"
git tag -a "backup-2025-12-06" -m "Full backup after code inspection"
```

---

## 📞 문제 해결

### 백업 스크립트가 실행되지 않을 때
1. **PowerShell 실행 정책 확인**
   ```powershell
   Get-ExecutionPolicy
   ```

2. **임시로 정책 변경**
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```

3. **배치 파일 사용**
   ```cmd
   backup_project.bat
   ```

### 백업 폴더가 생성되지 않을 때
1. 백업 디렉토리 수동 생성
   ```cmd
   mkdir C:\Users\plain\vccode1_backups
   ```

2. 권한 확인 (관리자 권한으로 실행)

---

## 📝 백업 기록

### 백업 로그 양식
```
날짜: 2025-12-06
시간: [실행 시간]
방법: backup_project.bat
크기: [백업 크기] MB
상태: [성공/실패]
비고: 코드 점검 후 첫 백업
```

---

**마지막 업데이트**: 2025-12-06  
**다음 백업 권장**: 2025-12-13 (7일 후)