import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/app_routes.dart';
import '../navigation/global_navigator_key.dart';
import '../services/account_service.dart';
import '../services/aicore_gemini_service.dart';
import '../services/voice_input_bridge.dart';
import '../utils/pref_keys.dart';
import 'voice_expense_parser.dart';

/// Delegate interface for voice command side effects.
abstract class VoiceCommandDelegate {
  Future<void> speak(String text);
  void startListening();
  void stopAndExit();
  void setProcessing(bool processing);
  void showResultMessage(bool success, String message);
}

/// Handles voice command interpretation, NLU, and navigation.
class VoiceCommandHandler {
  VoiceCommandHandler({required this.delegate});

  final VoiceCommandDelegate delegate;
  final AICoreGeminiService _aicore = AICoreGeminiService();

  /// 대화 단계 관리
  String currentStep = 'idle';

  /// 지출 데이터 임시 저장
  String? tempExpenseItem;
  String? tempExpensePrice;

  /// 임시 데이터 초기화
  void reset() {
    tempExpenseItem = null;
    tempExpensePrice = null;
    currentStep = 'idle';
  }

  /// 구글 어시스턴트 전용 지출 화면 열기 보장
  Future<void> ensureQuickExpenseScreen() async {
    bool alreadyOnScreen = false;
    final navState = appNavigatorKey.currentState;

    if (navState != null) {
      navState.popUntil((route) {
        if (route.settings.name == AppRoutes.quickSimpleExpenseInput) {
          alreadyOnScreen = true;
        }
        return true; // 실제로 팝(pop)하지 않음
      });
    }

    if (!alreadyOnScreen) {
      await goToQuickExpenseAndListen();
      await Future.delayed(const Duration(milliseconds: 700));
    }
  }

  /// 음성 명령 처리 - Google Assistant 페르소나
  Future<void> handleVoiceCommand(String text) async {
    final lowerText = text.toLowerCase().trim();

    final isYes = containsAny(lowerText, [
      '네', '응', '어', '그래', '좋아', '기록해',
      '맞아', '해줘', '저장', '기록', '확인',
    ]);
    final isNo = containsAny(lowerText, [
      '아니', '됐어', '취소', '그만', '안 해', '틀려', '아냐',
    ]);

    switch (currentStep) {
      case 'confirm_start':
        if (isYes) {
          currentStep = 'ask_item';
          await ensureQuickExpenseScreen();
          await delegate.speak('네, 입력할 품목을 말씀해 주세요.');
          delegate.startListening();
        } else if (isNo) {
          await delegate.speak(
            '알겠습니다. 더 필요하신 작업이 있으면 언제든 말씀해 주세요.',
          );
          currentStep = 'idle';
          delegate.stopAndExit();
        } else {
          await _handleGoogleNlu(text);
        }
        break;

      case 'ask_open_expense':
        if (isYes) {
          await delegate.speak('네, 지출 입력 화면을 열어 드릴게요.');
          await ensureQuickExpenseScreen();
          currentStep = 'ask_item';
          await delegate.speak('이제 입력할 품목을 말씀해 주세요.');
          delegate.startListening();
        } else if (isNo) {
          await delegate.speak(
            '알겠습니다. 지출 화면을 열지 않고 대화를 마칩니다.',
          );
          currentStep = 'idle';
          delegate.stopAndExit();
        } else {
          await _handleGoogleNlu(text);
        }
        break;

      case 'ask_item':
        if (text.isNotEmpty) {
          tempExpenseItem = text;
          currentStep = 'ask_price';
          VoiceInputBridge.instance.sendInput(tempExpenseItem!);
          await delegate.speak('금액은 얼마인가요?');
          delegate.startListening();
        }
        break;

      case 'ask_price':
        if (text.isNotEmpty) {
          tempExpensePrice = text;
          currentStep = 'confirm_all';
          final displayPrice = tempExpensePrice!.contains('원')
              ? tempExpensePrice!
              : '$tempExpensePrice원';
          final combined = '$tempExpenseItem $displayPrice';
          VoiceInputBridge.instance.sendInput(combined);
          await delegate.speak(
            '확인했습니다. $tempExpenseItem, $displayPrice. 저장할까요?',
          );
          delegate.startListening();
        }
        break;

      case 'confirm_all':
        if (isYes) {
          await delegate.speak('네, 지출 내역을 성공적으로 저장했습니다.');
          final finalLine = '$tempExpenseItem $tempExpensePrice';
          VoiceInputBridge.instance.sendInput(finalLine, submit: true);
          currentStep = 'idle';
          delegate.stopAndExit();
        } else if (isNo) {
          await delegate.speak(
            '입력을 취소했습니다. 더 도와드릴 일이 있을까요?',
          );
          currentStep = 'idle';
          delegate.stopAndExit();
        }
        break;

      default:
        await _handleGoogleNlu(text);
    }
  }

  /// Google NLU (자연어 이해) 스타일 분석
  Future<void> _handleGoogleNlu(String text) async {
    final lowerText = text.toLowerCase();

    // 1. 인사 응답
    if (containsAny(lowerText, ['안녕', '반가워', '누구니', '이름', '뭐해'])) {
      await delegate.speak(
        '안녕하세요, 구글 어시스턴트 스타일의 가계부 비서입니다. '
        '지출을 입력하거나 통계를 확인하는 걸 도와드릴 수 있어요.',
      );
      delegate.startListening();
      return;
    }

    // 2. Gemini Nano NLU (온디바이스 전용)
    bool nanoProcessed = false;
    if (await _aicore.isAvailable()) {
      delegate.setProcessing(true);
      try {
        final result = await _aicore.processVoiceInput(text);
        if (result.containsKey('items') &&
            (result['items'] as List).isNotEmpty) {
          final first = (result['items'] as List)[0] as Map<String, dynamic>;
          final item = first['name']?.toString();
          final total = first['total']?.toString();

          if (item != null || total != null) {
            tempExpenseItem = item;
            tempExpensePrice = total;
            nanoProcessed = true;
            debugPrint('[Nano] 파싱 성공: item=$item, price=$total');
          }
        }
      } catch (e) {
        debugPrint('[Nano] Floating Button NLU Error: $e');
      } finally {
        delegate.setProcessing(false);
      }
    }

    // 3. Fallback to regex
    if (!nanoProcessed) {
      final parsed = parseExpense(text);
      tempExpenseItem = parsed['item'];
      tempExpensePrice = parsed['price'];
    }

    // 4. 지출/기록 의도 확인
    final isExpenseIntent = containsAny(lowerText, [
      '지출', '기록', '돈', '썼', '결제', '구매', '샀',
    ]);

    if (isExpenseIntent ||
        tempExpenseItem != null ||
        tempExpensePrice != null) {
      if (tempExpenseItem == null && tempExpensePrice == null) {
        currentStep = 'ask_open_expense';
        await delegate.speak('지출 화면을 열어 드릴까요?');
        delegate.startListening();
        return;
      }

      await ensureQuickExpenseScreen();

      if (tempExpenseItem != null && tempExpensePrice != null) {
        currentStep = 'confirm_all';
        final displayPrice = tempExpensePrice!.contains('원')
            ? tempExpensePrice!
            : '$tempExpensePrice원';
        final combined = '$tempExpenseItem $displayPrice';
        VoiceInputBridge.instance.sendInput(combined);
        await delegate.speak(
          '확인했습니다. $tempExpenseItem, $displayPrice 저장할까요?',
        );
      } else if (tempExpenseItem != null) {
        currentStep = 'ask_price';
        VoiceInputBridge.instance.sendInput(tempExpenseItem!);
        await delegate.speak(
          '네, $tempExpenseItem(이)군요. 금액은 얼마인가요?',
        );
      } else if (tempExpensePrice != null) {
        currentStep = 'ask_item';
        final displayPrice = tempExpensePrice!.contains('원')
            ? tempExpensePrice!
            : '$tempExpensePrice원';
        VoiceInputBridge.instance.sendInput(displayPrice);
        await delegate.speak('$displayPrice 확인했습니다. 어떤 상품인가요?');
      } else {
        currentStep = 'ask_item';
        await delegate.speak(
          '네, 지출 내역을 기록하겠습니다. 품목은 무엇인가요?',
        );
      }

      delegate.startListening();
      return;
    }

    // 수입 기록 의도
    if (containsAny(lowerText, ['수입', '입금', '월급', '받았'])) {
      await delegate.speak('알겠습니다. 수입 기록 화면을 열겠습니다.');
      await navigateToIncomeInput();
      delegate.stopAndExit();
      return;
    }

    // 조회 의도
    if (containsAny(lowerText, ['얼마', '통계', '내역', '확인'])) {
      await delegate.speak('네, 통계 화면을 열어 드릴게요.');
      await navigateToStats();
      delegate.stopAndExit();
      return;
    }

    // 이해 못함
    await delegate.speak(
      '죄송합니다. 잘 이해하지 못했어요. 지출 기록 또는 조회를 도와드릴 수 있습니다.',
    );
    delegate.startListening();
  }

  // ── Navigation ──

  Future<void> navigateToStats() async {
    final prefs = await SharedPreferences.getInstance();
    final accountName =
        prefs.getString(PrefKeys.selectedAccount)?.trim() ??
        AccountService().accounts.firstOrNull?.name ??
        '';
    if (accountName.isNotEmpty) {
      appNavigatorKey.currentState?.pushNamed(
        AppRoutes.periodStatsMonth,
        arguments: AccountArgs(accountName: accountName),
      );
    }
  }

  Future<void> navigateToIncomeInput() async {
    final prefs = await SharedPreferences.getInstance();
    final accountName =
        prefs.getString(PrefKeys.selectedAccount)?.trim() ??
        AccountService().accounts.firstOrNull?.name ??
        '';
    if (accountName.isNotEmpty) {
      appNavigatorKey.currentState?.pushNamed(
        AppRoutes.transactionAddIncome,
        arguments: TransactionAddArgs(accountName: accountName),
      );
    }
  }

  Future<void> goToQuickExpenseAndListen() async {
    final prefs = await SharedPreferences.getInstance();
    final accountName =
        prefs.getString(PrefKeys.selectedAccount)?.trim() ??
        AccountService().accounts.firstOrNull?.name;

    if (accountName == null || accountName.isEmpty) {
      await delegate.speak('계정을 먼저 생성해주세요');
      return;
    }

    appNavigatorKey.currentState?.pushNamed(
      AppRoutes.quickSimpleExpenseInput,
      arguments: QuickSimpleExpenseInputArgs(
        accountName: accountName,
        initialDate: DateTime.now(),
      ),
    );
  }
}
