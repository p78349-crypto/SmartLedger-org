# SmartLedger 개발 규칙 (2026-02-14)

## 📋 매 작업마다 필수 따라야 할 규칙

### 🔴 Rule 1: 중요 작업 전 원본 백업
**중요한 기능 수정을 시작하기 전에 반드시 실행:**

```powershell
# 현재 상태 전체 폴더 복사 (원본 보관)
$timestamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$backupDir = 'C:\Users\plain\SmartLedger_backups'
$sourceFolder = 'C:\Users\plain\SmartLedger'
$backupName = "SmartLedger_before_$timestamp"

Copy-Item -Path $sourceFolder -Destination "$backupDir\$backupName" -Recurse -Force
Write-Host "✅ Backup created: $backupDir\$backupName"
```

**목적:** 코드 꼬이면 이전 버전 즉시 복구 가능

---

### 🟡 Rule 2: 코드 수정 후 즉시 검증 (필수!)

**순서:**
```
1️⃣ 코드 수정 완료
   ↓
2️⃣ flutter analyze 실행
   ↓
3️⃣ "No issues found!" 확인 ⭐ (필수!)
   ├─ YES → 다음 단계
   └─ NO → 즉시 수정 후 2️⃣부터 재시작
   ↓
4️⃣ flutter clean; flutter build apk --release
   ↓
5️⃣ "Built build\app\outputs\flutter-apk\app-release.apk" 확인
   ├─ YES → ✅ 완료 (이전 작업은 건드리지 않음)
   └─ NO → analyze 재확인 후 수정
```

**체크리스트:**
```
☐ 코드 수정
☐ flutter analyze → "No issues found!"
☐ flutter build apk --release → "Built ...apk"
☐ 위 3가지 모두 확인 후에만 다음 작업 시작
```

---

### 🟢 Rule 3: 각 작업은 독립적으로 처리

**금지사항:**
```
❌ 여러 기능을 동시에 수정
❌ 검증 없이 다른 파일 건드리기
❌ "나중에 정리" 미루기
❌ info 오류 무시하기
```

**필수사항:**
```
✅ 한 기능씩 수정 → 검증 → 완료
✅ 완료되면 그 파일은 건드리지 않음
✅ 새로운 기능 수정할 때 Rule 1 재실행
```

---

### 🔵 Rule 4: 코드 라인 수 제한

**파일 크기 규칙:**
```
✅ 200줄 이상 300줄 미만: 정상
⚠️ 300줄 이상: 분리 검토
❌ 500줄 이상: 즉시 분리 (part 파일 사용)
❌ 1000줄: 재설계 필요
```

---

### 🟠 Rule 5: 하루 작업 완료 절차

**작업 마친 후:**
```
1️⃣ flutter analyze (최종 확인)
2️⃣ git status (변경사항 확인)
3️⃣ 최종 백업 생성
   - 폴더명: SmartLedger_backup_Final_yyyy-MM-dd_HHmmss
   - 저장: C:\Users\plain\SmartLedger_backups\
4️⃣ 작업 로그 업데이트 (2026-2-14작업.md)
```

---

## 🚨 긴급 상황 대응

### 코드 꼬였을 때:
```
1️⃣ 현재 폴더 제외 (건드리지 않음)
2️⃣ C:\Users\plain\SmartLedger_backups\ 에서 
   "SmartLedger_before_*" 폴더 확인
3️⃣ 가장 최근 폴더를 원본으로 복구
4️⃣ Rule 1부터 다시 시작
```

---

## ✅ 현재 상태 (2026-02-14)

```
✅ flutter analyze: No issues found
✅ APK: 101.9MB
✅ 9가지 작업 완료
✅ 모든 파일 검증 완료

남은 작업:
⏳ 디바이스 테스트
⏳ 최종 백업
```

---

**이 규칙은 "골드 스탠다드"입니다.**
- 매 작업마다 반드시 따르기
- 귀찮다고 건너뛰지 않기
- 규칙을 지킬 때 3배 빨라짐 (나중에 디버깅 안 해도 되므로)
