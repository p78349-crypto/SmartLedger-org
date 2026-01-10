import 'package:flutter/material.dart';

/// 다국어 지원 유틸리티
/// 
/// 사용 예시:
/// ```dart
/// // 번역 가져오기
/// final text = LocalizationUtils.tr(context, 'hello');
/// 
/// // 플레이스홀더 포함
/// final text = LocalizationUtils.tr(context, 'welcome', args: {'name': '홍길동'});
/// 
/// // 언어 코드 가져오기
/// final lang = LocalizationUtils.getCurrentLanguage(context); // 'ko', 'en', 'ja'
/// ```
class LocalizationUtils {
  LocalizationUtils._();

  /// 현재 언어 코드 가져오기
  static String getCurrentLanguage(BuildContext context) {
    return Localizations.localeOf(context).languageCode;
  }

  /// 현재 로케일 가져오기
  static Locale getCurrentLocale(BuildContext context) {
    return Localizations.localeOf(context);
  }

  /// 한국어인지 확인
  static bool isKorean(BuildContext context) {
    return getCurrentLanguage(context) == 'ko';
  }

  /// 영어인지 확인
  static bool isEnglish(BuildContext context) {
    return getCurrentLanguage(context) == 'en';
  }

  /// 일본어인지 확인
  static bool isJapanese(BuildContext context) {
    return getCurrentLanguage(context) == 'ja';
  }

  /// 간단한 번역 (인메모리 맵 사용)
  static String tr(
    BuildContext context,
    String key, {
    Map<String, String>? args,
  }) {
    final lang = getCurrentLanguage(context);
    final translations = _translations[lang] ?? _translations['ko']!;
    var text = translations[key] ?? key;

    // 플레이스홀더 치환
    if (args != null) {
      args.forEach((key, value) {
        text = text.replaceAll('{$key}', value);
      });
    }

    return text;
  }

  /// 언어별 포맷 (숫자, 날짜 등)
  static String formatCurrency(
    BuildContext context,
    double amount, {
    String? symbol,
  }) {
    final lang = getCurrentLanguage(context);
    final currencySymbol = symbol ?? _getCurrencySymbol(lang);

    switch (lang) {
      case 'en':
        return '$currencySymbol${amount.toStringAsFixed(2)}';
      case 'ja':
        return '$currencySymbol${amount.toStringAsFixed(0)}';
      case 'ko':
      default:
        return '${amount.toStringAsFixed(0)}$currencySymbol';
    }
  }

  static String _getCurrencySymbol(String lang) {
    switch (lang) {
      case 'en':
        return '\$';
      case 'ja':
        return '¥';
      case 'ko':
      default:
        return '원';
    }
  }

  /// 복수형 처리
  static String plural(
    BuildContext context,
    String key,
    int count,
  ) {
    final lang = getCurrentLanguage(context);

    if (lang == 'ko' || lang == 'ja') {
      // 한국어/일본어는 복수형 없음
      return tr(context, key);
    }

    // 영어 복수형
    if (count == 1) {
      return tr(context, '${key}_one');
    } else {
      return tr(context, '${key}_other', args: {'count': count.toString()});
    }
  }
}

/// 번역 데이터 (예시)
const Map<String, Map<String, String>> _translations = {
  'ko': {
    // 공통
    'app_name': 'SmartLedger',
    'ok': '확인',
    'cancel': '취소',
    'save': '저장',
    'delete': '삭제',
    'edit': '편집',
    'add': '추가',
    'search': '검색',
    'close': '닫기',
    'back': '뒤로',
    'next': '다음',
    'done': '완료',
    'error': '오류',
    'loading': '로딩 중...',
    'no_data': '데이터가 없습니다',
    
    // 거래
    'transaction': '거래',
    'expense': '지출',
    'income': '수입',
    'savings': '저축',
    'refund': '반품',
    'amount': '금액',
    'description': '설명',
    'category': '카테고리',
    'date': '날짜',
    'memo': '메모',
    
    // 음성 명령
    'voice_command_expense': '지출 기록',
    'voice_command_income': '수입 기록',
    'voice_command_recipe': '요리 추천',
    'voice_command_shopping': '쇼핑 안내',
    'voice_command_receipt': '영수증 분석',
    
    // 영수증
    'receipt': '영수증',
    'receipt_scan': '영수증 스캔',
    'receipt_analysis': '영수증 분석',
    'health_score': '건강 점수',
    'store': '상점',
    'items': '항목',
    
    // 요리
    'recipe': '레시피',
    'ingredients': '재료',
    'cooking': '요리',
    'expiring_soon': '유통기한 임박',
    'days_left': '{days}일 남음',
    
    // 메시지
    'welcome': '환영합니다, {name}님!',
    'transaction_saved': '거래가 저장되었습니다',
    'confirm_delete': '삭제하시겠습니까?',
  },
  'en': {
    // Common
    'app_name': 'SmartLedger',
    'ok': 'OK',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'add': 'Add',
    'search': 'Search',
    'close': 'Close',
    'back': 'Back',
    'next': 'Next',
    'done': 'Done',
    'error': 'Error',
    'loading': 'Loading...',
    'no_data': 'No data available',
    
    // Transaction
    'transaction': 'Transaction',
    'expense': 'Expense',
    'income': 'Income',
    'savings': 'Savings',
    'refund': 'Refund',
    'amount': 'Amount',
    'description': 'Description',
    'category': 'Category',
    'date': 'Date',
    'memo': 'Memo',
    
    // Voice commands
    'voice_command_expense': 'Record expense',
    'voice_command_income': 'Record income',
    'voice_command_recipe': 'Recommend recipe',
    'voice_command_shopping': 'Shopping guide',
    'voice_command_receipt': 'Analyze receipt',
    
    // Receipt
    'receipt': 'Receipt',
    'receipt_scan': 'Scan receipt',
    'receipt_analysis': 'Receipt analysis',
    'health_score': 'Health score',
    'store': 'Store',
    'items': 'Items',
    
    // Recipe
    'recipe': 'Recipe',
    'ingredients': 'Ingredients',
    'cooking': 'Cooking',
    'expiring_soon': 'Expiring soon',
    'days_left': '{days} days left',
    
    // Messages
    'welcome': 'Welcome, {name}!',
    'transaction_saved': 'Transaction saved',
    'confirm_delete': 'Are you sure you want to delete?',
  },
  'ja': {
    // 共通
    'app_name': 'SmartLedger',
    'ok': 'OK',
    'cancel': 'キャンセル',
    'save': '保存',
    'delete': '削除',
    'edit': '編集',
    'add': '追加',
    'search': '検索',
    'close': '閉じる',
    'back': '戻る',
    'next': '次へ',
    'done': '完了',
    'error': 'エラー',
    'loading': '読み込み中...',
    'no_data': 'データがありません',
    
    // 取引
    'transaction': '取引',
    'expense': '支出',
    'income': '収入',
    'savings': '貯蓄',
    'refund': '返品',
    'amount': '金額',
    'description': '説明',
    'category': 'カテゴリ',
    'date': '日付',
    'memo': 'メモ',
    
    // 音声コマンド
    'voice_command_expense': '支出を記録',
    'voice_command_income': '収入を記録',
    'voice_command_recipe': 'レシピを推薦',
    'voice_command_shopping': '買い物案内',
    'voice_command_receipt': 'レシート分析',
    
    // レシート
    'receipt': 'レシート',
    'receipt_scan': 'レシートスキャン',
    'receipt_analysis': 'レシート分析',
    'health_score': '健康スコア',
    'store': '店舗',
    'items': '項目',
    
    // 料理
    'recipe': 'レシピ',
    'ingredients': '材料',
    'cooking': '料理',
    'expiring_soon': '期限切れ間近',
    'days_left': '残り{days}日',
    
    // メッセージ
    'welcome': 'ようこそ、{name}さん！',
    'transaction_saved': '取引が保存されました',
    'confirm_delete': '削除してもよろしいですか？',
  },
};

/// 간단한 확장 메서드
extension LocalizationExtension on BuildContext {
  /// 번역 가져오기
  String tr(String key, {Map<String, String>? args}) {
    return LocalizationUtils.tr(this, key, args: args);
  }

  /// 현재 언어 코드
  String get languageCode => LocalizationUtils.getCurrentLanguage(this);

  /// 한국어 여부
  bool get isKorean => LocalizationUtils.isKorean(this);

  /// 영어 여부
  bool get isEnglish => LocalizationUtils.isEnglish(this);

  /// 일본어 여부
  bool get isJapanese => LocalizationUtils.isJapanese(this);

  /// 통화 포맷
  String formatCurrency(double amount, {String? symbol}) {
    return LocalizationUtils.formatCurrency(this, amount, symbol: symbol);
  }
}
