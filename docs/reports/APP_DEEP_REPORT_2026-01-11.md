# SmartLedger — 심층 앱 보고서

작성일: 2026-01-11
작성자: 자동 생성 (도움: GitHub Copilot)

## 요약
- 최근 목표: 환불을 예산 복원으로 처리하고, 환불 UX 개선 및 CEO 전용 분석·보고 기능(월간 방어 보고서, CSV/PDF/TTS) 추가.
- 상태: 기능 구현 및 통합 테스트 추가 완료. PDF 생성은 동작하나, 한글 렌더링을 위한 폰트 자산(NotoSansKR)이 필요함.

## 중요한 변경사항 (하이라이트)
- 환불 관련 로직: 환불을 예산으로 복원하는 의미 반영 및 원결제(원거래) 정보 노출.
- UX: 환불 생성 흐름(검색에서 생성 가능), 환불 결제수단 입력을 라디오+자동완성으로 변경, 최근 결제수단 보관.
- CEO/분석: ROI 유틸리티(`lib/utils/roi_utils.dart`), `PolicyService` 추가, ROI 상세 화면 및 `CEOMonthlyDefenseReportScreen` 구현.
- 보고서 생성: CSV + PDF + TTS 스크립트 생성, `generateMonthlyDefenseReportFiles(...)` 헬퍼와 통합 테스트 추가.

## 변경된 주요 파일
- [lib/screens/ceo_monthly_defense_report_screen.dart](lib/screens/ceo_monthly_defense_report_screen.dart)
- [lib/services/policy_service.dart](lib/services/policy_service.dart)
- [lib/utils/roi_utils.dart](lib/utils/roi_utils.dart)
- [test/integration/generate_monthly_report_test.dart](test/integration/generate_monthly_report_test.dart)
- [pubspec.yaml](pubspec.yaml) (PDF/printing deps 유지, 자산 폰트 항목 추가)

## 현재 동작 확인
- 통합 테스트(`test/integration/generate_monthly_report_test.dart`)는 환경 폴더 대체(fallbacks)로 실행되며, CSV/PDF 파일을 시스템 임시 디렉토리(Directory.systemTemp 또는 getTemporaryDirectory())에 생성합니다.
- PDF 생성 시 기본 폰트(헬베티카 등)가 한글을 지원하지 않아 PDF 패키지에서 유니코드 대체 폰트 경고가 발생합니다. 기능적으로는 생성되지만 한글 출력 품질을 개선하려면 폰트 자산을 추가해야 합니다.

## 재현 가이드 (개발자)
1. (필요 시) 프로젝트 루트로 이동:

```powershell
cd C:\Users\plain\SmartLedger
```

2. (폴더에 폰트 배치)
- 권장: `assets/fonts/NotoSansKR-Regular.ttf` 파일을 추가합니다.

3. 디펜던시 갱신:

```powershell
flutter pub get
```

4. 통합 테스트 실행 (월간 보고서 생성 확인):

```powershell
flutter test test/integration/generate_monthly_report_test.dart -r expanded
```

5. 생성된 파일 위치 예시:
- Windows 임시: `C:\Users\<user>\AppData\Local\Temp\monthly_defense_report_YYYY_M_stamp.pdf`

## 남은 작업 / 우선순위
- (1) 긴급: `assets/fonts/NotoSansKR-Regular.ttf` 추가 — 한글 PDF 품질 확보.
- (2) 통합: 폰트 추가 후 `flutter pub get` 및 통합 테스트 재실행으로 경고 해소 확인.
- (3) 선택: PDF 레이아웃 미세조정(테이블 스타일, 머리말/꼬리말 정렬, 커버 페이지 스타일) 및 공유/프린트 UX 개선.
- (4) 보안/배포: CEO 화면 접근에 대한 루트 인증(지문/생체) 강제 및 권한 검토.

## 기술적 세부사항
- 플랫폼: Flutter/Dart 모바일 앱 (Windows 개발 환경에서 테스트 가능).
- 보고서 생성: `pdf` 패키지로 PDF 빌드, `share_plus`로 경로 공유, TTS는 `flutter_tts`로 보고서 음성 재생.
- 테스트: Flutter `flutter_test` harness + mock SharedPreferences, path_provider fallback을 사용하여 헤드리스 테스트 환경에서 파일 생성 검증함.

## 권장 다음 행동(투표/승인)
- 제가 리포지터리에 Noto Sans KR 폰트를 직접 추가해도 될까요? (허가 시 제가 파일을 업로드하고 테스트를 재실행하겠습니다.)

---

파일 생성 위치: [APP_DEEP_REPORT_2026-01-11.md](APP_DEEP_REPORT_2026-01-11.md)

