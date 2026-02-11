// ignore_for_file: invalid_use_of_protected_member
part of 'voice_dashboard_screen.dart';

/// 지출/수입 입력창 열기 핸들러.
extension VoiceDashHandlers3 on _VoiceDashboardScreenState {
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
}
