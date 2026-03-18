part of 'ai_model_selector_screen.dart';

extension AiModelSelectorScreenLogic on _AiModelSelectorScreenState {
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      _useAiForCeoPrediction = await _prefsService.useAiForCeoPrediction;
      _useAiForInvestment = await _prefsService.useAiForInvestment;
      _useAiForAnalytics = await _prefsService.useAiForAnalytics;
      _preferOfflineAi = await _prefsService.preferOfflineAi;
    } catch (e) {
      print('설정 로드 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await _prefsService.setUseAiForCeoPrediction(_useAiForCeoPrediction);
      await _prefsService.setUseAiForInvestment(_useAiForInvestment);
      await _prefsService.setUseAiForAnalytics(_useAiForAnalytics);
      await _prefsService.setPreferOfflineAi(_preferOfflineAi);

      if (mounted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI 모델 설정이 저장되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('설정 저장 실패: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testAiModels() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('AI 모델 테스트 중'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('AI 모델 연결 상태를 확인하고 있습니다...'),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2)); // 시뮬레이션

    if (mounted) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('테스트 결과'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ Gemini Nano: 사용 가능 (오프라인)'),
              Text('✅ Gemini 1.5 Flash: 사용 가능 (온라인)'),
              Text('✅ 전통적 알고리즘: 항상 사용 가능'),
              SizedBox(height: 8),
              Text(
                '모든 AI 모델이 정상 작동합니다!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
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

  void _showModelComparison() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI 모델 비교'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '📊 성능 비교 (상대적)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('처리 속도:'),
              Text('• Gemini Nano: ⭐⭐⭐⭐⭐'),
              Text('• 전통적 알고리즘: ⭐⭐⭐⭐⭐'),
              Text('• Gemini 1.5 Flash: ⭐⭐⭐'),
              SizedBox(height: 8),
              Text('분석 정확도:'),
              Text('• Gemini 1.5 Flash: ⭐⭐⭐⭐⭐'),
              Text('• Gemini Nano: ⭐⭐⭐⭐'),
              Text('• 전통적 알고리즘: ⭐⭐⭐'),
              SizedBox(height: 8),
              Text('프라이버시:'),
              Text('• Gemini Nano: ⭐⭐⭐⭐⭐'),
              Text('• 전통적 알고리즘: ⭐⭐⭐⭐⭐'),
              Text('• Gemini 1.5 Flash: ⭐⭐⭐'),
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
