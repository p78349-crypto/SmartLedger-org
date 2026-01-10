# SmartLedger 다국어 지원 가이드

## 📚 개요

SmartLedger는 `localization_utils.dart`를 통해 간단한 다국어 지원을 제공합니다.

**지원 언어:**
- 🇰🇷 한국어 (ko)
- 🇺🇸 영어 (en)
- 🇯🇵 일본어 (ja)

## 🚀 빠른 시작

### 1️⃣ 기본 사용법

```dart
import '../utils/localization_utils.dart';

// 방법 1: LocalizationUtils 직접 사용
final text = LocalizationUtils.tr(context, 'expense');

// 방법 2: 확장 메서드 사용 (더 간결)
final text = context.tr('expense');
```

### 2️⃣ 플레이스홀더 치환

```dart
// {name} 플레이스홀더
final welcome = context.tr('welcome', args: {'name': '홍길동'});
// 결과: "환영합니다, 홍길동님!" (ko)
// 결과: "Welcome, 홍길동!" (en)

// {days} 플레이스홀더
final daysLeft = context.tr('days_left', args: {'days': '3'});
// 결과: "3일 남음" (ko)
// 결과: "3 days left" (en)
```

### 3️⃣ 언어 감지

```dart
// 현재 언어 코드
final lang = context.languageCode; // 'ko', 'en', 'ja'

// 언어별 분기
if (context.isKorean) {
  print('한국어 사용자');
} else if (context.isEnglish) {
  print('English user');
} else if (context.isJapanese) {
  print('日本語ユーザー');
}
```

### 4️⃣ 통화 포맷

```dart
// 언어별 통화 포맷 자동 적용
final formatted = context.formatCurrency(45800);
// 한국어: "45800원"
// 영어: "$45800.00"
// 일본어: "¥45800"

// 커스텀 심볼
final custom = context.formatCurrency(1000, symbol: '€');
// "1000€" (ko), "€1000.00" (en)
```

## 📝 번역 키 추가하기

### 1️⃣ `localization_utils.dart` 수정

```dart
const Map<String, Map<String, String>> _translations = {
  'ko': {
    // ... 기존 키들
    'new_feature': '새로운 기능', // ✅ 추가
  },
  'en': {
    // ... 기존 키들
    'new_feature': 'New Feature', // ✅ 추가
  },
  'ja': {
    // ... 기존 키들
    'new_feature': '新機能', // ✅ 추가
  },
};
```

### 2️⃣ 사용

```dart
Text(context.tr('new_feature'))
```

## 🎯 실제 사용 예시

### 예시 1: 버튼 텍스트

```dart
ElevatedButton(
  onPressed: _save,
  child: Text(context.tr('save')), // "저장" / "Save" / "保存"
)
```

### 예시 2: 다이얼로그

```dart
AlertDialog(
  title: Text(context.tr('confirm_delete')),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(context.tr('cancel')),
    ),
    TextButton(
      onPressed: _delete,
      child: Text(context.tr('ok')),
    ),
  ],
)
```

### 예시 3: 음성 명령

```dart
final voiceCommand = context.tr('voice_command_expense');
// 한국어: "지출 기록"
// 영어: "Record expense"
// 일본어: "支出を記録"
```

### 예시 4: 건강도 분석

```dart
Text(context.tr('health_score')) // "건강 점수" / "Health score"

final scoreText = context.tr('receipt_analysis');
// 한국어: "영수증 분석"
// 영어: "Receipt analysis"
// 일본어: "レシート分析"
```

## 🔧 고급 사용법

### 복수형 처리

```dart
// 영어에서만 복수형 적용
final text = LocalizationUtils.plural(context, 'item', count);
// count = 1: "item"
// count > 1: "items"

// 한국어/일본어는 복수형 없음
```

### 조건부 텍스트

```dart
Widget buildTitle(BuildContext context) {
  if (context.isKorean) {
    return Text('환영합니다');
  } else {
    return Text(context.tr('welcome', args: {'name': 'User'}));
  }
}
```

### 날짜/시간 포맷

```dart
// 언어별 날짜 포맷은 intl 패키지 사용 권장
import 'package:intl/intl.dart';

String formatDate(BuildContext context, DateTime date) {
  final locale = context.languageCode;
  final formatter = DateFormat.yMMMd(locale);
  return formatter.format(date);
  // 한국어: "2026. 1. 10."
  // 영어: "Jan 10, 2026"
  // 일본어: "2026年1月10日"
}
```

## 📋 기본 제공 번역 키

### 공통
- `app_name`, `ok`, `cancel`, `save`, `delete`, `edit`, `add`
- `search`, `close`, `back`, `next`, `done`
- `error`, `loading`, `no_data`

### 거래
- `transaction`, `expense`, `income`, `savings`, `refund`
- `amount`, `description`, `category`, `date`, `memo`

### 음성 명령
- `voice_command_expense`, `voice_command_income`
- `voice_command_recipe`, `voice_command_shopping`
- `voice_command_receipt`

### 영수증
- `receipt`, `receipt_scan`, `receipt_analysis`
- `health_score`, `store`, `items`

### 요리
- `recipe`, `ingredients`, `cooking`
- `expiring_soon`, `days_left`

### 메시지
- `welcome`, `transaction_saved`, `confirm_delete`

## 🌍 언어 전환

### 시스템 언어 따르기 (기본)

```dart
MaterialApp(
  localizationsDelegates: [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: [
    Locale('ko', 'KR'),
    Locale('en', 'US'),
    Locale('ja', 'JP'),
  ],
  // 시스템 언어 자동 적용
)
```

### 수동 언어 전환 (향후 구현 가능)

```dart
// 설정 화면에서 언어 선택
class LanguageSettings extends StatefulWidget {
  // ...
}

// SharedPreferences에 저장
await prefs.setString('language', 'en');

// 앱 재시작 시 적용
final savedLang = prefs.getString('language') ?? 'ko';
MaterialApp(
  locale: Locale(savedLang),
  // ...
)
```

## 🎨 UI 예시

### 언어 선택 다이얼로그

```dart
void showLanguageDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr('select_language')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Text('🇰🇷'),
            title: Text('한국어'),
            onTap: () => _changeLanguage('ko'),
          ),
          ListTile(
            leading: Text('🇺🇸'),
            title: Text('English'),
            onTap: () => _changeLanguage('en'),
          ),
          ListTile(
            leading: Text('🇯🇵'),
            title: Text('日本語'),
            onTap: () => _changeLanguage('ja'),
          ),
        ],
      ),
    ),
  );
}
```

## 💡 팁

### 1. 번역 키 네이밍 규칙

```dart
// ✅ Good: 명확하고 계층적
'transaction_expense_add'
'recipe_ingredient_list'
'voice_command_receipt'

// ❌ Bad: 모호하고 중복 가능
'add'
'list'
'command'
```

### 2. 플레이스홀더 사용

```dart
// ✅ Good: 동적 데이터는 플레이스홀더
'welcome': '환영합니다, {name}님!'
'days_left': '{days}일 남음'

// ❌ Bad: 하드코딩
'welcome_kim': '환영합니다, 김철수님!' // 유지보수 어려움
```

### 3. 컨텍스트 제공

```dart
// ✅ Good: 의미 명확
'button_save'
'dialog_confirm_delete'
'error_network_failed'

// ❌ Bad: 컨텍스트 없음
'save'  // 버튼? 메시지? 액션?
```

### 4. 긴 텍스트 처리

```dart
// 여러 줄 텍스트는 개행 문자 사용
'help_text': '이것은 도움말입니다.\n'
             '여러 줄로 작성할 수 있습니다.\n'
             '각 줄은 개행으로 구분됩니다.'
```

## 🔍 디버깅

### 누락된 번역 확인

```dart
String tr(BuildContext context, String key, {Map<String, String>? args}) {
  final lang = getCurrentLanguage(context);
  final translations = _translations[lang] ?? _translations['ko']!;
  var text = translations[key];
  
  if (text == null) {
    print('⚠️ Missing translation: $key for $lang'); // ✅ 디버그 로그
    return key; // 키 자체 반환
  }
  
  // ...
}
```

### 언어 전환 테스트

```dart
// 시뮬레이터/에뮬레이터 언어 변경
// iOS: Settings → General → Language & Region
// Android: Settings → System → Languages → Add a language
```

## 📚 참고 자료

- [Flutter Internationalization](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [intl 패키지](https://pub.dev/packages/intl)
- [easy_localization 패키지](https://pub.dev/packages/easy_localization) (향후 고려)

---

**작성일**: 2026-01-10  
**버전**: 1.0.0  
**상태**: 기본 구조 완성, 확장 가능
