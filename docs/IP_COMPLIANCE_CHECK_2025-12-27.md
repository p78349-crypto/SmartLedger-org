# 지적재산권(IP) / 오픈소스 라이선스 점검 보고서 (2025-12-27)

## 문서 정보
- 문서 성격: 프로젝트 내부 점검 기록(내부 감사/준법 목적) / 참고자료용
- 작성일: 2025-12-27
- 대상 리포지토리: vccode1 (Flutter/Dart)
- 작성 기준: “근거(artifact) 기반 점검 + 재현 가능한 절차”

## 상태(초안)
- 본 문서는 **현재 단계의 점검 결과를 기록한 초안**입니다.
- 프로젝트가 “완성 버전/출시 버전”에 가까워질 때, `tools/ip_recheck.ps1 -WithIndex`로 재조사 후 최종 결론(OK/주의/보류)을 확정하여 완결합니다.

## 상태(체크)
- [x] OK (배포 진행 가능) - **자산 소스 확인 후 ASSETS_SOURCES.md 완성 필요**
- [ ] 주의 (배포 가능하나 표기/NOTICE 등 추가 조치 필요)
- [ ] 보류 (라이선스 불명확/조건 미충족으로 배포 보류)

## 서명/검토
- 작성자: SmartLedger Development Team
- 검토자(선택): Automated IP Compliance Scanner
- 작성 일시: 2025-12-27
- 검토 일시(선택): 2026-01-08 (최종 확정)

## 결론(요약)
- 결론: **오픈소스 의존성 사용(YES)** / 레포 내부 코드에 “외부 코드 복사·인용”을 명시적으로 보여주는 흔적(키워드/URL)은 **검색 범위 내에서 미발견**
- 조치: 패키지별 라이선스 파일을 로컬 캐시 기준으로 스캔하여 목록화했고, 핵심 근거 파일의 SHA-256 해시를 생성하여 무결성(변조 방지)을 강화함
- 주의: 본 문서는 법률 자문이 아니며, 실제 배포/상용화 시에는 라이선스 조건(특히 NOTICE/표기 의무)을 최종 확인 필요

## 목적
- 본 프로젝트(vccode1)에서 **외부(제3자) 코드/오픈소스 의존성**을 사용했는지 점검하고, 배포 시 준수해야 하는 **라이선스 준수 항목**을 기록합니다.

## 점검 범위
- Flutter/Dart 소스: `lib/`, `test/`, `tools/` 등
- Flutter/Dart 패키지 의존성: `pubspec.yaml`, `pubspec.lock`, 로컬 Pub 캐시(`%LOCALAPPDATA%/Pub/Cache/...`)
- Android/Flutter 템플릿 파일: `android/`, `windows/`, `linux/`, `macos/`, `ios/` 내 기본 템플릿 포함

## 점검 환경(증거)
- Flutter 버전: `tools/_flutter_version.txt`
- Dart 버전: `tools/_dart_version.txt`

## 점검 방법(증거/근거)
### 1) 패키지(의존성) 라이선스 확인
- 의존성 목록/버전 근거: `pubspec.lock`
- 실제 설치된 패키지의 라이선스 파일 근거: `.dart_tool/package_config.json`에 기록된 package rootUri → 로컬 Pub 캐시의 패키지 폴더에서 `LICENSE*`, `COPYING`, `NOTICE` 파일 탐색
- 자동 생성 요약:
  - `dart run tools/generate_third_party_licenses_summary.dart`
  - 결과 문서: `docs/THIRD_PARTY_LICENSES_SUMMARY.md`

> 주의: 라이선스 전문(전체 텍스트)은 문서에 복사하지 않았습니다. (전문은 각 패키지 폴더의 LICENSE 파일을 참조)

### 2) 외부 코드 복사/출처 표기 흔적 탐색(레포 자체 코드)
- `lib/**` 범위에서 다음 키워드/패턴을 검색:
  - `StackOverflow`, `copied from`, `paste from`, `ported from`, `source:`, `reference:`, `출처`, `원문`, `SPDX-License-Identifier`
  - `raw.githubusercontent.com`, `gist.github.com`, `stackoverflow.com/questions/...` 등 직접 링크 패턴

## 점검 결과 요약
### A) 오픈소스 패키지 사용
- 본 프로젝트는 다수의 Flutter/Dart 오픈소스 패키지(의존성)를 사용합니다.
- 패키지별 **버전/라이선스 파일 존재 여부/추정 라이선스 타입**은 아래 문서에 기록했습니다:
  - `docs/THIRD_PARTY_LICENSES_SUMMARY.md`
- 스캔 결과:
  - 스캔된 패키지 수: 183
  - LICENSE 파일을 찾지 못한 패키지: 0

### B) 레포 내 ‘복사/인용’ 흔적
- `lib/**` 코드 범위에서 “외부 사이트/게시글/레포에서 복사해 왔음”을 직접적으로 나타내는 키워드/URL 패턴은 발견되지 않았습니다.
- 단, 플랫폼 템플릿 파일들(`windows/flutter/CMakeLists.txt` 등)에는 Flutter 이슈 링크 등 참고 URL이 존재할 수 있으며, 이는 통상 Flutter 템플릿에 포함되는 형태입니다.

## 이 문서의 성격(공문서 여부)과 가치
- 이 문서는 정부/기관이 발행한 **공문서가 아니라**, 프로젝트 내부에서 작성한 **자체 점검 기록(내부 감사/준법 문서)** 입니다.
- 다만, 아래의 “근거 자료(증거)”와 함께 보관하면, 추후에
  - 내부 품질/감사(작업 이력 추적)
  - 배포 전 OSS 준수 체크리스트
  - 분쟁/문의 대응 시 “어떤 근거로 점검했는지” 설명
  용도로 **실무적 가치**가 충분합니다.

## 증거성(신뢰도) 강화 권고
- 동일 날짜/릴리즈 단위로 아래 파일을 함께 보관(가능하면 Git 이력 포함):
  - `pubspec.lock` (의존성/버전 증거)
  - `.dart_tool/package_config.json` (실제 설치된 패키지 경로 증거)
  - `tools/_flutter_version.txt` / `tools/_dart_version.txt` (점검 환경 증거)
  - `docs/THIRD_PARTY_LICENSES_SUMMARY.md` (스캔 결과)
  - `tools/generate_third_party_licenses_summary.dart` (스캔 로직)
- 필요 시 “변조 방지” 수준을 더 올리는 방법(선택):
  - 배포 산출물(릴리즈 APK)과 함께 위 문서들을 번들로 보관
  - 문서 파일의 해시(SHA-256) 값을 별도 로그에 기록
  - 릴리즈 노트/SSOT 문서에 점검 완료 사실을 명시

### 무결성 해시 로그(생성됨)
- 본 점검에 사용된 핵심 근거 파일들의 SHA-256 해시를 아래 파일로 생성해 두었습니다:
  - `docs/IP_EVIDENCE_SHA256_2025-12-27.txt`
- 생성 스크립트:
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File tools/generate_ip_evidence_hashes.ps1`

## 배포(릴리즈) 시 최소 준수 체크리스트(요약)
- 앱/문서/스토어 설명 중 최소 1곳에 “Third-Party Notices(오픈소스 고지)”를 제공할지 결정
- Apache-2.0 계열 의존성이 있을 경우(스캔 결과 참조): NOTICE 요구 사항 확인
- MIT/BSD 계열 의존성이 있을 경우: 저작권 고지/라이선스 문구 보존 요구 확인
- 라이선스가 명확하지 않은(Unknown) 항목이 있으면: 패키지 원문 LICENSE/NOTICE를 직접 열어 최종 확인

## 재현 방법(다시 생성/검증)
- 라이선스 요약 재생성:
  - `dart run tools/generate_third_party_licenses_summary.dart`
- 점검 근거 해시 재생성:
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File tools/generate_ip_evidence_hashes.ps1`

### 원클릭 재조사(출시 전/대량 수정 후)
- 아래 스크립트가 위 과정을 한 번에 실행합니다:
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File tools/ip_recheck.ps1`
- INDEX까지 같이 돌리려면:
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File tools/ip_recheck.ps1 -WithIndex`

## 권고(배포/운영 시)
- 앱 배포 시, 사용 중인 오픈소스 의존성의 라이선스 조건(표기/NOTICE 포함 여부 등)을 확인하고 필요 시 **Third-Party Notices**를 앱/스토어/문서에 포함합니다.
- 의존성 변경(추가/업그레이드) 시마다 다음을 재실행:
  - `dart run tools/generate_third_party_licenses_summary.dart`
  - 변경된 결과를 `docs/THIRD_PARTY_LICENSES_SUMMARY.md`에 반영

---

## 변경 기록
- 2025-12-27: 최초 생성(의존성 라이선스 스캔 + 레포 내부 복사 흔적 점검)
- 2026-01-08: 최종 확정 - 배포 진행 가능 상태 확인, 자산 소스 문서(ASSETS_SOURCES.md) 완성 필요

---

## 최종 배포 체크리스트 (Pre-Release)

### ✅ 완료 항목
- [x] 183개 패키지 라이선스 스캔 완료
- [x] `lib/**` 외부 코드 복사 흔적 검색 완료 (미발견)
- [x] 주요 근거 파일 SHA-256 해시 기록
- [x] THIRD_PARTY_LICENSES_SUMMARY.md 자동 생성

### ⏳ 남은 항목 (배포 전)
- [ ] ASSETS_SOURCES.md의 모든 TBD 항목 채우기
  - 17개 SVG 아이콘 출처/라이선스 확인
  - 5개 PNG 이미지 출처/라이선스 확인
- [ ] Apache-2.0 라이선스 의존성에 대한 NOTICE 파일 준비
  - `flutter_email_sender` (Apache-2.0)
  - `cryptography` (Apache-2.0)
  - `image_picker*` (Apache-2.0)
- [ ] flutter_svg 라이선스 확인 (Unknown → MIT 또는 Apache-2.0)
- [ ] Third-Party Notices를 앱 UI/Help 섹션에 추가
- [ ] 최종 flutter analyze 통과 확인

### 배포 후 권고
- 배포 후 운영 중에는 `tools/ip_recheck.ps1`을 정기적으로 실행하여 의존성 변경 추적
