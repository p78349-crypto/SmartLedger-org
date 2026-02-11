// ignore_for_file: invalid_use_of_protected_member
part of 'voice_dashboard_screen.dart';

/// 음성 인식 초기화 + 시작/중지.
extension VoiceDashSpeech on _VoiceDashboardScreenState {
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
        setState(() => _isListening = false);
      }
      if (_autoListenEnabled && !_suspendAutoListen) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          if (_isListening || _isProcessing || _suspendAutoListen) return;
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
        .where((t) =>
            t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day &&
            t.type == TransactionType.expense)
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
    setState(() => _isListening = false);
  }
}
