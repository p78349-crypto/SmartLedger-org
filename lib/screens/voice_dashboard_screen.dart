import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/transaction.dart';
import '../services/account_service.dart';
import '../models/shopping_cart_item.dart';
import '../services/budget_service.dart';
import '../services/fixed_cost_service.dart';
import '../services/food_expiry_service.dart';
import '../services/consumable_inventory_service.dart';
import '../services/recipe_service.dart';
import '../services/transaction_service.dart';
import '../services/user_pref_service.dart';
import '../services/category_keyword_service.dart';
import '../services/smart_consuming_service.dart';
import 'account_main_screen.dart';
import 'transaction_add_screen.dart';
import 'quick_simple_expense_input_screen.dart';
import '../utils/currency_formatter.dart';

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
  final stt.SpeechToText _speech = stt.SpeechToText();
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

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _feedbackAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.easeOut),
    );
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: (error) {
          debugPrint('Speech error: $error');
          if (mounted) {
            setState(() {
              _isListening = false;
              _currentText = '';
            });
          }
        },
      );
      if (mounted) {
        setState(() {});

        if (widget.autoStartListening && _speechAvailable) {
          // Give the UI a beat before starting the permission/listen flow.
          Future.delayed(const Duration(milliseconds: 200), () {
            if (!mounted) return;
            if (_isListening) return;
            _startListening();
          });
        }
      }
    } catch (e) {
      debugPrint('Speech init error: $e');
    }
  }

  void _onSpeechStatus(String status) {
    debugPrint('Speech status: $status');
    if (status == 'done' || status == 'notListening') {
      if (_currentText.isNotEmpty) {
        _processVoiceCommand(_currentText);
      }
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }

      // Hands-free mode: keep listening for the next command.
      if (_autoListenEnabled && !_suspendAutoListen) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          if (_isListening) return;
          if (_isProcessing) return;
          if (_suspendAutoListen) return;
          _startListening();
        });
      }
    }
  }

  Future<void> _loadBudgetData() async {
    final now = DateTime.now();
    final budget = BudgetService().getBudget(_accountName);
    final transactions = TransactionService()
        .getTransactions(_accountName)
        .where(
          (t) =>
              t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day &&
              t.type == TransactionType.expense,
        )
        .toList();

    double foodExp = 0;
    double fixedExp = 0;
    for (final t in transactions) {
      if (t.mainCategory == '식비' || t.mainCategory == '식재료') {
        foodExp += t.amount;
      } else {
        fixedExp += t.amount;
      }
    }

    if (mounted) {
      setState(() {
        _todayBudget = budget > 0 ? budget : 30000;
        _todaySpent = transactions.fold(0.0, (sum, t) => sum + t.amount);
        _foodExpense = foodExp;
        _fixedCost = fixedExp;
      });
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      _showMessage('음성 인식을 사용할 수 없습니다');
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _isListening = true;
      _currentText = '';
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _currentText = result.recognizedWords;
          if (result.finalResult) {
            _lastRecognizedText = result.recognizedWords;
          }
        });
      },
      localeId: 'ko_KR',
      listenOptions: stt.SpeechListenOptions(),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _processVoiceCommand(String command) async {
    if (command.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _lastRecognizedText = command;
    });

    try {
      final result = await _parseAndExecuteCommand(command);

      _feedbackController.forward(from: 0);

      setState(() {
        _recentResults.insert(0, result);
        if (_recentResults.length > 5) {
          _recentResults.removeLast();
        }
        _isProcessing = false;
      });

      // 성공 시 데이터 새로고침
      if (result.success) {
        await _loadBudgetData();
        HapticFeedback.lightImpact();
      }

      // 음성 피드백 (TTS는 별도 구현 필요)
      _showMessage(result.message);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _recentResults.insert(
          0,
          VoiceCommandResult(
            command: command,
            success: false,
            message: '처리 중 오류가 발생했습니다',
            type: VoiceCommandType.unknown,
          ),
        );
      });
    } finally {
      // If we navigated to an overlay, it will resume listening itself.
      if (_autoListenEnabled && mounted && !_suspendAutoListen) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          if (_isListening) return;
          if (_isProcessing) return;
          if (_suspendAutoListen) return;
          _startListening();
        });
      }
    }
  }

  Future<VoiceCommandResult> _parseAndExecuteCommand(String command) async {
    final normalized = command.toLowerCase().trim();
    debugPrint('[Voice] 명령어: "$normalized"');

    // 0. 화면 열기/이동 같은 네비게이션 명령 (금액 없이도 동작)
    if (_isOpenIncomeInputCommand(normalized)) {
      debugPrint('[Voice] → 수입 입력 화면 열기');
      return await _handleOpenIncomeInput();
    }
    if (_isOpenExpenseInputCommand(normalized)) {
      debugPrint('[Voice] → 지출 입력 화면 열기');
      return await _handleOpenExpenseInput();
    }

    // 0-1. 지출 입력 + 금액 포함: 폼을 미리채움으로 열기(저장까지는 사용자가 확인)
    if (_isExpenseInputWithAmountCommand(normalized)) {
      debugPrint('[Voice] → 지출 입력 (금액 포함) 화면 열기');
      return await _handleOpenExpenseInputPrefilled(command);
    }

    // 레시피 추천/모 하지
    if (_isMenuRecommendCommand(normalized)) {
      debugPrint('[Voice] → 메뉴/할일 추천');
      return await _handleComplexMealQuery(command);
    }

    // 장바구니 추가 (가격 비교 안내 포함)
    if (_isShoppingCartAddCommand(normalized)) {
      debugPrint('[Voice] → 장바구니 추가');
      return await _handleShoppingCartAdd(command);
    }

    // 0-1.5. 재고/유통기한 리포트 (음성 응답)
    if (_isInventoryReportCommand(normalized)) {
      debugPrint('[Voice] → 재고/유통기한 리포트');
      return await _handleInventoryReport(command);
    }

    // NEW 1. 고정지출 브리핑
    if (_isFixedCostBriefingCommand(normalized)) {
      debugPrint('[Voice] → 고정지출 브리핑');
      return await _handleFixedCostBriefing(command);
    }

    // NEW 2. 지출 조언 (예산 코칭)
    if (_isSpendingAdviceCommand(normalized)) {
      debugPrint('[Voice] → 지출 조언/코칭');
      return await _handleSpendingAdvice(command);
    }

    // NEW 3. 폐기물 기록 (재고 삭제)
    if (_isWasteLogCommand(normalized)) {
      debugPrint('[Voice] → 폐기 기록');
      return await _handleWasteLog(command);
    }

    // NEW 4. 월말 정산/마감
    if (_isMonthlyClosingCommand(normalized)) {
      debugPrint('[Voice] → 월말 정산');
      return await _handleMonthlyClosing(command);
    }

    // NEW: 예외 처리 (방금 그거 예외로 해줘)
    if (_isExceptionMarkingCommand(normalized)) {
      debugPrint('[Voice] → 예외 처리 명령');
      return await _handleExceptionMarking(command);
    }

    // 0-2. 화면 네비게이션 명령어 (가계부, 대시보드, 자산 등)
    if (_isNavigationCommand(normalized)) {
      debugPrint('[Voice] → 네비게이션 명령');
      return await _handleNavigationCommand(normalized);
    }

    // 1. 지출 기록 명령
    if (_isExpenseCommand(normalized)) {
      debugPrint('[Voice] → 지출 기록 명령');
      return await _handleExpenseCommand(command);
    }

    // 2. 재료 조회 명령
    if (_isIngredientQueryCommand(normalized)) {
      debugPrint('[Voice] → 재료 조회');
      return _handleIngredientQuery(command);
    }

    // 3. 예산 조회 명령
    if (_isBudgetQueryCommand(normalized)) {
      debugPrint('[Voice] → 예산 조회');
      return _handleBudgetQuery();
    }

    // 4. 메뉴 추천 명령
    if (_isMenuRecommendCommand(normalized)) {
      debugPrint('[Voice] → 메뉴 추천');
      return _handleMenuRecommend();
    }

    // 5. 장바구니 추가 명령
    if (_isShoppingCartCommand(normalized)) {
      debugPrint('[Voice] → 장바구니');
      return _handleShoppingCartAdd(command);
    }

    // 6. 오늘 지출 요약
    if (_isTodaySummaryCommand(normalized)) {
      debugPrint('[Voice] → 오늘 요약');
      return _handleTodaySummary();
    }

    debugPrint('[Voice] → 인식 실패');
    return VoiceCommandResult(
      command: command,
      success: false,
      message: '이해하지 못했어요. 다시 말씀해 주세요.',
      type: VoiceCommandType.unknown,
    );
  }

  /// 4. 월말 정산/마감 핸들러
  Future<VoiceCommandResult> _handleMonthlyClosing(String command) async {
    // 1. Data Load
    await _loadBudgetData(); // Refreshes _todayBudget (monthly budget stored here usually?), wait. _loadBudgetData calcs *Daily*?
    // Let's re-fetch explicitly for Month context to be sure.

    final budget = BudgetService().getBudget(_accountName);
    if (budget <= 0) {
      return VoiceCommandResult(
        command: command,
        success: false,
        message: '설정된 예산이 없습니다. 예산을 먼저 설정해주세요.',
        type: VoiceCommandType.query,
      );
    }

    final now = DateTime.now();
    final history = TransactionService().getTransactions(_accountName);
    final monthSpent = history.fold(0.0, (sum, t) {
      if (t.type == TransactionType.expense &&
          t.date.year == now.year &&
          t.date.month == now.month) {
        return sum + t.amount;
      }
      return sum;
    });

    final remaining = budget - monthSpent;
    final sb = StringBuffer();

    // 2. Logic & Message
    if (remaining < 0) {
      // Over budget
      final over = remaining.abs();
      sb.write('이번 달은 설정한 예산보다 많이 사용하셨네요. 😥\n');
      sb.write(
        '총 ${CurrencyFormatter.format(over)} 초과되었습니다. 다음 달엔 조금 더 아껴볼까요?',
      );
    } else {
      // Under budget
      sb.write(
        '축하해요! 이번 달 예산이 ${CurrencyFormatter.format(remaining)} 남았습니다. 🎉\n\n',
      );
      sb.write('💡 남은 돈은 이렇게 할 수 있어요:\n');
      sb.write('1. 이월하기 (다음 달 지출 예산에 마음속으로 합산)\n');
      sb.write('2. 비상금이나 자산(현금)으로 보내기');
    }

    return VoiceCommandResult(
      command: command,
      success: true,
      message: sb.toString(),
      type: VoiceCommandType.query, // Analysis
    );
  }

  // ============ 명령어 감지 ============

  bool _isMonthlyClosingCommand(String cmd) {
    return (cmd.contains('월말') ||
            cmd.contains('이번 달') ||
            cmd.contains('이번달')) &&
        (cmd.contains('정산') ||
            cmd.contains('마감') ||
            cmd.contains('결산') ||
            cmd.contains('어때') ||
            cmd.contains('남았'));
  }

  bool _containsAmountHint(String cmd) {
    return RegExp(r'\d').hasMatch(cmd) ||
        cmd.contains('원') ||
        cmd.contains('만') ||
        cmd.contains('천') ||
        cmd.contains('백') ||
        cmd.contains('십');
  }

  bool _isExpenseCommand(String cmd) {
    // NOTE: Saving money by voice is sensitive.
    // Only treat as a "save" intent when the user explicitly says a save-like verb.
    final hasSaveVerb =
        cmd.contains('기록') ||
        cmd.contains('저장') ||
        cmd.contains('추가') ||
        cmd.contains('썼어') ||
        cmd.contains('썼다') ||
        cmd.contains('샀어') ||
        cmd.contains('샀다') ||
        cmd.contains('결제') ||
        cmd.contains('지불') ||
        cmd.contains('지출') ||
        cmd.contains('적립') ||
        cmd.contains('받았'); // 포인트 적립, 용돈 받았어 등

    if (!hasSaveVerb) return false;
    if (!_containsAmountHint(cmd)) return false;

    // Allow both explicit "지출" commands and natural spending phrases.
    return true;
  }

  bool _isExpenseInputWithAmountCommand(String cmd) {
    if (!cmd.contains('지출')) return false;
    final hasInput = cmd.contains('입력') || cmd.contains('입력창');
    return hasInput && _containsAmountHint(cmd);
  }

  bool _isOpenExpenseInputCommand(String cmd) {
    final hasExpense = cmd.contains('지출');
    if (!hasExpense) return false;

    final hasInput = cmd.contains('입력') || cmd.contains('입력창');
    final hasOpen =
        cmd.contains('열어') ||
        cmd.contains('열러') ||
        cmd.contains('켜') ||
        cmd.contains('띄워');
    final hasMove =
        cmd.contains('가') || cmd.contains('이동') || cmd.contains('진입');
    final hasRecord =
        cmd.contains('기록') || cmd.contains('저장') || cmd.contains('추가');

    // e.g. "지출 입력 열어줘", "지출입력 열어", "지출 입력으로 이동"
    // Also: "지출 기록해", "지출 입력해", "지출 추가" (금액 없이 화면 열기)
    if ((hasInput && (hasOpen || hasMove)) || cmd.contains('지출입력')) {
      return true;
    }
    // "지출 기록해", "지출 저장", "지출 추가" (금액 없이) -> 화면 열기
    if (hasRecord && !_containsAmountHint(cmd)) {
      return true;
    }
    return false;
  }

  bool _isOpenIncomeInputCommand(String cmd) {
    final hasIncome = cmd.contains('수입') || cmd.contains('월급');
    if (!hasIncome) return false;

    final hasInput = cmd.contains('입력') || cmd.contains('입력창');
    final hasOpen =
        cmd.contains('열어') ||
        cmd.contains('열러') ||
        cmd.contains('켜') ||
        cmd.contains('띄워');
    final hasMove =
        cmd.contains('가') || cmd.contains('이동') || cmd.contains('진입');
    final hasRecord =
        cmd.contains('기록') || cmd.contains('저장') || cmd.contains('추가');

    // e.g. "수입 입력 열어줘", "수입입력", "수입 기록해", "월급 기록"
    if ((hasInput && (hasOpen || hasMove)) || cmd.contains('수입입력')) {
      return true;
    }
    // "수입 기록해", "월급 기록" (금액 없이) -> 화면 열기
    if (hasRecord && !_containsAmountHint(cmd)) {
      return true;
    }
    return false;
  }

  bool _isIngredientQueryCommand(String cmd) {
    return cmd.contains('남은') ||
        cmd.contains('얼마나') ||
        cmd.contains('있어') && (cmd.contains('재료') || cmd.contains('식재료'));
  }

  bool _isBudgetQueryCommand(String cmd) {
    return cmd.contains('예산') ||
        cmd.contains('얼마 남았') ||
        cmd.contains('남은 돈') ||
        cmd.contains('오늘 예산');
  }

  bool _isMenuRecommendCommand(String cmd) {
    if (cmd.contains('뭐 먹') ||
        cmd.contains('메뉴 추천') ||
        cmd.contains('뭐 해먹') ||
        cmd.contains('요리 추천') ||
        cmd.contains('레시피 추천') ||
        cmd.contains('뭐해먹') ||
        cmd.contains('뭐하지')) {
      return true;
    }

    if ((cmd.contains('아침') || cmd.contains('점심') || cmd.contains('저녁')) &&
        (cmd.contains('뭐') || cmd.contains('추천'))) {
      return true;
    }
    return false;
  }

  bool _isShoppingCartCommand(String cmd) {
    // 단순 조회/이동은 Navigation에서 처리하고, 여기서는 추가 Intent 분리
    return _isShoppingCartAddCommand(cmd);
  }

  bool _isShoppingCartAddCommand(String cmd) {
    return (cmd.contains('장바구니') || cmd.contains('쇼핑') || cmd.contains('사야')) &&
        (cmd.contains('추가') ||
            cmd.contains('담아') ||
            cmd.contains('넣어') ||
            cmd.contains('기록') ||
            cmd.contains('해줘'));
  }

  bool _isTodaySummaryCommand(String cmd) {
    return cmd.contains('오늘') &&
        (cmd.contains('얼마') || cmd.contains('지출') || cmd.contains('요약'));
  }

  /// 화면 네비게이션 명령어 감지
  bool _isNavigationCommand(String cmd) {
    if (cmd.contains('가계부') || cmd.contains('대시보드') || cmd.contains('홈')) {
      return true;
    }
    if (cmd.contains('자산') || cmd.contains('통장')) {
      return true;
    }
    final isStatus =
        cmd.contains('현황') || cmd.contains('통계') || cmd.contains('내역');
    if (cmd.contains('지출') && isStatus) {
      return true;
    }
    // 식재료/냉장고/유통기한 (화면 이동)
    final isFood = cmd.contains('냉장고') || cmd.contains('식재료');
    final isOpen =
        cmd.contains('열어') || cmd.contains('가줘') || cmd.contains('보여줘');

    if (isFood && isOpen) {
      return true;
    }
    if (cmd.contains('유통기한') && (cmd.contains('관리') || cmd.contains('화면'))) {
      return true;
    }
    if (cmd.contains('저축') || cmd.contains('적금')) {
      return true;
    }
    if (cmd.contains('달력') || cmd.contains('캘린더')) {
      return true;
    }
    if (cmd.contains('장바구니') || cmd.contains('쇼핑리스트')) {
      return true;
    }
    if (cmd.contains('생필품') || cmd.contains('소모품')) {
      return true;
    }
    if (cmd.contains('설정') || cmd.contains('세팅')) {
      return true;
    }
    // 페이지 이동 (숫자/이름 + 가줘/이동)
    if (_containsPageNavigation(cmd)) {
      return true;
    }
    return false;
  }

  bool _containsPageNavigation(String cmd) {
    if (cmd.contains('페이지')) {
      return cmd.contains('가줘') ||
          cmd.contains('이동') ||
          cmd.contains('보여줘') ||
          cmd.contains('열어');
    }
    return false;
  }

  bool _isInventoryReportCommand(String cmd) {
    // "재고 알려줘", "남은 재료", "유통기한 알려줘" 등
    final isQuery =
        cmd.contains('재고') ||
        cmd.contains('남은') ||
        cmd.contains('유통기한') ||
        cmd.contains('부족한');
    final isAction =
        cmd.contains('알려줘') ||
        cmd.contains('뭐야') ||
        cmd.contains('확인') ||
        cmd.contains('체크') ||
        cmd.contains('조회');
    return isQuery && isAction;
  }

  // --- NEW COMMAND DETECTORS ---
  bool _isFixedCostBriefingCommand(String cmd) {
    final isFixed =
        (cmd.contains('고정') && (cmd.contains('지출') || cmd.contains('비용'))) ||
        cmd.contains('공과금');
    final isDue =
        (cmd.contains('낼 거') || cmd.contains('낼거')) && cmd.contains('남았');
    return isFixed || isDue;
  }

  bool _isSpendingAdviceCommand(String cmd) {
    final isBuying =
        cmd.contains('사도') ||
        cmd.contains('써도') ||
        cmd.contains('지러도') ||
        cmd.contains('질러도') ||
        cmd.contains('살까');
    final isAsking =
        cmd.contains('돼') ||
        cmd.contains('되') ||
        cmd.contains('될까') ||
        cmd.contains('까요');
    return isBuying && isAsking;
  }

  bool _isExceptionMarkingCommand(String cmd) {
    return cmd.contains('예외') &&
        (cmd.contains('해줘') || cmd.contains('처리') || cmd.contains('등록'));
  }

  bool _isWasteLogCommand(String cmd) {
    return cmd.contains('버렸') ||
        cmd.contains('상해서') ||
        cmd.contains('상했') ||
        cmd.contains('폐기');
  }

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

  String _extractExpenseDescription(String command) {
    var text = command;
    // Remove common amount expressions
    text = text.replaceAll(RegExp(r'\d[\d,]*\s*원'), '');
    text = text.replaceAll(RegExp(r'(\d+)\s*(만|천|백|십)'), '');
    // Remove common intent words
    text = text
        .replaceAll('지출', '')
        .replaceAll('기록', '')
        .replaceAll('저장', '')
        .replaceAll('추가', '')
        .replaceAll('입력', '')
        .replaceAll('열어', '')
        .replaceAll('열러', '')
        .replaceAll('켜', '')
        .replaceAll('띄워', '')
        .trim();
    if (text.isEmpty) return '음성 입력';
    return text;
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

  Future<VoiceCommandResult> _handleExpenseCommand(String command) async {
    final extractedAmount = _extractKrwAmount(command);
    // Amount can be modified by bonus logic, so we use a var
    var amount = extractedAmount ?? 0.0; // Default to 0 for logic if null

    debugPrint('[Voice] 금액 추출: $amount from "$command"');
    if (extractedAmount == null) {
      // Special case: "무지출" command usually has no amount.
      if (!command.contains('무지출')) {
        return VoiceCommandResult(
          command: command,
          success: false,
          message: '금액을 인식하지 못했어요. "지출 5천원 커피 입력"처럼 말해주세요.',
          type: VoiceCommandType.expense,
        );
      }
      // If 무지출, let amount be 0 (or bonus points will be added later)
    }

    if (amount < 0) {
      // Allow 0 for non-spending record start
      return VoiceCommandResult(
        command: command,
        success: false,
        message: '유효하지 않은 금액입니다.',
        type: VoiceCommandType.expense,
      );
    }

    final description = _extractExpenseDescription(command);

    // [1억 프로젝트] 포인트 적립 감지
    final isPointAccumulation =
        description.contains('포인트') ||
        command.contains('적립') ||
        description.contains('무지출');
    TransactionType type = TransactionType.expense; // 기본값
    String customFeedback = '';

    // 카테고리 자동 유추 (학습 -> 사전 -> 미분류)
    var (mainCategory, subCategory) = _inferCategory(description);

    if (isPointAccumulation) {
      type = TransactionType.income; // 포인트 적립은 수입으로 처리
      mainCategory = '기타수입'; // 혹은 '포인트'
      subCategory = '포인트적립';

      // 누적 횟수 및 총액 체크 (1억 프로젝트)
      final history = TransactionService().getTransactions(_accountName);
      final prevPoints = history.where(
        (t) =>
            (t.description.contains('포인트') ||
                (t.subCategory ?? '').contains('포인트')) &&
            t.type == TransactionType.income, // 수입인 것만
      );

      // [New Logic: Safety Net & Payback]
      double bonusPoints = 0;
      final now = DateTime.now();

      // 1. Golden Time Bonus (Same day exceptional expense)
      final todayExpenses = history.where((t) {
        if (t.type != TransactionType.expense) return false;
        if (t.date.year != now.year ||
            t.date.month != now.month ||
            t.date.day != now.day) {
          return false;
        }

        final desc = t.description;
        // Check for exceptions
        final isException =
            desc.contains('병원') ||
            desc.contains('약국') ||
            desc.contains('치료') ||
            desc.contains('축의금') ||
            desc.contains('조의금') ||
            desc.contains('수리') ||
            desc.contains('과태료');
        return isException;
      }).toList();

      if (todayExpenses.isNotEmpty && description.contains('무지출')) {
        bonusPoints += 500; // Bonus for saving after shock
        customFeedback +=
            '\n\n🛡️ 갑작스러운 지출에 놀라셨죠? 그래도 다른 소비를 잘 참아내셨네요! '
            '대견함의 의미로 보너스 포인트를 드립니다.';
      }

      // 2. Payback (Recovery Points within 3 days)
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      final recentShock = history.where((t) {
        if (t.type != TransactionType.expense) return false;
        if (t.date.isBefore(threeDaysAgo)) return false;

        final desc = t.description;
        final isException =
            desc.contains('병원') ||
            desc.contains('약국') ||
            desc.contains('치료') ||
            desc.contains('축의금') ||
            desc.contains('조의금') ||
            desc.contains('수리') ||
            desc.contains('과태료');
        return isException;
      }).toList();

      if (recentShock.isNotEmpty && description.contains('무지출')) {
        bonusPoints += 300;
        customFeedback +=
            '\n\n🔄 지난번 갑작스러운 지출 이후 바로 허리띠를 졸라매셨군요! 회복 탄력성이 대단하십니다. '
            '"회복 포인트" 적립해 드려요!';
      }

      // Apply Bonus
      amount += bonusPoints;

      final pointCount = prevPoints.length;
      final prevTotal = prevPoints.fold(0.0, (sum, t) => sum + t.amount);
      final currentTotal = prevTotal + amount;

      // [1억 프로젝트] 진행률 계산
      final double progressPercent = (currentTotal / 100000000.0) * 100;
      // 0.0001% 단위까지 표시 (작은 금액도 소중하니까요)
      final String progressStr = progressPercent.toStringAsFixed(4);

      // 마일스톤 돌파 체크
      // 10만, 7만, 5만, 3만, 1만 순으로 체크 (높은 금액 우선)
      if (prevTotal < 100000 && currentTotal >= 100000) {
        customFeedback =
            '\n🎉 대단해요! 드디어 10만원을 모으셨습니다!\n'
            '🏦 이제 예금 상품으로 돈을 불릴 차례예요. 1억 프로젝트의 첫 단계 달성을 축하드립니다!';
      } else if (prevTotal < 70000 && currentTotal >= 70000) {
        customFeedback = '\n🔥 7만원 돌파! 이제 고지가 눈앞입니다. 조금만 더 힘내세요!';
      } else if (prevTotal < 50000 && currentTotal >= 50000) {
        customFeedback = '\n✨ 벌써 절반인 5만원을 모으셨네요! 시작이 반이라더니, 정말 대단합니다. 👏';
      } else if (prevTotal < 30000 && currentTotal >= 30000) {
        customFeedback = '\n🍗 3만원 달성! 치킨 한 마리 값은 벌었네요! 하지만 우린 1억을 향해 계속 갑니다!';
      } else if (prevTotal < 10000 && currentTotal >= 10000) {
        customFeedback = '\n☕ 와! 첫 1만원을 돌파했습니다! 작은 돈도 모이면 이렇게 커집니다. 계속 가볼까요?';
      } else if (pointCount == 0) {
        // 첫 적립
        customFeedback = '\n🎉 첫 포인트 적립이네요! 포인트를 모아보세요. "1억 프로젝트"를 시작할 수 있습니다.';
      } else {
        // n회 적립 (일반)
        customFeedback =
            '\n👍 ${pointCount + 1}번째 포인트 적립! 현재까지 총 ${CurrencyFormatter.format(currentTotal)} '
            '모으셨어요.';
      }

      // 진행률 정보 추가 (모든 케이스에 적용)
      customFeedback += '\n\n📈 현재 1억 중 $progressStr% 달성하셨습니다.';
    }

    // 사용자 피드백을 위한 메시지 구성
    String feedbackMsg =
        '🏪 $description ${CurrencyFormatter.format(amount)} 저장 완료!';
    if (customFeedback.isNotEmpty) {
      feedbackMsg += customFeedback;
    } else if (mainCategory != '미분류') {
      feedbackMsg += '\n분류: $mainCategory';
      if (subCategory != null && subCategory.isNotEmpty) {
        feedbackMsg += ' > $subCategory';
      }
    } else {
      feedbackMsg += '\n(카테고리를 찾지 못해 "미분류"로 저장했습니다)';
    }

    if (type == TransactionType.income && isPointAccumulation) {
      // 포인트 적립 성공 메시지를 덮어씁니다 (스크립트 요구사항 반)
      feedbackMsg =
          '저장 완료했습니다. 첫 포인트가 적립되었네요! 이제 1억 프로젝트의 첫발을 떼셨습니다. 이 기세로 쭉 가보시죠!\n'
          '\n(텍스트) 🏪 $description ${CurrencyFormatter.format(amount)} 저장 완료!';
    }

    // 거래 생성 및 저장
    final transaction = Transaction(
      id: 'voice_${DateTime.now().millisecondsSinceEpoch}',
      type: type, // 수정된 타입 적용
      amount: amount, // (참고: 경조사/의료비 등은 나중에 '예외 지출' 처리 로직 추가 고려)
      date: DateTime.now(),
      description: description,
      mainCategory: mainCategory,
      subCategory: subCategory,
    );

    // [음성 비서 잔소리 & 칭찬 & 위로 로직]
    if (type == TransactionType.expense) {
      bool isSpecialCase = false;

      // 1. 의료비/병원비 (건강 우선)
      if (description.contains('병원') ||
          description.contains('약국') ||
          description.contains('치료') ||
          description.contains('진료') ||
          description.contains('비타민') ||
          (mainCategory.contains('건강') || mainCategory.contains('의료'))) {
        isSpecialCase = true;
        const hospitalMsgPart1 =
            '\n\n💊 아이구, 어디 많이 아프신 건 아니죠? 건강을 잃으면 1억 프로젝트도 소용없어요.';
        const hospitalMsgPart2 = '약 잘 챙겨 드시고 오늘은 푹 쉬세요.';
        const hospitalMsgPart3 = '병원비 내역은 제가 알아서 잘 정리해둘게요. (포인트 연속 보호됨)';
        const hospitalMsg =
            '$hospitalMsgPart1\n$hospitalMsgPart2\n$hospitalMsgPart3';
        customFeedback += hospitalMsg;
      }
      // 2. 경조사비 (사람 우선)
      else if (description.contains('축의금') ||
          description.contains('조의금') ||
          description.contains('부조금') ||
          description.contains('결혼') ||
          description.contains('장례') ||
          description.contains('화환') ||
          (mainCategory.contains('경조사'))) {
        isSpecialCase = true;
        customFeedback +=
            '\n\n🤝 기쁜 소식이네요! 이런 소중한 지출은 1억 프로젝트 포인트 차감 대상에서 제외됩니다. '
            '인맥이라는 더 큰 자산을 쌓으셨으니까요! (포인트 차감 면제)';
      }
      // 3. 자기계발 (미래 투자)
      else if (description.contains('도서') ||
          description.contains('책') ||
          description.contains('강의') ||
          description.contains('수강') ||
          description.contains('학원') ||
          description.contains('공부')) {
        isSpecialCase = true;
        customFeedback +=
            '\n\n📚 미래를 위한 투자는 언제나 옳습니다! 1억 프로젝트의 핵심은 결국 "나 자신"의 가치를 높이는 거니까요. '
            '응원합니다!';
      }
      // 4. 공과금/세금 (필수 지출)
      else if (description.contains('공과금') ||
          description.contains('세금') ||
          description.contains('수도') ||
          description.contains('전기') ||
          description.contains('가스') ||
          description.contains('관리비')) {
        isSpecialCase = true;
        customFeedback +=
            '\n\n💡 숨만 쉬어도 나가는 돈이지만, 연체 없이 깔끔하게 처리하셨네요! 신용 점수도 자산입니다.';
      }
      // 5. 예기치 못한 수리/과태료 (위로)
      else if (description.contains('수리') ||
          description.contains('과태료') ||
          description.contains('벌금') ||
          description.contains('사고')) {
        isSpecialCase = true;
        customFeedback +=
            '\n\n🛠 악! 정말 속상하시겠어요. 예상치 못한 복병이 나타났네요. 하지만 액땜했다고 생각해요! '
            '제가 다음 달 예산 계획을 더 꼼꼼하게 짜서 1억 프로젝트에 차질 없게 도와드릴게요. (연속 보호됨)';
      }

      // 일반적인 잔소리 로직 (특수 상황이 아닐 때만 발동)
      if (!isSpecialCase) {
        if (mainCategory == '식비' || mainCategory == '외식') {
          final foodItems = FoodExpiryService.instance.items.value;
          final now = DateTime.now();
          final expiringFood = foodItems.where((i) {
            final days = i.expiryDate.difference(now).inDays;
            return days >= 0 && days <= 3;
          }).toList();

          if (expiringFood.isNotEmpty) {
            final msgs = [
              '냉장고 속 우유가 자기 버려달라고 울고 있어요. 외식 말고 집밥으로 우유를 구출해 주세요!',
              '냉장고에 재료가 가득한데 외식이라니요? 이건 냉장고에 대한 예의가 아니라고 생각합니다.',
            ];
            customFeedback += '\n\n😈 ${msgs[Random().nextInt(msgs.length)]}';
          }
        }

        await _loadBudgetData(); // Refresh budget info
        final budget = BudgetService().getBudget(_accountName);
        if (budget > 0) {
          final history = TransactionService().getTransactions(_accountName);
          final now = DateTime.now();
          final thisMonthSpent = history.fold(0.0, (sum, t) {
            if (t.type == TransactionType.expense &&
                t.date.year == now.year &&
                t.date.month == now.month) {
              return sum + t.amount;
            }
            return sum;
          });

          // 이번 거래 포함
          final totalSpent = thisMonthSpent + amount;
          final remaining = budget - totalSpent;

          if (remaining < 0) {
            final msgs = [
              '비상! 현재 예산이 멸종 위기입니다. 이제부터는 숨만 쉬어도 예산 초과예요.',
              '주인님, 우리 당분간은 편의점 앞도 지나가지 말기로 약속해요. 눈 감고 지나가세요!',
              '1억 프로젝트가 지금 잠시 멈춤 상태입니다. 다시 엔진을 돌리려면 "무지출"이라는 기름이 필요해요.',
            ];
            customFeedback += '\n\n🚨 ${msgs[Random().nextInt(msgs.length)]}';
          } else if (remaining < budget * 0.2) {
            // 20% 미만 남았을 때 (Warning Phase)
            final msgs = [
              '주인님, 지금 지갑에 구멍 난 것 같아요! 1억 프로젝트가 1억 년 뒤로 밀리고 있습니다.',
              "방금 지출로 이번 달 '치킨권'이 소멸되었습니다. 오늘 저녁은 냉장고 파먹기 어떠세요?",
              '자산 그래프가 다이어트 중인가 봐요. 주인님 지갑은 홀쭉해지고 제 마음은 무거워지네요.',
            ];
            customFeedback += '\n\n⚠️ ${msgs[Random().nextInt(msgs.length)]}';
          } else {
            // Budget is fine, but check impulse buying suspicion (High amount, non-fixed)
            final isFixedCost =
                mainCategory.contains('고정') ||
                mainCategory.contains('월세') ||
                mainCategory.contains('공과금');
            if (!isFixedCost && amount >= 30000) {
              final msgs = [
                '이 물건, 정말 1억 프로젝트보다 중요한가요? 제 인공지능 회로로는 이해가 잘 안 되네요!',
                '지름신이 강림하셨군요. 하지만 그 신은 잔액을 책임져주지 않는다는 사실, 잊지 마세요.',
                "지금 지르시면 '오늘의 행복'은 얻겠지만, '내일의 통장'은 눈물을 흘릴 거예요.",
              ];
              customFeedback += '\n\n🤔 ${msgs[Random().nextInt(msgs.length)]}';
            }
          }
        }
      }
    } else if (type == TransactionType.income && isPointAccumulation) {
      // 칭찬 강화 (무지출 등 긍정적 상황 가정)
      if (description.contains('무지출')) {
        customFeedback +=
            '\n\n🎉 와! 오늘 지갑을 한 번도 안 여셨네요? 1억 프로젝트에 한 걸음 더 가까워졌습니다. 포인트 쏴드릴게요!';
      }
    }

    await TransactionService().addTransaction(_accountName, transaction);

    return VoiceCommandResult(
      command: command,
      success: true,
      message: feedbackMsg,
      type: VoiceCommandType.expense,
      data: {
        'amount': amount,
        'description': description,
        'category': mainCategory,
        'subCategory': subCategory,
      },
    );
  }

  Future<VoiceCommandResult> _handleInventoryReport(String command) async {
    // 1. Food Expiry Check
    final foodItems = FoodExpiryService.instance.items.value;
    final now = DateTime.now();
    final expiringFood = foodItems.where((i) {
      final days = i.expiryDate.difference(now).inDays;
      return days >= 0 && days <= 3;
    }).toList();

    // 2. Consumable Inventory Check
    final consumableItems = ConsumableInventoryService.instance.items.value;
    final lowStockItems = consumableItems
        .where((i) => i.currentStock <= i.threshold)
        .toList();

    // Build Message
    final sb = StringBuffer();
    bool hasIssue = false;

    if (expiringFood.isEmpty && lowStockItems.isEmpty) {
      return VoiceCommandResult(
        command: command,
        success: true,
        message:
            '유통기한 임박 식재료나 부족한 생필품이 없습니다.\n\n💡 사용내역을 입력하시면 외출해서도 냉장고 안을 볼 수 있습니다.',
        type: VoiceCommandType.query,
      );
    }

    if (expiringFood.isNotEmpty) {
      hasIssue = true;
      sb.write('유통기한 임박 재료가 ${expiringFood.length}개 있습니다. ');
      if (expiringFood.length <= 3) {
        final names = expiringFood.map((e) => e.name).join(', ');
        sb.write('($names) ');
      }
    }

    if (lowStockItems.isNotEmpty) {
      if (hasIssue) sb.write('\n');
      sb.write('부족한 생필품이 ${lowStockItems.length}개 있습니다. ');
      if (lowStockItems.length <= 3) {
        final names = lowStockItems.map((e) => e.name).join(', ');
        sb.write('($names)');
      }
    }

    // 팁 추가 (사용자 안내)
    // 매번 말하면 귀찮을 수 있으니 30% 확률 또는 특정 조건에서 추가하는 것이 좋으나
    // 요청사항 준수를 위해 메시지 끝에 추가합니다.
    sb.write('\n\n💡 사용내역을 입력하시면 외출해서도 냉장고 안을 볼 수 있습니다.');

    return VoiceCommandResult(
      command: command,
      success: true,
      message: sb.toString().trim(),
      type: VoiceCommandType.query,
    );
  }

  /// 화면 네비게이션 명령 처리
  Future<VoiceCommandResult> _handleNavigationCommand(String cmd) async {
    String? route;
    String screenName = '';
    int? mainPageIndex;

    // --- MAIN SCREEN PAGE NAVIGATION (Index Mapping) ---
    // 0: 대시보드 (1페이지)
    // 1: 요리/쇼핑/지출 (2페이지)
    // 2: 수입 (3페이지)
    // 3: 통계 (4페이지)
    // 4: 자산 (5페이지)
    // 5: ROOT (6페이지)
    // 6: 설정 (7페이지)

    if (cmd.contains('1페이지') ||
        (cmd.contains('대시보드') && (cmd.contains('가줘') || cmd.contains('이동')))) {
      mainPageIndex = 0;
      screenName = '대시보드';
    } else if (cmd.contains('2페이지') ||
        cmd.contains('요리') ||
        cmd.contains('쇼핑') ||
        cmd.contains('지출')) {
      // "지출 통계" vs "지출(탭)" 구분 필요.
      // 만약 "지출"만 있고 "통계/현황/내역" 없으면 이동.
      if (!(cmd.contains('통계') || cmd.contains('현황') || cmd.contains('내역'))) {
        mainPageIndex = 1;
        screenName = '요리/쇼핑/지출';
      }
    } else if (cmd.contains('3페이지') || cmd.contains('수입')) {
      if (!(cmd.contains('입력') || cmd.contains('추가'))) {
        mainPageIndex = 2;
        screenName = '수입';
      }
    } else if (cmd.contains('4페이지') ||
        (cmd.contains('통계') && !cmd.contains('지출'))) {
      mainPageIndex = 3;
      screenName = '통계';
    } else if (cmd.contains('5페이지') ||
        cmd.contains('자산') ||
        cmd.contains('통장')) {
      mainPageIndex = 4;
      screenName = '자산';
    } else if (cmd.contains('6페이지') ||
        cmd.contains('루트') ||
        cmd.contains('관리자')) {
      mainPageIndex = 5;
      screenName = 'ROOT 관리';
    } else if (cmd.contains('7페이지') ||
        cmd.contains('설정') ||
        cmd.contains('세팅')) {
      mainPageIndex = 6;
      screenName = '설정';
    }

    if (mainPageIndex != null) {
      _suspendAutoListen = true;
      if (_isListening) await _stopListening();
      if (!mounted) return _buildClosedResult(cmd);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AccountMainScreen(
            accountName: _accountName,
            initialIndex: mainPageIndex!,
          ),
        ),
      );
      _suspendAutoListen = false;
      return VoiceCommandResult(
        command: cmd,
        success: true,
        message: '$screenName(으)로 이동합니다.',
        type: VoiceCommandType.navigation,
      );
    }

    // --- OTHER ROUTES ---
    // 가계부/대시보드/홈
    if (cmd.contains('가계부') || cmd.contains('대시보드') || cmd.contains('홈')) {
      route = '/';
      screenName = '메인 대시보드';
    }
    // 자산 현황
    else if (cmd.contains('자산') || cmd.contains('통장')) {
      route = '/asset/dashboard';
      screenName = '자산 대시보드';
    }
    // 지출 현황/통계
    else if (cmd.contains('지출') &&
        (cmd.contains('현황') || cmd.contains('통계') || cmd.contains('내역'))) {
      route = '/stats/spending-analysis';
      screenName = '지출 통계';
    }
    // 유통기한/냉장고/재료
    else if (cmd.contains('유통기한') ||
        cmd.contains('냉장고') ||
        cmd.contains('재료') ||
        cmd.contains('식재료')) {
      route = '/food/expiry';
      screenName = '식재료 관리';
    }
    // 저축/적금
    else if (cmd.contains('저축') || cmd.contains('적금')) {
      route = '/nudges/micro-savings';
      screenName = '저축 관리';
    }
    // 달력/캘린더
    else if (cmd.contains('달력') || cmd.contains('캘린더')) {
      route = '/calendar';
      screenName = '달력';
    }
    // 장바구니
    else if (cmd.contains('장바구니') || cmd.contains('쇼핑')) {
      route = '/shopping/cart';
      screenName = '장바구니';
    }
    // 생필품/소모품
    else if (cmd.contains('생필품') || cmd.contains('소모품')) {
      if (cmd.contains('입력') || cmd.contains('추가')) {
        route = '/household/consumables';
        screenName = '생필품 입력';
      } else {
        route = '/household/inventory';
        screenName = '생필품 재고';
      }
    }
    // 설정
    else if (cmd.contains('설정')) {
      route = '/settings';
      screenName = '설정';
    }

    if (route == null) {
      return VoiceCommandResult(
        command: cmd,
        success: false,
        message: '이동할 화면을 찾지 못했어요.',
        type: VoiceCommandType.navigation,
      );
    }

    // 네비게이션 실행
    _suspendAutoListen = true;
    if (_isListening) {
      await _stopListening();
    }

    if (!mounted) {
      _suspendAutoListen = false;
      return VoiceCommandResult(
        command: cmd,
        success: false,
        message: '화면이 닫혀서 이동할 수 없습니다.',
        type: VoiceCommandType.navigation,
      );
    }

    Navigator.of(context).pushNamed(route);
    _suspendAutoListen = false;

    return VoiceCommandResult(
      command: cmd,
      success: true,
      message: '$screenName(으)로 이동합니다.',
      type: VoiceCommandType.navigation,
    );
  }

  /// 장바구니 추가 + 최저가 안내
  Future<VoiceCommandResult> _handleShoppingCartAdd(String command) async {
    // 1. 상품명 추출
    final itemName = command
        .replaceAll('장바구니', '')
        .replaceAll('쇼핑', '')
        .replaceAll('리스트', '')
        .replaceAll('목록', '')
        .replaceAll('추가', '')
        .replaceAll('담아', '')
        .replaceAll('넣어', '')
        .replaceAll('해줘', '')
        .replaceAll('에', '')
        .replaceAll('을', '')
        .replaceAll('를', '')
        .replaceAll('좀', '')
        .trim();

    if (itemName.isEmpty) {
      return VoiceCommandResult(
        command: command,
        success: false,
        message: '어떤 상품을 추가할까요? "우유 장바구니에 담아줘" 처럼 말해주세요.',
        type: VoiceCommandType.unknown,
      );
    }

    // 2-1. 중복 구매 방지 알림 (Inventory & Recent History Check)
    String warningMsg = '';

    // (1) 현재 냉장고/팬트리 재고 확인
    final inventory = FoodExpiryService.instance.items.value;
    final consumables = ConsumableInventoryService.instance.items.value;

    final inStock = inventory
        .where((i) => i.name.contains(itemName) || itemName.contains(i.name))
        .toList();
    final inConsumables = consumables
        .where((i) => i.name.contains(itemName) || itemName.contains(i.name))
        .toList();

    if (inStock.isNotEmpty) {
      final item = inStock.first;
      warningMsg =
          '⚠️ 냉장고에 이미 ${item.name} (${item.quantity}${item.unit}) 있습니다.';
    } else if (inConsumables.isNotEmpty) {
      final item = inConsumables.first;
      if (item.currentStock > item.threshold) {
        warningMsg = '⚠️ 집에 이미 ${item.name} 재고가 넉넉합니다.';
      }
    }

    // (2) 재고에 없으면 최근 구매 이력 확인 (혹시 샀는데 등록 안 했을 수 있음)
    if (warningMsg.isEmpty) {
      final history = TransactionService().getTransactions(_accountName);
      // 최근 7일 이내 구매 내역 확인
      final recentThreshold = DateTime.now().subtract(const Duration(days: 7));
      final recentPurchase = history.where((t) {
        if (t.type != TransactionType.expense) return false;
        if (t.date.isBefore(recentThreshold)) return false;
        return t.description.contains(itemName);
      }).toList();

      if (recentPurchase.isNotEmpty) {
        // 가장 최근 것
        recentPurchase.sort((a, b) => b.date.compareTo(a.date));
        final last = recentPurchase.first;
        final daysAgo = DateTime.now().difference(last.date).inDays;
        final timeStr = daysAgo == 0 ? '오늘' : '$daysAgo일 전';
        warningMsg =
            '⚠️ $timeStr에 "${last.description}" 구매 내역이 있어요. 냉장고를 확인해보세요.';
      }
    }

    // 2. 장바구니에 추가
    final currentItems = await UserPrefService.getShoppingCartItems(
      accountName: _accountName,
    );
    final isDuplicate = currentItems.any((i) => i.name == itemName);
    if (isDuplicate) {
      return VoiceCommandResult(
        command: command,
        success: false,
        message: '이미 장바구니에 "$itemName"이(가) 있습니다.',
        type: VoiceCommandType.unknown,
      );
    }

    // 새 아이템 생성
    final newItem = ShoppingCartItem(
      id: 'voice_${DateTime.now().millisecondsSinceEpoch}',
      name: itemName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final nextItems = [...currentItems, newItem];
    await UserPrefService.setShoppingCartItems(
      accountName: _accountName,
      items: nextItems,
    );

    // 3. 가격 비교 로직 (과거 이력 조회)
    String priceFeedback = '';
    try {
      final history = TransactionService().getTransactions(_accountName);
      final relevantParams = history.where((t) {
        if (t.type != TransactionType.expense) return false;
        // 정확도 향상을 위해 상품명이 포함된 거래만 필터링
        return t.description.contains(itemName);
      }).toList();

      if (relevantParams.isNotEmpty) {
        // 최근 3개월 데이터만 유효하다고 가정
        final recentThreshold = DateTime.now().subtract(
          const Duration(days: 90),
        );
        final recent = relevantParams
            .where((t) => t.date.isAfter(recentThreshold))
            .toList();

        if (recent.isNotEmpty) {
          // 상점별 최저가 찾기
          final Map<String, double> storeMinPrices = {};

          for (final t in recent) {
            // 상점명 추출 시도 (store 필드가 없으면 description에서 유추하거나 메모 등 활용)
            // 여기서는 description이나 store 필드를 가정. Transaction 모델에 store 필드가 있음.
            final storeName = t.store ?? '알수없음';
            if (storeName == '알수없음') {
              // description에서 유추하는 간단한 로직 (e.g. "이마트 우유" -> "이마트")
              // 혹은 나중에 StoreAliasService 등을 활용 가능
              // 임시로 description 앞부분 등을 사용할 수도 있음.
              // 여기서는 간단히 생략하거나, description 전체를 힌트로 삼긴 어려우므로 패스.
            }

            if (storeName != '알수없음' && t.amount > 0) {
              if (!storeMinPrices.containsKey(storeName) ||
                  t.amount < storeMinPrices[storeName]!) {
                storeMinPrices[storeName] = t.amount;
              }
            }
          }

          if (storeMinPrices.isNotEmpty) {
            // 전체 최저가 찾기
            final bestEntry = storeMinPrices.entries.reduce(
              (a, b) => a.value < b.value ? a : b,
            );
            final formattedPrice = CurrencyFormatter.format(bestEntry.value);
            priceFeedback =
                '최근 ${bestEntry.key}에서 $formattedPrice에 가장 저렴하게 구매하셨네요.';
          } else {
            // 상점명은 모르지만 가격 이력은 있는 경우
            // 가장 최근 가격 or 최저 가격 안내
            final minPrice = recent
                .map((t) => t.amount)
                .reduce((a, b) => a < b ? a : b);
            priceFeedback =
                '최근 최저가는 ${CurrencyFormatter.format(minPrice)}이었습니다.';
          }
        }
      }
    } catch (e) {
      debugPrint('Price check error: $e');
    }

    final sb = StringBuffer();
    sb.write('$itemName, 장바구니에 담았습니다.');

    if (warningMsg.isNotEmpty) {
      sb.write('\n$warningMsg'); // 중복 구매 경고 (최우선)
    } else if (priceFeedback.isNotEmpty) {
      sb.write('\n💡 $priceFeedback'); // 가격 정보 (이슈 없으면 표시)
    }

    return VoiceCommandResult(
      command: command,
      success: true,
      message: sb.toString(),
      type: VoiceCommandType.unknown, // Using generic type
    );
  }

  VoiceCommandResult _buildClosedResult(String cmd) {
    _suspendAutoListen = false;
    return VoiceCommandResult(
      command: cmd,
      success: false,
      message: '화면이 닫혀서 이동할 수 없습니다.',
      type: VoiceCommandType.navigation,
    );
  }

  Future<VoiceCommandResult> _handleOpenExpenseInput({
    Transaction? initialTransaction,
    bool treatAsNew = false,
    String? openedFromCommand,
  }) async {
    _suspendAutoListen = true;
    if (_isListening) {
      await _stopListening();
      if (!mounted) {
        _suspendAutoListen = false;
        return VoiceCommandResult(
          command: openedFromCommand ?? '지출 입력 열기',
          success: false,
          message: '화면이 닫혀서 실행할 수 없습니다.',
          type: VoiceCommandType.navigation,
        );
      }
    }
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height;
        return SizedBox(
          height: height * 0.95,
          child: TransactionAddScreen(
            accountName: _accountName,
            initialTransaction: initialTransaction,
            treatAsNew: treatAsNew,
            closeAfterSave: true,
          ),
        );
      },
    );

    _suspendAutoListen = false;
    if (_autoListenEnabled && mounted) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        if (_isListening) return;
        if (_isProcessing) return;
        if (_suspendAutoListen) return;
        _startListening();
      });
    }

    return VoiceCommandResult(
      command: openedFromCommand ?? '지출 입력 열기',
      success: true,
      message: initialTransaction == null
          ? '지출 입력을 열었습니다.'
          : '지출 입력을 열었습니다. (금액/메모 미리 채움)',
      type: VoiceCommandType.navigation,
    );
  }

  Future<VoiceCommandResult> _handleOpenExpenseInputPrefilled(
    String command,
  ) async {
    final amount = _extractKrwAmount(command);
    if (amount == null || amount <= 0) {
      return VoiceCommandResult(
        command: command,
        success: false,
        message: '금액을 인식하지 못했어요. "지출 입력 5천원 커피"처럼 말해주세요.',
        type: VoiceCommandType.navigation,
      );
    }

    final description = _extractExpenseDescription(command);
    // Use QuickSimpleExpenseInputScreen with pre-filled line
    final prefilledLine = '$description ${amount.toInt()}';

    _suspendAutoListen = true;
    if (_isListening) await _stopListening();

    if (!mounted) {
      return VoiceCommandResult(
        command: command,
        success: false,
        message: '화면이 종료되었습니다.',
        type: VoiceCommandType.navigation,
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.95,
          child: QuickSimpleExpenseInputScreen(
            accountName: _accountName,
            initialDate: DateTime.now(),
            initialLine: prefilledLine,
          ),
        );
      },
    );

    _suspendAutoListen = false;
    if (_autoListenEnabled && mounted) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        if (!_isListening) _startListening();
      });
    }

    return VoiceCommandResult(
      command: command,
      success: true,
      message: '간편 지출 입력을 열었습니다. (내용 자동 입력됨)',
      type: VoiceCommandType.navigation,
    );
  }

  Future<VoiceCommandResult> _handleOpenIncomeInput() async {
    final template = Transaction(
      id: 'template_income_voice',
      type: TransactionType.income,
      description: '',
      amount: 0,
      date: DateTime.now(),
      mainCategory: Transaction.defaultMainCategory,
    );

    _suspendAutoListen = true;
    if (_isListening) {
      await _stopListening();
      if (!mounted) {
        _suspendAutoListen = false;
        return VoiceCommandResult(
          command: '수입 입력 열기',
          success: false,
          message: '화면이 닫혀서 실행할 수 없습니다.',
          type: VoiceCommandType.navigation,
        );
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height;
        return SizedBox(
          height: height * 0.95,
          child: TransactionAddScreen(
            accountName: _accountName,
            initialTransaction: template,
            treatAsNew: true,
            closeAfterSave: true,
          ),
        );
      },
    );

    _suspendAutoListen = false;
    if (_autoListenEnabled && mounted) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        if (_isListening) return;
        if (_isProcessing) return;
        if (_suspendAutoListen) return;
        _startListening();
      });
    }

    return VoiceCommandResult(
      command: '수입 입력 열기',
      success: true,
      message: '수입 입력을 열었습니다.',
      type: VoiceCommandType.navigation,
    );
  }

  // --- Special Exception Handler ---
  Future<VoiceCommandResult> _handleExceptionMarking(String command) async {
    final history = TransactionService().getTransactions(_accountName);

    // 1. Find target transaction
    Transaction? target;

    if (command.contains('방금') ||
        command.contains('마지막') ||
        command.contains('그거')) {
      // Last transaction
      if (history.isNotEmpty) {
        target = history.first; // history is sorted desc
      }
    } else {
      // Search by keyword (e.g. "축의금 예외로")
      final keyword = command
          .replaceAll('예외', '')
          .replaceAll('로', '')
          .replaceAll('해줘', '')
          .replaceAll('처리', '')
          .replaceAll('그거', '')
          .trim();

      if (keyword.isNotEmpty) {
        try {
          target = history.firstWhere((t) => t.description.contains(keyword));
        } catch (e) {
          // Not found
        }
      } else {
        // Fallback to last if no keyword
        if (history.isNotEmpty) target = history.first;
      }
    }

    if (target == null) {
      return VoiceCommandResult(
        command: command,
        success: false,
        message: '예외 처리할 내역을 찾지 못했어요. "방금 그거 예외로 해줘" 또는 "병원비 예외로 해줘"처럼 말해주세요.',
        type: VoiceCommandType.unknown,
      );
    }

    // 2. Mark as Exception (Update Category or Description tag)
    // We append [예외] tag to description for simple persistence without schema change
    // Or we handle it via category logic update.
    // Let's use a Special Category "특별예산" or "예외지출".

    final oldDesc = target.description;
    final newDesc = oldDesc.contains('[예외]') ? oldDesc : '$oldDesc [예외]';
    final oldMainCat = target.mainCategory;
    const newMainCat = '예외지출'; // Special Category

    final updatedTransaction = Transaction(
      id: target.id,
      type: target.type,
      amount: target.amount,
      date: target.date,
      description: newDesc,
      mainCategory: newMainCat, // Force move to Exception Category
      subCategory: oldMainCat, // Keep original category as sub
      store: target.store,
      memo: target.memo,
      // isExcluded: true, // Assuming Transaction model has exclude flag, or we use category filter
    );

    // Update via Delete + Add (or proper update if available)
    await TransactionService().deleteTransaction(_accountName, target.id);
    await TransactionService().addTransaction(_accountName, updatedTransaction);

    String feedback = '';
    if (oldDesc.contains('병원') || oldDesc.contains('약국')) {
      feedback = '건강이 최우선이죠! 병원비는 이번 달 예산 압박에서 제외해 드렸습니다. 쾌차하세요!';
    } else if (oldDesc.contains('축의금') || oldDesc.contains('조의금')) {
      feedback = '이해했습니다. 소중한 경조사비는 이번 달 예산 관리에서 따로 분리해둘게요. 인맥 자산 +1 하셨네요!';
    } else {
      feedback = '네, 방금 입력한 항목을 "특별 지출"로 전환했습니다. 포인트는 깎이지 않으니 안심하세요!';
    }

    return VoiceCommandResult(
      command: command,
      success: true,
      message: '🛡️ $feedback',
      type: VoiceCommandType.query,
      data: {'isException': true},
    );
  }

  /// 1. 고정지출 브리핑 핸들러
  Future<VoiceCommandResult> _handleFixedCostBriefing(String command) async {
    // Load fixed costs
    await FixedCostService().loadFixedCosts();
    final costs = FixedCostService().getFixedCosts(_accountName);

    final today = DateTime.now().day;
    final upcoming = costs.where((c) => (c.dueDay ?? 0) >= today).toList();
    upcoming.sort((a, b) => (a.dueDay ?? 0).compareTo(b.dueDay ?? 0));

    // Calculate total upcoming
    double totalRemaining = 0;
    for (final c in upcoming) {
      totalRemaining += c.amount;
    }

    final sb = StringBuffer();
    if (upcoming.isEmpty) {
      sb.write('이번 달 남은 고정 지출이 없습니다. 마음 편히 지내세요! 😄');
    } else {
      sb.write('네, ${upcoming.length}건의 고정 지출이 남아있어요.\n');
      for (final c in upcoming) {
        sb.write(
          '${c.dueDay}일 ${c.name} (${CurrencyFormatter.format(c.amount)})\n',
        );
      }
      sb.write('\n총 ${CurrencyFormatter.format(totalRemaining)}은 남겨두셔야 해요.');
    }

    return VoiceCommandResult(
      command: command,
      success: true,
      message: sb.toString(),
      type: VoiceCommandType.query, // or briefing
    );
  }

  /// 2. 지출 조언 (예산 코칭) 핸들러
  Future<VoiceCommandResult> _handleSpendingAdvice(String command) async {
    // 1. Parse amount request (e.g., "10만원")
    final amount = _extractKrwAmount(command);
    if (amount == null) {
      return VoiceCommandResult(
        command: command,
        success: false,
        message: '얼마를 쓰시려는지 알 수 없어요. "10만원 사도 돼?" 처럼 물어봐주세요.',
        type: VoiceCommandType.query,
      );
    }

    // 2. Refresh Budget Data (Optional, but good for UI sync)
    // await _loadBudgetData();

    // 3. Use SmartConsumingService for analysis
    final advice = await SmartConsumingService().analyzeSpending(
      _accountName,
      amount,
    );

    return VoiceCommandResult(
      command: command,
      success:
          true, // Always return success=true so it shows as a green/valid result (unless error)
      message: '${advice.message}\n\n${advice.details}',
      type: VoiceCommandType.query,
      data: {'isResilience': advice.isResilience, 'canSpend': advice.canSpend},
    );
  }

  /// 3. 폐기물 기록 (재고 삭제) 핸들러
  Future<VoiceCommandResult> _handleWasteLog(String command) async {
    // Extract Item Name
    final itemName = command
        .replaceAll('버렸어', '')
        .replaceAll('버림', '')
        .replaceAll('상해서', '')
        .replaceAll('상했어', '')
        .replaceAll('폐기', '')
        .replaceAll('썩어서', '')
        .trim();

    if (itemName.isEmpty) {
      return VoiceCommandResult(
        command: command,
        success: false,
        message: '무엇을 버리셨나요? "우유 버렸어" 처럼 말씀해주세요.',
        type: VoiceCommandType.unknown,
      );
    }

    // Find and Delete from Inventory
    final foodItems = FoodExpiryService.instance.items.value;
    final target = foodItems
        .where((i) => i.name.contains(itemName) || itemName.contains(i.name))
        .toList();

    if (target.isEmpty) {
      return VoiceCommandResult(
        command: command,
        success: false,
        message: '냉장고 목록에서 "$itemName"을(를) 찾을 수 없어요. 이미 지우셨나요?',
        type: VoiceCommandType.unknown,
      );
    }

    // Delete first match
    final itemToDelete = target.first;
    // FoodExpiryService uses deleteById for deletion
    await FoodExpiryService.instance.deleteById(itemToDelete.id);

    // Tip Logic (Advanced: Check past waste history)
    // For now, simple scripted advice
    final tip =
        '아이고, 아까운 $itemName가 버려졌네요. 폐기 로그에 저장했습니다. 다음엔 유통기한 임박 알림을 더 크게 드릴게요! 장바구니에 다시 넣어둘까요?';

    return VoiceCommandResult(
      command: command,
      success: true,
      message: '🥛 폐기 로그 저장: $itemName (유통기한 경과)\n\n$tip',
      type: VoiceCommandType.expense, // Using expensetype as it's a loss
    );
  }

  VoiceCommandResult _handleIngredientQuery(String command) {
    // 식재료 서비스에서 조회
    final items = FoodExpiryService.instance.items.value;

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
        final days = i.expiryDate.difference(DateTime.now()).inDays;
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
        final daysLeft = item.expiryDate.difference(DateTime.now()).inDays;
        final quantityStr = '${item.quantity}${item.unit}';

        return VoiceCommandResult(
          command: command,
          success: true,
          message:
              '${item.name} $quantityStr 남아있네요. '
              '${daysLeft >= 0 ? '유통기한은 $daysLeft일 남았어요.' : '유통기한이 지났어요!'}',
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

  Future<VoiceCommandResult> _handleComplexMealQuery(String command) async {
    // 1. 유통기한 임박 재료 (Food Expiry)
    final foodItems = FoodExpiryService.instance.items.value;
    final now = DateTime.now();
    final expiringFood = foodItems.where((i) {
      final days = i.expiryDate.difference(now).inDays;
      return days >= -1 && days <= 3; // 어제 만료 ~ 3일 후 만료
    }).toList();
    // Sort by most urgent
    expiringFood.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    // 2. 레시피 매칭 (Recipe Service)
    await RecipeService.instance.load();
    final recipes = RecipeService.instance.recipes.value;

    // 현재 보유 중인 모든 재료 이름 (Food Expiry + Consumables)
    final availableNames = foodItems.map((e) => e.name.trim()).toSet();
    // (Consumables are usually not food, but just in case user mixes them)
    // final consumableItems = ConsumableInventoryService.instance.items.value;
    // availableNames.addAll(consumableItems.map((e) => e.name.trim()));

    final recommended =
        <Map<String, dynamic>>[]; // {recipe, missingCount, missingItems}

    for (final recipe in recipes) {
      int missingCount = 0;
      final missingItems = <String>[];

      for (final ingredient in recipe.ingredients) {
        // Simple name match. In real app, fuzzy search is better
        final hasItem = availableNames.any(
          (n) => n.contains(ingredient.name) || ingredient.name.contains(n),
        );
        if (!hasItem) {
          missingCount++;
          missingItems.add(ingredient.name);
        }
      }

      if (missingCount == 0) {
        recommended.add({'recipe': recipe, 'missingCount': 0, 'missing': []});
      } else if (missingCount <= 2) {
        recommended.add({
          'recipe': recipe,
          'missingCount': missingCount,
          'missing': missingItems,
        });
      }
    }

    // Sort: Fully match first, then by missing count
    recommended.sort((a, b) {
      final mA = a['missingCount'] as int;
      final mB = b['missingCount'] as int;
      return mA.compareTo(mB);
    });

    // Build Response
    final sb = StringBuffer();

    // Step 1: Expiring Alert
    if (expiringFood.isNotEmpty) {
      final top = expiringFood.take(3).map((e) => e.name).join(', ');
      sb.write('유통기한이 임박한 $top 등이 있어요. 우선 드시는 게 좋겠어요.\n');
    } else {
      sb.write('유통기한 걱정 없는 신선한 냉장고네요!\n');
    }

    // Step 2: Recipe Recommendation
    if (recommended.isEmpty) {
      sb.write('현재 재료로 딱 맞는 레시피를 찾지 못했어요. 장을 좀 보셔야 할 것 같아요.');
    } else {
      // 100% Match
      final perfect = recommended.where((r) => r['missingCount'] == 0).toList();
      if (perfect.isNotEmpty) {
        final rName = (perfect.first['recipe'] as dynamic).name;
        sb.write('현재 재료로 "$rName" 요리가 가능해요! 바로 해드실 수 있어요.');
      } else {
        // Partial Match
        final partial = recommended.first;
        final rName = (partial['recipe'] as dynamic).name;
        final missing = (partial['missing'] as List).join(', ');
        sb.write('"$rName" 어떠세요? $missing만 사오면 만들 수 있어요.');
      }
    }

    return VoiceCommandResult(
      command: command,
      success: true,
      message: sb.toString(),
      type: VoiceCommandType.recommend,
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 16)),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
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
  Widget _buildStatusBar(ColorScheme colorScheme) {
    final isActive = _isListening || _isProcessing;
    final statusColor = isActive ? Colors.green : colorScheme.outline;
    final statusText = _isListening
        ? '🟢 듣고 있어요...'
        : _isProcessing
        ? '⏳ 처리 중...'
        : '⚪ 대기 중';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_isListening)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (!_speechAvailable)
                Chip(
                  label: const Text('음성 인식 불가'),
                  backgroundColor: colorScheme.errorContainer,
                  labelStyle: TextStyle(
                    color: colorScheme.onErrorContainer,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (_currentText.isNotEmpty || _lastRecognizedText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.format_quote,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentText.isNotEmpty
                          ? _currentText
                          : _lastRecognizedText,
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 예산 카드 (3단계 계층)
  Widget _buildBudgetCard(ColorScheme colorScheme) {
    final remaining = _todayBudget - _todaySpent;
    final isOver = remaining < 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1단계: 현재 예산
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '현재 한 끼 예산',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  CurrencyFormatter.format(remaining.abs()),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isOver ? colorScheme.error : colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (isOver)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '⚠️ 예산 초과!',
                  style: TextStyle(color: colorScheme.error, fontSize: 12),
                ),
              ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // 2단계: 비용 분류
            Row(
              children: [
                Expanded(
                  child: _buildCostChip('🥬 식재료비', _foodExpense, Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCostChip('📦 고정비', _fixedCost, Colors.orange),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3단계: 진행 바
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_todaySpent / _todayBudget).clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  isOver ? colorScheme.error : colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '사용: ${CurrencyFormatter.format(_todaySpent)}',
                  style: TextStyle(fontSize: 12, color: colorScheme.outline),
                ),
                Text(
                  '예산: ${CurrencyFormatter.format(_todayBudget)}',
                  style: TextStyle(fontSize: 12, color: colorScheme.outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostChip(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 최근 활동 카드
  Widget _buildRecentActivityCard(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  '최근 음성 입력',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_recentResults.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.mic_none,
                        size: 48,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '아래 마이크 버튼을 눌러 말해보세요',
                        style: TextStyle(color: colorScheme.outline),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._recentResults.take(3).map(_buildResultTile),
          ],
        ),
      ),
    );
  }

  Widget _buildResultTile(VoiceCommandResult result) {
    final colorScheme = Theme.of(context).colorScheme;
    final isException =
        result.data != null && result.data!['isException'] == true;

    final icon = isException
        ? Icons.shield
        : (result.success ? Icons.check_circle : Icons.error);
    final color = isException
        ? Colors.amber.shade700
        : (result.success ? Colors.green : colorScheme.error);

    return AnimatedBuilder(
      animation: _feedbackAnimation,
      builder: (context, child) {
        final isLatest =
            _recentResults.isNotEmpty && _recentResults.first == result;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isLatest
                ? color.withValues(alpha: 0.1 * _feedbackAnimation.value)
                : (isException
                      ? Colors.amber.withValues(alpha: 0.05)
                      : colorScheme.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(8),
            border: isException
                ? Border.all(color: Colors.amber, width: 1.5)
                : (isLatest
                      ? Border.all(color: color.withValues(alpha: 0.5))
                      : null),
            boxShadow: (isException && isLatest)
                ? [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: isException ? 24 : 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.message,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (result.data != null && result.data!['amount'] != null)
                      Text(
                        '${result.data!['description']} '
                        '• ${result.data!['category']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
  Widget _buildVoiceGuideCard(ColorScheme colorScheme) {
    final currentGuide = _voiceGuidePages[_selectedGuideIndex];
    final levelColor = Color(currentGuide.levelColorValue);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Icon(Icons.school, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  '🎓 보이스 가이드',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showFullVoiceGuide,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('전체보기'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 레벨 선택 탭 버튼
            Row(
              children: List.generate(_voiceGuidePages.length, (index) {
                final guide = _voiceGuidePages[index];
                final color = Color(guide.levelColorValue);
                final isSelected = _selectedGuideIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGuideIndex = index),
                    child: Container(
                      margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color
                            : color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: color.withValues(
                            alpha: isSelected ? 1.0 : 0.3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            guide.levelEmoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            guide.level,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            // 선택된 가이드 콘텐츠
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildGuideContent(
                key: ValueKey(_selectedGuideIndex),
                guide: currentGuide,
                levelColor: levelColor,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideContent({
    required Key key,
    required _VoiceGuideData guide,
    required Color levelColor,
    required ColorScheme colorScheme,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            levelColor.withValues(alpha: 0.12),
            levelColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: levelColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Text(
            guide.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: levelColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            guide.description,
            style: TextStyle(fontSize: 12, color: colorScheme.outline),
          ),
          const SizedBox(height: 10),
          // 예시 문장들
          ...guide.examples.map(
            (example) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () {
                  final command = example.replaceAll('"', '');
                  _processVoiceCommand(command);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: levelColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 16,
                        color: levelColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          example,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // 팁
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 14, color: levelColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  guide.tip,
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: levelColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 전체 보이스 가이드 다이얼로그
  void _showFullVoiceGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          final colorScheme = Theme.of(context).colorScheme;
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // 핸들
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 헤더
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.school, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        '🎓 보이스 가이드 - 완전 정복!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // 콘텐츠
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildGuideSection(
                        title: '🌱 초급 - 첫 걸음',
                        color: Colors.green,
                        items: const [
                          _GuideItem(
                            command: '지출 3,000원 입력해줘',
                            description: '가장 기본적인 지출 입력',
                            category: '기타',
                          ),
                          _GuideItem(
                            command: '5천원 썼어',
                            description: '간단하게 금액만 말하기',
                            category: '기타',
                          ),
                          _GuideItem(
                            command: '예산 얼마 남았어?',
                            description: '오늘 남은 예산 확인',
                            category: '조회',
                          ),
                          _GuideItem(
                            command: '오늘 얼마 썼어?',
                            description: '오늘 지출 총액 확인',
                            category: '조회',
                          ),
                        ],
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 20),
                      _buildGuideSection(
                        title: '🌿 중급 - 스마트 기록',
                        color: Colors.orange,
                        items: const [
                          _GuideItem(
                            command: '팽이버섯 1봉 썼어',
                            description: '재료명 + 수량으로 기록',
                            category: '식비 자동분류',
                          ),
                          _GuideItem(
                            command: '달걀 한판 6천원',
                            description: '재료 + 금액 함께 기록',
                            category: '식재료 자동분류',
                          ),
                          _GuideItem(
                            command: '남은 양파 얼마야?',
                            description: '냉장고 재고 확인',
                            category: '재료 조회',
                          ),
                          _GuideItem(
                            command: '우유 장바구니 추가',
                            description: '장볼 목록에 추가',
                            category: '장바구니',
                          ),
                        ],
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 20),
                      _buildGuideSection(
                        title: '🌳 고급 - AI 활용',
                        color: Colors.purple,
                        items: const [
                          _GuideItem(
                            command: '오늘 남은 재료로 메뉴 추천해줘',
                            description: '유통기한 임박 재료 기반 추천',
                            category: '메뉴 추천',
                          ),
                          _GuideItem(
                            command: '3천원으로 뭐 만들지?',
                            description: '예산 맞춤 메뉴 추천',
                            category: '메뉴 추천',
                          ),
                          _GuideItem(
                            command: '냉장고에 뭐 있어?',
                            description: '전체 재료 현황 파악',
                            category: '재고 조회',
                          ),
                          _GuideItem(
                            command: '이번 주 뭐 많이 썼어?',
                            description: '지출 분석 요청',
                            category: '분석',
                          ),
                        ],
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 20),
                      _buildGuideSection(
                        title: '👑 마스터 - 복합 명령',
                        color: Colors.amber.shade700,
                        items: const [
                          _GuideItem(
                            command: '두부 천원 쓰고 장바구니에서 빼줘',
                            description: '지출 기록 + 장바구니 삭제',
                            category: '복합',
                          ),
                          _GuideItem(
                            command: '예산 확인하고 메뉴 추천해줘',
                            description: '조회 + 추천 한 번에',
                            category: '복합',
                          ),
                          _GuideItem(
                            command: '어제 점심에 뭐 먹었지?',
                            description: '과거 기록 조회',
                            category: '이력 조회',
                          ),
                          _GuideItem(
                            command: '이번 달 식비 정리해줘',
                            description: '월간 식비 분석',
                            category: '분석',
                          ),
                        ],
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 24),
                      // 팁 박스
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.tips_and_updates,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '💡 꿀팁!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text('• 마이크 버튼을 길게 누르면 계속 듣기 모드!'),
                            const SizedBox(height: 4),
                            const Text('• 예시 문장을 탭하면 바로 실행됩니다'),
                            const SizedBox(height: 4),
                            const Text('• 숫자는 "천원", "만원"처럼 자연스럽게 말해도 OK'),
                            const SizedBox(height: 4),
                            const Text('• 빅스비/시리에서도 같은 문장 사용 가능!'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuideSection({
    required String title,
    required Color color,
    required List<_GuideItem> items,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildGuideItemTile(item, color, colorScheme)),
      ],
    );
  }

  Widget _buildGuideItemTile(
    _GuideItem item,
    Color color,
    ColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _processVoiceCommand(item.command);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.mic, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"${item.command}"',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.category,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 빠른 단축어 (기존 호환)
  Widget _buildQuickCommandsCard(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, size: 20, color: colorScheme.tertiary),
                const SizedBox(width: 8),
                const Text(
                  '⚡ 빠른 명령',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCommandChip('💰 예산 확인', colorScheme),
                _buildCommandChip('🍳 메뉴 추천', colorScheme),
                _buildCommandChip('🥬 재고 확인', colorScheme),
                _buildCommandChip('📊 오늘 지출', colorScheme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandChip(String text, ColorScheme colorScheme) {
    return InkWell(
      onTap: () {
        String command;
        if (text.contains('예산')) {
          command = '예산 얼마 남았어?';
        } else if (text.contains('메뉴')) {
          command = '오늘 뭐 먹지?';
        } else if (text.contains('재고')) {
          command = '냉장고에 뭐 있어?';
        } else if (text.contains('지출')) {
          command = '오늘 얼마 썼어?';
        } else {
          command = text;
        }
        _processVoiceCommand(command);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onTertiaryContainer,
          ),
        ),
      ),
    );
  }

  /// 마이크 버튼
  Widget _buildMicrophoneButton(ColorScheme colorScheme, Size size) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              onLongPress: _startListening,
              onLongPressUp: _stopListening,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isListening ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening ? Colors.red : colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isListening
                                        ? Colors.red
                                        : colorScheme.primary)
                                    .withValues(alpha: 0.4),
                            blurRadius: _isListening ? 20 : 10,
                            spreadRadius: _isListening ? 5 : 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isListening ? '탭하여 중지' : '탭하여 말하기',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline),
            SizedBox(width: 8),
            Text('음성 제어 도움말'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('💰 지출 기록', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• "팽이버섯 2천원 지출"'),
              Text('• "점심 만원 기록해"'),
              SizedBox(height: 12),
              Text('🔍 재료 조회', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• "남은 양파 얼마야?"'),
              Text('• "달걀 있어?"'),
              SizedBox(height: 12),
              Text('📊 예산 확인', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• "예산 얼마 남았어?"'),
              Text('• "오늘 얼마 썼어?"'),
              SizedBox(height: 12),
              Text('🍳 메뉴 추천', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• "오늘 뭐 먹지?"'),
              Text('• "메뉴 추천해줘"'),
              SizedBox(height: 12),
              Text('🛒 장바구니', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• "우유 장바구니 추가"'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

// ============ 데이터 모델 ============

enum VoiceCommandType {
  expense,
  navigation,
  query,
  recommend,
  shopping,
  unknown,
}

class VoiceCommandResult {
  final String command;
  final bool success;
  final String message;
  final VoiceCommandType type;
  final Map<String, dynamic>? data;

  VoiceCommandResult({
    required this.command,
    required this.success,
    required this.message,
    required this.type,
    this.data,
  });
}

/// 보이스 가이드 아이템
class _GuideItem {
  final String command;
  final String description;
  final String category;

  const _GuideItem({
    required this.command,
    required this.description,
    required this.category,
  });
}

/// 보이스 가이드 데이터 모델
class _VoiceGuideData {
  final String level;
  final String levelEmoji;
  final int levelColorValue;
  final String title;
  final String description;
  final List<String> examples;
  final String tip;

  const _VoiceGuideData({
    required this.level,
    required this.levelEmoji,
    required this.levelColorValue,
    required this.title,
    required this.description,
    required this.examples,
    required this.tip,
  });
}
