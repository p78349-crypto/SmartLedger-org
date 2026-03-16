# AI 투자 분석 동의 운영 가이드 (KO)

> 문서 버전: 2026-02-28-v1  
> 적용 대상: `AI 투자 참고정보` 기능

---

## 1) 목적

- `AI 투자 참고정보` 기능의 법적 고지/동의 흐름을 운영 기준으로 고정한다.
- 고지 문구가 변경될 때 **재동의가 자동으로 강제**되도록 버전 운영 절차를 명확히 한다.

---

## 2) 현재 구현 기준

- 진입 게이트: `lib/screens/ai_investment_advisor_screen.dart`
- 동의 버전 상수: `_consentVersion`
- 저장 키(`SharedPreferences`):
  - `ai_investment_consent_accepted_v1`
  - `ai_investment_consent_accepted_at_ms_v1`
  - `ai_investment_consent_version_v1`
  - `ai_investment_consent_locale_v1`
- 운영 확인 경로: 설정 > 법적 고지 > 투자 분석 동의 기록

---

## 3) 동의 버전 운영 원칙

### 3.1 버전 상향이 필요한 경우

다음 중 1개라도 해당하면 `_consentVersion`을 상향한다.

- 면책 문구 의미가 바뀐 경우
- 책임 주체/범위 문구가 바뀐 경우
- 분쟁/관할 관련 고지 문구가 바뀐 경우
- 투자 분석 제공 범위(예: 추천/권유 관련 정책)가 바뀐 경우

### 3.2 버전 명명 규칙

- 형식: `ai_investment_notice_YYYY_MM_DD_vN`
- 예시: `ai_investment_notice_2026_03_01_v1`

---

## 4) 배포 전 체크리스트

- [ ] `_consentVersion`이 최신 문구 기준으로 갱신되었는가?
- [ ] 동의 다이얼로그 문구와 `보안.md` 문구가 일치하는가?
- [ ] 설정 화면에서 동의 기록(상태/시각/버전/로케일) 조회가 가능한가?
- [ ] 동의 기록 초기화 후 재진입 시 동의 다이얼로그가 다시 뜨는가?
- [ ] `flutter analyze --no-fatal-infos` 통과했는가?

### 4.1 E2E 5단계(릴리즈 직전)

1. 최초 진입 시 고지/동의 다이얼로그 노출 확인
2. 체크박스 미선택 상태에서 동의 버튼 비활성 확인
3. 취소 시 화면 진입 차단 확인
4. 동의 후 설정 화면에서 기록(시각/버전/로케일) 확인
5. 기록 초기화 후 재진입 시 재동의 강제 확인

---

## 5) 운영 절차 (문구 변경 시)

1. 법무/정책 문구 확정
2. `ai_investment_advisor_screen.dart` 동의 다이얼로그 문구 수정
3. `_consentVersion` 값 상향
4. `보안.md` 및 릴리즈 문서 동기화
5. 기기에서 기존 동의 사용자 계정으로 재진입 테스트
6. 설정 > 법적 고지에서 기록 값(버전/시각/로케일) 확인

---

## 6) 장애 대응

- 증상: 동의했는데 계속 다이얼로그 반복
  - 점검: `ai_investment_consent_*` 저장 성공 여부, `_consentVersion` 오타 확인
- 증상: 동의 없이 진입됨
  - 점검: `_checkConsentThenLoad()` 호출 누락 여부, 동의 확인 조건(`accepted && savedVersion`) 확인
- 증상: 설정 기록 미표시
  - 점검: 설정 화면 로딩 시 `PrefKeys.aiInvestmentConsent*` 읽기 코드 확인

---

## 7) 변경 이력

- 2026-02-28: 초안 작성, 동의 버전 강제 재동의 운영 규칙 확정
