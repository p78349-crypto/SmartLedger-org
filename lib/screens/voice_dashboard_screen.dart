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
import 'voice_dashboard_models.dart';

part '_voice_dash_speech.dart';
part '_voice_dash_process.dart';
part '_voice_dash_cmd_check.dart';
part '_voice_dash_expense.dart';
part '_voice_dash_expense_nag.dart';
part '_voice_dash_handlers1.dart';
part '_voice_dash_handlers2.dart';
part '_voice_dash_handlers3.dart';
part '_voice_dash_handlers4.dart';
part '_voice_dash_handlers5.dart';
part '_voice_dash_ui_status.dart';
part '_voice_dash_ui_activity.dart';
part '_voice_dash_ui_guide.dart';
part '_voice_dash_ui_guide_full.dart';
part '_voice_dash_ui_bottom.dart';

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
          _buildStatusBar(colorScheme),
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
          _buildMicrophoneButton(colorScheme, size),
        ],
      ),
    );
  }
}
