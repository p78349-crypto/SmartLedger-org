import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/consumable_inventory_item.dart';
import '../services/consumable_inventory_service.dart';
import '../services/user_pref_service.dart';
import '../services/aicore_gemini_service.dart';
import '../utils/quick_stock_use_utils.dart';
import '../navigation/app_routes_paths.dart';
import '../navigation/app_routes_args.dart' as route_args;
import '../navigation/deep_link_handler.dart';
import '../utils/constants.dart';
import '../utils/wms_data_gateway.dart';

part 'quick_stock_use_screen.action_row.dart';
part 'quick_stock_use_screen.build.dart';
part 'quick_stock_use_screen.search.dart';
part 'quick_stock_use_screen.selected_item.dart';
part 'quick_stock_use_screen.stock_sheet.dart';
part 'quick_stock_use_screen.submit.dart';
part 'quick_stock_use_screen.suggestion_widgets.dart';
part 'quick_stock_use_screen.voice.dart';

/// 식료품/생활용품 사용기록 화면
///
/// 상품명 입력 → 사용량 입력 → 자동 차감
class QuickStockUseScreen extends StatefulWidget {
  final String accountName;
  final String? initialProductName;
  final double? initialAmount;
  final bool autoSubmit;

  const QuickStockUseScreen({
    super.key,
    required this.accountName,
    this.initialProductName,
    this.initialAmount,
    this.autoSubmit = false,
  });

  /// 라우트 인자에서 생성
  factory QuickStockUseScreen.fromArgs(QuickStockUseArgs args) {
    return QuickStockUseScreen(
      accountName: args.accountName,
      initialProductName: args.initialProductName,
      initialAmount: args.initialAmount,
      autoSubmit: args.autoSubmit,
    );
  }

  @override
  State<QuickStockUseScreen> createState() => _QuickStockUseScreenState();
}

class _QuickStockUseScreenState extends State<QuickStockUseScreen> {
  @override
  void initState() {
    super.initState();
    WmsInventoryGateway.instance.getItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('빠른 재고 차감'), centerTitle: true),
      body: _QuickStockUseBody(
        accountName: widget.accountName,
        initialProductName: widget.initialProductName,
        initialAmount: widget.initialAmount,
        autoSubmit: widget.autoSubmit,
      ),
    );
  }
}

class _QuickStockUseBody extends StatefulWidget {
  final String accountName;
  final String? initialProductName;
  final double? initialAmount;
  final bool autoSubmit;

  const _QuickStockUseBody({
    required this.accountName,
    this.initialProductName,
    this.initialAmount,
    this.autoSubmit = false,
  });

  @override
  State<_QuickStockUseBody> createState() => _QuickStockUseBodyState();
}

class _QuickStockUseBodyState extends State<_QuickStockUseBody> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController(text: '1');
  final FocusNode _entButtonFocus = FocusNode();
  final AICoreGeminiService _aicore = AICoreGeminiService();

  // 음성 인식
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _recognizedText = '';

  ConsumableInventoryItem? _selectedItem;
  List<ConsumableInventoryItem> _suggestions = [];
  List<String> _shoppingHistoryNames = [];
  List<String> _historySuggestions = [];
  List<_RecentUse> _recentUses = [];

  // 상품별 단위/중량/가격 참조 테이블
  static const Map<String, _ProductUnitInfo> _productUnitMap = {
    '달걀': _ProductUnitInfo(unit: '판', weightPerUnit: 600, pricePerUnit: 6500),
    '팽이버섯': _ProductUnitInfo(unit: '봉', weightPerUnit: 200, pricePerUnit: 1200),
    '양파': _ProductUnitInfo(unit: '개', weightPerUnit: 200, pricePerUnit: 800),
    '감자': _ProductUnitInfo(unit: '개', weightPerUnit: 150, pricePerUnit: 700),
    '당근': _ProductUnitInfo(unit: '개', weightPerUnit: 200, pricePerUnit: 1000),
    '대파': _ProductUnitInfo(unit: '단', weightPerUnit: 300, pricePerUnit: 2000),
    '두부': _ProductUnitInfo(unit: '모', weightPerUnit: 350, pricePerUnit: 1500),
    '우유': _ProductUnitInfo(unit: '팩', weightPerUnit: 1000, pricePerUnit: 2800),
    // 생활용품 (중량 0)
    '휴지': _ProductUnitInfo(unit: '롤', weightPerUnit: 0, pricePerUnit: 500),
    '세제': _ProductUnitInfo(unit: '개', weightPerUnit: 0, pricePerUnit: 8000),
    '샴푸': _ProductUnitInfo(unit: '개', weightPerUnit: 0, pricePerUnit: 9000),
  };

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
    _amountController.addListener(_onAmountChanged);
    _loadShoppingHistoryNames();
    if (AppConstants.voiceInputEnabled) {
      _initSpeech();
    }

    if (widget.initialProductName != null &&
        widget.initialProductName!.isNotEmpty) {
      _nameController.text = widget.initialProductName!;

      if (widget.initialAmount != null && widget.initialAmount! > 0) {
        _amountController.text = _formatQty(widget.initialAmount!);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onNameChanged();

        if (widget.autoSubmit && _selectedItem != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _submit();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _entButtonFocus.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildMain(context);
}

// ── Helper data classes ──

class _RecentUse {
  final String name;
  final double amount;
  final String unit;
  final double remaining;
  final DateTime time;
  final double shortage;
  final bool addedToCart;

  _RecentUse({
    required this.name,
    required this.amount,
    required this.unit,
    required this.remaining,
    required this.time,
    this.shortage = 0,
    this.addedToCart = false,
  });
}

class _ScoredName {
  final String name;
  final int score;

  const _ScoredName({required this.name, required this.score});
}

/// 상품 단위/중량/가격 정보
class _ProductUnitInfo {
  final String unit;
  final int weightPerUnit;
  final int pricePerUnit;

  const _ProductUnitInfo({
    required this.unit,
    required this.weightPerUnit,
    required this.pricePerUnit,
  });
}

/// 음성 명령 파싱 결과
class _VoiceParsedResult {
  final String productName;
  final int amount;
  final String? unit;

  const _VoiceParsedResult({
    required this.productName,
    required this.amount,
    this.unit,
  });
}
