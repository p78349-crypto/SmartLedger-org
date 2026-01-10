# 책스캔 PDF 앱 ↔ SmartLedger OCR 연계 가이드

## 📱 개요

**목적:** SmartLedger의 앱 용량을 최소화하면서 정확한 영수증 OCR 기능 제공

**구조:**
- **SmartLedger** - 가계부 기능 전담 (ML Kit 없음)
- **책스캔 PDF 앱** - OCR 처리 전담 (ML Kit 포함)
- **연계 방식** - Deep Link로 데이터 전송

## 🔗 연계 플로우

### 1️⃣ 사용자 시나리오

```
[사용자] 마트에서 장보고 영수증 받음
    ↓
[사용자] 책스캔 PDF 앱 실행
    ↓
[책스캔앱] 영수증 촬영 및 OCR 처리
    ↓
[책스캔앱] 텍스트 추출 완료
    - 상점명: 이마트
    - 합계 금액: 45,800원
    - 구매 항목: 양배추, 브로콜리, 닭고기, 우유
    - 날짜: 2026-01-10
    ↓
[사용자] "빅스비, 영수증 지출 기록" (음성 명령)
    ↓
[책스캔앱] SmartLedger로 Deep Link 전송
    ↓
[SmartLedger] 지출 입력 화면 자동 열림 (모든 필드 채워진 상태)
    ↓
[사용자] 확인 버튼만 클릭
    ↓
[완료] 지출 기록 저장 완료!
```

### 2️⃣ 기술적 플로우

```dart
// 책스캔 PDF 앱에서
class ReceiptOCRResult {
  final String storeName;
  final double totalAmount;
  final List<String> items;
  final DateTime? date;
  
  String toDeepLink() {
    final itemsStr = items.join(',');
    final dateStr = date?.toIso8601String().split('T').first ?? '';
    
    return 'smartledger://transaction/add?'
        'amount=$totalAmount&'
        'store=$storeName&'
        'items=$itemsStr&'
        'source=ocr&'
        'date=$dateStr';
  }
}

// OCR 완료 후 SmartLedger 호출
final result = ReceiptOCRResult(
  storeName: '이마트',
  totalAmount: 45800,
  items: ['양배추', '브로콜리', '닭고기', '우유'],
  date: DateTime(2026, 1, 10),
);

await launchUrl(Uri.parse(result.toDeepLink()));
```

## 📋 Deep Link 스펙

### 기본 형식

```
smartledger://transaction/add?amount=<금액>&store=<상점>&items=<항목>&source=ocr
```

### 파라미터

| 파라미터 | 필수 | 설명 | 예시 |
|---------|------|------|------|
| `amount` | ✅ | 합계 금액 | `45800` |
| `store` | ⭐ | 상점명 | `이마트` |
| `items` | ⭐ | 구매 항목 (쉼표 구분) | `양배추,닭고기,우유` |
| `source` | ⭐ | 데이터 출처 | `ocr` (고정값) |
| `date` | ⬜ | 영수증 날짜 | `2026-01-10` |
| `description` | ⬜ | 설명 | `식료품` |
| `memo` | ⬜ | 추가 메모 | `세일 상품` |

> ✅ 필수, ⭐ 권장, ⬜ 선택

### 예시

#### 예시 1: 기본 영수증
```
smartledger://transaction/add?
  amount=45800&
  store=이마트&
  items=양배추,브로콜리,닭고기,우유&
  source=ocr
```

#### 예시 2: 날짜 포함
```
smartledger://transaction/add?
  amount=128500&
  store=코스트코&
  items=양배추,브로콜리,닭고기,돼지고기,우유,요구르트&
  source=ocr&
  date=2026-01-10
```

#### 예시 3: 상세 정보 포함
```
smartledger://transaction/add?
  amount=32000&
  description=편의점&
  store=GS25&
  items=라면,과자,음료수&
  memo=야식&
  source=ocr
```

## 🎯 SmartLedger 처리

### 1️⃣ Deep Link 파싱

SmartLedger의 `DeepLinkService`가 자동으로 파싱:

```dart
// lib/services/deep_link_service.dart
case 'transaction':
  if (pathSegments.isNotEmpty && pathSegments.first == 'add') {
    return DeepLinkAction.addTransaction(
      // ... 기존 파라미터들
      items: params['items'],      // ✅ 추가됨
      source: params['source'],    // ✅ 추가됨
    );
  }
```

### 2️⃣ 지출 입력 화면 자동 채우기

`DeepLinkHandler`가 자동으로 처리:

```dart
// lib/navigation/deep_link_handler.dart
void _handleAddTransaction(NavigatorState navigator, AddTransactionAction action) {
  // ... 기존 로직
  
  // items를 memo에 자동 추가
  if (action.items != null && action.items!.isNotEmpty) {
    final itemsList = action.items!.split(',').map((e) => e.trim()).toList();
    final itemsText = itemsList.join(', ');
    memo = '📋 $itemsText';
  }
  
  // Transaction 객체 생성 및 화면 열기
  // ...
}
```

### 3️⃣ 결과

지출 입력 화면이 다음과 같이 채워진 상태로 열림:

- **금액**: `45,800원`
- **상점**: `이마트`
- **메모**: `📋 양배추, 브로콜리, 닭고기, 우유`
- **날짜**: `2026-01-10` (제공된 경우)
- **출처**: OCR 태그 자동 기록

## 🎤 음성 명령 연계

### Bixby Capsule 구현

```javascript
// bookscan-capsule/actions/sendReceiptToSmartLedger.js
action (SendReceiptToSmartLedger) {
  type (Calculation)
  collect {
    // 마지막 OCR 결과 가져오기
  }
  output (Result)
  
  action-endpoint {
    // 책스캔앱의 최신 OCR 결과를 Deep Link로 변환
    // SmartLedger 호출
  }
}
```

### 음성 명령

```
# Samsung Bixby
"빅스비, 영수증 지출 기록"
"빅스비, 영수증 기록"
"빅스비, 영수증 입력"

# Google Assistant
"Hey Google, 영수증 기록"

# Apple Siri
"시리야, 영수증 기록"
```

## 🔧 책스캔앱 구현 가이드

### 1️⃣ OCR 결과 저장

```dart
class BookScanApp {
  ReceiptOCRResult? _lastOCRResult;
  
  Future<void> processReceipt(File imageFile) async {
    // ML Kit OCR 처리
    final recognizedText = await textRecognizer.processImage(
      InputImage.fromFile(imageFile),
    );
    
    // 영수증 파싱
    final result = parseReceipt(recognizedText.text);
    
    // 결과 저장
    _lastOCRResult = result;
    await _saveToPreferences(result);
  }
  
  ReceiptOCRResult parseReceipt(String text) {
    // 텍스트에서 상점명, 금액, 항목 추출
    // 정규표현식 사용
    // ...
  }
}
```

### 2️⃣ SmartLedger 연계 버튼

```dart
// UI에 "SmartLedger로 보내기" 버튼 추가
ElevatedButton.icon(
  icon: Icon(Icons.send),
  label: Text('가계부에 기록'),
  onPressed: () async {
    if (_lastOCRResult != null) {
      final deepLink = _lastOCRResult!.toDeepLink();
      await launchUrl(Uri.parse(deepLink));
    }
  },
)
```

### 3️⃣ 음성 명령 처리

```dart
// Bixby Capsule 또는 App Shortcuts에서 호출
Future<void> handleVoiceCommand(String command) async {
  if (command.contains('영수증') && command.contains('기록')) {
  // "빅스비, 영수증 지출에 기록" 처리
  if (command.contains('영수증') && (command.contains('기록') || command.contains('입력')
      final deepLink = _lastOCRResult!.toDeepLink();
      await launchUrl(Uri.parse(deepLink));
    } else {
      // "먼저 영수증을 스캔해주세요" 안내
    }
  }
}
```

## 📊 장점

### ✅ SmartLedger 측면

1. **앱 용량 최소화**
   - ML Kit 제거로 30-50MB 감소
   - 앱 스토어 업로드 가능
   - 빠른 다운로드 및 설치

2. **기능 유지**
   - OCR 기능은 그대로 사용 가능
   - 책스캔앱을 통한 간접 제공
   - 사용자 경험 동일

3. **유지보수 용이**
   - OCR 관련 코드 제거
   - 단순한 Deep Link 처리만 유지
   - 버그 발생 가능성 감소

### ✅ 책스캔앱 측면

1. **기능 강화**
   - ML Kit 포함으로 강력한 OCR
   - 영수증 전용 최적화 가능
   - 다양한 문서 타입 지원

2. **에코시스템 확장**
   - SmartLedger와 연계로 가치 상승
   - 다른 앱과도 연계 가능
   - 범용 OCR 솔루션으로 발전

3. **사용자 편의성**
   - 한 번의 OCR로 여러 앱에 활용
   - 음성 명령으로 간편 전송
   - 수동 입력 불필요

### ✅ 사용자 측면

1. **시간 절약**
   - 영수증 항목 수동 입력 불필요
   - 음성 명령 한 번으로 자동화
   - 즉시 지출 기록 완료

2. **정확성 향상**
   - OCR로 자동 추출 (오타 없음)
   - 상점명/금액 자동 인식
   - 날짜 정보 자동 파싱

3. **편리함**
   - 두 앱의 장점 결합
   - 복잡한 설정 불필요
   - 자연스러운 워크플로우

## 🚀 다음 단계

### Phase 1: 기본 연계 (현재)
- ✅ SmartLedger Deep Link 수신 준비 완료
- ✅ items, source 파라미터 처리 구현 완료
- ✅ 지출 입력 화면 자동 채우기 완료

### Phase 2: 책스캔앱 구현 (진행 필요)
- 📝 ML Kit OCR 통합
- 📝 영수증 파싱 로직
- 📝 SmartLedger 연계 버튼 추가
- 📝 최근 OCR 결과 저장 기능

### Phase 3: 음성 명령 (진행 필요)
- 📝 Bixby Capsule 업데이트
- 📝 음성 명령 핸들러 구현
- 📝 자동 실행 로직 추가

### Phase 4: 고도화 (향후)
- 🔜 건강도 분석 연계
- 🔜 카테고리 자동 분류
- 🔜 영수증 사진 보관
- 🔜 중복 입력 방지

## 📚 참고 자료

- [SmartLedger Deep Link 문서](VOICE_ASSISTANT_INTEGRATION.md)
- [DeepLinkService 구현](../lib/services/deep_link_service.dart)
- [DeepLinkHandler 구현](../lib/navigation/deep_link_handler.dart)
- [영수증 건강도 분석](RECEIPT_HEALTH_ANALYZER.md)

## 💡 팁

### 책스캔앱 OCR 정확도 향상

```dart
// 영수증 특화 전처리
final preprocessedImage = await preprocessReceiptImage(rawImage);

// ML Kit Text Recognition V2 사용 (더 정확)
final textRecognizer = GoogleMlKit.vision.textRecognizerV2();

// 한글 최적화 옵션
final options = TextRecognizerOptions(
  script: TextRecognitionScript.korean,
);
```

### Deep Link URL 인코딩

```dart
// 한글 상점명/항목명 URL 인코딩 필수
final encodedStore = Uri.encodeComponent('이마트');
final encodedItems = Uri.encodeComponent('양배추,닭고기,우유');

final deepLink = 'smartledger://transaction/add?'
    'amount=45800&'
    'store=$encodedStore&'
    'items=$encodedItems&'
    'source=ocr';
```

### 에러 처리

```dart
try {
  await launchUrl(Uri.parse(deepLink));
} catch (e) {
  // SmartLedger가 설치되지 않은 경우
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('SmartLedger 필요'),
      content: Text('SmartLedger 앱을 먼저 설치해주세요.'),
      actions: [
        TextButton(
          onPressed: () {
            // 앱 스토어로 이동
            launchUrl(Uri.parse('market://details?id=com.smartledger'));
          },
          child: Text('설치하기'),
        ),
      ],
    ),
  );
}
```

---

**작성일**: 2026-01-10  
**버전**: 1.0.0  
**상태**: SmartLedger 준비 완료, 책스캔앱 구현 대기 중
