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
    ConsumableInventoryService.instance.load();
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

  // 상품별 단위/중량/가격 매핑
  static const Map<String, _ProductUnitInfo> _productUnitMap = {
    '팽이버섯': _ProductUnitInfo(unit: '봉', weightPerUnit: 180, pricePerUnit: 2268),
    '새송이버섯': _ProductUnitInfo(
      unit: '팩',
      weightPerUnit: 300,
      pricePerUnit: 3500,
    ),
    '느타리버섯': _ProductUnitInfo(
      unit: '봉',
      weightPerUnit: 200,
      pricePerUnit: 2500,
    ),
    '양파': _ProductUnitInfo(unit: '개', weightPerUnit: 200, pricePerUnit: 500),
    '감자': _ProductUnitInfo(unit: '개', weightPerUnit: 150, pricePerUnit: 400),
    '당근': _ProductUnitInfo(unit: '개', weightPerUnit: 180, pricePerUnit: 600),
    '대파': _ProductUnitInfo(unit: '단', weightPerUnit: 300, pricePerUnit: 2000),
    '달걀': _ProductUnitInfo(unit: '판', weightPerUnit: 600, pricePerUnit: 6000),
    '두부': _ProductUnitInfo(unit: '모', weightPerUnit: 300, pricePerUnit: 1500),
    '우유': _ProductUnitInfo(unit: 'L', weightPerUnit: 1000, pricePerUnit: 2800),
    '식빵': _ProductUnitInfo(unit: '봉', weightPerUnit: 400, pricePerUnit: 2500),
    '돼지고기': _ProductUnitInfo(unit: 'g', weightPerUnit: 100, pricePerUnit: 1800),
    '소고기': _ProductUnitInfo(unit: 'g', weightPerUnit: 100, pricePerUnit: 4500),
    '닭고기': _ProductUnitInfo(unit: 'g', weightPerUnit: 100, pricePerUnit: 1200),
    '휴지': _ProductUnitInfo(unit: '롤', weightPerUnit: 0, pricePerUnit: 500),
    '세제': _ProductUnitInfo(unit: 'ml', weightPerUnit: 0, pricePerUnit: 8),
    '샴푸': _ProductUnitInfo(unit: 'ml', weightPerUnit: 0, pricePerUnit: 15),
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

    // 초기 상품명 설정 (딥링크/음성 어시스턴트에서 전달된 경우)
    if (widget.initialProductName != null &&
        widget.initialProductName!.isNotEmpty) {
      _nameController.text = widget.initialProductName!;

      // 초기 수량도 설정
      if (widget.initialAmount != null && widget.initialAmount! > 0) {
        _amountController.text = _formatQty(widget.initialAmount!);
      }

      // 상품 선택 처리
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onNameChanged();

        // 자동 제출이면 잠시 후 실행
        if (widget.autoSubmit && _selectedItem != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _submit();
          });
        }
      });
    }
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
              if (_recognizedText.isNotEmpty) {
                _processVoiceInput(_recognizedText);
              }
            }
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Speech init error: $e');
    }
  }

  /// 음성 입력 처리 - Gemini Nano 우선 사용, 정규식 대체
  void _processVoiceInput(String text) async {
    bool nanoProcessed = false;

    // 1. Gemini Nano 파싱 시도 (온디바이스 전용)
    try {
      if (await _aicore.isAvailable()) {
        final result = await _aicore.processVoiceInput(text);
        if (result.containsKey('items')) {
          final items = result['items'] as List;
          if (items.isNotEmpty) {
            final first = items[0] as Map<String, dynamic>;
            final name = first['name']?.toString();
            final qty =
                (first['qty'] as num?)?.toDouble() ??
                (first['total'] as num?)?.toDouble() ??
                1.0;

            if (name != null && name.isNotEmpty && mounted) {
              _applyVoiceResult(name, qty);
              nanoProcessed = true;
              debugPrint('[Nano] 재고 파싱 성공: $name $qty');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[Nano] 재고 파싱 오류: $e');
    }

    if (nanoProcessed) return;

    // 2. Fallback: 기존 정규식 파싱
    final parsed = _parseVoiceCommand(text);
    if (parsed != null && mounted) {
      _applyVoiceResult(
        parsed.productName,
        parsed.amount.toDouble(),
        unit: parsed.unit,
      );
    } else if (mounted) {
      // 파싱 실패 시 원본 텍스트를 상품명에 입력
      _nameController.text = text;
      _onNameChanged();
    }
  }

  void _applyVoiceResult(String name, double amount, {String? unit}) {
    // 상품명 설정
    _nameController.text = name;
    _onNameChanged();

    // 약간의 지연 후 수량 설정 (상품 선택 완료 대기)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _amountController.text = _formatQty(amount);
      // ENT 버튼으로 포커스 이동
      _entButtonFocus.requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎤 "$name" ${_formatQty(amount)}${unit ?? '개'} 입력됨'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  /// 음성 명령 파싱: "팽이버섯 1봉", "달걀 한판", "양파 2개"
  _VoiceParsedResult? _parseVoiceCommand(String text) {
    final cleanText = text.trim().toLowerCase();
    if (cleanText.isEmpty) return null;

    // 숫자 + 단위 패턴 찾기
    final patterns = [
      RegExp(r'(.+?)\s*(\d+)\s*(봉|개|판|팩|단|모|롤|ml|g|L)'),
      RegExp(r'(.+?)\s*(한|두|세|네|다섯)\s*(봉|개|판|팩|단|모|롤)'),
      RegExp(r'(.+?)\s*(\d+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        var productName = match.group(1)?.trim() ?? '';
        var amountStr = match.group(2) ?? '1';
        final unit = match.groupCount >= 3 ? match.group(3) : null;

        // 한글 숫자 변환
        amountStr = _convertKoreanNumber(amountStr);
        final amount = int.tryParse(amountStr) ?? 1;

        // 상품명 정규화 (앞뒤 공백, 조사 제거)
        productName = productName.replaceAll(RegExp(r'[을를이가은는]$'), '').trim();

        if (productName.isNotEmpty) {
          return _VoiceParsedResult(
            productName: productName,
            amount: amount,
            unit: unit,
          );
        }
      }
    }

    // 단순 상품명만 있는 경우
    final simpleMatch = RegExp(r'^([가-힣a-zA-Z]+)$').firstMatch(cleanText);
    if (simpleMatch != null) {
      return _VoiceParsedResult(
        productName: simpleMatch.group(1) ?? cleanText,
        amount: 1,
      );
    }

    return null;
  }

  String _convertKoreanNumber(String text) {
    const koreanNumbers = {
      '한': '1',
      '두': '2',
      '세': '3',
      '네': '4',
      '다섯': '5',
      '여섯': '6',
      '일곱': '7',
      '여덟': '8',
      '아홉': '9',
      '열': '10',
    };
    return koreanNumbers[text] ?? text;
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('음성 인식을 사용할 수 없습니다')));
      return;
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
        });
      },
      localeId: 'ko_KR',
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _entButtonFocus.dispose();
    _speech.stop();
    super.dispose();
  }

  String _formatQty(double value) {
    if (!value.isFinite) return '0';
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.000001) return rounded.toStringAsFixed(0);
    // Keep one decimal for fractional unit usage (e.g., 1.5롤/일).
    return value.toStringAsFixed(1);
  }

  void _onAmountChanged() {
    // Live preview: update the UI as the user types.
    if (!mounted) return;
    setState(() {});
  }

  void _onNameChanged() {
    final query = _nameController.text;
    setState(() {
      _suggestions = QuickStockUseUtils.searchItems(query);
      _selectedItem = QuickStockUseUtils.findExactItem(query);
      _historySuggestions = _selectedItem == null
          ? _searchHistoryNames(query, names: _shoppingHistoryNames)
          : [];
    });
  }

  List<String> _searchHistoryNames(
    String query, {
    required List<String> names,
  }) {
    final q = query.trim();
    if (q.isEmpty || names.isEmpty) return const [];

    final lowerQuery = q.toLowerCase();
    final chosungQuery = QuickStockUseUtils.extractChosung(lowerQuery);

    final scored = <_ScoredName>[];
    for (final name in names) {
      final lowerName = name.toLowerCase();
      final chosungName = QuickStockUseUtils.extractChosung(name);
      int score = 0;

      if (lowerName == lowerQuery) {
        score = 100;
      } else if (lowerName.startsWith(lowerQuery)) {
        score = 80;
      } else if (lowerName.contains(lowerQuery)) {
        score = 60;
      } else if (chosungName.startsWith(chosungQuery)) {
        score = 50;
      } else if (chosungName.contains(chosungQuery)) {
        score = 40;
      }

      if (score > 0) {
        scored.add(_ScoredName(name: name, score: score));
      }
    }

    scored.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) return cmp;
      return a.name.compareTo(b.name);
    });

    return scored.map((s) => s.name).take(20).toList(growable: false);
  }

  Future<void> _loadShoppingHistoryNames() async {
    try {
      final entries = await UserPrefService.getShoppingCartHistory(
        accountName: widget.accountName,
      );
      final seen = <String>{};
      final names = <String>[];
      for (final e in entries) {
        final n = e.name.trim();
        if (n.isEmpty) continue;
        final key = n.toLowerCase();
        if (seen.contains(key)) continue;
        seen.add(key);
        names.add(n);
      }

      if (!mounted) return;
      setState(() {
        _shoppingHistoryNames = names;
        _historySuggestions = _selectedItem == null
            ? _searchHistoryNames(_nameController.text, names: names)
            : [];
      });
    } catch (_) {
      // Best-effort: history suggestions are optional.
    }
  }

  Future<void> _createAndSelectByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final existing = QuickStockUseUtils.findExactItem(trimmed);
    if (existing != null) {
      _selectItem(existing);
      return;
    }

    await ConsumableInventoryService.instance.addItem(name: trimmed);

    final created = QuickStockUseUtils.findExactItem(trimmed);
    if (created != null) {
      _selectItem(created);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('상품 등록에 실패했습니다')));
  }

  void _selectItem(ConsumableInventoryItem item) {
    setState(() {
      _nameController.text = item.name;
      _selectedItem = item;
      _suggestions = [];
    });
  }

  /// 상품명으로 단위/중량/가격 정보 조회
  _ProductUnitInfo? _getProductUnit(String productName) {
    if (productName.isEmpty) return null;
    final lowerName = productName.toLowerCase();
    for (final entry in _productUnitMap.entries) {
      if (lowerName.contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(lowerName)) {
        return entry.value;
      }
    }
    return null;
  }

  /// 자동완성 목록 타일 - 유통기한/가격 정보 포함
  Widget _buildSuggestionTile(ConsumableInventoryItem item) {
    final isLow = item.currentStock <= item.threshold;
    final isEmpty = item.currentStock == 0;

    // 상품 가격 정보
    final productUnit = _getProductUnit(item.name);
    final priceText = productUnit != null
        ? '약 ${_formatPrice(productUnit.pricePerUnit)}원/${productUnit.unit}'
        : null;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isEmpty
            ? Colors.red
            : isLow
            ? Colors.orange
            : Colors.grey,
        child: isEmpty
            ? const Icon(Icons.warning, color: Colors.white, size: 18)
            : Text(item.name[0]),
      ),
      title: Row(
        children: [
          Expanded(child: Text(item.name)),
          if (isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '재고 없음',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📦 ${_formatQty(item.currentStock)}${item.unit}',
                style: TextStyle(
                  color: isEmpty
                      ? Colors.red
                      : isLow
                      ? Colors.orange
                      : null,
                  fontWeight: isEmpty || isLow ? FontWeight.bold : null,
                ),
              ),
              Text(' | 📍${item.location}'),
            ],
          ),
          if (priceText != null)
            Text(
              '💰 $priceText',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
        ],
      ),
      isThreeLine: priceText != null,
      onTap: isEmpty ? null : () => _selectItem(item),
    );
  }

  /// 중량/가격 힌트 위젯
  Widget _buildWeightPriceHint(_ProductUnitInfo unitInfo) {
    final amount = double.tryParse(_amountController.text) ?? 1;
    final totalWeight = (unitInfo.weightPerUnit * amount).round();
    final totalPrice = (unitInfo.pricePerUnit * amount).round();

    // 중량이 0이면 (휴지, 세제 등 비식품) 가격만 표시
    final weightText = unitInfo.weightPerUnit > 0
        ? '약 ${_formatWeight(totalWeight)}'
        : '';
    final priceText = '${_formatPrice(totalPrice)}원 차감';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              weightText.isNotEmpty
                  ? '($weightText / $priceText)'
                  : '($priceText)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatWeight(int grams) {
    if (grams >= 1000) {
      return '${(grams / 1000).toStringAsFixed(1)}kg';
    }
    return '${grams}g';
  }

  String _formatPrice(int price) {
    if (price >= 10000) {
      final man = price ~/ 10000;
      final remainder = price % 10000;
      if (remainder == 0) {
        return '$man만';
      }
      return '$man만${_formatPrice(remainder)}';
    }
    if (price >= 1000) {
      final cheon = price ~/ 1000;
      final remainder = price % 1000;
      if (remainder == 0) {
        return '$cheon,000';
      }
      return '$cheon,${remainder.toString().padLeft(3, '0')}';
    }
    return price.toString();
  }

  Widget _buildPrimaryActionRow() {
    final hasItem = _selectedItem != null;
    final stockText = hasItem
        ? '${_formatQty(_selectedItem!.currentStock)}${_selectedItem!.unit}'
        : '상품 선택';
    final pillRadius = BorderRadius.circular(8);
    const pillPadding = EdgeInsets.symmetric(vertical: 12, horizontal: 16);

    Widget buildPill({
      required Widget child,
      VoidCallback? onTap,
      EdgeInsetsGeometry? padding,
      bool isPrimary = false,
    }) {
      final enabled = onTap != null;
      final colorScheme = Theme.of(context).colorScheme;
      return Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: InkWell(
          onTap: onTap,
          borderRadius: pillRadius,
          child: Container(
            padding: padding ?? pillPadding,
            decoration: BoxDecoration(
              color: isPrimary
                  ? colorScheme.primary
                  : (enabled
                        ? colorScheme.surface
                        : colorScheme.surfaceContainerHighest),
              border: Border.all(
                width: 1.3,
                color: isPrimary ? colorScheme.primary : colorScheme.outline,
              ),
              borderRadius: pillRadius,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: buildPill(
            // 상품 선택 전: 재고 목록 보기, 선택 후: 재고 정보 표시
            onTap: hasItem
                ? () => _showStockInfo(stockText)
                : _showStockListBottomSheet,
            padding: pillPadding,
            child: Builder(
              builder: (context) {
                final colorScheme = Theme.of(context).colorScheme;
                return Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '현재고량 ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: hasItem ? stockText : '상품 ...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: hasItem
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (hasItem)
                        TextSpan(
                          text: '  ⊖ ENT',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Focus(
            focusNode: _entButtonFocus,
            child: buildPill(
              onTap: hasItem ? _submit : null,
              padding: pillPadding,
              isPrimary: true,
              child: Builder(
                builder: (context) {
                  final colorScheme = Theme.of(context).colorScheme;
                  return Center(
                    child: Text(
                      'ENT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 재고 목록 바텀시트 - 유통기한 임박순/자주 쓰는 순/재고 많은 순
  void _showStockListBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              final colorScheme = Theme.of(context).colorScheme;
              final items = ConsumableInventoryService.instance.items.value;

              // 정렬 옵션
              final sortOptions = ['유통기한 임박순', '자주 쓰는 순', '재고 많은 순', '이름순'];
              var selectedSort = '유통기한 임박순';

              // 정렬된 목록
              List<ConsumableInventoryItem> sortedItems = _sortItems(
                items,
                selectedSort,
              );

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
                          Icon(Icons.inventory_2, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            '재고 목록',
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
                    // 정렬 옵션
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: sortOptions.map((option) {
                            final isSelected = selectedSort == option;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(option),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setModalState(() {
                                      selectedSort = option;
                                      sortedItems = _sortItems(items, option);
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    // 목록
                    Expanded(
                      child: sortedItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 64,
                                    color: colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '등록된 재고가 없습니다',
                                    style: TextStyle(
                                      color: colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: sortedItems.length,
                              itemBuilder: (context, index) {
                                final item = sortedItems[index];
                                return _buildStockListTile(item, () {
                                  _selectItem(item);
                                  Navigator.pop(context);
                                });
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 재고 목록 정렬
  List<ConsumableInventoryItem> _sortItems(
    List<ConsumableInventoryItem> items,
    String sortOption,
  ) {
    final now = DateTime.now();
    final sorted = [...items];

    switch (sortOption) {
      case '유통기한 임박순':
        // 생활용품은 유통기한이 없으므로 이름순 정렬
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case '자주 쓰는 순':
        sorted.sort((a, b) {
          // 최근 30일 사용 횟수 비교
          final thirtyDaysAgo = now.subtract(const Duration(days: 30));
          final aUsage = a.usageHistory
              .where((r) => r.timestamp.isAfter(thirtyDaysAgo))
              .length;
          final bUsage = b.usageHistory
              .where((r) => r.timestamp.isAfter(thirtyDaysAgo))
              .length;
          return bUsage.compareTo(aUsage);
        });
        break;
      case '재고 많은 순':
        sorted.sort((a, b) => b.currentStock.compareTo(a.currentStock));
        break;
      case '이름순':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return sorted;
  }

  /// 재고 목록 타일
  Widget _buildStockListTile(ConsumableInventoryItem item, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLow = item.currentStock <= item.threshold;
    final isEmpty = item.currentStock == 0;

    // 최근 사용 빈도
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentUsageCount = item.usageHistory
        .where((r) => r.timestamp.isAfter(thirtyDaysAgo))
        .length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isEmpty
          ? Colors.red.shade50
          : null,
      child: ListTile(
        onTap: isEmpty ? null : onTap,
        leading: CircleAvatar(
          backgroundColor: isEmpty
              ? Colors.red
              : isLow
              ? Colors.orange
              : colorScheme.primaryContainer,
          child: isEmpty
              ? const Icon(Icons.warning, color: Colors.white, size: 18)
              : Text(
                  item.name.isNotEmpty ? item.name[0] : '?',
                  style: TextStyle(
                    color: isLow
                        ? Colors.white
                        : colorScheme.onPrimaryContainer,
                  ),
                ),
        ),
        title: Text(item.name),
        subtitle: Row(
          children: [
            Text(
              '재고: ${_formatQty(item.currentStock)}${item.unit}',
              style: TextStyle(
                color: isEmpty
                    ? Colors.red
                    : isLow
                    ? Colors.orange
                    : null,
                fontWeight: isEmpty || isLow ? FontWeight.bold : null,
              ),
            ),
            if (recentUsageCount > 0) ...[
              const SizedBox(width: 8),
              Icon(Icons.trending_up, size: 14, color: colorScheme.outline),
              Text(
                ' 최근 $recentUsageCount회',
                style: TextStyle(fontSize: 12, color: colorScheme.outline),
              ),
            ],
          ],
        ),
        trailing: isEmpty
            ? const Icon(Icons.block, color: Colors.red)
            : Icon(Icons.chevron_right, color: colorScheme.outline),
      ),
    );
  }

  void _showStockInfo(String stockText) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('현재 재고: $stockText'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedItem == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('상품을 선택해주세요')));
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사용량을 입력해주세요')));
      return;
    }

    // 재고 초과 체크
    if (amount > _selectedItem!.currentStock) {
      final currentLabel =
          '${_formatQty(_selectedItem!.currentStock)}${_selectedItem!.unit}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('재고 부족! 현재: $currentLabel'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // 개선된 차감 로직 (부족분 장바구니 자동 추가)
    final result = await QuickStockUseUtils.useStockWithShortage(
      itemId: _selectedItem!.id,
      amount: amount,
      accountName: widget.accountName,
    );

    if (mounted) {
      if (result.success) {
        // 최근 사용 기록 추가
        setState(() {
          _recentUses.insert(
            0,
            _RecentUse(
              name: _selectedItem!.name,
              amount: result.actualUsed,
              unit: _selectedItem!.unit,
              remaining: result.remaining,
              time: DateTime.now(),
              shortage: result.shortage,
              addedToCart: result.addedToCart,
            ),
          );
          if (_recentUses.length > 5) {
            _recentUses = _recentUses.take(5).toList();
          }
        });

        // 결과 메시지 생성
        String message;
        Color bgColor;

        if (result.addedToCart) {
          // 부족분이 장바구니에 추가됨
          message =
              '⚠️ ${_selectedItem!.name} '
              '${_formatQty(result.actualUsed)}${_selectedItem!.unit} 차감\n'
              '부족분 '
              '${_formatQty(result.shortage)}${_selectedItem!.unit} '
              '→ 장바구니 추가됨';
          bgColor = Colors.orange;
        } else if (result.remaining == 0) {
          // 재고 소진
          message =
              '✅ ${_selectedItem!.name} '
              '${_formatQty(result.actualUsed)}${_selectedItem!.unit} 차감 완료\n'
              '⚠️ 재고가 모두 소진되었습니다!';
          bgColor = Colors.orange.shade700;
        } else {
          // 정상 차감
          final predictionLine = result.addedToCartByPrediction
              ? '\n예상 소진 임박 → 장바구니 추가됨'
              : '';
          message =
              '✅ ${_selectedItem!.name} '
              '${_formatQty(result.actualUsed)}${_selectedItem!.unit} 차감 완료\n'
              '남은 재고: ${_formatQty(result.remaining)}${_selectedItem!.unit}'
              '$predictionLine';
          bgColor = Colors.green;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: bgColor,
            duration: const Duration(seconds: 3),
          ),
        );

        // 입력 초기화
        _nameController.clear();
        _amountController.text = '1';
        _selectedItem = null;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('차감 실패: ${result.error ?? "알 수 없는 오류"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ConsumableInventoryService.instance.items.value;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (AppConstants.voiceInputEnabled)
            Card(
              color: colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          '상품명 입력 → 사용량 입력 → ENT',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 음성 입력 버튼
                    InkWell(
                      onTap: _isListening ? _stopListening : _startListening,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _isListening
                              ? Colors.red
                              : colorScheme.primary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isListening ? Icons.stop : Icons.mic,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isListening
                                  ? '듣는 중... "$_recognizedText"'
                                  : '🎤 음성으로 입력하기',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_speechAvailable) ...[
                      const SizedBox(height: 4),
                      Text(
                        '예: "팽이버섯 1봉", "달걀 한판"',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSecondaryContainer.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            Card(
              color: colorScheme.secondaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      '상품명 입력 → 사용량 입력 → ENT',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // 상품명 입력
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '상품명',
              hintText: '휴지, 세제, 샴푸 등',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
              suffixIcon: _selectedItem != null
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
          ),

          // 자동완성 목록
          if ((_suggestions.isNotEmpty || _historySuggestions.isNotEmpty) &&
              _selectedItem == null)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final item in _suggestions) ...[
                    _buildSuggestionTile(item),
                  ],
                  if (_suggestions.isEmpty && _historySuggestions.isNotEmpty)
                    const Divider(height: 1),
                  for (final name in _historySuggestions) ...[
                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.history, size: 18),
                      ),
                      title: Text(name),
                      subtitle: const Text('쇼핑 기록에서 찾음 (탭하면 등록 후 선택)'),
                      onTap: () => _createAndSelectByName(name),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 16),

          _buildPrimaryActionRow(),

          const SizedBox(height: 16),

          // 사용량 입력 + 장바구니 버튼
          Builder(
            builder: (context) {
              // 상품별 단위 자동 설정
              final productUnit = _getProductUnit(
                _selectedItem?.name ?? _nameController.text,
              );
              final displayUnit =
                  _selectedItem?.unit ?? productUnit?.unit ?? '개';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(fontSize: 18),
                          decoration: InputDecoration(
                            labelText: '사용량',
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            suffixText: displayUnit,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 108,
                        height: 56,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.shoppingCart,
                              arguments: route_args.ShoppingCartArgs(
                                accountName: widget.accountName,
                              ),
                            );
                          },
                          child: const Text('장바구니'),
                        ),
                      ),
                    ],
                  ),
                  // 중량/가격 힌트 표시
                  if (productUnit != null) ...[
                    const SizedBox(height: 8),
                    _buildWeightPriceHint(productUnit),
                  ],
                ],
              );
            },
          ),

          if (_selectedItem != null) ...[
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final item = _selectedItem!;
                final amount = double.tryParse(_amountController.text) ?? 0;
                final used = amount < 0 ? 0 : amount;
                final remaining = item.currentStock - used;
                final remainingClamped = remaining < 0 ? 0.0 : remaining;
                final shortage = used - item.currentStock;
                final shortageClamped = shortage < 0 ? 0.0 : shortage;

                String relativeLastUpdated() {
                  final now = DateTime.now();
                  var diff = now.difference(item.lastUpdated);
                  if (diff.isNegative) diff = Duration.zero;
                  if (diff.inMinutes < 1) return '방금 전';
                  if (diff.inHours < 1) return '${diff.inMinutes}분 전';
                  if (diff.inDays < 1) return '${diff.inHours}시간 전';
                  return '${diff.inDays}일 전';
                }

                DateTime startOfDay(DateTime dt) =>
                    DateTime(dt.year, dt.month, dt.day);

                String formatDate(DateTime dt) {
                  final y = dt.year.toString().padLeft(4, '0');
                  final m = dt.month.toString().padLeft(2, '0');
                  final d = dt.day.toString().padLeft(2, '0');
                  return '$y-$m-$d';
                }

                // Usage-based expected depletion
                int? expectedDaysLeft;
                int? avgIntervalDays;
                DateTime? expectedDepletionDate;

                if (item.usageHistory.length >= 2) {
                  final sorted = [...item.usageHistory]
                    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

                  final first = sorted.first.timestamp;
                  final last = sorted.last.timestamp;
                  final spanDays = startOfDay(
                    last,
                  ).difference(startOfDay(first)).inDays.abs();
                  final denomDays = spanDays < 1 ? 1 : spanDays;
                  final totalUsed = sorted.fold<double>(
                    0.0,
                    (sum, r) => sum + r.amount,
                  );
                  final avgPerDay = totalUsed / denomDays;

                  if (avgPerDay > 0 && item.currentStock > 0) {
                    expectedDaysLeft = (item.currentStock / avgPerDay).ceil();
                    expectedDepletionDate = startOfDay(
                      DateTime.now(),
                    ).add(Duration(days: expectedDaysLeft));
                  }

                  final intervals = <int>[];
                  for (var i = 1; i < sorted.length; i++) {
                    final delta = startOfDay(
                      sorted[i].timestamp,
                    ).difference(startOfDay(sorted[i - 1].timestamp)).inDays;
                    if (delta > 0) intervals.add(delta);
                  }
                  if (intervals.isNotEmpty) {
                    final avg =
                        intervals.reduce((a, b) => a + b) / intervals.length;
                    avgIntervalDays = avg.round();
                  }
                }

                String? secondaryLine;
                Color? secondaryColor;

                if (expectedDaysLeft != null &&
                    expectedDepletionDate != null) {
                  final expectedLeft = expectedDaysLeft;
                  final expectedDate = expectedDepletionDate;

                  final avgText = avgIntervalDays == null
                      ? ''
                      : ' (평균 $avgIntervalDays일 사용)';
                  secondaryLine =
                      '예상 소진: $expectedLeft일 뒤 (${formatDate(expectedDate)})'
                      '$avgText';
                  secondaryColor = expectedLeft <= 2
                      ? Colors.orange
                      : Theme.of(context).colorScheme.onSurfaceVariant;
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  final value = item.currentStock;
                                  final label = _formatQty(value);
                                  _amountController.text = label;
                                  FocusScope.of(context).unfocus();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    '현재 '
                                    '${_formatQty(item.currentStock)}'
                                    '${item.unit} '
                                    '남음',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            if (item.currentStock > 0)
                              TextButton(
                                onPressed: () {
                                  _amountController.text = _formatQty(
                                    item.currentStock,
                                  );
                                  FocusScope.of(context).unfocus();
                                },
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('전량'),
                              ),
                            Text(
                              '최근 차감: ${relativeLastUpdated()}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                        if (secondaryLine != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            secondaryLine,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: secondaryColor),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '차감 후 예상 남은 재고: '
                                '${_formatQty(remainingClamped)}${item.unit}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (shortageClamped > 0)
                              Text(
                                '부족 ${_formatQty(shortageClamped)}${item.unit}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.orange),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],

          // 최근 사용 기록
          if (_recentUses.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text('최근 차감 기록', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...(_recentUses.map((r) {
              final hasShortage = r.shortage > 0;
              final isEmpty = r.remaining == 0;
              final minute = r.time.minute.toString().padLeft(2, '0');
              final timeLabel = '${r.time.hour}:$minute';

              return Card(
                color: hasShortage
                    ? Colors.orange.shade50
                    : isEmpty
                    ? Colors.red.shade50
                    : null,
                child: ListTile(
                  leading: Icon(
                    hasShortage
                        ? Icons.shopping_cart
                        : isEmpty
                        ? Icons.warning
                        : Icons.check_circle,
                    color: hasShortage
                        ? Colors.orange
                        : isEmpty
                        ? Colors.red
                        : Colors.green,
                  ),
                  title: Text(
                    '${r.name} -${r.amount.toStringAsFixed(0)}${r.unit}',
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEmpty
                            ? '⚠️ 재고 없음!'
                            : '남은 재고: '
                                  '${r.remaining.toStringAsFixed(0)}${r.unit}',
                        style: TextStyle(
                          color: isEmpty ? Colors.red : null,
                          fontWeight: isEmpty ? FontWeight.bold : null,
                        ),
                      ),
                      if (hasShortage)
                        Text(
                          '🛒 부족분 '
                          '${r.shortage.toStringAsFixed(0)}${r.unit} '
                          '장바구니 추가됨',
                          style: const TextStyle(color: Colors.orange),
                        ),
                    ],
                  ),
                  trailing: Text(
                    timeLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  isThreeLine: hasShortage,
                ),
              );
            })),
          ],

          // 등록된 재고가 없을 때
          if (items.isEmpty) ...[
            const SizedBox(height: 32),
            Card(
              color: Colors.orange.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 32, color: Colors.orange),
                    SizedBox(height: 8),
                    Text(
                      '등록된 재고가 없습니다.\n먼저 소모품 재고 화면에서 상품을 등록해주세요.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
  final int weightPerUnit; // 단위당 중량 (g)
  final int pricePerUnit; // 단위당 가격 (원)

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
