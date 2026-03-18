# AI Agent 코딩 규칙 (SSOT v3)

> **요약**: Stage0(Plan) → A(80자·300줄·모듈화·ErrorZero) → B(검증·추론로그) → C(분리·배럴·의존성) → D(안전) → E(보안) → F(UI) → G(체크리스트) → H(롤백) → I(관련문서) → J(주입문)


> 통합 버전 v3 (2026-03-18) — 2026년형 에이전트 룰 반영
> 이전 파일: `#-AI_CODE_RULES-(ORG).md`, `AI_CODE_RULES2.md`,
> `AI_CODE_RULES (2).md`, `AI_WORK_LOG_RULES.md` → 모두 Deprecated

---

## Stage 0. Plan Mode (설계 우선 원칙)

> 코드를 쓰기 전에 **먼저 생각한다**. Token 낭비와 삽질을 원천 차단.

| 조건 | 행동 |
|------|------|
| 파일 2개 이상 수정 | Plan 필수 |
| 50라인 이상 로직 변경 | Plan 필수 |
| 신규 파일 생성 | Plan 필수 |
| 단순 버그 수정 (1파일, <50라인) | Plan 생략 가능 |

### Plan Mode 프로세스
1. **Plan 작성** — 변경 대상, 파일 경계, A2 라인 수 예측, import 영향 분석
2. **사용자 승인** — "Proceed" 사인 확인 후 구현 착수
3. **승인 없이 코드 생성 → 반려(Reject) 대상**

---

## A. 4대 절대 원칙

| # | 원칙 | 기준 |
|---|------|------|
| A1 | **80자 제한** | 코드 라인 폭 80자 이내 (코드·주석 포함, import/URL/문자열 리터럴은 예외) |
| A2 | **300줄 제한** | 단일 파일 300줄 이내 (250줄↑ 분리 준비, 280줄↑ 추가 금지) |
| A3 | **선(先) 모듈화** | 구현 전 Structure Plan 제시 → 사용자 승인 후 착수 |
| A4 | **Error ZERO** | `flutter analyze` 에러 0 유지 |

### A2 세부: Warning Zone 프로세스
> **수정 전 대상 파일의 현재 라인 수를 먼저 보고한다.**
> 수정 후 280줄 초과가 예상되면 코드 작성 전 분할 계획부터 수립한다.

| 구간 | 상태 | 행동 |
|------|------|------|
| ~249줄 | 🟢 안전 | 정상 작업 |
| 250~279줄 | 🟡 경고 | 분리 준비 — 다음 작업 시 분할 계획 수립 |
| 280~300줄 | 🔴 동결 | **신규 코드 추가 금지** — 분할 먼저 |
| 300줄↑ | ⛔ 위반 | 즉시 분할 실행 |

**예외**:
- 테스트 파일(`test/`)은 setup/mocking 특성상 **500줄까지 허용**
- 자동 생성 파일(`*.g.dart`, `*.freezed.dart`) — 라인 수 제한 **적용 제외**
- `part/part of` 파일 — 본체 파일과 합산하여 300줄 기준 적용

### A3 세부: 설계 승인 = Stage 0
> "일단 짜고 나중에 옮긴다" = **금지**.
> A3의 구체적 프로세스는 **Stage 0 Plan Mode**와 동일 — 중복 참조 불필요.

---

## B. 검증 & 보고

1. **거짓 보고 금지** — 터미널 직접 실행 결과만 보고
2. **완료 전 필수 실행**
   - `flutter analyze` → 에러/경고 0
   - `flutter test` → 전체 통과
   - 보안 작업 시 `.\local_security_check.ps1` 실행
3. **증거 포함 보고** — 실행 결과 캡처를 보고에 첨부
4. **작업 상세 기록** — 아래 5항목 필수 기재:
   - 작업 절차 / 문제 위치 / 수정 내용(Before→After)
   - 현재 상태 / 잔여 이슈 및 권장 사항
5. **추론 로그 (Self-Correction)** — 에러 해결 시 필수:
   - `[에러 로그]` → `[가설]` → `[검증 결과]` → `[수정 액션]`
   - 단순 "에러남" 보고 금지 — Why→How→Action 순서 기록

---

## C. 코드 품질

| 규칙 | 내용 |
|------|------|
| **로직 분리** | 비즈니스 로직 → `lib/utils` · `lib/logic` (UI 파일 금지) |
| **모듈화** | 반복/공통 UI → `lib/widgets/` 범용 위젯 추출 |
| **import 호환** | 파일 분리 시 기존 import는 export 연결로 유지 |
| **배럴 파일** | 도메인 폴더마다 배럴 파일로 export 통합 (아래 참조) |
| **의존성 분석** | 수정 전 대상 파일의 상위 의존성(Dependency) 트리를 먼저 분석·보고 |
| **환경 명시** | 외부 의존성 → 스크립트 상단 주석 또는 REQUIREMENTS.md |
| **예외 처리** | 엔트리 포인트에 Try-Catch, 에러 시 복구 방법 안내 |

### C 세부: 배럴 파일 vs part 패턴

| 패턴 | 사용 조건 | 예시 |
|------|----------|------|
| **배럴 파일 (export)** | 독립 클래스/유틸 분리 시 | `auth.dart` → export 3개 |
| **part/part of** | 하나의 클래스가 너무 커서 분할 시 | `backup_service.dart` + 7개 part |

> 기존 `part` 패턴이 있는 파일은 무리하게 배럴로 전환하지 않는다.
> 신규 분리 시에는 **배럴 파일 우선** 적용.

파일 분할 시 import 지저분해지는 것을 방지:
```
lib/logic/auth/
├── auth.dart              ← 배럴 파일 (외부는 이것만 import)
├── auth_pin_logic.dart
├── auth_password_logic.dart
└── auth_policy_logic.dart
```
```dart
// auth.dart (배럴 파일)
export 'auth_pin_logic.dart';
export 'auth_password_logic.dart';
export 'auth_policy_logic.dart';
```
```dart
// 외부 사용처 — 하나만 import
import 'package:smart_ledger/logic/auth/auth.dart';
```

---

## D. 작업 안전

| 규칙 | 내용 |
|------|------|
| **무단 변경 금지** | 사용자 지시 없는 자동 생성/삭제/수정 금지 |
| **대규모 리팩터** | 사전 승인 + 원본 격리 후 단계적 진행 |
| **작업량 제한** | 단일 사이클 변경 300라인 내외 |
| **수정 전 백업** | 원본 파일 수정 전 백업 폴더에 복사 (아래 D1 참조) |
| **원본 보존** | 300줄↑ 리팩터링 시 원본 복사 후 작업, 원본은 복구용 유지 |
| **설계 우선** | 50라인↑ 로직 변경 또는 파일 신설 시, Stage 0 Plan Mode 필수 |

### D1. 수정 전 원본 백업 프로세스

> **원칙**: 원본을 먼저 백업한 뒤 수정한다. 문제 발생 시 백업에서 즉시 복구한다.

**절차**:
1. **백업 폴더 생성** — `_backup_before_edit/YYYY-MM-DD_HHmmss/`
2. **원본 복사** — 수정 대상 파일을 원래 경로 구조 유지한 채 복사
3. **수정 착수** — 백업 완료 확인 후 코드 수정 시작
4. **문제 발생 시 복구** — 백업 폴더에서 원본 덮어쓰기로 즉시 복원
5. **작업 완료 후** — 3건 이상 작업 완료 시 정식 백업 또는 로컬 커밋 수행

**적용 기준**:
| 조건 | 백업 필수 여부 |
|------|:-----------:|
| 파일 2개 이상 수정 | ✅ 필수 |
| 50라인 이상 변경 | ✅ 필수 |
| 300줄↑ 파일 리팩터링 | ✅ 필수 |
| 단순 버그 수정 (1파일, <50라인) | 선택 (권장) |

**PowerShell 예시**:
```powershell
$ts = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$backupDir = "_backup_before_edit\$ts"
New-Item -ItemType Directory -Path $backupDir -Force

# 수정 대상 파일 백업 (경로 구조 유지)
$files = @('lib/services/my_service.dart', 'lib/utils/helper.dart')
foreach ($f in $files) {
    $dest = Join-Path $backupDir $f
    New-Item -ItemType Directory -Path (Split-Path $dest) -Force
    Copy-Item $f $dest
}
```

**복구 예시**:
```powershell
# 문제 발생 시 — 백업에서 원본 위치로 복원
$backupDir = '_backup_before_edit\2026-03-18_153000'
Copy-Item "$backupDir\lib\services\my_service.dart" 'lib\services\my_service.dart' -Force
```

---

## E. 보안 & 저작권

- 하드코딩 비밀번호 · API 키 · 개인정보 노출 **절대 금지**
- 중국계 AI 모델/서비스 사용 **금지** (Qwen 등)
- 허용: 검증된 서구권 오픈소스 모델 로컬 구동만 (Gemma, Llama 등)
- 저작권 위반 소지 코드 사용 금지
- info 이슈·경고 없이 깔끔하게 정리

---

## F. UI 정책

- 메인 페이지 = 순수 게이트웨이 (기능 진입점만)
- 아이콘: 48-60px (메인) / 24px (하단)
- 기능 그룹화: 더보기/햄버거 메뉴 활용
- 하단 버튼 3-4개 제한
- 예시/데모 코드는 `lib/`에 두지 않음

---

## G. 완료 체크리스트

```
[ ] S0  Plan Mode 완료 (2파일↑ 또는 50라인↑ 변경 시)
[ ] A1  80자 이내
[ ] A2  300줄 이내 (수정 전 라인 수 보고 완료)
[ ] A3  모듈화 Structure Plan 승인 Proceed
[ ] A4  flutter analyze 에러 0
[ ] B   flutter test 통과
[ ] B5  에러 시 추론 로그 포함 (Why→How→Action)
[ ] C   로직 분리 + 배럴 파일 + 의존성 분석 확인
[ ] D   무단 변경 없음, 수정 전 원본 백업(D1) 완료
[ ] E   보안·저작권 점검
```

---

## H. 위반 시 롤백 절차

| 위반 | 즉시 조치 |
|------|----------|
| A2 300줄 초과 | 추가 코드 revert → 분할 Plan 수립 후 재작업 |
| A4 에러 발생 | 에러 유발 변경 revert → 추론 로그(B5) 작성 → 재시도 |
| Stage 0 미승인 구현 | 코드 전량 revert → Plan부터 재시작 |
| import 깨짐 | 배럴 파일 export 누락 확인 → 즉시 보완 |
| 다중 파일 파손 | `_backup_before_edit/` 에서 원본 일괄 복원(D1) → 재작업 |

> **원칙**: revert 먼저, 원인 분석 후, 재작업.
> 절대 에러 상태에서 추가 코드를 쌓지 않는다.

---

## I. 관련 문서

| 문서 | 역할 |
|------|------|
| `AI_CODE_RULES.md` (본 문서) | 코딩 규칙 SSOT |
| `INFRA_PERFORMANCE_RULES.md` | 인프라·성능·장애복구·보안 패치 규칙 |
| `_deprecated_rules/` | 이전 규칙 파일 보관 (이력용) |

---

## J. SSOT 주입 선언문 (새 세션 시작 시)

> 아래를 새 대화/에이전트 호출 시 선언하여 규칙 강제 적용:

```
너는 [SSOT v3 2026-03-18] 규칙을 준수하는 시니어 수석 개발자다.
모든 작업 전 AI_CODE_RULES.md를 대조하라.

절대 원칙:
- A2(300줄)와 A4(Error ZERO)는 타협 불가능.
- 2파일 이상 수정 또는 50라인↑ 변경 시 Stage 0 Plan Mode 필수.
- 에러 해결 시 추론 로그(Why→How→Action) 기록.
- 파일 분리 시 배럴 파일 export 구조 활용.
- 수정 전 대상 파일의 의존성 트리를 먼저 분석.
- 작업 보고 시 G항 완료 체크리스트를 반드시 포함.
- 수정 전 원본 백업(D1) 필수 → 문제 시 백업에서 즉시 복구.
- 위반 시 H항 롤백 절차에 따라 revert 먼저 실행.
- 인프라/성능 관련은 INFRA_PERFORMANCE_RULES.md 참조.
```
