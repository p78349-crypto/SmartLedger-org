import 'package:flutter/material.dart';
import '../services/ai_model_preferences_service.dart';
import '../widgets/ai_model_status_widget.dart';
import '../config/ai_security_seal.dart';

part 'ai_model_selector_screen_logic.dart';
part 'ai_model_selector_screen_ui.dart';

/// AI 모델 선택 및 관리 화면
/// 🔒 현재 보안상 이유로 AI 기능 봉인됨 (2026-02-21)
/// 사용자가 AI 기능별로 사용할 모델을 선택할 수 있음
class AiModelSelectorScreen extends StatefulWidget {
  const AiModelSelectorScreen({super.key});

  @override
  State<AiModelSelectorScreen> createState() => _AiModelSelectorScreenState();
}

class _AiModelSelectorScreenState extends State<AiModelSelectorScreen> {
  bool _useAiForCeoPrediction = true;
  bool _useAiForInvestment = true;
  bool _useAiForAnalytics = true;
  bool _preferOfflineAi = true;
  bool _isLoading = false;

  final AiModelPreferencesService _prefsService =
      AiModelPreferencesService.instance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    // 🔒 보안 봉인 체크
    if (AiSecuritySeal.isSealed && !AiSecuritySeal.isDeveloperModeEnabled) {
      return _buildSealedScreen(context);
    }

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 모델 선택'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            tooltip: '설정 저장',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AiModelStatusWidget(),
            const SizedBox(height: 20),
            _buildModelOverview(),
            const SizedBox(height: 20),
            _buildAiToggleSection(),
            const SizedBox(height: 20),
            _buildModelPreference(),
            const SizedBox(height: 20),
            _buildFeatureSettings(),
            const SizedBox(height: 20),
            _buildTestButtons(),
          ],
        ),
      ),
    );
  }

  /// 🔒 보안 봉인 상태 화면
}
