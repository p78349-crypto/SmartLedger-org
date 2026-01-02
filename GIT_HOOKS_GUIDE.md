# 자동 백업/커밋 검증 시스템 설명서

**작성일**: 2025-01-03  
**시스템**: Git Hooks 기반 자동화

---

## 📋 개요

작업 완료 후 **자동 백업**과 **강제 검증**을 의무화하는 Git Hooks 시스템입니다.

### 두 가지 Hook

1. **Pre-Commit Hook** (커밋 전)
   - 정적 분석 실행 (`flutter analyze`)
   - 의존성 검증 (`flutter pub get`)
   - 실패 시 커밋 중단

2. **Post-Commit Hook** (커밋 후)
   - 자동 백업 생성
   - 주요 파일 보존
   - 커밋 해시 기록

---

## 🚀 빠른 시작

### 1단계: Git Hooks 활성화

```powershell
cd C:\Users\plain\SmartLedger
powershell -ExecutionPolicy Bypass -File setup_git_hooks.ps1 -Action enable
```

✅ **출력**:
```
Enabling Git Hooks...
ENABLED: pre-commit
ENABLED: post-commit
Git Hooks Configuration Complete!
```

### 2단계: 상태 확인

```powershell
powershell -ExecutionPolicy Bypass -File setup_git_hooks.ps1 -Action status
```

✅ **출력**:
```
Git Hooks Status:
pre-commit : ENABLED (Script: EXISTS)
post-commit : ENABLED (Script: EXISTS)
```

### 3단계: 커밋 수행

```powershell
git add .
git commit -m "프로젝트 명칭 변경: vccode1 -> SmartLedger"
```

---

## 🔄 자동 프로세스 흐름

### 커밋 실행 시

```
git commit -m "message"
    ↓
[Pre-Commit 검증 시작]
    ├─ 분석 검사: flutter analyze
    ├─ 의존성 확인: flutter pub get
    └─ 테스트 실행: flutter test
    ↓
✅ 모두 통과하면 커밋 진행
❌ 실패하면 커밋 중단 (백업 생성 안함)
    ↓
[커밋 완료]
    ↓
[Post-Commit 백업 시작]
    ├─ 백업 디렉토리 생성: backups/auto-backup-YYYY-MM-DD_HH-MM-SS/
    ├─ lib/ 폴더 복사
    ├─ test/ 폴더 복사
    ├─ tools/ 폴더 복사
    ├─ pubspec.yaml/pubspec.lock 복사
    └─ 분석 규칙 파일 복사
    ↓
✅ 백업 완료
📝 커밋 SHA 및 메시지 기록
```

---

## 📂 백업 구조

```
backups/
├── auto-backup-2025-01-03_10-15-30/
│   ├── lib/
│   ├── test/
│   ├── tools/
│   ├── pubspec.yaml
│   ├── pubspec.lock
│   ├── analysis_options.yaml
│   └── PROJECT_RENAMING_RECORD_2025-01-03.md
├── auto-backup-2025-01-03_10-20-45/
│   └── ...
└── ...
```

---

## ⚙️ 설정 파일

### Pre-Commit Hook Script

**위치**: `.git/hooks/pre-commit.ps1`

**기능**:
- `flutter analyze --no-pub`: 정적 분석
- `flutter pub get`: 의존성 확인
- `flutter test`: 단위 테스트

### Post-Commit Hook Script

**위치**: `.git/hooks/post-commit.ps1`

**기능**:
- 자동 백업 생성
- 커밋 메타데이터 기록
- 타임스탬프 포함

---

## 🛑 Git Hooks 비활성화

어떤 이유로든 자동 검증을 비활성화하려면:

```powershell
powershell -ExecutionPolicy Bypass -File setup_git_hooks.ps1 -Action disable
```

❌ **출력**:
```
Disabling Git Hooks...
DISABLED: pre-commit
DISABLED: post-commit
Git Hooks Disabled
```

### 재활성화

```powershell
powershell -ExecutionPolicy Bypass -File setup_git_hooks.ps1 -Action enable
```

---

## 📊 사용 통계

### 커밋 로그 확인

```powershell
git log --oneline -10
```

### 백업 이력 확인

```powershell
Get-ChildItem backups/auto-backup-* | Measure-Object
```

---

## 🐛 문제 해결

### 문제 1: Pre-Commit 실패

**원인**: 분석이나 테스트 실패

**해결방법**:
```powershell
# 1. 에러 확인
flutter analyze

# 2. 에러 수정

# 3. 다시 커밋
git add .
git commit -m "message"
```

### 문제 2: Hook 실행 안됨

**원인**: PowerShell 실행 정책 제한

**해결방법**:
```powershell
# Hook을 Batch 파일로 다시 생성
powershell -ExecutionPolicy Bypass -File setup_git_hooks.ps1 -Action enable
```

### 문제 3: 백업 용량 증가

**원인**: 자동 백업이 계속 생성됨

**해결방법**:
```powershell
# 오래된 백업 삭제 (선택 사항)
Get-ChildItem backups/auto-backup-* -Directory | 
  Sort-Object LastWriteTime | 
  Select-Object -SkipLast 5 | 
  Remove-Item -Recurse
```

---

## 📋 체크리스트

### 설정 완료 확인

- [ ] Git Hooks 활성화됨
- [ ] Pre-Commit Hook 작동함
- [ ] Post-Commit Hook 작동함
- [ ] 백업 디렉토리 생성됨
- [ ] 커밋 로그 기록됨

### 첫 커밋 테스트

```powershell
# 1. 테스트 파일 수정
echo "test" >> test.txt
git add test.txt

# 2. 커밋 실행
git commit -m "Test commit"

# 3. 결과 확인
Get-ChildItem backups/auto-backup-* | Select-Object -First 1 | 
  Get-ChildItem -Recurse | Measure-Object
```

---

## 🔐 보안 고려사항

1. **감도 높은 파일**: `.env`, `.secrets` 등은 `.gitignore`에 추가
2. **백업 암호화**: 프로덕션 환경에서는 암호화된 백업 권장
3. **용량 관리**: 오래된 백업은 주기적으로 정리
4. **접근 제어**: 백업 디렉토리의 권한 관리

---

## 📞 문의 및 지원

- Git Hooks 관련: `.git/hooks/` 디렉토리의 스크립트 파일 참조
- 백업 관련: `backups/` 디렉토리 구조 확인
- 커밋 기록: `git log --stat` 명령으로 상세 조회

---

## 📝 참고 자료

- [Git Hooks 공식 문서](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
- [PowerShell 스크립팅](https://docs.microsoft.com/powershell/)
- [Flutter 분석 도구](https://flutter.dev/docs/testing/code-metrics)

---

**마지막 업데이트**: 2025-01-03  
**상태**: ✅ 활성화됨
