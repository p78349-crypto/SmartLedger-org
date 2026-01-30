# AICore (Gemini Nano) 사용 방법

## 🎯 실제 호출 흐름

```
사용자 → Flutter UI → AICoreGeminiService → MethodChannel → AICoreMethodChannel (Kotlin) → Gemini Nano
```

## 📦 Gemini Nano 설치 방식

### ✅ 자동 설치 (별도 다운로드 불필요)

**Gemini Nano는 Android 시스템 구성 요소로 자동 제공됩니다:**

1. **Pixel 8 Pro 이상**: 시스템에 기본 내장
2. **Android 14+ 기기**: Google Play Services 통해 **자동 다운로드**
3. **사용자 조치 불필요**: 앱 설치 시 백그라운드에서 자동 처리

### 📱 지원 기기
- ✅ **Pixel 8 Pro, Pixel 9** 시리즈 (기본 탑재)
- ✅ **삼성 Galaxy S24 Ultra** (Android 14+, 자동 다운로드)
- ✅ **기타 Android 14+** 플래그십 기기 (Google Play Services 통해 자동)

### ⚠️ 미지원 기기
- ❌ Android 13 이하
- ❌ 저사양 기기 (RAM 4GB 이하)
→ **자동으로 온라인 API로 폴백**

## 📱 1. Flutter에서 호출

### 기본 사용법

```dart
import 'package:smart_ledger/services/aicore_gemini_service.dart';

// 1️⃣ 서비스 인스턴스 생성
final aicore = AICoreGeminiService();

// 2️⃣ AICore 사용 가능 여부 확인
final available = await aicore.isAvailable();
if (available) {
  print('✅ Gemini Nano 사용 가능 (완전 오프라인)');
} else {
  print('❌ Android 14+ 또는 Gemini Nano 미설치');
}
```

### 영수증 텍스트 파싱

```dart
final ocrText = '''
GS25 강남점
2026-01-28 14:30
사과 2개 5,000원
바나나 3개 3,000원
합계: 8,000원
''';

// 3️⃣ AICore로 파싱 (온디바이스)
final result = await aicore.parseReceiptText(ocrText);

if (result.containsKey('error')) {
  print('에러: ${result['error']}');
} else {
  print('상점: ${result['store']}');
  print('날짜: ${result['date']}');
  print('총액: ${result['total']}원');
  print('신뢰도: ${result['confidence']}');
}
```

### 음성 입력 처리

```dart
// 4️⃣ 음성 텍스트를 구조화된 거래로 변환
final userSpeech = "어제 스타벅스에서 아메리카노 5500원 샀어";
final result = await aicore.processVoiceInput(userSpeech);

// 결과 활용
if (!result.containsKey('error')) {
  final transaction = Transaction(
    id: DateTime.now().toString(),
    type: TransactionType.expense,
    description: result['store'] ?? '미분류',
    amount: result['total']?.toDouble() ?? 0.0,
    date: DateTime.parse(result['date']),
    memo: '${result['category']} - AI 자동 입력',
  );
  
  await TransactionService().addTransaction(accountName, transaction);
}
```

---

## 🔧 2. Android Native 호출 (자동)

### MethodChannel 통신

```dart
// Flutter → Android 호출 (내부 구현)
final result = await _channel.invokeMethod<String>(
  'generateText',
  {'prompt': '영수증을 JSON으로 변환하세요'},
);
```

### Kotlin에서 Gemini Nano 호출

```kotlin
// AICoreMethodChannel.kt (자동 실행)
val generativeModel = GenerativeModel(
    modelName = "gemini-nano",
    context = context,
    generationConfig = generationConfig {
        temperature = 0.7f
        topK = 40
        topP = 0.95f
        maxOutputTokens = 1024
    }
)

// 텍스트 생성
val response = model.generateContent(
    Content.Builder()
        .addText(prompt)
        .build()
)
```

---

## 📋 3. 실전 예제: GeminiVoiceInputScreen

### 화면 초기화

```dart
class _GeminiVoiceInputScreenState extends State<GeminiVoiceInputScreen> {
  late final AICoreGeminiService _aicore;
  bool _aicoreAvailable = false;
  
  @override
  void initState() {
    super.initState();
    _aicore = AICoreGeminiService();
    _checkAICore();
  }
  
  Future<void> _checkAICore() async {
    final available = await _aicore.isAvailable();
    setState(() => _aicoreAvailable = available);
  }
}
```

### 음성 입력 처리

```dart
Future<void> _processVoiceInput(String audioPath) async {
  setState(() => _isProcessing = true);
  
  try {
    // AICore (Gemini Nano) 호출 - 완전 오프라인
    final result = await _aicore.processVoiceInput(userSpeech);
    
    setState(() {
      _parsedData = result;
      _isProcessing = false;
    });
    
    if (!result.containsKey('error')) {
      _showConfirmDialog(result);
    }
  } catch (e) {
    _showError('처리 실패: $e');
  }
}
```

### OCR 텍스트 처리

```dart
Future<void> _processTextInput(String ocrText) async {
  // AICore로 영수증 파싱
  final result = await _aicore.parseReceiptText(ocrText);
  
  if (!result.containsKey('error')) {
    // 거래 저장
    _saveTransaction(result);
  }
}
```

---

## 🎨 4. UI에 상태 표시

```dart
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('🎙️ AI 음성 입력'),
      actions: [
        // AICore 상태 칩
        Chip(
          avatar: Icon(
            _aicoreAvailable ? Icons.offline_bolt : Icons.cloud,
            color: _aicoreAvailable ? Colors.green : Colors.orange,
          ),
          label: Text(_aicoreAvailable ? '오프라인' : '온라인'),
        ),
      ],
    ),
    body: Column(
      children: [
        // 경고 배너
        if (!_aicoreAvailable)
          Container(
            color: Colors.orange.withAlpha(30),
            child: Text('AICore 미지원 - 온라인 API 사용 중'),
          ),
        
        // 나머지 UI...
      ],
    ),
  );
}
```

---

## 🧪 5. 테스트 방법

### 간단한 테스트 코드

```dart
void testAICore() async {
  final aicore = AICoreGeminiService();
  
  // 1. 사용 가능 여부
  print('AICore 확인 중...');
  final available = await aicore.isAvailable();
  print(available ? '✅ 사용 가능' : '❌ 사용 불가');
  
  if (!available) return;
  
  // 2. 영수증 파싱 테스트
  final receiptResult = await aicore.parseReceiptText('''
    편의점 
    우유 3000원
    빵 2000원
    총 5000원
  ''');
  print('영수증 파싱: $receiptResult');
  
  // 3. 음성 입력 테스트
  final voiceResult = await aicore.processVoiceInput(
    '오늘 마트에서 사과 2개 5000원 샀어'
  );
  print('음성 처리: $voiceResult');
  
  // 4. 카테고리 예측 테스트
  final category = await aicore.predictCategory('아메리카노');
  print('카테고리: $category');
}
```

### Android Studio 로그 확인

```bash
# 터미널에서 로그 모니터링
adb logcat | grep -i "aicore\|gemini"

# 또는 Android Studio Logcat에서:
# 필터: tag:AICoreMethodChannel
```

---

## 🔄 6. 폴백 전략

```dart
class SmartAIService {
  final _aicore = AICoreGeminiService();
  final _geminiApi = GeminiApiService(); // 온라인 API
  
  Future<Map<String, dynamic>> parseReceipt(String text) async {
    // 1차: AICore (오프라인)
    if (await _aicore.isAvailable()) {
      try {
        return await _aicore.parseReceiptText(text);
      } catch (e) {
        print('AICore 실패, 온라인 API로 전환: $e');
      }
    }
    
    // 2차: Gemini API (온라인)
    return await _geminiApi.parseReceiptText(text);
  }
}
```

---

## ⚡ 7. 성능 최적화

### 배치 처리

```dart
Future<List<Map<String, dynamic>>> processBatch(
  List<String> receipts
) async {
  final results = <Map<String, dynamic>>[];
  
  for (final receipt in receipts) {
    final result = await _aicore.parseReceiptText(receipt);
    results.add(result);
    
    // 과열 방지 지연
    await Future.delayed(Duration(milliseconds: 100));
  }
  
  return results;
}
```

### 캐싱

```dart
final _cache = <String, Map<String, dynamic>>{};

Future<Map<String, dynamic>> parseWithCache(String text) async {
  final hash = text.hashCode.toString();
  
  if (_cache.containsKey(hash)) {
    return _cache[hash]!;
  }
  
  final result = await _aicore.parseReceiptText(text);
  _cache[hash] = result;
  return result;
}
```

---

## 📊 8. 에러 처리

```dart
Future<Map<String, dynamic>> safeParseReceipt(String text) async {
  try {
    return await _aicore.parseReceiptText(text);
  } on PlatformException catch (e) {
    return {
      'error': 'Platform 에러: ${e.message}',
      'code': e.code,
    };
  } catch (e) {
    return {
      'error': '알 수 없는 에러: $e',
    };
  }
}
```

---

## ✅ 실행 체크리스트

1. **코드 통합 완료**
   - [x] AICoreGeminiService.dart
   - [x] AICoreMethodChannel.kt
   - [x] MainActivity.kt 연결
   - [x] build.gradle.kts 의존성

2. **기기 요구사항**
   - [ ] Android 14 (API 34) 이상
   - [ ] Gemini Nano 설치 확인
   - [ ] Google Play Services 최신

3. **테스트**
   - [ ] isAvailable() 확인
   - [ ] parseReceiptText() 테스트
   - [ ] processVoiceInput() 테스트
   - [ ] 실제 기기 동작 확인

4. **배포 준비**
   - [ ] 폴백 전략 구현
   - [ ] 에러 로깅 추가
   - [ ] 사용자 가이드 작성

---

**요약**: `AICoreGeminiService()`를 생성하고 `await aicore.parseReceiptText(text)` 또는 `await aicore.processVoiceInput(speech)`를 호출하면 됩니다! 🚀
