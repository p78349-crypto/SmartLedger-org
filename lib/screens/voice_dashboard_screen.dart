import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/transaction.dart';
import '../services/account_service.dart';
import '../services/budget_service.dart';
import '../services/food_expiry_service.dart';
import '../services/transaction_service.dart';
import '../services/category_keyword_service.dart';
import 'transaction_add_screen.dart';
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

    // 0. 화면 열기/이동 같은 네비게이션 명령 (금액 없이도 동작)
    if (_isOpenIncomeInputCommand(normalized)) {
      return await _handleOpenIncomeInput();
    }
    if (_isOpenExpenseInputCommand(normalized)) {
      return await _handleOpenExpenseInput();
    }

    // 0-1. 지출 입력 + 금액 포함: 폼을 미리채움으로 열기(저장까지는 사용자가 확인)
    if (_isExpenseInputWithAmountCommand(normalized)) {
      return await _handleOpenExpenseInputPrefilled(command);
    }

    // 1. 지출 기록 명령
    if (_isExpenseCommand(normalized)) {
      return await _handleExpenseCommand(command);
    }

    // 2. 재료 조회 명령
    if (_isIngredientQueryCommand(normalized)) {
      return _handleIngredientQuery(command);
    }

    // 3. 예산 조회 명령
    if (_isBudgetQueryCommand(normalized)) {
      return _handleBudgetQuery();
    }

    // 4. 메뉴 추천 명령
    if (_isMenuRecommendCommand(normalized)) {
      return _handleMenuRecommend();
    }

    // 5. 장바구니 추가 명령
    if (_isShoppingCartCommand(normalized)) {
      return _handleShoppingCartAdd(command);
    }

    // 6. 오늘 지출 요약
    if (_isTodaySummaryCommand(normalized)) {
      return _handleTodaySummary();
    }

    return VoiceCommandResult(
      command: command,
      success: false,
      message: '이해하지 못했어요. 다시 말씀해 주세요.',
      type: VoiceCommandType.unknown,
    );
  }

  // ============ 명령어 감지 ============

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
        cmd.contains('지불');

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
    final hasOpen = cmd.contains('열어') ||
      cmd.contains('열러') ||
      cmd.contains('켜') ||
      cmd.contains('띄워');
    final hasMove = cmd.contains('가') || cmd.contains('이동') || cmd.contains('진입');

    // e.g. "지출 입력 열어줘", "지출입력 열어", "지출 입력으로 이동"
    return (hasInput && (hasOpen || hasMove)) || cmd.contains('지출입력');
  }

  bool _isOpenIncomeInputCommand(String cmd) {
    final hasIncome = cmd.contains('수입');
    if (!hasIncome) return false;

    final hasInput = cmd.contains('입력') || cmd.contains('입력창');
    final hasOpen = cmd.contains('열어') ||
        cmd.contains('열러') ||
        cmd.contains('켜') ||
        cmd.contains('띄워');
    final hasMove = cmd.contains('가') || cmd.contains('이동') || cmd.contains('진입');

    return (hasInput && (hasOpen || hasMove)) || cmd.contains('수입입력');
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
    return cmd.contains('뭐 먹') ||
        cmd.contains('메뉴 추천') ||
        cmd.contains('뭐 해먹') ||
        cmd.contains('요리 추천');
  }

  bool _isShoppingCartCommand(String cmd) {
    return cmd.contains('장바구니') ||
        cmd.contains('장볼것') ||
        cmd.contains('사야') && cmd.contains('추가');
  }

  bool _isTodaySummaryCommand(String cmd) {
    return cmd.contains('오늘') &&
        (cmd.contains('얼마') || cmd.contains('지출') || cmd.contains('요약'));
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

  Future<VoiceCommandResult> _handleExpenseCommand(String command) async {
    final amount = _extractKrwAmount(command);
    if (amount == null) {
      return VoiceCommandResult(
        command: command,
        success: false,
        message: '금액을 인식하지 못했어요. "지출 5천원 커피 기록"처럼 말해주세요.',
        type: VoiceCommandType.expense,
      );
    }

    if (amount <= 0) {
      return VoiceCommandResult(
        command: command,
        success: false,
        message: '유효하지 않은 금액입니다.',
        type: VoiceCommandType.expense,
      );
    }

    final description = _extractExpenseDescription(command);

    // 카테고리 자동 분류
    final category = CategoryKeywordService.instance.classify(description);
    final mainCategory = category?.$1 ?? '식비';

    // 거래 생성 및 저장
    final transaction = Transaction(
      id: 'voice_${DateTime.now().millisecondsSinceEpoch}',
      type: TransactionType.expense,
      amount: amount,
      date: DateTime.now(),
      description: description,
      mainCategory: mainCategory,
    );

    await TransactionService().addTransaction(_accountName, transaction);

    return VoiceCommandResult(
      command: command,
      success: true,
      message: '$description ${CurrencyFormatter.format(amount)} 기록 완료!',
      type: VoiceCommandType.expense,
      data: {
        'amount': amount,
        'description': description,
        'category': mainCategory,
      },
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
    final category = CategoryKeywordService.instance.classify(description);
    final mainCategory = category?.$1 ?? '식비';

    final template = Transaction(
      id: 'template_expense_voice',
      type: TransactionType.expense,
      amount: amount,
      date: DateTime.now(),
      description: description,
      mainCategory: mainCategory,
    );

    return _handleOpenExpenseInput(
      initialTransaction: template,
      treatAsNew: true,
      openedFromCommand: command,
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
            '현재 $count개의 재료가 있어요. '
            '${expiringSoon > 0 ? '$expiringSoon개는 곧 유통기한이에요.' : ''}',
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
              '${item.name} $quantityStr 있어요. '
              '${daysLeft >= 0 ? '$daysLeft일 남았어요.' : '유통기한이 지났어요!'}',
          type: VoiceCommandType.query,
          data: {'item': item.name, 'daysLeft': daysLeft},
        );
      }
    }

    return VoiceCommandResult(
      command: command,
      success: true,
      message: '해당 재료를 찾지 못했어요.',
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
    // 유통기한 임박 재료 기반 추천
    final items = FoodExpiryService.instance.items.value;
    final expiringSoon = items.where((i) {
      final days = i.expiryDate.difference(DateTime.now()).inDays;
      return days >= 0 && days <= 3;
    }).toList();

    if (expiringSoon.isEmpty) {
      return VoiceCommandResult(
        command: '메뉴 추천',
        success: true,
        message: '유통기한 임박 재료가 없어요. 냉장고를 확인해보세요!',
        type: VoiceCommandType.recommend,
      );
    }

    final ingredient = expiringSoon.first.name;
    return VoiceCommandResult(
      command: '메뉴 추천',
      success: true,
      message: '$ingredient이(가) 곧 상해요! $ingredient을(를) 활용한 요리를 추천해 드릴까요?',
      type: VoiceCommandType.recommend,
      data: {'ingredient': ingredient},
    );
  }

  VoiceCommandResult _handleShoppingCartAdd(String command) {
    // 장바구니 추가 (실제 구현은 ShoppingCartService 연동 필요)
    final item = command
        .replaceAll('장바구니', '')
        .replaceAll('추가', '')
        .replaceAll('사야', '')
        .replaceAll('장볼것', '')
        .trim();

    if (item.isEmpty) {
      return VoiceCommandResult(
        command: command,
        success: false,
        message: '추가할 품목을 말씀해 주세요.',
        type: VoiceCommandType.shopping,
      );
    }

    // TODO: ShoppingCartService에 실제 추가
    return VoiceCommandResult(
      command: command,
      success: true,
      message: '$item을(를) 장바구니에 추가했어요.',
      type: VoiceCommandType.shopping,
      data: {'item': item},
    );
  }

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
    final icon = result.success ? Icons.check_circle : Icons.error;
    final color = result.success ? Colors.green : colorScheme.error;

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
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: isLatest
                ? Border.all(color: color.withValues(alpha: 0.5))
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
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
      title: '기본 지출 기록',
      description: '간단한 금액부터 시작해보세요!',
      examples: ['"지출 3,000원 기록해줘"', '"5천원 썼어"', '"점심 만원"'],
      tip: '금액만 말해도 자동으로 기록됩니다',
    ),
    _VoiceGuideData(
      level: '중급',
      levelEmoji: '🌿',
      levelColorValue: 0xFFFF9800, // Colors.orange
      title: '재료와 함께 기록',
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
                            command: '지출 3,000원 기록해줘',
                            description: '가장 기본적인 지출 기록',
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
