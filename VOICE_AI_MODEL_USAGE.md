# SmartLedger 음성입력 및 AI 모델 사용 구조

## 1. 음성 인식 (Speech-to-Text)
- **패키지:** `speech_to_text`
- **주요 사용 위치:**
  - `lib/screens/voice_dashboard_screen.dart` (STT 엔진)
  - `lib/widgets/floating_voice_button.dart` (플로팅 버튼NLU 연동)
  - `lib/screens/quick_simple_expense_input_screen.dart` (간편지출 정규화)
  - `lib/screens/quick_stock_use_screen.dart` (재고 차감 파싱)
    
    ```dart
    import 'package:speech_to_text/speech_to_text.dart' as stt;
    // ...
    final stt.SpeechToText _speech = stt.SpeechToText();
    ```

---

## 2. 온디바이스 자연어 해석 (Google Gemini Nano, AICore)
- **서비스 클래스:** `AICoreGeminiService`
- **파일 위치:** `lib/services/aicore_gemini_service.dart`
- **주요 사용처:**
  - **간편지출:** 음성으로 입력된 텍스트를 "품목 금액" 형식으로 자동 변환
  - **재고 차감:** "팽이버섯 2봉" 등의 자연어를 상품명과 수량으로 추출
  - **플로팅 버튼:** 사용자의 발화 의도를 분석하여 적절한 화면 이동 및 데이터 슬롯 필링
- **주요 코드:**

    ```dart
    /// Google AI Edge SDK (AICore)를 통한 Gemini Nano 호출
    class AICoreGeminiService {
      // ...
      Future<Map<String, dynamic>> processVoiceInput(String userSpeech) async {
        // ...
        final result = await _channel.invokeMethod<String>(
          'generateText',
          {'prompt': prompt},
        );
        // ...
      }
    }
    ```

---

## 3. (사용 중단) 클라우드 자연어 해석 (Google Gemini Flash/API)
- **상태:** **영구 비활성화 (Strictly Offline Only)**
- **결정 사유:** 
  - 사용자의 민감한 금융 데이터를 외부로 1%도 유출하지 않기 위함.
  - 네트워크 연결이 없는 환경(지하, 해외 등)에서도 동일한 사용자 경험 보장.
- **조치 사항:** 
  - `GeminiNanoService.dart`의 모든 호출 로직을 코드에서 제거함.
  - 온디바이스 AI 미지원 기기에서는 클라우드 전송 대신 로컬 정규식 엔진(Level 2)으로 즉시 대체.

---

## 🛡️ 데이터 보안 및 오프라인 원칙 (Strictly Offline Policy)
SmartLedger는 다음의 3단계 로컬 처리 원칙을 준수합니다:

1.  **Zero-Cloud Path**: 음성 인식(STT)부터 결과 분석(NLU)까지 모든 과정에서 외부 서버 API 호출을 수행하지 않습니다.
2.  **On-Device AI First**: Google Gemini Nano가 탑재된 기기에서는 최신 LLM 기술을 활용해 오프라인으로 문맥을 이해합니다.
3.  **Local Fallback**: AI 모델이 없는 기기에서도 기기 내부의 고정 알고리즘(Regex)을 사용하여 분석하며, 데이터는 항상 기기 내부 DB(`Isar/SQLite`)에만 저장됩니다.

---

## 왜 Google Assistant보다 Gemini Nano인가? (SmartLedger 기준)
SmartLedger는 개인 자산 및 재고 관리를 다루므로, **Gemini Nano**가 대안인 Google Assistant보다 압도적으로 유리한 점이 많습니다:

- **완전한 프라이버시 (Privacy First):** 가계부 거래 내역이나 재고 데이터가 Google 서버를 포함한 어떠한 외부 서버로도 전송되지 않고 내 기기 안에서만 처리됩니다. 이는 금융 데이터 보안에 있어 가장 중요한 원칙입니다.
- **초고속 응답 (Edge AI):** 네트워크 연결 상태에 가상관 없이 즉각적인 자연어 처리가 가능하여, "계란 2개 차감" 같은 명령에 딜레이 없이 즉시 반응합니다.
- **자유로운 커스텀 (Developer Control):** Google Assistant는 정해진 명령 체계 내에서 동작하지만, Gemini Nano는 앱 고유의 복잡한 로직(재고 차감, 다중 항목 입력 등)을 개발자가 의도한 대로 자연스럽게 처리할 수 있습니다.
- **최신 LLM 기술:** 기존의 키워드 인식 방식인 Assistant와 달리, Gemini Nano는 최신 대규모 언어 모델 기술을 기반으로 문맥과 다양한 표현을 더 똑똑하게 이해합니다.

---

## 🌍 글로벌/다국어 배포 시 리스크 관리 (Gemini Nano 관련)
다국어 배포 시 Gemini Nano(AICore)가 걸림돌이 되지 않도록 다음 리스크와 대응 방안을 고려하고 있습니다:

- **기기 호환성 리스크:** Gemini Nano는 현재 특정 고성능 안드로이드 기기(예: Pixel 8, Galaxy S24 등)와 최신 OS 버전에서만 동작합니다. 
  - **대응:** 앱은 Nano를 호출하기 전 `isAvailable()`을 통해 온디바이스 모델 존재 여부를 확인하며, **성공 시 즉시 로드(loadModel)**합니다. 미지원 기기이거나 모델이 없는 경우, 보안과 프라이버시를 위해 클라우드로 전송하지 않고 **정규식(Regex) 기반 엔진**이 최선(Best-effort)의 분석을 수행하도록 설계되었습니다.
- **플랫폼 제한:** AICore는 안드로이드 전용 기능입니다. iOS 버전 출시 시에는 Apple의 On-device AI (CoreML/Apple Intelligence) 또는 Regex 기반 처리를 검토합니다. (온라인 API 사용 지양)
- **언어별 성능 차이:** 영어에 비해 한국어, 일본어 등 기타 언어의 문맥 이해도가 낮을 수 있습니다.
  - **대응:** `aicore_gemini_service.dart` 내의 프롬프트를 다국어에 최적화하고, 인식 실패 시 사용자에게 원본 텍스트를 그대로 보여주는 안전장치를 마련했습니다.
- **지역별 가용성:** 특정 국가에서는 Google Play 서비스나 AICore 업데이트가 늦어질 수 있습니다.
  - **대응:** 온디바이스 AI를 '필수' 기능이 아닌 '사용자 경험 향상용 옵션'으로 배치하여, AI가 작동하지 않더라도 앱의 핵심 기능(가계부 기록 등)은 유지되도록 구현했습니다.

---

## ⚠️ 지적재산권 및 상업적 이용 주의사항 (지속적 검토 필요)
- **지적재산권(IP)은 여전히 핵심적인 검토 대상입니다:**
  - **공식 SDK 사용:** 현재 방식처럼 Google의 공식 SDK와 API를 사용하는 것은 기술적으로 적법한 경로이나, 이는 Google의 **서비스 약관(ToS)**을 엄격히 준수한다는 전제 하에 유효합니다.
  - **출력 데이터의 권리:** AI가 생성한 결과물에 대한 저작권 및 소유권 법리는 국가별로 정립 중인 단계이므로, 상업적 이용 시 법무팀을 통한 정기적인 검토가 필요합니다.
  - **라이선스 변경 가능성:** Google의 AI 정책은 매우 빠르게 변화하므로, 출시 전뿐만 아니라 서비스 운영 중에도 주기적으로 약관 변경을 모니터링해야 합니다.
- **국가별 규제 대응:**
  - 한국의 개인정보보호법, 유럽의 AI 법안(AI Act), 미국의 관련 규제 등 각국의 법률이 지적재산권 및 데이터 활용 범위에 영향을 미칠 수 있습니다.
- **상업적 서비스, 대규모 배포, 해외 서비스**의 경우:
  - Google Cloud Platform(GCP) 및 Android(AICore) 관련 최신 약관, 정책, 상업적 사용 조건을 반드시 확인해야 합니다.
  - Google Cloud 및 Android 관련 전문적인 법무 검토(법률 자문)를 강력히 권장합니다.
  - API 결과물의 재배포, 데이터 보안, 개인정보 처리, 서비스 지역 제한 등도 별도 검토 필요
- 공식 문서 및 약관 링크:
  - [Google Cloud Gemini API 약관](https://cloud.google.com/terms)
  - [Google Play 서비스 및 Android 개발자 정책](https://play.google.com/about/developer-content-policy/)
  - [AICore 공식 문서](https://ai.google.dev/edge/aicore)

---

## 보안 주의
- 본 프로젝트의 코드에는 Google Gemini Flash(API)용 API key가 포함되어 있지 않습니다.
- 실제 서비스 배포 시에도 API key는 코드 저장소에 직접 포함하지 말고, 환경변수 또는 보안 저장소를 통해 안전하게 관리해야 합니다.

---

## 국가별(Gemini Nano) 서비스 참고
- Google Gemini Nano(AICore)는 한국, 미국, 일본, 영국 등 주요 국가의 Android 기기에서 공식적으로 지원됩니다.
- 단, 실제 지원 여부는 기기 제조사, Android 버전, Google Play 서비스 정책에 따라 다를 수 있습니다.
- 각국의 개인정보 보호법, AI/데이터 관련 법률(예: GDPR, CCPA, 일본 개인정보보호법 등)도 반드시 준수해야 합니다.
- 일부 국가(중국 등)에서는 Google 서비스가 제한될 수 있으니, 서비스 대상국가의 정책을 사전 확인하세요.

---

## 요약
- **STT(음성→텍스트):** `speech_to_text` 패키지 (온디바이스 인식 우선)
- **자연어 해석:**
  - 온디바이스: **Google Gemini Nano** (AICore, 100% 오프라인)
  - 보조 엔진: **정규식(Regex)** (AI 미지원 기기용 로컬 엔진)
  - 클라우드: **사용 안 함** (데이터 보안 및 프라이버시 원칙)

각 서비스의 실제 코드 위치와 주요 구현부를 위와 같이 정리했습니다.
