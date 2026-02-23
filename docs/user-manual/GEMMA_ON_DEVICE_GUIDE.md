# 온디바이스 AI (Gemma 2 2B) 통합 가이드

이 프로젝트는 서버 없이 기기 내에서 직접 실행되는 온디바이스 AI(MediaPipe + Gemma 2 2B)를 통해 카테고리 자동 분류 기능을 제공합니다.

## 1. 모델 파일 준비

Gemma 2 2B 모델 파일을 안드로이드 앱에서 인식할 수 있도록 다음 단계를 수행해야 합니다.

1.  **모델 다운로드**: Kaggle 또는 Google AI Edge 모델 제공처에서 Gemma 2 2B (GPU 전용, int4 양자화 권장) `.bin` 파일을 다운로드합니다.
2.  **파일명 변경**: 다운로드한 파일명을 `gemini-2b-it-gpu-int4.bin`으로 변경합니다. (현재 코드가 이 이름을 찾도록 설정되어 있습니다.)
3.  **파일 업로드**:
    *   실제 기기 또는 에뮬레이터의 내부 저장소에 파일을 복사해야 합니다.
    *   경로: `/data/user/0/com.example.smartledger/files/gemini-2b-it-gpu-int4.bin`
    *   또는 앱 설정의 '모델 데이터 관리' 메뉴를 통해 업로드 처리가 되도록 추후 확장 가능합니다.

## 2. 작동 방식

*   **카테고리 분류**: 지출/수입 입력 화면의 상품명 입력란 옆에 있는 반짝이($\text{\Large\faMagic}$) 버튼을 누르면 Gemma 2 2B 모델이 실행됩니다.
*   **프롬프트 엔진**: `AICoreGeminiService.predictCategory`에서 현재 앱에 정의된 실제 카테고리 목록(식비, 주거비 등)을 모델에게 전달하여 가장 적합한 항목을 선택하게 합니다.
*   **오프라인 보장**: 인터넷이 전혀 연결되지 않은 상태에서도 작동합니다.

## 3. 관련 파일

*   **Dart 서비스**: [lib/services/aicore_gemini_service.dart](lib/services/aicore_gemini_service.dart)
*   **안드로이드 Native 연동**: [android/app/src/main/kotlin/com/example/smartledger/AICoreMethodChannel.kt](android/app/src/main/kotlin/com/example/smartledger/AICoreMethodChannel.kt)
*   **입력 화면**: [lib/screens/transaction_add_screen.dart](lib/screens/transaction_add_screen.dart)

## 4. 참고 사항

*   Gemma 2 2B 모델은 약 1.5GB 내외의 용량을 차지하므로 기기 저장 공간이 충분해야 합니다.
*   최초 실행 시 모델을 로드하는 데 몇 초 정도의 시간이 소요될 수 있습니다.
*   MediaPipe LLM Inference API를 활용하여 최적의 성능을 냅니다.
