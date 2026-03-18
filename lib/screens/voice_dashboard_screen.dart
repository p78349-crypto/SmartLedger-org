import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;  // 🔒 AI 규제 준수로 제외
import '../models/transaction.dart';
import '../services/account_service.dart';
import '../models/shopping_cart_item.dart';
import '../services/budget_service.dart';
import '../services/fixed_cost_service.dart';
import '../services/consumable_inventory_service.dart';
import '../services/transaction_service.dart';
import '../services/user_pref_service.dart';
import '../services/category_keyword_service.dart';
import '../services/smart_consuming_service.dart';
import '../services/unified_recipe_recommendation_service.dart';
import 'account_main_screen.dart';
import 'transaction_add_screen.dart';
import 'quick_simple_expense_input_screen.dart';
import '../utils/currency_formatter.dart';
part 'voice_dashboard_screen_logic.dart';
part 'voice_dashboard_screen_ui.dart';

/// 음성 제어 전용 대시보드 - 주방에서 손을 쓸 수 없는 상황을 위한 관제 센터
class VoiceDashboardScreen extends StatefulWidget {
  final String? accountName;
  final bool autoStartListening;

  const VoiceDashboardScreen({
    super.key,
    this.accountName,
    this.autoStartListening = false,
  });

  @override
  State<VoiceDashboardScreen> createState() => _VoiceDashboardScreenState();
}

class _VoiceDashboardScreenState extends State<VoiceDashboardScreen>
    with TickerProviderStateMixin {
  // 음성 인식
  final _SealedSpeechEngine _speech = const _SealedSpeechEngine();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _lastRecognizedText = '';
  String _currentText = '';
  bool _suspendAutoListen = false;

  bool get _autoListenEnabled => widget.autoStartListening;

  // 상태
  final List<VoiceCommandResult> _recentResults = [];
  bool _isProcessing = false;

  // 애니메이션
  late AnimationController _pulseController;
  late AnimationController _feedbackController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _feedbackAnimation;

  // 예산 데이터
  double _todayBudget = 0;
  double _todaySpent = 0;
  double _foodExpense = 0;
  double _fixedCost = 0;

  // 보이스 가이드 선택 인덱스
  int _selectedGuideIndex = 0;

  // 계정
  String get _accountName =>
      widget.accountName ?? AccountService().accounts.firstOrNull?.name ?? '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initAnimations();
    _loadBudgetData();

    // 화면 켜짐 유지
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// 4. 월말 정산/마감 핸들러

  // ============ 명령어 감지 ============

  /// 화면 네비게이션 명령어 감지

  // --- NEW COMMAND DETECTORS ---

  // ============ 명령어 처리 ============

  double? _extractKrwAmount(String command) {
    final withWon = RegExp(r'(\d[\d,]*)\s*원').firstMatch(command);
    if (withWon != null) {
      final amountStr = withWon.group(1)!.replaceAll(',', '');
      final amount = double.tryParse(amountStr);
      if (amount != null && amount > 0) return amount;
    }

    // Supports: 5천원, 2만 3천, 1만500, 12천 등
    final unitRegex = RegExp(r'(\d+)\s*(만|천|백|십)');
    final matches = unitRegex.allMatches(command).toList();
    if (matches.isNotEmpty) {
      double sum = 0;
      for (final m in matches) {
        final raw = m.group(1);
        final unit = m.group(2);
        if (raw == null || unit == null) continue;
        final v = double.tryParse(raw);
        if (v == null) continue;
        switch (unit) {
          case '만':
            sum += v * 10000;
            break;
          case '천':
            sum += v * 1000;
            break;
          case '백':
            sum += v * 100;
            break;
          case '십':
            sum += v * 10;
            break;
        }
      }

      // Remainder digits after the last unit (e.g., "1만500")
      final last = matches.last;
      final tail = command.substring(last.end);
      final tailDigits = RegExp(r'(\d[\d,]*)').firstMatch(tail);
      if (tailDigits != null) {
        final raw = tailDigits.group(1)!.replaceAll(',', '');
        final v = double.tryParse(raw);
        if (v != null) sum += v;
      }
      if (sum > 0) return sum;
    }

    // Fallback: first number token (only when intent already indicates expense)
    final digits = RegExp(r'(\d[\d,]*)').firstMatch(command);
    if (digits != null) {
      final raw = digits.group(1)!.replaceAll(',', '');
      final amount = double.tryParse(raw);
      if (amount != null && amount > 0) return amount;
    }

    return null;
  }

  // ============ 카테고리 추론 헬퍼 ============
  (String, String?) _inferCategory(String description) {
    // 1. 최근 기록 기반 학습 (History Learning)
    try {
      final history = TransactionService().getTransactions(_accountName);
      final search = description.replaceAll(' ', '').toLowerCase();

      // 최신순 탐색
      for (int i = history.length - 1; i >= 0; i--) {
        final t = history[i];
        if (t.type != TransactionType.expense) continue;

        // 설명이 비슷하면 해당 카테고리 채택
        final tDesc = t.description.replaceAll(' ', '').toLowerCase();
        if (tDesc == search || (search.length > 1 && tDesc.contains(search))) {
          return (t.mainCategory, t.subCategory);
        }
      }
    } catch (e) {
      // Ignore error
    }

    // 2. 키워드 사전 기반 (Dictionary)
    final keywordMatch = CategoryKeywordService.instance.classify(description);
    if (keywordMatch != null) return keywordMatch;

    // 3. 기본값
    return ('미분류', null);
  }

  /// 화면 네비게이션 명령 처리

  /// 장바구니 추가 + 최저가 안내

  VoiceCommandResult _buildClosedResult(String cmd) {
    _suspendAutoListen = false;
    return VoiceCommandResult(
      command: cmd,
      success: false,
      message: '화면이 닫혀서 이동할 수 없습니다.',
      type: VoiceCommandType.navigation,
    );
  }

  // --- Special Exception Handler ---

  /// 1. 고정지출 브리핑 핸들러

  /// 2. 지출 조언 (예산 코칭) 핸들러

  /// 3. 폐기물 기록 (재고 삭제) 핸들러

  VoiceCommandResult _handleIngredientQuery(String command) {
    // 식재료 서비스에서 조회
    final items = ConsumableInventoryService.instance.items.value;

    // 특정 재료 검색
    final keywords = command
        .replaceAll('남은', '')
        .replaceAll('얼마나', '')
        .replaceAll('있어', '')
        .replaceAll('재료', '')
        .replaceAll('?', '')
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();

    if (keywords.isEmpty) {
      // 전체 재료 현황
      final count = items.length;
      final expiringSoon = items.where((i) {
        final expiryDate = i.expiryDate;
        if (expiryDate == null) return false;
        final days = expiryDate.difference(DateTime.now()).inDays;
        return days >= 0 && days <= 3;
      }).length;

      return VoiceCommandResult(
        command: command,
        success: true,
        message:
            '현재 $count개의 재료가 등록되어 있어요. '
            '${expiringSoon > 0 ? '$expiringSoon개는 곧 유통기한이에요.' : ''}\n\n'
            '💡 등록된 재고가 실제와 다를 수 있어요. 가계부 내역도 함께 참고하세요.', // 유저 요청 반영: 정확성 한계 안내
        type: VoiceCommandType.query,
      );
    }

    // 특정 재료 검색
    for (final keyword in keywords) {
      final matches = items
          .where((i) => i.name.contains(keyword) || keyword.contains(i.name))
          .toList();

      if (matches.isNotEmpty) {
        final item = matches.first;
        final expiryDate = item.expiryDate;
        final daysLeft = expiryDate?.difference(DateTime.now()).inDays;
        final quantityStr = '${item.currentStock}${item.unit}';

        return VoiceCommandResult(
          command: command,
          success: true,
          message:
              '${item.name} $quantityStr 남아있네요. '
              '${daysLeft == null ? '유통기한 정보가 없습니다.' : (daysLeft >= 0 ? '유통기한은 $daysLeft일 남았어요.' : '유통기한이 지났어요!')}',
          type: VoiceCommandType.query,
          data: {'item': item.name, 'daysLeft': daysLeft},
        );
      }
    }

    // 재고 목록에 없을 경우 -> 최근 구매 기록 확인 (Transaction Service)
    try {
      final history = TransactionService().getTransactions(_accountName);
      final recentPurchase = history.where((t) {
        if (t.type != TransactionType.expense) return false;
        // 30일 이내 구매 내역만
        if (DateTime.now().difference(t.date).inDays > 30) return false;
        // 키워드 포함 여부
        return keywords.any(
          (k) =>
              t.description.contains(k) ||
              (t.store != null && t.store!.contains(k)),
        );
      }).toList();

      // 최신순 정렬
      recentPurchase.sort((a, b) => b.date.compareTo(a.date));

      if (recentPurchase.isNotEmpty) {
        final last = recentPurchase.first;
        final daysAgo = DateTime.now().difference(last.date).inDays;
        final timeStr = daysAgo == 0 ? '오늘' : '$daysAgo일 전';

        return VoiceCommandResult(
          command: command,
          success: true,
          message:
              '재고 목록엔 없지만, $timeStr에 "${last.description}" 구매하신 내역이 있어요. 아직 남아있을 수도 있겠네요!',
          type: VoiceCommandType.query,
        );
      }
    } catch (e) {
      // ignore
    }

    return VoiceCommandResult(
      command: command,
      success: true,
      message: '해당 재료를 찾지 못했어요. 구매하신 지 오래되었거나 내역이 없을 수 있어요.',
      type: VoiceCommandType.query,
    );
  }

  VoiceCommandResult _handleBudgetQuery() {
    final remaining = _todayBudget - _todaySpent;
    final message = remaining >= 0
        ? '오늘 예산 ${CurrencyFormatter.format(remaining)} 남았어요.'
        : '오늘 예산을 ${CurrencyFormatter.format(-remaining)} 초과했어요.';

    return VoiceCommandResult(
      command: '예산 조회',
      success: true,
      message: message,
      type: VoiceCommandType.query,
      data: {
        'remaining': remaining,
        'budget': _todayBudget,
        'spent': _todaySpent,
      },
    );
  }

  VoiceCommandResult _handleMenuRecommend() {
    // Legacy simple handler (now delegated to _handleComplexMealQuery)
    return VoiceCommandResult(
      command: '메뉴 추천',
      success: false,
      message: '잠시만요...',
      type: VoiceCommandType.unknown,
    );
  }

  // REMOVED DUPLICATE _handleShoppingCartAdd METHOD

  VoiceCommandResult _handleTodaySummary() {
    return VoiceCommandResult(
      command: '오늘 요약',
      success: true,
      message:
          '오늘 ${CurrencyFormatter.format(_todaySpent)} 썼어요. '
          '식재료비 ${CurrencyFormatter.format(_foodExpense)}, '
          '기타 ${CurrencyFormatter.format(_fixedCost)}이에요.',
      type: VoiceCommandType.query,
      data: {'total': _todaySpent, 'food': _foodExpense, 'fixed': _fixedCost},
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _pulseController.dispose();
    _feedbackController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('🎙️ 음성 제어'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: '도움말',
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. 상단: 실시간 상태 바
          _buildStatusBar(colorScheme),

          // 2. 중앙: 실시간 피드백 카드
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildBudgetCard(colorScheme),
                  const SizedBox(height: 16),
                  _buildRecentActivityCard(colorScheme),
                  const SizedBox(height: 16),
                  _buildVoiceGuideCard(colorScheme),
                  const SizedBox(height: 16),
                  _buildQuickCommandsCard(colorScheme),
                ],
              ),
            ),
          ),

          // 3. 하단: 마이크 버튼
          _buildMicrophoneButton(colorScheme, size),
        ],
      ),
    );
  }

  /// 상단 상태 바

  /// 예산 카드 (3단계 계층)

  /// 최근 활동 카드

  /// 보이스 가이드 데이터
  static const List<_VoiceGuideData> _voiceGuidePages = [
    _VoiceGuideData(
      level: '초급',
      levelEmoji: '🌱',
      levelColorValue: 0xFF4CAF50, // Colors.green
      title: '기본 지출 입력',
      description: '간단한 금액부터 시작해보세요!',
      examples: ['"지출 3,000원 입력해줘"', '"5천원 썼어"', '"점심 만원"'],
      tip: '금액만 말해도 자동으로 저장됩니다',
    ),
    _VoiceGuideData(
      level: '중급',
      levelEmoji: '🌿',
      levelColorValue: 0xFFFF9800, // Colors.orange
      title: '재료와 함께 입력',
      description: '무엇을 샀는지도 말해보세요!',
      examples: ['"팽이버섯 1봉 썼어"', '"달걀 한판 6천원"', '"양파 2개 천원"'],
      tip: '재료 이름을 말하면 식비로 자동 분류!',
    ),
    _VoiceGuideData(
      level: '고급',
      levelEmoji: '🌳',
      levelColorValue: 0xFF9C27B0, // Colors.purple
      title: '스마트 메뉴 추천',
      description: '남은 재료와 예산으로 메뉴 추천!',
      examples: ['"오늘 남은 재료로 메뉴 추천해줘"', '"3천원으로 뭐 만들지?"', '"냉장고에 뭐 있어?"'],
      tip: '유통기한 임박 재료를 우선 추천해요',
    ),
    _VoiceGuideData(
      level: '마스터',
      levelEmoji: '👑',
      levelColorValue: 0xFFFFA000, // Colors.amber.shade700
      title: '복합 명령',
      description: '여러 작업을 한 번에!',
      examples: ['"두부 천원 쓰고 장바구니에서 빼줘"', '"예산 확인하고 메뉴 추천해줘"', '"오늘 뭐 썼는지 알려줘"'],
      tip: '자연스럽게 대화하듯 말해보세요',
    ),
  ];

  /// 보이스 가이드 - 탭 버튼 전환 방식 (메인 페이지 스와이프와 충돌 방지)

  /// 전체 보이스 가이드 다이얼로그

  /// 빠른 단축어 (기존 호환)

  /// 마이크 버튼
}
