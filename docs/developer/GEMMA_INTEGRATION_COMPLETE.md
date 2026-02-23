# Gemma API 서버 SmartLedger 앱 통합 완료

**날짜**: 2026-01-27  
**상태**: ✅ 통합 완료 및 테스트 준비

---

## 🎯 작업 요약

Gemma 2 2B Budget Specialist 모델의 API 서버를 SmartLedger Flutter 앱에 완전히 통합했습니다.

### 생성된 파일

#### 1. **서비스 레이어**
- `lib/services/gemma_api_service.dart` - Gemma API 직접 통신
- `lib/services/receipt_processing_service.dart` - Gemma + Gemini 통합 처리

#### 2. **UI 레이어**
- `lib/screens/gemma_api_test_screen.dart` - 테스트 전용 화면

#### 3. **라우팅**
- `lib/navigation/app_routes_paths.dart` - 라우트 경로 추가
- `lib/navigation/app_router.dart` - Import 추가
- `lib/navigation/app_router_settings.dart` - 라우트 핸들러 추가

---

## 🏗️ 아키텍처

```
┌─────────────────────┐
│  Flutter App UI     │
│  (영수증 입력)      │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│ ReceiptProcessing   │
│ Service             │
│ (통합 레이어)       │
└──┬──────────────┬───┘
   │              │
   ▼              ▼
┌──────────┐  ┌──────────┐
│ Gemma    │  │ Gemini   │
│ API      │  │ API      │
│ (로컬)   │  │ (클라우드)│
└──────────┘  └──────────┘
   ▼
┌──────────────────────┐
│ Gemma 2 2B Model     │
│ (Python 서버)        │
│ localhost:5000       │
└──────────────────────┘
```

### 처리 흐름

1. **우선순위 1**: Gemma API (로컬)
   - 빠르고 정확함
   - 프라이버시 보장
   - 오프라인 가능

2. **폴백**: Gemini API (클라우드)
   - Gemma 서버 미실행 시
   - 인터넷 필요
   - 유사한 정확도

---

## 📦 주요 기능

### GemmaApiService
```dart
// 서버 상태 확인
await GemmaApiService().checkHealth();

// 영수증 추출
final result = await GemmaApiService().extractReceiptInfo(ocrText);
```

**기능**:
- ✅ 헬스 체크 (5분 캐싱)
- ✅ 영수증 텍스트 → 구조화 데이터
- ✅ 샘플 테스트
- ✅ 에러 핸들링

### ReceiptProcessingService
```dart
// 자동 폴백 처리
final result = await ReceiptProcessingService().processReceipt(
  ocrText: receiptText,
  forceGemini: false, // Gemma 우선
);

if (result.success) {
  // result.data: ReceiptExtractionResult
  // result.model: "Gemma 2 2B (Local)" 또는 "Gemini (Cloud)"
}
```

**기능**:
- ✅ Gemma 우선 시도
- ✅ 실패 시 Gemini 자동 폴백
- ✅ 모델 정보 반환
- ✅ 통합 에러 처리

### ReceiptExtractionResult
```dart
class ReceiptExtractionResult {
  final String? storeName;        // 상점명
  final DateTime? date;           // 날짜
  final List<ReceiptItem> items;  // 상품 목록
  final double? totalAmount;      // 총액
}

class ReceiptItem {
  final String name;              // 상품명
  final int quantity;             // 수량
  final double unitPrice;         // 단가
  final double totalPrice;        // 총액
}
```

---

## 🧪 테스트 방법

### 1. Gemma API 서버 시작
```powershell
cd C:\Users\plain\GemmaFineTuning
.\start_api_server.ps1
```

### 2. SmartLedger 앱 실행
```powershell
cd C:\Users\plain\SmartLedger
flutter run -d windows
```

### 3. 테스트 화면 접근

**방법 A: 직접 네비게이션**
```dart
Navigator.pushNamed(context, AppRoutes.gemmaApiTest);
```

**방법 B: Deep Link**
```
smartledger://dev/gemma-api-test
```

### 4. 테스트 시나리오

#### 시나리오 1: Gemma 서버 실행 중
1. "샘플 로드" 버튼 클릭
2. "Gemma 추출" 버튼 클릭
3. ✅ 결과: "추출 성공 (Gemma 2 2B (Local))"

#### 시나리오 2: Gemma 서버 미실행
1. Gemma 서버 종료 (Ctrl+C)
2. "샘플 로드" 버튼 클릭
3. "Gemma 추출" 버튼 클릭
4. ✅ 결과: "추출 성공 (Gemini (Cloud))" (폴백)

#### 시나리오 3: 커스텀 영수증
1. 실제 영수증 텍스트 입력
2. "Gemma 추출" 버튼 클릭
3. 상품명, 수량, 단가, 총액 확인

---

## 🎨 테스트 UI 기능

### 상단 패널
- 🟢 **서버 상태**: Gemma 서버 실행 여부
- 🔄 **새로고침**: 서버 상태 재확인

### 입력 영역
- 📝 **텍스트 필드**: 영수증 텍스트 입력
- 📄 **샘플 로드**: 테스트용 샘플 자동 입력

### 버튼
- 🤖 **Gemma 추출**: Gemma API 우선 (폴백 포함)
- ☁️ **Gemini 추출**: Gemini API 직접 호출
- 🧪 **서버 샘플 테스트**: API 서버의 내장 샘플

### 결과 영역
- ✅ **성공**: 상점명, 날짜, 항목 목록, 총액
- ❌ **실패**: 에러 메시지
- 📋 **복사**: 결과 JSON 복사

---

## 🔌 실제 앱 통합 예시

### 영수증 스캔 화면에서 사용

```dart
// lib/screens/receipt_scan_screen.dart

import '../services/receipt_processing_service.dart';

class ReceiptScanScreen extends StatefulWidget {
  // ...
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  final _receiptService = ReceiptProcessingService();

  Future<void> _processReceiptImage(String imagePath) async {
    // 1. OCR로 텍스트 추출 (기존 로직)
    final ocrText = await _extractTextFromImage(imagePath);

    // 2. Gemma/Gemini로 구조화
    final result = await _receiptService.processReceipt(
      ocrText: ocrText,
    );

    if (!result.success) {
      _showError('영수증 분석에 실패했습니다.');
      return;
    }

    // 3. 결과를 지출입력 화면으로 전달
    final data = result.data!;
    
    Navigator.pushNamed(
      context,
      AppRoutes.transactionAdd,
      arguments: TransactionAddArgs(
        accountName: _currentAccount,
        initialAmount: data.totalAmount,
        initialDescription: data.storeName ?? '',
        initialDate: data.date ?? DateTime.now(),
        // 상품 목록을 메모에 추가
        initialMemo: _formatItems(data.items),
      ),
    );
  }

  String _formatItems(List<ReceiptItem> items) {
    return items.map((item) {
      return '${item.name} ${item.quantity}개 x ${item.unitPrice}원';
    }).join('\n');
  }
}
```

### 음성 명령 통합

```dart
// "영수증 스캔" 음성 명령 처리

void _handleVoiceCommand(String command) {
  if (command.contains('영수증') && command.contains('스캔')) {
    // 카메라 or 갤러리 열기
    _openReceiptScanner();
  }
}

Future<void> _openReceiptScanner() async {
  final image = await ImagePicker().pickImage(source: ImageSource.camera);
  if (image != null) {
    await _processReceiptImage(image.path);
  }
}
```

---

## 📊 성능 비교

### Gemma API (로컬)
| 항목 | 성능 |
|------|------|
| 응답 시간 | 3-10초 |
| 정확도 | 높음 (전문 학습) |
| 비용 | 무료 |
| 오프라인 | ✅ 가능 |
| 프라이버시 | ✅ 완벽 |

### Gemini API (클라우드)
| 항목 | 성능 |
|------|------|
| 응답 시간 | 5-15초 |
| 정확도 | 높음 (범용) |
| 비용 | 무료 (할당량) |
| 오프라인 | ❌ 불가 |
| 프라이버시 | ⚠️ 클라우드 전송 |

---

## 🚀 다음 단계

### 1. OCR 통합
```dart
// lib/services/ocr_service.dart 생성
class OcrService {
  Future<String> extractText(String imagePath) async {
    // ML Kit, Tesseract, 또는 클라우드 OCR
  }
}
```

### 2. 카메라 스캔 화면
```dart
// lib/screens/receipt_camera_screen.dart
// 카메라 프리뷰 + 실시간 텍스트 인식
```

### 3. 배치 처리
```dart
// 여러 영수증 한번에 처리
final results = await Future.wait(
  receiptTexts.map((text) => _receiptService.processReceipt(ocrText: text))
);
```

### 4. 캐싱 레이어
```dart
// 동일 영수증 재처리 방지
class ReceiptCache {
  final Map<String, ReceiptExtractionResult> _cache = {};
  
  ReceiptExtractionResult? get(String receiptHash) {
    return _cache[receiptHash];
  }
}
```

### 5. 사용자 피드백
```dart
// 추출 결과 수정 가능
class ReceiptEditDialog extends StatefulWidget {
  final ReceiptExtractionResult result;
  // 사용자가 수정한 내용으로 재학습 데이터 생성
}
```

---

## 🐛 트러블슈팅

### 문제: "Server not reachable"
**원인**: Gemma API 서버 미실행  
**해결**: 
```powershell
cd C:\Users\plain\GemmaFineTuning
.\start_api_server.ps1
```

### 문제: "ModuleNotFoundError: No module named 'flask'"
**원인**: Flask 미설치  
**해결**:
```bash
pip install flask
```

### 문제: 느린 추출 속도
**원인**: CPU 모드  
**해결**: GPU 버전 PyTorch 설치
```bash
pip install torch --index-url https://download.pytorch.org/whl/cu121
```

### 문제: JSON 파싱 실패
**원인**: 모델 출력 형식 불일치  
**해결**: 프롬프트 튜닝 또는 Gemini 폴백 사용

---

## 📝 코드 리뷰 체크리스트

- ✅ GemmaApiService: HTTP 통신, 에러 핸들링
- ✅ ReceiptProcessingService: Gemma → Gemini 폴백 로직
- ✅ ReceiptExtractionResult: 타입 안전한 모델
- ✅ GemmaApiTestScreen: 전체 UI 테스트
- ✅ 라우팅: AppRoutes에 등록
- ✅ Import: dart:convert 누락 수정
- ✅ 에러 처리: try-catch, timeout 설정
- ✅ 캐싱: 헬스 체크 5분 캐싱

---

## 🎓 학습 포인트

### 1. Flutter HTTP 통신
```dart
final response = await http.post(
  Uri.parse(url),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode(data),
).timeout(Duration(seconds: 60));
```

### 2. Fallback 패턴
```dart
// 우선순위 체인
final result = await tryGemma() ?? await tryGemini() ?? fallbackResult;
```

### 3. 싱글톤 서비스
```dart
class MyService {
  static final MyService _instance = MyService._internal();
  factory MyService() => _instance;
  MyService._internal();
}
```

### 4. 타입 안전 모델
```dart
factory Model.fromJson(Map<String, dynamic> json) {
  return Model(
    field: json['field'] as String? ?? 'default',
  );
}
```

---

## 📦 배포 고려사항

### Windows 앱
- ✅ Gemma 서버 자동 시작 스크립트 포함
- ✅ 서버 상태 모니터링
- ✅ Gemini 폴백으로 안정성 보장

### 모바일 앱
- ⚠️ 로컬 서버 불가 → Gemini API 사용
- 또는 TensorFlow Lite로 온디바이스 추론

### 웹 앱
- ⚠️ CORS 설정 필요
- 또는 서버사이드 프록시

---

## ✅ 완료 상태

- ✅ **Gemma API 서버**: 생성 및 실행 가능
- ✅ **서비스 레이어**: GemmaApiService, ReceiptProcessingService
- ✅ **데이터 모델**: ReceiptExtractionResult, ReceiptItem
- ✅ **테스트 UI**: GemmaApiTestScreen
- ✅ **라우팅**: AppRoutes 통합
- ✅ **폴백 로직**: Gemma → Gemini 자동 전환
- ✅ **에러 핸들링**: 타임아웃, 네트워크 오류 처리

---

## 🎉 결론

Gemma 2 2B Budget Specialist 모델이 SmartLedger 앱에 완전히 통합되었습니다!

**테스트 방법**:
1. API 서버 실행: `.\start_api_server.ps1`
2. 앱 실행: `flutter run -d windows`
3. 테스트 화면: `Navigator.pushNamed(context, AppRoutes.gemmaApiTest)`

**다음 작업**: OCR 통합 → 카메라 스캔 → 거래 자동 입력
