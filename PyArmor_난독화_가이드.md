# PyArmor 소스코드 난독화 가이드 (재사용 템플릿)

> **작성일**: 2026-03-15  
> **검증 환경**: PyArmor 9.2.3 (Basic), Python 3.11.9, Windows 10/11  
> **적용 사례**: EPUB Translator (7개 파일, 10,650줄 → 난독화 성공)

---

## 1. 사전 준비

### 1-1. PyArmor 설치
```powershell
pip install pyarmor
```

### 1-2. 라이선스 활성화 (유료)
```powershell
# 라이선스 파일로 활성화 (Basic 이상 권장)
pyarmor reg pyarmor-regcode-XXXXX.txt
```

### 1-3. 라이선스 확인
```powershell
pyarmor --version
```
출력 예시:
```
Pyarmor 9.2.3 (basic), 012003, EPUB_Translator
License Type    : pyarmor-basic
License No.     : pyarmor-vax-012003
License To      : P.JeongSeo
License Product : EPUB_Translator
```

> **주의**: Basic 라이선스는 **한 제품(Product)에 귀속**됨.  
> 다른 프로젝트에 사용하려면 **추가 라이선스 구매** 또는  
> **Group/CI 라이선스**로 업그레이드 필요.  
> → [PyArmor 라이선스 정책](https://pyarmor.readthedocs.io/en/latest/licenses.html)

---

## 2. 난독화 실행 (핵심 명령어)

### 2-1. 기본 명령어
```powershell
# 단일 파일
pyarmor gen -O <출력폴더> <파일.py>

# 복수 파일 (공백으로 구분)
pyarmor gen -O <출력폴더> file1.py file2.py file3.py
```

### 2-2. 실전 예시 (EPUB Translator)
```powershell
pyarmor gen -O obf_dist `
    epub_helper.py `
    get_hardware_id.py `
    gui_epub_translator.py `
    gui_io_helper.py `
    license_key_generator.py `
    model_config_helper.py `
    security_helper.py
```

### 2-3. 출력 결과 구조
```
obf_dist/
├── pyarmor_runtime_XXXXXX/    ← 런타임 (필수 동봉)
│   ├── __init__.py
│   └── pyarmor_runtime.pyd    ← 네이티브 바이너리
├── epub_helper.py             ← 난독화된 파일
├── gui_epub_translator.py     ← 난독화된 파일
└── ...
```

---

## 3. 난독화된 파일의 내부 구조

난독화 후 `.py` 파일을 열면 아래처럼 보임:
```python
# Pyarmor 9.2.3 (basic), 012003, EPUB_Translator, 2026-03-15T10:02:25
from pyarmor_runtime_012003 import __pyarmor__
__pyarmor__(__name__, __file__, b'PY012003\x00\x03\x0b...<암호화 바이너리>')
```

- 원본 소스코드는 **완전히 제거**되고 암호화된 바이트열로 대체됨
- `pyarmor_runtime.pyd` (C 확장 모듈)이 런타임에 복호화하여 실행
- `uncompyle6` 등 디컴파일러로 **역분석 불가**

---

## 4. 배포 패키지 구성 스크립트 (템플릿)

아래를 프로젝트에 맞게 수정하여 사용:

```powershell
# ============================================================
# build_secure.ps1 — PyArmor 난독화 배포 빌드 템플릿
# ============================================================
$ErrorActionPreference = "Stop"

# ── 설정 ──────────────────────────────────────────────────
$OBF_DIR   = "obf_dist"          # 난독화 중간 출력
$DIST_DIR  = "dist_secure"       # 최종 배포 폴더
$PY_FILES  = @(                  # 난독화 대상 .py 파일 목록
    "main.py"
    "helper.py"
    "security.py"
    # ... 필요시 추가
)
$EXTRA_FILES = @(                # 추가 복사할 리소스
    "config.json"
    "requirements.txt"
    "README.txt"
    # ... 필요시 추가
)
$EXTRA_DIRS = @(                 # 추가 복사할 폴더(모델 등)
    # "Kokoro-82M"
    # ... 필요시 추가
)

# ── 1단계: 이전 빌드 정리 ─────────────────────────────────
Write-Host "[1/3] 기존 빌드 잔재 정리..."
if (Test-Path $OBF_DIR) {
    Remove-Item -Recurse -Force $OBF_DIR
}
if (Test-Path $DIST_DIR) {
    Remove-Item -Recurse -Force "$DIST_DIR\*" -ErrorAction SilentlyContinue
}

# ── 2단계: PyArmor 난독화 ─────────────────────────────────
Write-Host "[2/3] PyArmor 소스코드 난독화..."
$cmd = "pyarmor gen -O $OBF_DIR " + ($PY_FILES -join " ")
Invoke-Expression $cmd

# ── 3단계: 배포 폴더 구성 ─────────────────────────────────
Write-Host "[3/3] 배포 폴더 구성..."
New-Item -ItemType Directory -Force -Path $DIST_DIR | Out-Null

# 난독화된 코드 복사
Copy-Item -Path "$OBF_DIR\*" -Destination $DIST_DIR `
    -Recurse -Force

# 추가 파일 복사
foreach ($f in $EXTRA_FILES) {
    if (Test-Path $f) {
        Copy-Item $f -Destination $DIST_DIR -Force
    }
}

# 추가 폴더 복사
foreach ($d in $EXTRA_DIRS) {
    if (Test-Path $d) {
        Copy-Item -Path $d -Destination $DIST_DIR `
            -Recurse -Force
    }
}

Write-Host "=========================================="
Write-Host "✅ 보안 빌드 완료! → [$DIST_DIR]"
Write-Host "=========================================="
```

---

## 5. Inno Setup 설치 프로그램 연동

난독화된 `dist_secure` 폴더를 Inno Setup으로 패키징:

```iss
[Setup]
AppName=내 프로그램
AppVersion=1.0.0
DefaultDirName={autopf}\MyProgram
OutputDir=release_packages
OutputBaseFilename=MyProgram_Setup_v1.0.0

[Files]
; dist_secure 전체를 설치 대상으로 지정
Source: ".\dist_secure\*"; DestDir: "{app}"; \
    Flags: ignoreversion recursesubdirs createallsubdirs

; 대용량 모델 제외 예시 (사용자가 별도 다운로드)
; Source: ".\dist_secure\*"; Excludes: "nllb-200-*"; ...
```

빌드 명령:
```powershell
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" `
    installer_script.iss
```

---

## 6. USB 포터블 배포

설치 없이 USB에서 바로 실행하는 패키지:

```powershell
$USB = "USB_PORTABLE"
New-Item -ItemType Directory -Force -Path $USB | Out-Null

# 난독화된 코드 복사
Copy-Item -Path "dist_secure\*" -Destination $USB `
    -Recurse -Force

# AI 모델 폴더 복사 (필요한 것만)
Copy-Item "nllb-200-distilled-600M" -Destination $USB `
    -Recurse -Force
Copy-Item "Kokoro-82M" -Destination $USB `
    -Recurse -Force

# USB용 config: 모델 경로를 현재 폴더(".")로 설정
$cfg = Get-Content "$USB\config.json" -Raw -Encoding UTF8 `
    | ConvertFrom-Json
$cfg.model_path = "."
$cfg | ConvertTo-Json -Depth 10 `
    | Set-Content "$USB\config.json" -Encoding UTF8
```

---

## 7. 주의사항 & 트러블슈팅

### 7-1. 경로 문제 (`__file__` 금지)
난독화/배포 환경에서 `__file__` 기반 경로는 깨질 수 있음.  
**반드시 `get_base_path()` 같은 헬퍼 함수 사용:**

```python
import os, sys

def get_base_path():
    """PyInstaller/PyArmor/일반 실행 모두 호환"""
    if getattr(sys, 'frozen', False):
        return os.path.dirname(sys.executable)
    # PyArmor 환경에서도 안전
    return os.path.dirname(os.path.abspath(
        sys.modules['__main__'].__file__
    ))
```

코드 내 모든 리소스 경로:
```python
base = get_base_path()
model_path = os.path.join(base, "Kokoro-82M", "model.pth")
html_path  = os.path.join(base, "editor.html")
```

### 7-2. 한글 파일명 처리
PowerShell에서 한글 파일명을 복사할 때 `-LiteralPath` 사용:
```powershell
# ❌ 깨질 수 있음
Copy-Item -Path "실행.bat" -Destination $dst

# ✅ 안전
Copy-Item -LiteralPath "실행.bat" -Destination $dst
```

또는 유니코드 이스케이프 사용:
```powershell
$fileName = [char]0xC2E4 + [char]0xD589 + ".bat"  # "실행.bat"
Copy-Item -LiteralPath (Join-Path $scriptDir $fileName) `
    -Destination $dst -Force
```

### 7-3. `pyarmor_runtime` 폴더 필수
- 난독화된 `.py`는 `pyarmor_runtime_XXXXXX/` 폴더 없이 실행 불가
- **배포 시 반드시 함께 포함**해야 함
- 이 폴더 안의 `.pyd` 파일은 **OS/Python 버전에 종속**  
  → Windows에서 빌드하면 Windows에서만 실행됨

### 7-4. 난독화 대상 선별
| 난독화 대상 (✅) | 난독화 불필요 (❌) |
|---|---|
| 비즈니스 로직 | config.json (설정) |
| 라이선스/보안 코드 | requirements.txt |
| GUI 메인 코드 | HTML/CSS 리소스 |
| 헬퍼/유틸리티 | AI 모델 파일 (.bin, .onnx) |

### 7-5. 라이선스 제약 요약
| 라이선스 | 가격 | 프로젝트 수 | 파일 크기 |
|---|---|---|---|
| Trial (무료) | $0 | - | 소규모만 |
| Basic | ~$56 | **1개 제품** | 무제한 |
| Group | ~$159 | 무제한 | 무제한 |
| CI/CD | 별도 | 무제한 + CI | 무제한 |

> **다수 프로젝트 운용 시 Group 라이선스 권장**

---

## 8. 보안 수준 요약

| 공격 시도 | 차단 여부 |
|---|---|
| 텍스트 에디터로 소스 열람 | ✅ 차단 (바이너리 blob만 보임) |
| `uncompyle6` 등 디컴파일러 | ✅ 차단 (런타임 암호화) |
| `dis` 모듈 바이트코드 분석 | ✅ 차단 |
| 메모리 덤프 분석 | ⚠️ 고급 공격 — 상당히 어려움 |
| `.pyd` 네이티브 리버싱 | ⚠️ IDA Pro급 도구 필요 — 비용 대비 비현실적 |

**결론**: 일반 사용자/경쟁사의 소스 탈취는 **사실상 불가능**.  
국가급 기관이 `.pyd`를 리버싱하지 않는 한 안전.

---

## 9. 빠른 시작 체크리스트

```
□ 1. pip install pyarmor
□ 2. pyarmor reg <라이선스파일>  (유료 시)
□ 3. 난독화 대상 .py 파일 목록 정리
□ 4. pyarmor gen -O obf_dist file1.py file2.py ...
□ 5. obf_dist/ 내용물 → dist_secure/ 폴더로 복사
□ 6. config.json, 리소스, 모델 등 추가 복사
□ 7. __file__ 기반 경로 → get_base_path() 로 전환 확인
□ 8. pyarmor_runtime_XXXXXX/ 폴더 포함 확인
□ 9. dist_secure/ 폴더에서 python main.py 테스트 실행
□ 10. (선택) Inno Setup / USB 포터블 패키징
```

---

## 부록: EPUB Translator 실전 적용 기록

- **난독화 대상**: 7개 파일 (총 ~10,650줄)
- **PyArmor 버전**: 9.2.3 (Basic)
- **라이선스**: pyarmor-vax-012003 (EPUB_Translator 제품)
- **빌드 스크립트**: `build_epub_translator_secure.ps1`
- **출력**: `dist_buyer_secure/` (319.5MB 인스톨러)
- **USB 포터블**: `USB_PORTABLE/` (6.48GB, 모델 포함)
- **결과**: 모든 기능 정상 작동, 역공학 차단 확인
