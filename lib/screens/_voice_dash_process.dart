// ignore_for_file: invalid_use_of_protected_member
part of 'voice_dashboard_screen.dart';

/// 음성 명령 처리 + 분기 로직.
extension VoiceDashProcess on _VoiceDashboardScreenState {
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
        if (_recentResults.length > 5) _recentResults.removeLast();
        _isProcessing = false;
      });
      if (result.success) {
        await _loadBudgetData();
        HapticFeedback.lightImpact();
      }
      _showMessage(result.message);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _recentResults.insert(0, VoiceCommandResult(
          command: command, success: false,
          message: '처리 중 오류가 발생했습니다',
          type: VoiceCommandType.unknown));
      });
    } finally {
      if (_autoListenEnabled && mounted && !_suspendAutoListen) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          if (_isListening || _isProcessing || _suspendAutoListen) return;
          _startListening();
        });
      }
    }
  }

  Future<VoiceCommandResult> _parseAndExecuteCommand(String command) async {
    final normalized = command.toLowerCase().trim();
    debugPrint('[Voice] 명령어: "$normalized"');

    if (_isOpenIncomeInputCommand(normalized)) {
      return await _handleOpenIncomeInput();
    }
    if (_isOpenExpenseInputCommand(normalized)) {
      return await _handleOpenExpenseInput();
    }
    if (_isExpenseInputWithAmountCommand(normalized)) {
      return await _handleOpenExpenseInputPrefilled(command);
    }
    if (_isMenuRecommendCommand(normalized)) {
      return await _handleComplexMealQuery(command);
    }
    if (_isShoppingCartAddCommand(normalized)) {
      return await _handleShoppingCartAdd(command);
    }
    if (_isInventoryReportCommand(normalized)) {
      return await _handleInventoryReport(command);
    }
    if (_isFixedCostBriefingCommand(normalized)) {
      return await _handleFixedCostBriefing(command);
    }
    if (_isSpendingAdviceCommand(normalized)) {
      return await _handleSpendingAdvice(command);
    }
    if (_isWasteLogCommand(normalized)) {
      return await _handleWasteLog(command);
    }
    if (_isMonthlyClosingCommand(normalized)) {
      return await _handleMonthlyClosing(command);
    }
    if (_isExceptionMarkingCommand(normalized)) {
      return await _handleExceptionMarking(command);
    }
    if (_isNavigationCommand(normalized)) {
      return await _handleNavigationCommand(normalized);
    }
    if (_isExpenseCommand(normalized)) {
      return await _handleExpenseCommand(command);
    }
    if (_isIngredientQueryCommand(normalized)) {
      return _handleIngredientQuery(command);
    }
    if (_isBudgetQueryCommand(normalized)) {
      return _handleBudgetQuery();
    }
    if (_isMenuRecommendCommand(normalized)) {
      return _handleMenuRecommend();
    }
    if (_isShoppingCartCommand(normalized)) {
      return _handleShoppingCartAdd(command);
    }
    if (_isTodaySummaryCommand(normalized)) {
      return _handleTodaySummary();
    }

    return VoiceCommandResult(
      command: command, success: false,
      message: '이해하지 못했어요. 다시 말씀해 주세요.',
      type: VoiceCommandType.unknown);
  }
}
